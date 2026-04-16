// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.
/*!
 * Implementation of the info command.
 */

// Imports
use anyhow;
use clap;
use colored::Colorize;
use log::{debug, trace, warn};
use serde::Deserialize;
use std::fmt::Write;

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

#[derive(Deserialize, Debug)]
pub struct Target {
    pub name: String,
    pub available: bool,
    pub unavailable_reason: Option<String>,
    pub category: String,
    pub parent: Option<String>,
}

#[derive(Deserialize)]
pub struct HelpTargets {
    pub schema_version: u32,
    pub project: String,
    pub targets: Vec<Target>,
}

// Traits

// Implementation

/// Emit output for a single target group; that is, for a collection of
/// buildable targets which all fall under the same semantic umbrella.
fn emit_target_group(out: &mut String, category: &str, items: &Vec<Target>) {
    let indent = "    "; // 4 spaces
    let filtered: Vec<_> = items.iter().filter(|t| t.category == category).collect();
    println!("items: {:?} filtered: {:?}", items, filtered);
    let width = filtered.iter().map(|t| t.name.len()).max().unwrap_or(20) + 1;

    // label on its own line
    let _ = writeln!(out, "  {}", category.bold());

    if filtered.is_empty() {
        let _ = writeln!(out, "{} (None)", indent);
        return;
    }
    for item in filtered {
        let reason = item.unavailable_reason.as_deref();
        let _ = writeln!(
            out,
            "{}{:.<width$} {} {}",
            indent,
            item.name,
            if item.available {
                "YES".green().bold()
            } else {
                "NO".dimmed()
            },
            reason.map_or(String::new(), |r| format!("({})", r.yellow())),
        );
    }
}

