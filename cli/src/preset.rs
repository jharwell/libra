// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.
/*!
 * Integration with and handling of CMake presets.
 */

// Imports
use anyhow;

// Types

// Traits

// Implementation

// Public API

/// Die with an actionable message if the project structure is not usable.
pub fn check_project_root() -> anyhow::Result<()> {
    if !std::path::Path::new("CMakeLists.txt").exists() {
        anyhow::bail!("no CMakeLists.txt found. Run libra from the project root.");
    }

    let has_presets = std::path::Path::new("CMakePresets.json").exists()
        || std::path::Path::new("CMakeUserPresets.json").exists();

    if !has_presets {
        anyhow::bail!(
            "no CMakePresets.json or CMakeUserPresets.json found.\n\
             libra requires CMake presets to function. Options:\n\
               - Create CMakePresets.json manually\n\
               - Use 'libra init' to scaffold a full preset hierarchy  [Phase 3]"
        );
    }

    Ok(())
}

/// Resolve a preset name or return an actionable error.
///
/// Priority: --preset flag > CMakeUserPresets.json vendor field >
///           CMakePresets.json vendor field > per-subcommand default
///           > die.
pub fn resolve(ctx: &crate::runner::Context, default: Option<&str>) -> anyhow::Result<String> {
    let preset = if let Some(preset) = &ctx.preset {
        if ctx.verbose {
            eprintln!("Preset resolved via --preset");
        }
        preset.clone()
    } else if let Some(preset) = read_preset(
        "CMakeUserPresets.json",
        "vendor.libra.defaultConfigurePreset",
    )? {
        if ctx.verbose {
            eprintln!("Preset resolved via CMakeUserPresets.json");
        }
        preset
    } else if let Some(preset) =
        read_preset("CMakePresets.json", "libra.vendor.defaultConfigurePreset")?
    {
        if ctx.verbose {
            eprintln!("Preset resolved via CMakePresets.json");
        }
        preset
    } else if let Some(d) = default {
        if ctx.verbose {
            eprintln!("Preset resolved via default={}", default.unwrap());
        }
        d.to_string()
    } else {
        anyhow::bail!(
            "no preset specified and no defaultConfigurePreset found.\n\
             Options:\n\
               - Pass --preset=<n> explicitly\n\
               - Add vendor.libra.defaultConfigurePreset to CMakeUserPresets.json\n\
               - Use 'libra preset default <n>'  [Phase 3]"
        );
    };

    if !ctx.quiet {
        eprintln!("Preset: {preset}");
    }

    Ok(preset)
}
/// Read <preset> from a preset file, if present.
/// Returns Ok(None) if the file doesn't exist or the field is absent.
/// Returns Err if the file exists but is not valid JSON.
pub fn read_preset(path: &str, preset: &str) -> anyhow::Result<Option<String>> {
    let p = std::path::Path::new(path);
    if !p.exists() {
        return Ok(None);
    }

    let content = std::fs::read_to_string(p)?;
    let value: serde_json::Value =
        serde_json::from_str(&content).map_err(|e| anyhow::anyhow!("{path}: invalid JSON: {e}"))?;

    let mut current = &value;
    for component in preset.split(".") {
        match current.get(component) {
            Some(v) => current = v,
            None => return Ok(None),
        }
    }
    let result = current.as_str().map(str::to_owned);
    Ok(result)
}
