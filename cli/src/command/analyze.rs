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

// Types

// Traits

// Implementation

// Public API
#[derive(clap::Parser, Debug)]
pub struct AnalyzeArgs {
    #[command(subcommand)]
    pub tool: Option<Tool>,

    #[arg(short = 'j', long, default_value_t = utils::num_cpus())]
    pub jobs: u32,

    #[arg(short = 'k', long)]
    pub keep_going: bool,

    #[arg(short = 'D', value_name = "VAR=VALUE")]
    pub defines: Vec<String>,
}

#[derive(clap::Subcommand, Debug)]
pub enum Tool {
    ClangTidy,
    ClangCheck,
    CppCheck,
    ClangFormat,
    CmakeFormat,
}

pub fn run(ctx: &runner::Context, args: AnalyzeArgs) -> anyhow::Result<()> {
    match args.tool {
        Some(Tool::ClangTidy) => run_target(&ctx, args, "analyze-clang-tidy"),
        Some(Tool::ClangCheck) => run_target(&ctx, args, "analyze-clang-check"),
        Some(Tool::CppCheck) => run_target(&ctx, args, "analyze-cppcheck"),
        Some(Tool::ClangFormat) => run_target(&ctx, args, "analyze-clang-format"),
        Some(Tool::CmakeFormat) => run_target(&ctx, args, "analyze-cmake-format"),
        None => run_target(&ctx, args, "analyze"),
    }
}

pub fn run_target(ctx: &runner::Context, args: AnalyzeArgs, target: &str) -> anyhow::Result<()> {
    preset::check_project_root()?;
    let preset = preset::resolve(ctx, Some("analyze"))?;

    eprintln!("Analyzing...");

    if ctx.reconfigure {
        cmake::reconf(ctx, &preset, &args.defines)?;
    }

    match cmake::target_status(target, &preset, ctx.quiet)? {
        cmake::TargetStatus::Available => {
            let mut cmd = cmake::base_build(&preset);
            ctx.run(
                cmd.args(["--target", target, "--parallel", &args.jobs.to_string()])
                    .args(if args.keep_going {
                        &["-k"][..]
                    } else {
                        &[][..]
                    }),
            )?;
        }
        cmake::TargetStatus::Unavailable(reason) => {
            anyhow::bail!(
                "Analysis target {} does not exist! Reason: {}",
                &target,
                reason
            );
        }
    }

    Ok(())
}
