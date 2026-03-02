// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.
/*!
 * Integration with and handling of CMake presets.
 */


// Imports
use crate::runner;
use anyhow;
use std::path as path;

// Types

// Traits

// Implementation

// Public API

/// Die with an actionable message if the project structure is not usable.
pub fn check_project_root() -> anyhow::Result<()> {
    if !path::Path::new("CMakeLists.txt").exists() {
        anyhow::bail!("no CMakeLists.txt found. Run libra from the project root.");
    }

    let has_presets = path::Path::new("CMakePresets.json").exists()
        || path::Path::new("CMakeUserPresets.json").exists();

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
///           CMakePresets.json vendor field > die.
pub fn resolve(ctx: &Context) -> anyhow::Result<String> {
    if let Some(preset) = &ctx.preset {
        return Ok(preset.clone());
    }

    for path in ["CMakeUserPresets.json", "CMakePresets.json"] {
        if let Some(preset) = read_vendor_preset(path)? {
            return Ok(preset);
        }
    }

    anyhow::bail!(
        "no preset specified and no defaultConfigurePreset found.\n\
         Options:\n\
           - Pass --preset=<n> explicitly\n\
           - Add vendor.libra.defaultConfigurePreset to CMakeUserPresets.json\n\
           - Use 'libra preset default <n>'  [Phase 3]"
    );
}

/// Read vendor.libra.defaultConfigurePreset from a preset file, if present.
/// Returns Ok(None) if the file doesn't exist or the field is absent.
/// Returns Err if the file exists but is not valid JSON.
fn read_vendor_preset(path: &str) -> anyhow::Result<Option<String>> {
    let p = path::Path::new(path);
    if !p.exists() {
        return Ok(None);
    }

    let content = std::fs::read_to_string(p)?;
    let value: serde_json::Value = serde_json::from_str(&content)
        .map_err(|e| anyhow::anyhow!("{path}: invalid JSON: {e}"))?;

    let preset = value
        .get("vendor")
        .and_then(|v| v.get("libra"))
        .and_then(|v| v.get("defaultConfigurePreset"))
        .and_then(|v| v.as_str())
        .map(str::to_owned);

    Ok(preset)
}
