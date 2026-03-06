// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.
/*!
 * Implementation of the doctor command.
 */

// Imports
use crate::preset;
use anyhow;
use clap;
use which;

// Types
#[derive(clap::Parser, Debug)]
pub struct DoctorArgs {}

// Traits

// Implementation
fn check_tool(
    name: &str,
    min_version: &str,
    optional: bool,
    ok: &mut u32,
    warn: &mut u32,
    fail: &mut u32,
) {
    if let Ok(path) = which::which(name) {
        let ver = std::process::Command::new(name)
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
        let found_ver = ver
            .split_whitespace()
            .find_map(|s| {
                let s = s.trim_matches(|c: char| !c.is_ascii_digit());
                if s.is_empty() {
                    None
                } else {
                    Some(s.to_string())
                }
            })
            .unwrap_or_default();

        let version_ok = min_version.is_empty() || version_gte(&found_ver, min_version);

        if version_ok {
            println!("  ✓ {} -> {} ({})", name, path.display(), ver);
            *ok += 1;
        } else {
            println!(
                "  ✗ {} -> found {} but need >= {}",
                name, found_ver, min_version
            );
            *fail += 1;
        }
    } else if optional {
        println!("  ⚠ {} not found (optional)", name);
        *warn += 1;
    } else {
        println!("  ✗ {} not found", name);
        *fail += 1;
    }
}

fn check_project_structure(ok: &mut u32, warn: &mut u32) {
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
                "  ✓ {}{} exists",
                thing,
                if path.is_dir() { "/" } else { "" }
            );
            *ok += 1;
        } else {
            *warn += 1;
            println!(
                "  ⚠ {}{} does not exist",
                thing,
                if path.is_dir() { "/" } else { "" }
            );
        }
    }
}
fn version_gte(found: &str, min: &str) -> bool {
    let parse = |s: &str| -> Vec<u64> { s.split('.').filter_map(|p| p.parse().ok()).collect() };
    let found = parse(found);
    let min = parse(min);

    for (f, m) in found.iter().zip(min.iter()) {
        if f > m {
            return true;
        }
        if f < m {
            return false;
        }
    }
    found.len() >= min.len()
}

// Public API
pub fn run(_args: DoctorArgs) -> anyhow::Result<()> {
    preset::check_project_root()?;

    println!("Checking LIBRA environment...\n");
    println!("Tools:");
    let mut ok_count: u32 = 0;
    let mut warn_count: u32 = 0;
    let mut fail_count: u32 = 0;

    let tools = [
        ("cmake", "3.31", false),
        ("ninja", "", true),
        ("make", "", true),
        ("gcc", "9", true),
        ("g++", "9", true),
        ("clang", "17", true),
        ("clang++", "17", true),
        ("icx", "2025.0", true),
        ("icpx", "2025.0", true),
        ("gcovr", "5.0", true),
        ("cppcheck", "2.1", true),
        ("clang-tidy", "17", true),
        ("clang-format", "17", true),
        ("ccache", "", true),
    ];
    for (name, min_ver, optional) in tools {
        check_tool(
            name,
            min_ver,
            optional,
            &mut ok_count,
            &mut warn_count,
            &mut fail_count,
        );
    }

    println!("\nProject structure:\n");
    check_project_structure(&mut ok_count, &mut warn_count);

    println!(
        "\nChecked {} items: {} errors, {} warnings, {} ok",
        ok_count + warn_count + fail_count,
        fail_count,
        warn_count,
        ok_count
    );
    if fail_count > 0 {
        anyhow::bail!("doctor found errors!");
    }
    Ok(())
}
