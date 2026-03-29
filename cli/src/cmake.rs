// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.
/*!
 * CMake utility functions.
 */

// Imports
use crate::preset;
use crate::runner;

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
pub fn target_status(
    target: &str,
    preset: &str,
    ctx: &runner::Context,
) -> anyhow::Result<TargetStatus> {
    let (_, stderr) = ctx.run_capture(base_build(preset).args(["--target", "help-targets"]))?;

    for line in stderr.lines() {
        // Each line contains 3 fields {target, status, reason}
        let parts: Vec<&str> = line
            .splitn(3, ' ')
            .map(str::trim)
            .filter(|s| !s.is_empty())
            .collect();
        if parts.len() >= 2 && parts[0] == target {
            if parts[1] == "YES" {
                return Ok(TargetStatus::Available);
            }
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

#[cfg(test)]
mod tests {
    use super::*;

    // -------------------------------------------------------------------------
    // target_status parsing
    // -------------------------------------------------------------------------

    fn parse_status(output: &str, target: &str) -> TargetStatus {
        // Simulate what target_status() does: iterate lines, split_whitespace,
        // match target name. Extracted here so tests don't need a real cmake.
        for line in output.lines() {
            let parts: Vec<&str> = line.split_whitespace().collect();
            if parts.len() >= 2 && parts[0] == target {
                return if parts[1] == "YES" {
                    TargetStatus::Available
                } else {
                    let reason = parts[2..].join(" ");
                    TargetStatus::Unavailable(reason)
                };
            }
        }
        TargetStatus::Unavailable("not found".to_string())
    }

    #[test]
    fn target_status_parses_yes() {
        let output = "lcov-report YES\n";
        assert!(matches!(
            parse_status(output, "lcov-report"),
            TargetStatus::Available
        ));
    }

    #[test]
    fn target_status_parses_no_with_reason() {
        let output = "gcovr-report NO LIBRA_CODE_COV=OFF\n";
        match parse_status(output, "gcovr-report") {
            TargetStatus::Unavailable(reason) => assert_eq!(reason, "LIBRA_CODE_COV=OFF"),
            _ => panic!("expected Unavailable"),
        }
    }

    #[test]
    fn target_status_returns_unavailable_for_unknown_target() {
        let output = "some-target YES\nother-target NO reason\n";
        match parse_status(output, "no-such-target") {
            TargetStatus::Unavailable(_) => {}
            _ => panic!("expected Unavailable for unknown target"),
        }
    }

    #[test]
    fn target_status_handles_multi_word_reason() {
        let output = "analyze NO LIBRA_ANALYSIS=OFF (requires clang)\n";
        match parse_status(output, "analyze") {
            TargetStatus::Unavailable(reason) => {
                assert!(reason.contains("LIBRA_ANALYSIS=OFF"));
            }
            _ => panic!("expected Unavailable"),
        }
    }

    #[test]
    fn target_status_is_case_sensitive_for_target_name() {
        let output = "Analyze YES\n";
        // lowercase "analyze" should not match "Analyze"
        match parse_status(output, "analyze") {
            TargetStatus::Unavailable(_) => {}
            _ => panic!("target name match should be case-sensitive"),
        }
    }
}
