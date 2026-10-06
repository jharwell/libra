// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.
/*!
 * Implementation of the build command.
 */

// Imports
use log::debug;

use crate::cmake;
use crate::preset;
use crate::runner;
use crate::utils;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
#[derive(clap::Parser, Debug)]
pub struct BuildArgs {
    /// Parallel job count. Defaults to the # of logical CPUs.
    #[arg(short = 'j', long, default_value_t = utils::num_cpus())]
    pub jobs: u32,

    /// Build a specific CMake target.
    #[arg(short, long)]
    pub target: Option<String>,

    /// Pass --clean-first to cmake --build.
    #[arg(long)]
    pub clean: bool,

    /// Continue building after errors. Only valid with {Ninja, Unix Makefiles}
    /// generators.
    #[arg(short = 'k', long)]
    pub keep_going: bool,

    #[command(flatten)]
    pub configure: cmake::ConfigureArgs,

    /// Run the build in verbose mode, printing build commands
    #[arg(short, long)]
    pub verbose: bool,
}

// Traits

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------
pub fn run(ctx: &runner::Context, args: BuildArgs) -> anyhow::Result<()> {
    preset::ensure_project_root(ctx)?;
    debug!("Begin");

    let preset = preset::resolve(ctx, None)?;
    cmake::ensure_configured(&ctx, &preset, &args.configure)?;

    let mut cmd = cmake::base_build(&preset);
    cmd.args(["--parallel", &args.jobs.to_string()]);

    if args.clean {
        cmd.arg("--clean-first");
    }

    if args.verbose {
        cmd.arg("--verbose");
    }
    if let Some(target) = &args.target {
        cmd.args(["--target", target]);
    }
    if args.keep_going {
        cmd = cmake::with_keep_going(cmd, &preset)?;
    }
    ctx.run(&mut cmd)?;

    Ok(())
}
