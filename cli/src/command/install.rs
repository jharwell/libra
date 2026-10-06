// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.
/*!
 * Implementation of the install command.
 */

// Imports
use clap;
use log::debug;

use crate::cmake;
use crate::preset;
use crate::runner;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
#[derive(clap::Parser, Debug)]
pub struct InstallArgs {
    #[command(flatten)]
    pub configure: cmake::ConfigureArgs,
}

// Traits

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------
pub fn run(ctx: &runner::Context, args: InstallArgs) -> anyhow::Result<()> {
    preset::ensure_project_root(ctx)?;

    debug!("Begin");

    let preset = preset::resolve(ctx, None)?;
    cmake::ensure_configured(&ctx, &preset, &args.configure)?;
    let mut cmd = cmake::base_build(&preset);
    cmd.args(["--target", "install"]);
    ctx.run(&mut cmd)?;

    Ok(())
}
