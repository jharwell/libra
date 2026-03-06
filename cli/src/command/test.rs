// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.
/*!
 * Implementation of the test command.
 */

// Imports
use anyhow;
use clap;

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
    /// Filter by test type.
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

    /// Run N tests in parallel.
    #[arg(long, default_value_t = utils::num_cpus())]
    pub parallel: u32,

    /// Skip the build step.
    #[arg(long)]
    pub no_build: bool,

    /// Forward -DVAR=VALUE to the cmake configure step when building.
    #[arg(short = 'D', value_name = "VAR=VALUE")]
    pub defines: Vec<String>,
}

// Traits

// Implementation

// Public API
pub fn run(ctx: &runner::Context, args: TestArgs) -> anyhow::Result<()> {
    preset::check_project_root()?;
    let preset = preset::resolve(ctx, None)?;

    let bdir = cmake::binary_dir(ctx)?;

    if ctx.reconfigure || !bdir.exists() {
        cmake::reconf(ctx, &preset, &args.defines)?;
    }
    if !args.no_build {
        ctx.run(&mut cmake::base_build(&preset))?;
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
