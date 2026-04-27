// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.
/*!
 * Integration with and handling of CMake presets.
 */

// Imports
use log::{debug, trace};

// Types

// Traits

// Implementation

/// Load the CMake{UserPresets,Presets}.json files from the specified directory
/// and merge them. This is required when walking the inheritance chain to
/// resolve fields, because the chain can span both files, and searching in each
/// individually gives wrong results.
fn load_presets(dir: &str) -> anyhow::Result<Vec<serde_json::Value>> {
    let mut all_presets = Vec::new();

    for filename in &["CMakePresets.json", "CMakeUserPresets.json"] {
        let path = std::path::Path::new(dir).join(filename);
        if !path.exists() {
            continue;
        }
        let content = std::fs::read_to_string(&path)?;
        let value: serde_json::Value = serde_json::from_str(&content)
            .map_err(|e| anyhow::anyhow!("{}: invalid JSON: {e}", path.display()))?;

        if let Some(presets) = value.get("configurePresets").and_then(|a| a.as_array()) {
            all_presets.extend(presets.iter().cloned());
        }
    }

    Ok(all_presets)
}

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
/// * `dir` - Directory name to search for the the preset files.
///
/// * `preset_name` - The name of the preset to lookup.
///
/// * `field` - The field within the preset to lookup.
///
pub fn read_configure_preset_field(
    dir: &str,
    preset_name: &str,
    field: &str,
) -> anyhow::Result<Option<String>> {
    let presets = load_presets(dir)?;
    if presets.is_empty() {
        trace!("No preset JSON files found in {}", dir);
        return Ok(None);
    }

    // BFS over the inheritance chain
    let mut queue = std::collections::VecDeque::new();
    let mut visited = std::collections::HashSet::new();
    queue.push_back(preset_name.to_string());

    debug!("Walking presets JSON to resolve {}.{}", preset_name, field);

    while let Some(current) = queue.pop_front() {
        trace!("Check preset {}", current);
        if !visited.insert(current.clone()) {
            // Already visited — avoid infinite loops from circular inheritance
            continue;
        }

        let preset = match presets
            .iter()
            .find(|p| p.get("name").and_then(|n| n.as_str()) == Some(&current))
        {
            Some(p) => p,
            None => {
                trace!(
                    "{} does not exist in configure preset list {:?}",
                    current,
                    presets
                        .iter()
                        .map(|v| v
                            .get("name")
                            .and_then(|n| n.as_str())
                            .unwrap_or("<unnamed>"))
                        .collect::<Vec<_>>()
                );
                continue; // Named preset not found, try next in queue
            }
        };

        // If this preset has the field, return it
        if let Some(val) = preset.get(field).and_then(|v| v.as_str()) {
            trace!(
                "Found {}.{}={}",
                preset["name"].as_str().unwrap_or_default(),
                field,
                val
            );
            return Ok(Some(val.to_owned()));
        }

        // Otherwise enqueue its parents
        match preset.get("inherits") {
            Some(serde_json::Value::String(s)) => {
                trace!(
                    "Push {} parent {}",
                    preset["name"].as_str().unwrap_or_default(),
                    s
                );
                queue.push_back(s.clone());
            }
            Some(serde_json::Value::Array(arr)) => {
                trace!(
                    "Push {} parents {:?}",
                    preset["name"].as_str().unwrap_or_default(),
                    arr
                );

                for parent in arr {
                    if let Some(s) = parent.as_str() {
                        queue.push_back(s.to_owned());
                    }
                }
            }
            _ => {}
        }
    }
    debug!("{}.{} not found", preset_name, field);
    Ok(None)
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
            presets
                .iter()
                .any(|p| p.get("name").and_then(|n| n.as_str()) == Some(preset_name))
        });

    Ok(exists)
}
