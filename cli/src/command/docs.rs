// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.
/*!
 * Implementation of the docs command.
 */

// Imports
use crate::cmake;
use crate::preset;
use crate::runner;
use anyhow;
use clap;

// Types
#[derive(clap::Parser, Debug)]
pub struct DocsArgs {
    #[arg(short = 'D', value_name = "VAR=VALUE")]
    pub defines: Vec<String>,
}

// Traits

// Implementation

// Public API
pub fn run(ctx: &runner::Context, args: DocsArgs) -> anyhow::Result<()> {
    preset::check_project_root()?;

    let preset = preset::resolve(ctx, Some("docs"))?;

    eprintln!("Building docs...");

    if ctx.reconfigure {
        cmake::reconf(ctx, &preset, &args.defines)?;
    }

    match cmake::target_status("apidoc", &preset, ctx.quiet)? {
        cmake::TargetStatus::Available => {
            let mut cmd = cmake::base_build(&preset);
            ctx.run(cmd.args(["--target", "apidoc"]))?;
        }
        cmake::TargetStatus::Unavailable(reason) => {
            eprintln!("apidoc target disabled (reason: {})--skipping", reason);
        }
    }
    match cmake::target_status("sphinxdoc", &preset, ctx.quiet)? {
        cmake::TargetStatus::Available => {
            let mut cmd = cmake::base_build(&preset);
            ctx.run(cmd.args(["--target", "sphinxdoc"]))?
        }
        cmake::TargetStatus::Unavailable(reason) => {
            eprintln!("sphinxdoc target disabled (reason: {})--skipping", reason);
        }
    }

    Ok(())
}
