// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.
/*!
 * Implementation of the build command.
 */

// Imports
use clap;
use log::{debug, warn};

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
}

// Traits

// Implementation

// Public API
pub fn run(ctx: &runner::Context, args: BuildArgs) -> anyhow::Result<()> {
    preset::ensure_project_root(ctx)?;
    debug!("Begin");

    let preset = preset::resolve(ctx, None)?;
    let bdir = cmake::binary_dir(&preset);

    if args.reconfigure || args.fresh || bdir.is_none() {
        debug!("Begin reconfigure");
        cmake::reconf(ctx, &preset, args.fresh, &args.defines)?;
    }
    if bdir.is_some() && !args.defines.is_empty() && !args.reconfigure && !args.fresh {
        anyhow::bail!(
            "{} -D values given but build directory exists and no --reconfigure;
            values will not be applied",
            args.defines.len()
        );
    }
    let mut cmd = cmake::base_build(&preset);
    cmd.args(["--parallel", &args.jobs.to_string()]);

    if args.clean {
        cmd.arg("--clean-first");
    }

    if let Some(target) = &args.target {
        cmd.args(["--target", target]);
    }
    if args.keep_going {
        let generator = cmake::generator(&preset).unwrap_or_else(|e| {
            warn!("Failed to detect CMake generator: {e}, defaulting to Unix Makefiles");
            "Unix Makefiles".to_string()
        });

        if generator == "Ninja" {
            cmd.args(["--", "-k0"]);
        } else if generator == "Unix Makefiles" {
            cmd.args(["--", "--keep-going"]);
        } else {
            anyhow::bail!("--keep-going only supported with {{Ninja, Unix Makefiles}} generators");
        }
    }
    ctx.run(&mut cmd)?;

    Ok(())
}
