// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.
/*!
 * Implementation of the build command.
 */

// Imports
use clap;

use crate::cmake;
use crate::preset;
use crate::runner;
use crate::utils;

// Types
#[derive(clap::Parser, Debug)]
pub struct BuildArgs {
    /// Parallel job count.
    #[arg(short = 'j', long, default_value_t = utils::num_cpus())]
    pub jobs: u32,

    /// Build a specific CMake target.
    #[arg(short, long)]
    pub target: Option<String>,

    /// Pass --clean-first to cmake --build.
    #[arg(long)]
    pub clean: bool,

    /// Continue building after errors.
    #[arg(short = 'k', long)]
    pub keep_going: bool,

    /// Forward -DVAR=VALUE to the cmake configure step.
    #[arg(short = 'D', value_name = "VAR=VALUE")]
    pub defines: Vec<String>,
}

// Traits

// Implementation

// Public API
pub fn run(ctx: &runner::Context, args: BuildArgs) -> anyhow::Result<()> {
    preset::check_project_root()?;
    let preset = preset::resolve(ctx, None)?;

    let bdir = cmake::binary_dir(ctx)?;

    if ctx.reconfigure || !bdir.exists() {
        cmake::reconf(ctx, &preset, &args.defines)?;
    }

    let mut cmd = cmake::base_build(&preset);
    cmd.args(["--parallel", &args.jobs.to_string()]);

    if args.keep_going {
        cmd.arg("--keep-going");
    }

    if args.clean {
        cmd.arg("--clean-first");
    }

    if let Some(target) = &args.target {
        cmd.args(["--target", target]);
    }
    ctx.run(&mut cmd)?;

    Ok(())
}
