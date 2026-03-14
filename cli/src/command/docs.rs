// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.
/*!
 * Implementation of the docs command.
 */

// Imports
use anyhow;
use clap;
use log::{debug, warn};

use crate::cmake;
use crate::preset;
use crate::runner;

// Types
#[derive(clap::Parser, Debug)]
pub struct DocsArgs {
    #[arg(short = 'D', value_name = "VAR=VALUE")]
    pub defines: Vec<String>,

    /// Force the configure step even if the build directory exists.
    #[arg(short, long)]
    pub reconfigure: bool,
}

// Traits

// Implementation

// Public API
pub fn run(ctx: &runner::Context, args: DocsArgs) -> anyhow::Result<()> {
    preset::ensure_project_root(ctx)?;

    let preset = preset::resolve(ctx, Some("docs"))?;

    debug!("Begin: {preset}");

    if args.reconfigure {
        debug!("Begin reconfigure");
        cmake::reconf(ctx, &preset, &args.defines)?;
    }

    cmake::ensure_libra_feature_enabled(ctx, &preset, "LIBRA_DOCS")?;

    match cmake::target_status("apidoc", &preset, ctx)? {
        cmake::TargetStatus::Available => {
            debug!("apidoc target available--building");
            let mut cmd = cmake::base_build(&preset);
            ctx.run(cmd.args(["--target", "apidoc"]))?;
        }
        cmake::TargetStatus::Unavailable(reason) => {
            warn!("apidoc target disabled (reason: {})--skipping", reason);
        }
    }
    match cmake::target_status("sphinxdoc", &preset, ctx)? {
        cmake::TargetStatus::Available => {
            debug!("sphinxdoc target available--building");
            let mut cmd = cmake::base_build(&preset);
            ctx.run(cmd.args(["--target", "sphinxdoc"]))?
        }
        cmake::TargetStatus::Unavailable(reason) => {
            warn!("sphinxdoc target disabled (reason: {})--skipping", reason);
        }
    }

    Ok(())
}
