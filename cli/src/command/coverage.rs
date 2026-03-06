// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.
/*!
 * Implementation of the coverage command.
 */

// Imports
use anyhow;
use clap;
use open;

use crate::cmake;
use crate::preset;
use crate::runner;

// Types
#[derive(clap::Parser, Debug)]
pub struct CoverageArgs {
    /// Generate HTML report.
    ///
    /// Tries gcovr and LLVM-based generation in order.
    #[arg(long, default_value_t = true)]
    pub html: bool,

    /// Check code coverage with gcovr.
    #[arg(long)]
    pub check: bool,

    /// Open the HTML report in the system browser after generation.
    #[arg(long)]
    pub open: bool,

    #[arg(short = 'D', value_name = "VAR=VALUE")]
    pub defines: Vec<String>,
}

// Traits

// Implementation

// Public API

pub fn run(ctx: &runner::Context, args: CoverageArgs) -> anyhow::Result<()> {
    preset::check_project_root()?;
    let preset = preset::resolve(ctx, Some("ci"))?;

    eprintln!("Running coverage...");

    let html_target = ["gcovr-report", "llvm-report"]
        .iter()
        .find(|t| cmake::target_available(&preset, t, ctx.quiet));
    let check_target = ["gcovr-check"]
        .iter()
        .find(|t| cmake::target_available(&preset, t, ctx.quiet));

    if args.html {
        match html_target {
            None => anyhow::bail!("No HTML-generating targets exist!"),
            Some(target) => {
                ctx.run(cmake::base_build(&preset).args(["--target", target]))?;
            }
        }
        if args.open {
            let bdir = cmake::binary_dir(ctx)?;
            open::that(bdir.join("coverage").join("index.html"))?;
        }
        return Ok(());
    }
    if args.check {
        match check_target {
            None => anyhow::bail!("No check targets exist!"),
            Some(target) => {
                ctx.run(cmake::base_build(&preset).args(["--target", target]))?;
            }
        }
        return Ok(());
    }
    anyhow::bail!("Failed to run any coverage targets")
}
