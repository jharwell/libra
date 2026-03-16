// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.
/*!
 * Implementation of the test command.
 */

// Imports
use anyhow;
use clap;
use log::debug;

use crate::cmake;
use crate::preset;
use crate::runner;
use crate::utils;

// Types
#[derive(clap::ValueEnum, Clone, Debug, Default)]
pub enum TestType {
    #[default]
    All,
    Unit,
    Integration,
    Regression,
}

#[derive(clap::Parser, Debug)]
pub struct TestArgs {
    /// Filter by test type. Defaults to no filtering.
    #[arg(long, default_value = "all")]
    pub r#type: TestType,

    /// Run only tests matching this regex (ctest --tests-regex).
    #[arg(long)]
    pub filter: Option<String>,

    /// Stop at the first test failure.
    #[arg(long)]
    pub stop_on_failure: bool,

    /// Rerun only failed tests.
    #[arg(long)]
    pub rerun_failed: bool,

    /// Run N tests in parallel. Defaults to # of logical CPUs.
    #[arg(long, default_value_t = utils::num_cpus())]
    pub parallel: u32,

    /// Skip the build step; run ctest directly.
    #[arg(long)]
    pub no_build: bool,

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

// Traits

// Implementation

// Public API
pub fn run(ctx: &runner::Context, args: TestArgs) -> anyhow::Result<()> {
    preset::ensure_project_root(ctx)?;

    debug!("Begin");
    let preset = preset::resolve(ctx, None)?;

    let bdir = cmake::binary_dir(&preset);

    if args.reconfigure || args.fresh || bdir.is_none_or(|b| !b.exists()) {
        cmake::reconf(ctx, &preset, args.fresh, &args.defines)?;
    }
    if !ctx.dry_run {
        cmake::ensure_libra_feature_enabled(ctx, &preset, "LIBRA_TESTS")?;
    }
    if !args.no_build {
        ctx.run(&mut cmake::base_build(&preset).args(["--target", "all-tests"]))?;
    }

    let mut cmd = cmake::base_test(&preset);

    match args.r#type {
        TestType::Unit => {
            cmd.args(["-L", "unit"]);
        }
        TestType::Integration => {
            cmd.args(["-L", "integration"]);
        }
        TestType::Regression => {
            cmd.args(["-L", "regression"]);
        }
        TestType::All => {}
    }
    cmd.args(["--parallel", &args.parallel.to_string()]);

    if let Some(filter) = &args.filter {
        cmd.args(["--tests-regex", filter]);
    }
    if args.stop_on_failure {
        cmd.arg("--stop-on-failure");
    }
    if args.rerun_failed {
        cmd.arg("--rerun-failed");
    }

    ctx.run(&mut cmd)?;

    Ok(())
}
