// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.
/*!
 * Implementation of the install command.
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
pub struct InstallArgs {
    /// Forward -DVAR=VALUE to the CMake configure step when active.  If the
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

    /// Enable LTO via LIBRA.
    #[arg(long)]
    pub lto: bool,
}

// Traits

// Implementation

// Public API

pub fn run(ctx: &runner::Context, mut args: InstallArgs) -> anyhow::Result<()> {
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
        && !bdir.as_ref().is_some_and(|b| {
            cmake::cache_bool(b.as_ref(), "LIBRA_LTO")
                .unwrap_or(Some(false))
                .unwrap_or(false)
        });

    if args.reconfigure || args.fresh || bdir.is_none() || needs_lto {
        debug!("Begin reconfigure");
        if needs_lto {
            args.defines.push("LIBRA_LTO=YES".to_string());
        }
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
    cmd.args(["--target", "install"]);
    ctx.run(&mut cmd)?;

    Ok(())
}
