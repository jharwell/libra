// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.
/*!
 * Implementation of the preset command.
 */

// Imports
use crate::preset;
use crate::runner;

use anyhow;
use clap;
use colored::Colorize;
use log::{debug, error, warn};

// Types

#[derive(clap::Subcommand, Debug)]
pub enum PresetSubCommand {
    /// Set the default preset.
    Default,

    /// Enumerate all configure presets from both {CMakePresets,
    /// CMakeUserPresets}.json.
    List,

    /// Print the resolved cache variables for a preset, walking inheritance
    /// chain.
    Show,
}

#[derive(clap::Parser, Debug)]
pub struct PresetArgs {
    #[command(subcommand)]
    pub command: PresetSubCommand,
}

// Implementation

/// List all presets CMake is aware of. Right now this just calls into cmake to
/// do the work of walking the preset JSON because that's the low hanging
/// fruit. The clarity of output could (probably) be improved by a custom walk
/// function.
fn run_list(ctx: &runner::Context) -> anyhow::Result<()> {
    let mut cmd = std::process::Command::new("cmake");
    cmd.args(["--list-presets=all"]);
    ctx.run(&mut cmd)
}

/// Show all resolved cache variables for the current preset.
fn run_show(ctx: &runner::Context) -> anyhow::Result<()> {
    let name = preset::resolve(ctx, ctx.preset.as_deref())?;
    let _found = preset::configure_preset_enumerate(std::path::PathBuf::from("."), &name)?
        .ok_or_else(|| anyhow::anyhow!("No such preset '{}'", name))?;

    println!("Resolved preset '{}':\n", name.bold());
    if let Some(vars) = preset::configure_preset_enumerate(std::path::PathBuf::from("."), &name)? {
        let width = vars.iter().map(|(k, _v)| k.len()).max().unwrap_or(20) + 1;
        for (k, v) in vars.iter() {
            println!("{:.<width$}: {}", k, v);
        }
    } else {
        error!("Unable to enumerate preset");
    };

    Ok(())
}

/// Set the default preset. This only goes in CMakeUserPresets.json because it
/// is a per-developer setting, at least for now.
fn run_default(ctx: &runner::Context) -> anyhow::Result<()> {
    let preset = ctx
        .preset
        .as_deref()
        .ok_or_else(|| anyhow::anyhow!("--preset is required"))?;

    let _found = preset::configure_preset_enumerate(std::path::PathBuf::from("."), preset)?
        .ok_or_else(|| anyhow::anyhow!("No such preset '{}'", preset))?;

    let path = std::path::PathBuf::from("CMakeUserPresets.json");
    let mut value: serde_json::Value = if path.exists() {
        let content = std::fs::read_to_string(&path)?;
        serde_json::from_str(&content)
            .map_err(|e| anyhow::anyhow!("{}: invalid JSON: {e}", path.display()))?
    } else {
        warn!("CMakeUserPresets.json doesn't exist--creating stub");
        serde_json::json!({ "version": 6 })
    };

    let obj = value
        .as_object_mut()
        .ok_or_else(|| anyhow::anyhow!("{}: root is not a JSON object", path.display()))?;

    obj.entry("vendor")
        .or_insert_with(|| serde_json::json!({}))
        .as_object_mut()
        .ok_or_else(|| anyhow::anyhow!("{}: 'vendor' is not an object", path.display()))?
        .entry("libra")
        .or_insert_with(|| serde_json::json!({}))
        .as_object_mut()
        .ok_or_else(|| anyhow::anyhow!("{}: 'vendor.libra' is not an object", path.display()))?
        .insert(
            "defaultConfigurePreset".to_string(),
            serde_json::Value::String(preset.to_string()),
        );

    std::fs::write(&path, serde_json::to_string_pretty(&value)?)?;
    println!("Set default configure preset to '{}'", preset.bold());

    Ok(())
}
// Public API

pub fn run(ctx: &runner::Context, args: PresetArgs) -> anyhow::Result<()> {
    debug!("Begin");

    match &args.command {
        PresetSubCommand::List => run_list(ctx),
        PresetSubCommand::Show => run_show(ctx),
        PresetSubCommand::Default => run_default(ctx),
    }?;
    debug!("End");
    Ok(())
}
