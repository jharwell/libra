// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.
/*!
 * Implementation of the format command.
 */

// Imports
use anyhow;
use clap;
use log::debug;

use crate::cmake;
use crate::preset;
use crate::runner;

// Types
#[derive(clap::Parser, Debug)]
pub struct FormatArgs {
    #[arg(short = 'D', value_name = "VAR=VALUE")]
    pub defines: Vec<String>,

    /// Force the configure step even if the build directory exists.
    #[arg(short, long)]
    pub reconfigure: bool,

    /// Reconfigure with a --fresh cmake build directory.
    #[arg(short, long)]
    pub fresh: bool,

    /// The check to run. Defaults to nothing.
    #[arg(short, long)]
    pub check: Option<CheckKind>,

    /// Continue building after errors. Only valid with {Ninja, Unix Makefiles}
    /// generators.
    #[arg(short = 'k', long)]
    pub keep_going: bool,
}

// Traits
#[derive(clap::ValueEnum, Debug, Clone)]
pub enum CheckKind {
    Clang,
    Cmake,
}

// Implementation
pub fn run_target(ctx: &runner::Context, args: &FormatArgs, target: &str) -> anyhow::Result<()> {
    preset::ensure_project_root(ctx)?;
    let preset = preset::resolve(ctx, Some("format"))?;

    debug!("Begin");

    if args.reconfigure || args.fresh {
        debug!("Begin reconfigure");
        cmake::reconf(ctx, &preset, args.fresh, &args.defines)?;
    }

    if !ctx.dry_run {
        cmake::ensure_libra_feature_enabled(ctx, &preset, "LIBRA_FORMAT")?;

        match cmake::target_status(target, &preset)? {
            cmake::TargetStatus::Unavailable(reason) => {
                anyhow::bail!("Format target {} disabled (reason: {})", &target, reason);
            }
            cmake::TargetStatus::Available => {}
        }
    }
    let mut cmd = cmake::base_build(&preset);
    cmd.args(["--target", target]);
    if args.keep_going {
        cmd = cmake::with_keep_going(cmd, &preset)?;
    }
    ctx.run(&mut cmd)?;
    Ok(())
}

// Public API
pub fn run(ctx: &runner::Context, args: FormatArgs) -> anyhow::Result<()> {
    preset::ensure_project_root(ctx)?;

    debug!("Begin");

    match args.check {
        Some(CheckKind::Clang) => run_target(ctx, &args, "format-check-clang")?,
        Some(CheckKind::Cmake) => run_target(ctx, &args, "format-check-cmake")?,
        None => {
            run_target(ctx, &args, "format-clang")?;
            run_target(ctx, &args, "format-cmake")?;
        }
    }

    Ok(())
}
