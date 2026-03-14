// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.
/*!
 * Implementation of the ci command.
 */

// Imports
use crate::cmake;
use crate::preset;
use crate::runner;
use anyhow;
use clap;
use log::{debug, warn};

// Types
#[derive(clap::Parser, Debug)]
pub struct CiArgs {
    #[arg(short = 'D', value_name = "VAR=VALUE")]
    pub defines: Vec<String>,

    /// Force the configure step even if the build directory exists.
    #[arg(short, long)]
    pub reconfigure: bool,
}

// Traits

// Implementation

// Public API
pub fn run(ctx: &runner::Context, args: CiArgs) -> anyhow::Result<()> {
    preset::ensure_project_root(ctx)?;

    debug!("Begin");

    let preset = preset::resolve(ctx, Some("ci"))?;

    for f in ["CMakeUserPresets.json", "CMakePresets.json"] {
        if preset::workflow_preset_exists(f, &preset)? {
            debug!("Running ci workflow preset");
            ctx.run(&mut cmake::base_workflow(&preset))?;
            return Ok(());
        }
    }
    warn!("No ci workflow preset found--falling back to manual steps");

    if args.reconfigure {
        debug!("Begin reconfigure");
        cmake::reconf(ctx, &preset, &args.defines)?;
    }

    if !ctx.dry_run {
        cmake::ensure_libra_feature_enabled(ctx, &preset, "LIBRA_CODE_COV")?;
        cmake::ensure_libra_feature_enabled(ctx, &preset, "LIBRA_TESTS")?;
    }

    let test_target = if ctx.dry_run { "all-tests"} else {
        match cmake::target_status("all-tests", &preset, ctx)? {
            cmake::TargetStatus::Unavailable(reason) => {
                anyhow::bail!(
                    "CI target all-tests does not exist! Reason: {}",
                    reason
                );
            }
            cmake::TargetStatus::Available => {"all-tests"}
        }
    };

    let check_target = if ctx.dry_run {"gcovr-check"} else {
        match cmake::target_status("gcovr-check", &preset, ctx)? {
            cmake::TargetStatus::Unavailable(reason) => {
                anyhow::bail!(
                    "CI target gcovr-check does not exist! Reason: {}",
                    reason
                );
            }
            cmake::TargetStatus::Available => {"gcovr-check"}
        }
    };

    // build
    ctx.run(cmake::base_build(&preset).args(["--target", test_target]))?;

    // test
    ctx.run(&mut cmake::base_test(&preset))?;

    // check
    ctx.run(cmake::base_build(&preset).args(["--target", check_target]))?;
    Ok(())
}
