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

// Public API

pub fn generator(ctx: &crate::runner::Context) -> anyhow::Result<String> {
    let bdir = binary_dir(ctx)?;
    let cache = bdir.join("CMakeCache.txt");
    let content = std::fs::read_to_string(cache)?;
    let generator = content
        .lines()
        .find(|l| l.starts_with("CMAKE_GENERATOR:"))
        .and_then(|l| l.split_once('=').map(|x| x.1))
        .ok_or_else(|| anyhow::anyhow!("CMAKE_GENERATOR not found in CMakeCache.txt"))?
        .to_string();
    Ok(generator)
}

pub fn binary_dir(ctx: &crate::runner::Context) -> anyhow::Result<std::path::PathBuf> {
    let preset = preset::resolve(ctx, None)?;

    let output = std::process::Command::new("cmake")
        .args(["--preset", &preset, "-N"])
        .stderr(std::process::Stdio::null())
        .output();
    if let Ok(out) = output {
        let stdout = String::from_utf8_lossy(&out.stdout);
        for line in stdout.lines() {
            if line.to_lowercase().contains("build directory") {
                if let Some(path) = line.split_once('=').map(|x| x.1) {
                    return Ok(std::path::PathBuf::from(path.trim()));
                }
            }
        }
    }
    Ok(std::path::PathBuf::from("./build").canonicalize()?)
}

pub fn target_available(preset: &str, target: &str, quiet: bool) -> bool {
    matches!(
        target_status(preset, target, quiet).unwrap_or(TargetStatus::Unavailable(String::new())),
        TargetStatus::Available
    )
}
pub fn target_status(preset: &str, target: &str, quiet: bool) -> anyhow::Result<TargetStatus> {
    let output = std::process::Command::new("cmake")
        .args(["--build", "--preset", preset, "--target", "help-targets"])
        .stderr(if quiet {
            std::process::Stdio::null()
        } else {
            std::process::Stdio::inherit()
        })
        .output()?;

    let stdout = String::from_utf8_lossy(&output.stdout);

    for line in stdout.lines() {
        // Each line contains 3 fields {target, status, reason}
        let parts: Vec<&str> = line
            .splitn(3, ' ')
            .map(str::trim)
            .filter(|s| !s.is_empty())
            .collect();

        if parts.len() >= 2 && parts[0] == target {
            return Ok(if parts[1] == "YES" {
                TargetStatus::Available
            } else {
                let reason = parts.get(2).unwrap_or(&"unknown").to_string();
                TargetStatus::Unavailable(reason)
            });
        }
    }

    Ok(TargetStatus::Unavailable("unknown".to_string()))
}

pub fn reconf(ctx: &runner::Context, preset: &str, defines: &[String]) -> anyhow::Result<()> {
    ctx.run(
        std::process::Command::new("cmake")
            .arg("--preset")
            .arg(&preset)
            .args(defines.iter().map(|d| format!("-D{}", d))),
    )?;
    Ok(())
}

pub fn base_build(preset: &str) -> std::process::Command {
    let mut cmd = std::process::Command::new("cmake");
    cmd.args(["--build", "--preset", preset]);
    cmd
}
pub fn base_test(preset: &str) -> std::process::Command {
    let mut cmd = std::process::Command::new("ctest");
    cmd.args(["--preset", preset]);
    cmd
}
pub fn base_workflow(preset: &str) -> std::process::Command {
    let mut cmd = std::process::Command::new("cmake");
    cmd.args(["--preset", preset]);
    cmd
}
