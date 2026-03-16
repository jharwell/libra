// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.
/*!
 * Implementation of the analyze command.
 */

// Imports
use crate::cmake;
use crate::preset;
use crate::runner;
use crate::utils;

use anyhow;
use clap;
use log::debug;

// Types

// Traits

// Implementation

// Public API
#[derive(clap::Parser, Debug)]
pub struct AnalyzeArgs {
    /// The tool to use. Defaults to running all available tools.
    #[command(subcommand)]
    pub tool: Option<Tool>,

    /// Parallel job count. Defaults to the # of logical CPUs.
    #[arg(short = 'j', long, default_value_t = utils::num_cpus())]
    pub jobs: u32,

    /// Continue building after errors.
    #[arg(short = 'k', long)]
    pub keep_going: bool,

    /// Forward -DVAR=VALUE to the CMake configure step when active. Ignored
    /// (with a warning) if the build directory exists and neither
    /// --reconfigure nor --fresh is given.
    #[arg(short = 'D', value_name = "VAR=VALUE")]
    pub defines: Vec<String>,

    /// Force the configure step even if the build directory exists.
    #[arg(short, long)]
    pub reconfigure: bool,

    /// Reconfigure with a --fresh cmake build directory.
    #[arg(short, long)]
    pub fresh: bool,
}

#[derive(clap::Subcommand, Debug)]
pub enum Tool {
    ClangTidy,
    ClangCheck,
    Cppcheck,
    ClangFormat,
    CmakeFormat,
}

pub fn run(ctx: &runner::Context, args: AnalyzeArgs) -> anyhow::Result<()> {
    match args.tool {
        Some(Tool::ClangTidy) => run_target(ctx, args, "analyze-clang-tidy"),
        Some(Tool::ClangCheck) => run_target(ctx, args, "analyze-clang-check"),
        Some(Tool::Cppcheck) => run_target(ctx, args, "analyze-cppcheck"),
        Some(Tool::ClangFormat) => run_target(ctx, args, "analyze-clang-format"),
        Some(Tool::CmakeFormat) => run_target(ctx, args, "analyze-cmake-format"),
        None => run_target(ctx, args, "analyze"),
    }
}

pub fn run_target(ctx: &runner::Context, args: AnalyzeArgs, target: &str) -> anyhow::Result<()> {
    preset::ensure_project_root(ctx)?;
    let preset = preset::resolve(ctx, Some("analyze"))?;

    debug!("Begin");

    if args.reconfigure || args.fresh {
        debug!("Begin reconfigure");
        cmake::reconf(ctx, &preset, args.fresh, &args.defines)?;
    }

    if !ctx.dry_run {
        cmake::ensure_libra_feature_enabled(ctx, &preset, "LIBRA_ANALYSIS")?;

        match cmake::target_status(target, &preset, ctx)? {
            cmake::TargetStatus::Unavailable(reason) => {
                anyhow::bail!(
                    "Analysis target {} does not exist! Reason: {}",
                    &target,
                    reason
                );
            }
            cmake::TargetStatus::Available => {}
        }
    }

    let mut cmd = cmake::base_build(&preset);
    ctx.run(
        cmd.args(["--target", target, "--parallel", &args.jobs.to_string()])
            .args(if args.keep_going {
                &["-k"][..]
            } else {
                &[][..]
            }),
    )?;
    Ok(())
}
