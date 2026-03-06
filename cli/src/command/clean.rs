// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.
/*!
 * Implementation of the clean command.
 */

// Imports
use anyhow;
use clap;

use crate::cmake;
use crate::preset;
use crate::runner;

// Types
#[derive(clap::Parser, Debug)]
pub struct CleanArgs {
    /// Remove the entire build directory instead of running the clean target.
    #[arg(long)]
    pub all: bool,
}

// Traits

// Implementation

// Public API

pub fn run(ctx: &runner::Context, args: CleanArgs) -> anyhow::Result<()> {
    preset::check_project_root()?;

    let preset = preset::resolve(ctx, None)?;

    if args.all {
        let bdir = cmake::binary_dir(ctx)?;
        std::fs::remove_dir_all(bdir)?;
    } else {
        ctx.run(
            std::process::Command::new("cmake")
                .args(["--build", "--preset", &preset, "--target", "clean"]),
        )?;
    }
    Ok(())
}
