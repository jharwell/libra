// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.
/*!
 * Integration with and handling of CMake presets.
 */

// Imports
use log::debug;

// Types

// Traits

// Implementation

// Public API

/// Die with an actionable message if the project structure is not usable.
pub fn ensure_project_root(ctx: &crate::runner::Context) -> anyhow::Result<()> {
    if !std::path::Path::new("CMakeLists.txt").exists() {
        anyhow::bail!("no CMakeLists.txt found. Run libra from the project root.");
    }
    debug!("CMakelists.txt found");
    let has_presets = std::path::Path::new("CMakePresets.json").exists()
        || std::path::Path::new("CMakeUserPresets.json").exists();

    if !has_presets && ctx.preset.is_none() {
        anyhow::bail!(
            "no CMakePresets.json or CMakeUserPresets.json found.\n\
             libra requires CMake presets to function. Options:\n\
               - Create CMakePresets.json manually\n\
               - Use 'libra init' to scaffold a full preset hierarchy  [Phase 3]"
        );
    }
    debug!("CMakelists.txt and one of {{CMakePresets.json,CMakeUserPresets}} found");
    Ok(())
}

/// Resolve a preset name or return an actionable error.
///
/// Priority: --preset flag > CMakeUserPresets.json vendor field >
///           CMakePresets.json vendor field > per-subcommand default
///           > die.
pub fn resolve(ctx: &crate::runner::Context, default: Option<&str>) -> anyhow::Result<String> {
    let preset = if let Some(preset) = &ctx.preset {
        debug!("Preset={} resolved via --preset", preset);
        preset.clone()
    } else if let Some(preset) = read_preset(
        "CMakeUserPresets.json",
        "vendor.libra.defaultConfigurePreset",
    )? {
        debug!("Preset={} resolved via CMakeUserPresets.json", preset);
        preset
    } else if let Some(preset) =
        read_preset("CMakePresets.json", "vendor.libra.defaultConfigurePreset")?
    {
        debug!("Preset={} resolved via CMakePresets.json", preset);
        preset
    } else if let Some(d) = default {
        debug!("Preset resolved via default={}", default.unwrap());
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

    Ok(preset)
}

/// Read <preset> from a preset file, if present.
///
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

/// Read a field from a configure preset.
///
/// If the preset exists, but `field` isn't found in it, walk the inheritance
/// chain until you find a parent element which does contain it, or you run out
/// of parent elements.
///
/// # Arguments
///
/// * `path` - Path to presets file.
///
/// * `preset_name` - The name of the preset to lookup.
///
/// * `field` - The field within the preset to lookup.
///
pub fn read_configure_preset_field(
    path: &str,
    preset_name: &str,
    field: &str,
) -> anyhow::Result<Option<String>> {
    let p = std::path::Path::new(path);
    if !p.exists() {
        return Ok(None);
    }

    let content = std::fs::read_to_string(p)?;
    let value: serde_json::Value =
        serde_json::from_str(&content).map_err(|e| anyhow::anyhow!("{path}: invalid JSON: {e}"))?;

    let presets = match value.get("configurePresets").and_then(|a| a.as_array()) {
        Some(p) => p,
        None => return Ok(None),
    };

    // find preset by name, then walk inherits chain
    let mut current = preset_name.to_string();
    loop {
        let found = presets
            .iter()
            .find(|p| p.get("name").and_then(|n| n.as_str()) == Some(&current));

        match found {
            None => return Ok(None),
            Some(p) => {
                if let Some(val) = p.get(field).and_then(|v| v.as_str()) {
                    return Ok(Some(val.to_owned()));
                }
                // field not on this preset — follow inherits
                match p.get("inherits").and_then(|v| v.as_str()) {
                    Some(parent) => current = parent.to_string(),
                    None => return Ok(None),
                }
            }
        }
    }
}

pub fn workflow_preset_exists(path: &str, preset_name: &str) -> anyhow::Result<bool> {
    let p = std::path::Path::new(path);
    if !p.exists() {
        return Ok(false);
    }

    let content = std::fs::read_to_string(p)?;
    let value: serde_json::Value =
        serde_json::from_str(&content).map_err(|e| anyhow::anyhow!("{path}: invalid JSON: {e}"))?;

    let exists = value
        .get("workflowPresets")
        .and_then(|a| a.as_array())
        .map_or(false, |presets| {
            presets.iter().any(|p| {
                p.get("name").and_then(|n| n.as_str()) == Some(preset_name)
            })
        });

    Ok(exists)
}
