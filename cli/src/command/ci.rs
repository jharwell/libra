// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.
/*!
 * Implementation of the ci command.
 */

// Imports
use clap;
use log::{debug, warn};

use crate::cmake;
use crate::preset;
use crate::runner;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
#[derive(clap::Parser, Debug)]
pub struct CiArgs {
    #[command(flatten)]
    pub configure: cmake::ConfigureArgs,
}

// Traits

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------
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
    cmake::ensure_configured(&ctx, &preset, &args.configure)?;

    if !ctx.dry_run {
        cmake::ensure_libra_feature_enabled(ctx, &preset, "LIBRA_COVERAGE")?;
        cmake::ensure_libra_feature_enabled(ctx, &preset, "LIBRA_TESTS")?;
    }

    let test_target = if ctx.dry_run {
        "all-tests"
    } else {
        match cmake::target_status("all-tests", &preset)? {
            cmake::TargetStatus::Unavailable(reason) => {
                anyhow::bail!("CI target all-tests does not exist! Reason: {}", reason);
            }
            cmake::TargetStatus::Available => "all-tests",
        }
    };

    let check_target = if ctx.dry_run {
        "gcovr-check"
    } else {
        match cmake::target_status("gcovr-check", &preset)? {
            cmake::TargetStatus::Unavailable(reason) => {
                anyhow::bail!("CI target gcovr-check does not exist! Reason: {}", reason);
            }
            cmake::TargetStatus::Available => "gcovr-check",
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
