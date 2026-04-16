// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.
/*!
 * CMake utility functions.
 */

// Imports
use crate::command::info;
use crate::preset;
use crate::runner;
use log::warn;

// Types
pub enum TargetStatus {
    /// The target is available in the build system.
    Available,

    /// The target is not available, with a string explaining why.
    Unavailable(String),
}
// Traits

// Implementation
pub fn expand_binary_dir(raw: &str, preset: &str) -> std::path::PathBuf {
    let source_dir = std::env::current_dir()
        .unwrap_or_default()
        .to_string_lossy()
        .into_owned();

    let expanded = raw
        .replace("${sourceDir}", &source_dir)
        .replace("${presetName}", preset)
        .replace(
            "${sourceDirName}",
            std::path::Path::new(&source_dir)
                .file_name()
                .unwrap_or_default()
                .to_string_lossy()
                .as_ref(),
        );

    std::path::PathBuf::from(expanded)
}
// Public API

/// Get the value of a variable in the CMake cache, given the build
/// directory. If the cache doesn't exist, that is not an error. If the cache
/// DOES exist, but the value isn't found, that is treated as an error.
pub fn cache_value(bdir: &std::path::Path, variable: &str) -> anyhow::Result<Option<String>> {
    let cache = bdir.join("CMakeCache.txt");
    if !cache.exists() {
        return Ok(None);
    }
    let content = std::fs::read_to_string(&cache)?;
    let value = content
        .lines()
        .find(|l| l.starts_with(&format!("{}:", variable)))
        .and_then(|l| l.split_once('=').map(|x| x.1.to_string()));
    Ok(value)
}

/// Get a boolean value out of the CMake cache, given the build directory.
pub fn cache_bool(bdir: &std::path::Path, variable: &str) -> anyhow::Result<Option<bool>> {
    let value = cache_value(bdir, variable)?;
    Ok(value.map(|v| {
        let v = v.to_uppercase();
        matches!(v.as_str(), "ON" | "YES" | "TRUE" | "Y")
            || v.parse::<f64>().map_or(false, |n| n != 0.0)
    }))
}

/// Verify that a given LIBRA feature is enabled by checking the CMake cache.
/// Will fail if the build directory doesn't exist, or the necessary feature
/// isn't enabled.
pub fn ensure_libra_feature_enabled(
    ctx: &crate::runner::Context,
    preset: &str,
    variable: &str,
) -> anyhow::Result<()> {
    if ctx.dry_run {
        return Ok(());
    }
    let bdir = binary_dir(preset).ok_or_else(|| {
        anyhow::anyhow!(
            "Build directory does not exist for preset '{}'.\n\
         Run 'libra build --preset {}' first.",
            preset,
            preset
        )
    })?;

    match cache_bool(&bdir, variable)? {
        // variable present and false — emit error
        Some(false) => anyhow::bail!(
            "Preset '{}' does not have {variable}=ON.\n\
                 Add {variable}=ON to your preset or use a preset that enables it.",
            preset
        ),
        // variable absent (non-LIBRA project) or true — proceed
        _ => Ok(()),
    }
}

/// Get the CMake generator in use, given the resolved preset. If the build
/// directory (and thus the CMake cache) doesn't exist yet, that's an error. If
/// the cache doesn't contain the `CMAKE_GENERATOR` field, that is also an error.
pub fn generator(preset: &str) -> anyhow::Result<String> {
    let bdir = binary_dir(preset).ok_or_else(|| {
        anyhow::anyhow!(
            "Build directory does not exist for preset '{}'.\n\
         Run 'clibra build' first to configure the project.",
            preset
        )
    })?;

    let content = std::fs::read_to_string(bdir.join("CMakeCache.txt"))?;
    let generator = content
        .lines()
        .find(|l| l.starts_with("CMAKE_GENERATOR:"))
        .and_then(|l| l.split_once('=').map(|x| x.1))
        .ok_or_else(|| anyhow::anyhow!("CMAKE_GENERATOR not found in CMakeCache.txt"))?
        .to_string();
    Ok(generator)
}

/// Get the build directory, given the resolved preset. Walks the preset file(s)
/// to check if the `binaryDir` field is set in the resolved preset or any of
/// its parents. If no preset files exist or `binaryDir` is not preset in
/// either, then checks for the presence of a `build/` directory in the current
/// dir. If that doesn't exist none is returned (not an error); a missing build
/// directory is perfectly valid in a cold start.
pub fn binary_dir(preset: &str) -> Option<std::path::PathBuf> {
    let path = {
        let from_user =
            preset::read_configure_preset_field("CMakeUserPresets.json", preset, "binaryDir")
                .unwrap_or(None);

        let from_project =
            preset::read_configure_preset_field("CMakePresets.json", preset, "binaryDir")
                .unwrap_or(None);
        from_user
            .or(from_project)
            .unwrap_or_else(|| "./build".to_string())
    };
    let bdir = expand_binary_dir(&path, preset);
    if bdir.exists() {
        return bdir.canonicalize().ok();
    }
    None
}

/// Get the status of a LIBRA target so that if it is missing, there's a reason
/// WHY.
///
/// Parses LIBRA diagnostic output for enabled/disabled features, so that
/// changes, this function will need to as well.
pub fn target_status(target: &str, preset: &str) -> anyhow::Result<TargetStatus> {
    let bdir = binary_dir(preset).ok_or_else(|| {
        anyhow::anyhow!(
            "Build directory does not exist for preset '{}'.\n\
         Run 'libra build --preset {}' first.",
            preset,
            preset
        )
    })?;

    let text = std::fs::read_to_string(bdir.join("libra_targets.json"))?;
    let data: info::HelpTargets = serde_json::from_str(&text)?;

    for t in data.targets {
        if t.name == target {
            return Ok(TargetStatus::Available);
        }
    }

    Ok(TargetStatus::Unavailable("unknown".to_string()))
}

pub fn reconf(
    ctx: &runner::Context,
    preset: &str,
    fresh: bool,
    defines: &[String],
) -> anyhow::Result<()> {
    let mut cmd = base_conf(preset);
    cmd.args(defines.iter().map(|d| format!("-D{}", d)));
    if fresh {
        cmd.arg("--fresh");
    }
    ctx.run(&mut cmd)?;
    Ok(())
}

pub fn base_build(preset: &str) -> std::process::Command {
    let mut cmd = std::process::Command::new("cmake");
    cmd.args(["--build", "--preset", preset]);
    cmd
}
pub fn base_conf(preset: &str) -> std::process::Command {
    let mut cmd = std::process::Command::new("cmake");
    cmd.args(["--preset", preset]);
    cmd
}
pub fn base_test(preset: &str) -> std::process::Command {
    let mut cmd = std::process::Command::new("ctest");
    cmd.args(["--preset", preset]);
    cmd
}
pub fn base_workflow(preset: &str) -> std::process::Command {
    let mut cmd = std::process::Command::new("cmake");
    cmd.args(["--workflow", "--preset", preset]);
    cmd
}

pub fn with_keep_going(
    mut cmd: std::process::Command,
    preset: &str,
) -> anyhow::Result<std::process::Command> {
    let generator = generator(preset).unwrap_or_else(|e| {
        warn!("Failed to detect CMake generator: {e}, defaulting to Unix Makefiles");
        "Unix Makefiles".to_string()
    });

    if generator == "Ninja" {
        cmd.args(["--", "-k0"]);
    } else if generator == "Unix Makefiles" {
        cmd.args(["--", "--keep-going"]);
    } else {
        anyhow::bail!("--keep-going only supported with {{Ninja, Unix Makefiles}} generators");
    }
    Ok(cmd)
}