/// Run command output through less, so that (a) if the content is > screen size
/// it handles nicely, and (b) color/bolding etc get preserved.
pub fn run_paged(output: &str) -> anyhow::Result<()> {
    use std::io::Write;
    use std::process::{Command, Stdio};

    let mut child = Command::new("less")
        .arg("-r") // ANSI colors
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

/// Emit target info for all cmake targets which LIBRA can create: what they
/// are, and whether or not they are enabled, and if not, a reason why.
///
/// This is read from the LIBRA cmake output, so if that changes, this
/// function will probably need to too.
fn emit_libra_targets(out: &mut String, preset: &str) -> anyhow::Result<()> {
    let bdir = cmake::binary_dir(preset);

    if bdir.is_none() {
        warn!("Build directory does not exist--no available target info can be emitted");
        return Ok(());
    }

    let text = std::fs::read_to_string(bdir.unwrap().join("libra_targets.json"))?;
    let data: HelpTargets = serde_json::from_str(&text)?;

    let s = format!("\nAvailable LIBRA targets for {}\n", data.project)
        .bold()
        .underline();
    if data.schema_version != 1 {
        anyhow::bail!(
            "Only info schema v1 supported, have {}",
            data.schema_version
        );
    }
    let _ = writeln!(out, "{}", s);

    emit_target_group(out, "test", &data.targets);
    emit_target_group(out, "docs", &data.targets);
    emit_target_group(out, "coverage", &data.targets);
    emit_target_group(out, "analysis", &data.targets);
    Ok(())
}

/// Emit info about the current build configuration. This is all things defined
/// by cmake: build type, generator, etc. Thus, if LIBRA's info summary/impl
/// changes, this function should not need to.
fn emit_build_configuration(
    out: &mut String,
    preset: &str,
    items: &[(String, String)],
    width: usize,
) -> anyhow::Result<()> {
    let bdir = cmake::binary_dir(preset);
    if bdir.is_none() {
        warn!("Build directory does not exist--no build configuration info can be emitted");
        return Ok(());
    }
    let _ = writeln!(out, "{}", "\nBuild configuration\n".bold().underline());

    let generator = cmake::generator(&preset)?;

    let _ = writeln!(out, "  Build dir: {}", bdir.unwrap().to_string_lossy());
    let _ = writeln!(out, "  Generator: {}", generator);
    for (k, v) in items {
        let _ = writeln!(out, "  {:<width$} = {}", k, v);
    }
    Ok(())
}

/// Emit info for all LIBRA cache variables (those which you could specify on
/// the cmdline). Use case is to capture knobs which are/are not enabled by
/// various cmake presets.
///
/// Values are highlighted in bold/green if truth-y in the CMake sense, and as
/// regular text otherwise.
fn emit_libra_vars(out: &mut String, items: &Vec<(String, String)>, width: usize) {
    let _ = writeln!(out, "{}", "\nLIBRA feature flags\n".bold().underline());
    if items.is_empty() {
        let _ = writeln!(out, "  (None)");
        return;
    }
    for (k, v) in items {
        let value_str = match v.as_str() {
            "YES" => v.bold().green().to_string(),
            "ON" => v.bold().green().to_string(),
            _ => v.to_string(),
        };
        let _ = writeln!(out, "  {:<width$} = {}", k, value_str);
    }
}

/// Parse the CMake cache for relevant `CMAKE_` and `LIBRA_` variables. Returns
/// empty lists on `--dry-run`.
fn parse_cmake_cache(
    ctx: &runner::Context,
    preset: &str,
) -> anyhow::Result<(Vec<(String, String)>, Vec<(String, String)>)> {
    if ctx.dry_run {
        debug!("dry-run: skipping cache read");
        return Ok((Vec::new(), Vec::new()));
    }
    let bdir = cmake::binary_dir(&preset).ok_or_else(|| {
        anyhow::anyhow!("Build directory does not exist — run 'clibra build' first")
    })?;

    // 2026-03-16 [JRH]: Note that we do not use cmake -N, because (among other
    // reasons), CMAKE_BUILD_TYPE is not visible, because that's a build-time
    // thing, not a configure-type thing.
    debug!("Reading CMake cache");
    let cache_path = bdir.join("CMakeCache.txt");
    let content = std::fs::read_to_string(&cache_path)
        .map_err(|_| anyhow::anyhow!("CMakeCache.txt not found — run 'clibra build' first"))?;

    let mut libra_items = vec![];
    let mut cmake_items = vec![];

    // There are a LOT of things CMake sets in the cache which we don't care
    // about (probably). So, compile a list of what to emit here.
    const CMAKE_INTERESTING: &[&str] = &[
        "CMAKE_BUILD_TYPE",
        "CMAKE_CXX_COMPILER",
        "CMAKE_C_COMPILER",
        "CMAKE_CXX_FLAGS",
        "CMAKE_C_FLAGS",
        "CMAKE_INSTALL_PREFIX",
        "CMAKE_EXPORT_COMPILE_COMMANDS",
        "CMAKE_PROJECT_NAME",
        "CMAKE_GENERATOR",
    ];
    for line in content.lines() {
        // skip comments and blank lines
        if line.starts_with('#') || line.starts_with("//") || line.is_empty() {
            continue;
        }
        // format is: VAR:TYPE=value
        if let Some((key_type, value)) = line.split_once('=') {
            let key = key_type.split(':').next().unwrap_or(key_type);
            if key.starts_with("CMAKE_") && CMAKE_INTERESTING.contains(&key) {
                trace!("Found CMake variable {}={}", key, value);
                cmake_items.push((key.to_string(), value.to_string()));
            } else if key.starts_with("LIBRA_") {
                trace!("Found LIBRA variable {}={}", key, value);
                libra_items.push((key.to_string(), value.to_string()));
            }
        }
    }
    return Ok((cmake_items, libra_items));
}

// Public API
pub fn run(ctx: &runner::Context, mut args: InfoArgs) -> anyhow::Result<()> {
    preset::ensure_project_root(ctx)?;

    // colored defaults to checking for a TTY, but we're writing to a buffer
    // then piping to less, so force it to use whatever the global --color
    // setting decided rather than doing its own TTY check.
    let use_color = colored::control::SHOULD_COLORIZE.should_colorize();
    colored::control::set_override(use_color);

    let preset = preset::resolve(ctx, None)?;
    if args.targets || args.build {
        args.all = false;
    }

    let (cmake_items, libra_items) = parse_cmake_cache(ctx, &preset)?;
    let width = libra_items
        .iter()
        .chain(cmake_items.iter())
        .map(|(k, _)| k.len())
        .max()
        .unwrap_or(0);

    let mut out = String::new();

    if args.all || args.build {
        emit_build_configuration(&mut out, &preset, &cmake_items, width)?;
        emit_libra_vars(&mut out, &libra_items, width);
    }
    if args.all || args.targets {
        emit_libra_targets(&mut out, &preset)?;
    }
    run_paged(&out)?;
    Ok(())
}
