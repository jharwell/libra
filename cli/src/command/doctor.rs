// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.
/*!
 * Implementation of the doctor command.
 */

// Imports
use anyhow;
use clap;
use colored::Colorize;
use log::debug;
use semver::Version;
use which;

use crate::preset;
use crate::runner;

// Types
#[derive(clap::Parser, Debug)]
pub struct DoctorArgs {}

/// Convenience struct representing a clibra/LIBRA tool to check.
struct Tool {
    /// The name of the binary as it would appear on PATH.
    name: &'static str,

    /// The minimum version of the tool required, if any.
    min_ver: Option<Version>,

    /// Is this tool optional, or required?
    optional: bool,
}

// traits

// Implementation
fn normalize_version(v: &str) -> String {
    let parts: Vec<&str> = v.split('.').collect();
    match parts.len() {
        1 => format!("{}.0.0", parts[0]),
        2 => format!("{}.{}.0", parts[0], parts[1]),
        _ => v.to_string(),
    }
}

fn check_tool(tool: &Tool, ok: &mut u32, warn: &mut u32, fail: &mut u32) {
    if let Ok(path) = which::which(tool.name) {
        let ver = std::process::Command::new(tool.name)
            .arg("--version")
            .output()
            .map(|o| {
                let out = String::from_utf8_lossy(&o.stdout).to_string();
                // Search all lines, not just the first
                out.lines()
                    .find(|line| line.contains(char::is_numeric))
                    .unwrap_or("unknown")
                    .trim()
                    .to_string()
            })
            .unwrap_or_else(|_| "unknown".to_string());

        // Extract first sequence of digits/dots from version string
        let raw_ver = ver
            .split_whitespace()
            .find_map(|s| {
                let s = s.trim_matches(|c: char| !c.is_ascii_digit());
                if s.is_empty() {
                    None
                } else {
                    Some(s.to_string())
                }
            })
            .unwrap_or_else(|| "unknown".to_string());

        // This handles things like 13.3.0-6ubuntu2~24.04.1, and falls back to
        // raw_ver if there are no such shennanigans.
        let clean_ver = raw_ver.split('-').next().unwrap_or(&raw_ver);

        let parsed_ver =
            Version::parse(&normalize_version(clean_ver)).unwrap_or_else(|_| Version::new(0, 0, 0));

        if let Some(min_ver) = &tool.min_ver {
            debug!(
                "Check tool {}: min_ver='{:?}',raw_tool='{}',parsed_tool='{}'",
                tool.name, tool.min_ver, raw_ver, parsed_ver
            );

            if parsed_ver >= *min_ver {
                println!(
                    "  {} {} -> {} >= {}",
                    "✓".bold().green(),
                    tool.name,
                    path.display(),
                    *min_ver
                );
                *ok += 1;
            } else {
                println!(
                    " {}  {} -> found {} but need >= {:?}",
                    "✗".bold().red(),
                    tool.name,
                    parsed_ver,
                    tool.min_ver
                );
                *fail += 1;
            }
        } else {
            println!(
                "  {} {} -> {} (present)",
                "✓".bold().green(),
                tool.name,
                path.display()
            );
            *ok += 1;
        }
    } else if tool.optional {
        println!(
            "  {} {} not found (optional)",
            "⚠".bold().yellow(),
            tool.name
        );
        *warn += 1;
    } else {
        println!("  {} {} not found", tool.name, "✗".bold().red());
        *fail += 1;
    }
}

