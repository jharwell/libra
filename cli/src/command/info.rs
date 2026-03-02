// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.
/*!
 * Implementation of the info command.
 */


// Imports
use anyhow;
use crate::runner;
use crate::preset;

// Types

// Traits

// Implementation

// Public API
pub fn run(ctx: &runner::Context) -> anyhow::Result<()> {
    preset::check_project_root()?;

    let preset = preset::resolve(ctx)?;

    if !ctx.quiet {
        eprintln!("Preset: {preset}");
    }

    // -N: no-op mode — reads and prints the cache without regenerating
    ctx.run(std::process::Command::new("cmake")
            .arg("--preset")
            .arg(&preset)
            .arg("-N"))
}
