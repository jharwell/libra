// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.
/*!
 * Implementation of the build command.
 */

// Imports
use clap;
use log::debug;

use crate::cmake;
use crate::preset;
use crate::runner;
use crate::utils;

// Types
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

    /// Forward -DVAR=VALUE to the CMake configure step when active. If the
    /// build directory exists and neither --reconfigure nor --fresh is given,
    /// abort.
    #[arg(short = 'D', value_name = "VAR=VALUE")]
    pub defines: Vec<String>,

    /// Force the configure step even if the build directory exists.
    #[arg(short, long)]
    pub reconfigure: bool,

    /// Reconfigure with a --fresh build directory by wiping the CMake cache.
    #[arg(short, long)]
    pub fresh: bool,

    /// Run the build in verbose mode, printing build commands
    #[arg(short, long)]
    pub verbose: bool,

    /// Enable LTO via LIBRA.
    #[arg(long, default_value_t = false, overrides_with = "no_lto")]
    pub lto: bool,

    /// Disable LTO via LIBRA.
    #[arg(long, overrides_with = "lto", hide = true)]
    no_lto: bool,
}

// Traits

// Implementation

// Public API
pub fn run(ctx: &runner::Context, mut args: BuildArgs) -> anyhow::Result<()> {
    preset::ensure_project_root(ctx)?;
    debug!("Begin");

    let preset = preset::resolve(ctx, None)?;
    let bdir = cmake::binary_dir(&preset);

    if bdir.is_some() && !args.defines.is_empty() && !args.reconfigure && !args.fresh {
        anyhow::bail!(
            "{} -D values given but build directory exists and no --reconfigure; values will not be applied. This is probably a configuration error.",
            args.defines.len()
        );
    }

    // 2026-06-03 [JRH]: This is here so that people who want to just tack on
    // LTO to whatever their current build config is can use clibra + LTO
    // without having to define CMake presets with LTO.
    let needs_lto = args.lto
        && !args.no_lto
        && !bdir.as_ref().is_some_and(|b| {
            cmake::cache_bool(b.as_ref(), "LIBRA_LTO")
                .unwrap_or(Some(false))
                .unwrap_or(false)
        });

    let needs_no_lto = args.no_lto
        && bdir.as_ref().is_some_and(|b| {
            cmake::cache_bool(b.as_ref(), "LIBRA_LTO")
                .unwrap_or(Some(true))
                .unwrap_or(true)
        });
    debug!("lto={}, no_lto={}", args.lto, args.no_lto);
    debug!(
        "cache LIBRA_LTO={:?}",
        bdir.as_ref()
            .map(|b| cmake::cache_bool(b.as_ref(), "LIBRA_LTO"))
    );
    debug!("needs_lto={needs_lto}, needs_no_lto={needs_no_lto}");
    if args.reconfigure || args.fresh || bdir.is_none() || needs_lto || needs_no_lto {
        debug!("Begin reconfigure");
        if needs_lto {
            args.defines.push("LIBRA_LTO=YES".to_string());
        }
        if needs_no_lto {
            args.defines.push("LIBRA_LTO=NO".to_string());
        }
        cmake::reconf(ctx, &preset, args.fresh, &args.defines)?;
    }

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
