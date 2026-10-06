// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.
/*!
 * Implementation of the clean command.
 */

// Imports
use anyhow::Context;
use clap;
use log::debug;

use crate::cmake;
use crate::preset;
use crate::runner;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
#[derive(clap::Parser, Debug)]
pub struct CleanArgs {
    /// Removes the preset's binaryDir entirely (rm -rf).  Requires the build
    /// directory to exist; exits with an error otherwise.
    #[arg(long)]
    pub all: bool,
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------
pub fn run(ctx: &runner::Context, args: CleanArgs) -> anyhow::Result<()> {
    preset::ensure_project_root(ctx)?;

    debug!("Begin");

    let preset = preset::resolve(ctx, None)?;

    if args.all {
        let bdir = cmake::binary_dir(&preset)
            .with_context(|| format!("Resolving binary directory for preset '{preset}'"))?;
        if !bdir.exists() && !ctx.dry_run {
            anyhow::bail!(
                "Build directory '{}' does not exist for preset '{preset}'.\n\
         Run 'libra build --preset {preset}' first.",
                bdir.display()
            );
        }
        std::fs::remove_dir_all(bdir)?;
    } else {
        ctx.run(
            std::process::Command::new("cmake")
                .args(["--build", "--preset", &preset, "--target", "clean"]),
        )?;
    }
    Ok(())
}