fn check_project_structure(ok: &mut u32, warn: &mut u32, err: &mut u32) {
    for thing in [
        "CMakePresets.json",
        "CMakeUserPresets.json",
        "src",
        "include",
        "tests",
        "docs",
        "docs/Doxyfile.in",
        "docs/conf.py",
    ] {
        let path = std::path::PathBuf::from(thing);
        if path.exists() {
            println!(
                "  {} {}{} exists",
                "✓".bold().green(),
                thing,
                if path.is_dir() { "/" } else { "" }
            );
            *ok += 1;
        } else {
            *warn += 1;
            println!(
                "  {} {}{} does not exist",
                "⚠".bold().yellow(),
                thing,
                if path.is_dir() { "/" } else { "" }
            );
        }
    }
    // Check that a CMake presets file is valid. Currently, this just checks if it
    // is valid JSON. We COULD also check against the current CMake schema, but
    // that's rather brittle: it is (somewhat) version-dependent, and requires
    // baking in config from the CMake repo into this binary.
    for thing in ["CMakePresets.json", "CMakeUserPresets.json"] {
        let path = std::path::PathBuf::from(thing);
        if path.exists() {
            let contents = std::fs::read_to_string(path).unwrap_or_default();
            if serde_json::from_str::<serde_json::Value>(&contents).is_ok() {
                *ok += 1;
                println!("  {} {} is valid JSON", "✓".bold().green(), thing);
            } else {
                println!("  {} {} is not valid JSON", "✗".bold().red(), thing);
                *err += 1;
            }
        }
    }
}

// Public API
pub fn run(ctx: &runner::Context, _args: DoctorArgs) -> anyhow::Result<()> {
    preset::ensure_project_root(ctx)?;

    println!("Checking LIBRA environment...\n");
    println!("Tools:");
    let mut ok_count: u32 = 0;
    let mut warn_count: u32 = 0;
    let mut err_count: u32 = 0;

    let tools = [
        Tool {
            name: "cmake",
            min_ver: Some(Version::new(3, 31, 0)),
            optional: false,
        },
        Tool {
            name: "ninja",
            min_ver: None,
            optional: true,
        },
        Tool {
            name: "make",
            min_ver: None,
            optional: true,
        },
        Tool {
            name: "gcc",
            min_ver: Some(Version::new(9, 0, 0)),
            optional: true,
        },
        Tool {
            name: "g++",
            min_ver: Some(Version::new(9, 0, 0)),
            optional: true,
        },
        Tool {
            name: "clang",
            min_ver: Some(Version::new(14, 0, 0)),
            optional: true,
        },
        Tool {
            name: "clang++",
            min_ver: Some(Version::new(14, 0, 0)),
            optional: true,
        },
        Tool {
            name: "icx",
            min_ver: Some(Version::new(2025, 0, 0)),
            optional: true,
        },
        Tool {
            name: "icpx",
            min_ver: Some(Version::new(2025, 0, 0)),
            optional: true,
        },
        Tool {
            name: "gcovr",
            min_ver: Some(Version::new(5, 0, 0)),
            optional: true,
        },
        Tool {
            name: "lcov",
            min_ver: Some(Version::new(2, 0, 0)),
            optional: true,
        },
        Tool {
            name: "cppcheck",
            min_ver: Some(Version::new(2, 1, 0)),
            optional: true,
        },
        Tool {
            name: "clang-tidy",
            min_ver: Some(Version::new(14, 0, 0)),
            optional: true,
        },
        Tool {
            name: "clang-check",
            min_ver: Some(Version::new(14, 0, 0)),
            optional: true,
        },
        Tool {
            name: "clang-format",
            min_ver: Some(Version::new(14, 0, 0)),
            optional: true,
        },
        Tool {
            name: "llvm-cov",
            min_ver: Some(Version::new(14, 0, 0)),
            optional: true,
        },
        Tool {
            name: "llvm-profdata",
            min_ver: Some(Version::new(14, 0, 0)),
            optional: true,
        },
        Tool {
            name: "ccache",
            min_ver: None,
            optional: true,
        },
        Tool {
            name: "cmake-format",
            min_ver: Some(Version::new(0, 6, 0)),
            optional: true,
        },
        Tool {
            name: "bats",
            min_ver: None,
            optional: true,
        },
        Tool {
            name: "doxygen",
            min_ver: None,
            optional: true,
        },
        Tool {
            name: "genhtml",
            min_ver: None,
            optional: true,
        },
    ];
    for tool in tools {
        check_tool(&tool, &mut ok_count, &mut warn_count, &mut err_count);
    }

    println!("\nProject structure:\n");
    check_project_structure(&mut ok_count, &mut warn_count, &mut err_count);

    println!(
        "\nChecked {} items: {} errors, {} warnings, {} ok",
        ok_count + warn_count + err_count,
        err_count,
        warn_count,
        ok_count
    );
    if err_count > 0 {
        anyhow::bail!("doctor found errors!");
    }
    Ok(())
}
