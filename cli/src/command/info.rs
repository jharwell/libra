// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.
/*!
 * Implementation of the info command.
 */

// Imports
use anyhow;
use clap;
use colored::Colorize;
use std::fmt::Write;
use strip_ansi_escapes;

use crate::cmake;
use crate::preset;
use crate::runner;

// Types
#[derive(clap::Parser, Debug)]
pub struct InfoArgs {
    /// Show everything: {build configuration, LIBRA targets}.
    #[arg(short = 'a', long, default_value_t = true)]
    pub all: bool,

    /// Show LIBRA target info only.
    #[arg(short = 't', long)]
    pub targets: bool,

    /// Show build configuration only.
    #[arg(long)]
    pub build: bool,
}

// Traits

// Implementation
fn emit_target_group(
    out: &mut String,
    label: &str,
    items: &[(&str, &str, String)],
    targets: &[&str],
) {
    let indent = "    "; // 4 spaces
    let filtered: Vec<_> = items
        .iter()
        .filter(|(t, _, _)| targets.contains(t))
        .collect();

    let width = filtered.iter().map(|(t, _, _)| t.len()).max().unwrap_or(20);

    // label on its own line
    let _ = writeln!(out, "  {}", label.bold());

    for item in filtered {
        let _ = writeln!(
            out,
            "{}{:.<width$} {} {}",
            indent,
            item.0,
            if item.1 == "YES" {
                item.1.green().bold().to_string()
            } else {
                item.1.dimmed().to_string()
            },
            if item.1 == "YES" {
                String::new()
            } else {
                format!("({})", item.2.yellow())
            }
        );
    }
}

pub fn run_paged(output: &str) -> anyhow::Result<()> {
    use std::io::Write;
    use std::process::{Command, Stdio};

    let mut child = Command::new("less")
        .arg("-R") // ANSI colors
        .arg("-F") // exit if output fits on one screen
        .arg("-X") // don't clear screen on exit
        .stdin(Stdio::piped())
        .spawn()?;

    if let Some(stdin) = child.stdin.take() {
        let mut stdin = stdin;
        stdin.write_all(output.as_bytes())?;
    }
    child.wait()?;
    Ok(())
}

fn emit_libra_targets(out: &mut String, preset: &str) -> anyhow::Result<()> {
    let tests_targets = [
        "all-tests",
        "integration-tests",
        "unit-tests",
        "regression-tests",
        "build-and-test",
    ];
    let coverage_targets = [
        "lcov-preinfo",
        "lcov-report",
        "gcovr-check",
        "gcovr-report",
        "llvm-summary",
        "llvm-show",
        "llvm-report-coverage",
        "llvm-export-lcov",
    ];
    let docs_targets = [
        "apidoc",
        "sphinxdoc",
        "apidoc-check-doxygen",
        "apidoc-check-clang",
    ];
    let analysis_targets = [
        "analyze",
        "analyze-clang-tidy",
        "analyze-clang-check",
        "analyze-cppcheck",
        "analyze-cmake-format",
        "format",
        "format-clang-format",
        "format-cmake-format",
        "fix",
        "fix-clang-tidy",
        "fix-clang-check",
    ];

    let output = std::process::Command::new("cmake")
        .args(["--build", "--preset", &preset, "--target", "help-targets"])
        .output()?;

    // all libra_message()s go to stderr
    let raw = String::from_utf8_lossy(&output.stderr);
    let stderr = strip_ansi_escapes::strip_str(raw.as_ref());

    // first 3 lines are the header
    let mut items = vec![];

    for line in stderr.lines().skip(3) {
        // Each line contains 3 fields {target, status, reason}
        let parts: Vec<&str> = line.split_whitespace().collect();

        if parts.len() >= 3 {
            items.push((parts[0], parts[1], parts[2..].join(" ")));
        }
        if parts.len() == 2 {
            items.push((parts[0], parts[1], String::new()));
        }
    }

    let _ = writeln!(out, "{}", "\nAvailable LIBRA targets\n".bold().underline());

    emit_target_group(out, "Tests", &items, &tests_targets);
    emit_target_group(out, "Docs", &items, &docs_targets);
    emit_target_group(out, "Coverage", &items, &coverage_targets);
    emit_target_group(out, "Analysis", &items, &analysis_targets);
    Ok(())
}

fn emit_build_configuration(
    out: &mut String,
    ctx: &runner::Context,
    items: &Vec<(&str, &str)>,
    width: usize,
) -> anyhow::Result<()> {
    let _ = writeln!(out, "{}", "\nBuild configuration\n".bold().underline());
    let mut qctx: runner::Context = ctx.clone();
    qctx.quiet = true;
    let generator = cmake::generator(&qctx)?;

    let _ = writeln!(
        out,
        "  Build dir: {}",
        cmake::binary_dir(&qctx)?.to_string_lossy()
    );
    let _ = writeln!(out, "  Generator: {}", generator);
    for (k, v) in items {
        let _ = writeln!(out, "  {:<width$} = {}", k, v);
    }
    Ok(())
}

fn emit_libra_vars(out: &mut String, items: &Vec<(&str, &str)>, width: usize) {
    let _ = writeln!(out, "{}", "\nLIBRA options\n".bold().underline());
    for (k, v) in items {
        let value_str = if *v == "OFF" || *v == "NONE" || *v == "INHERIT" || *v == "UNDEFINED" {
            v.dimmed().to_string()
        } else {
            v.bold().green().to_string()
        };
        let _ = writeln!(out, "  {:<width$} = {}", k, value_str);
    }
}

// Public API
pub fn run(ctx: &runner::Context, mut args: InfoArgs) -> anyhow::Result<()> {
    preset::check_project_root()?;

    let preset = preset::resolve(ctx, None)?;

    if args.targets || args.build {
        args.all = false;
    }
    if ctx.reconfigure {
        cmake::reconf(ctx, &preset, &[])?;
    }

    // -N: no-op mode — reads and emits the cache without
    // regenerating
    let output = std::process::Command::new("cmake")
        .args(["--preset", &preset, "-N"])
        .stderr(std::process::Stdio::null())
        .output()?;

    let stdout = String::from_utf8_lossy(&output.stdout);

    let mut libra_items = vec![];
    let mut cmake_items = vec![];

    // first line just hase "Preset CMake Variables"
    for line in stdout.lines().skip(1) {
        // Each line contains 2 fields {variable, value}
        if line.is_empty() {
            continue;
        }

        let parts: Vec<&str> = line
            .splitn(2, '=')
            .map(str::trim)
            .filter(|s| !s.is_empty())
            .collect();

        if parts[0].contains("CMAKE") {
            cmake_items.push((parts[0], parts[1].trim_matches('"')));
        }
        if parts[0].contains("LIBRA") {
            libra_items.push((parts[0], parts[1].trim_matches('"')));
        }
    }

    let width = libra_items
        .iter()
        .chain(cmake_items.iter())
        .map(|(k, _)| k.len())
        .max()
        .unwrap_or(0);

    let mut out = String::new();

    if args.all || args.build {
        emit_build_configuration(&mut out, ctx, &cmake_items, width)?;
        emit_libra_vars(&mut out, &libra_items, width);
    }
    if args.all || args.targets {
        emit_libra_targets(&mut out, &preset)?;
    }

    run_paged(&out)?;
    Ok(())
}
