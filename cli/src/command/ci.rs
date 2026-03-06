// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.
/*!
 * Implementation of the ci command.
 */

// Imports
use crate::cmake;
use crate::preset;
use crate::runner;

use anyhow;
use clap;

// Types
#[derive(clap::Parser, Debug)]
pub struct CiArgs {
    #[arg(short = 'D', value_name = "VAR=VALUE")]
    pub defines: Vec<String>,
}

// Traits

// Implementation

// Public API
pub fn run(ctx: &runner::Context, args: CiArgs) -> anyhow::Result<()> {
    preset::check_project_root()?;

    let preset = preset::resolve(ctx, Some("ci"))?;

    if let Some(workflow) = preset::read_preset("CMakeUserPresets.json", "workflowPresets.ci")? {
        ctx.run(cmake::base_workflow(&preset).args(["--workflow", &workflow]))?;
        return Ok(());
    }
    cmake::reconf(ctx, &preset, &args.defines)?;

    // build
    let test_target = ["all-tests"]
        .iter()
        .find(|t| cmake::target_available(t, &preset, ctx.quiet));

    match test_target {
        None => anyhow::bail!("all-tests target does not exist"),
        Some(target) => {
            ctx.run(cmake::base_build(&preset).args(["--target", target]))?;
        }
    }
    // test
    ctx.run(std::process::Command::new("ctest").args(["--preset", &preset]))?;

    // check coverage
    let check_target = ["gcovr-check"]
        .iter()
        .find(|t| cmake::target_available(t, &preset, ctx.quiet));
    match check_target {
        None => anyhow::bail!("Check target gcovr-check does not exist!"),
        Some(target) => {
            ctx.run(cmake::base_build(&preset).args(["--target", target]))?;
        }
    }

    Ok(())
}
