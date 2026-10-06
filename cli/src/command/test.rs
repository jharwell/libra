// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.
/*!
 * Implementation of the test command.
 */

// Imports

use log::debug;

use crate::cmake;
use crate::preset;
use crate::runner;
use crate::utils;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
#[derive(clap::ValueEnum, Clone, Copy, Debug, Default)]
pub enum TestType {
    #[default]
    /// Run all tests.
    All,

    /// Only run unit tests.
    Unit,

    /// Only run integration tests.
    Integration,

    /// Only run regression tests.
    Regression,
}

/// How strictly to treat valgrind (memcheck) findings.
///
/// Each policy fails on everything the previous one does, plus more.
#[derive(clap::ValueEnum, Clone, Copy, Debug, PartialEq, Eq)]
pub enum ValgrindPolicy {
    /// Report findings, but never fail because of them.
    Report,

    /// Fail on memory errors (invalid reads/writes, uses of uninitialised
    /// values, bad frees). Report leaks without failing.
    Errors,

    /// Also fail on memory that is definitely lost, and memory reachable only
    /// through it.
    Definite,

    /// Also fail on memory that is possibly lost.
    Leaks,

    /// Also fail on memory still reachable at exit, i.e. never freed but still
    /// pointed to by a global or static.
    Strict,
}

#[derive(clap::Parser, Debug)]
pub struct TestArgs {
    /// Filter by test type. Defaults to no filtering.
    #[arg(long, value_enum, default_value_t)]
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

    /// Run all tests under valgrind, failing on findings according to POLICY
    /// (default: strict). Requires valgrind to be installed.
    #[arg(
        long,
        value_enum,
        value_name = "POLICY",
        num_args = 0..=1,
        require_equals = true,
        default_missing_value = "strict"
    )]
    pub valgrind: Option<ValgrindPolicy>,

    /// Run N tests in parallel. Defaults to # of logical CPUs.
    #[arg(long, default_value_t = utils::num_cpus())]
    pub parallel: u32,

    /// Skip the build step; run ctest directly.
    #[arg(long)]
    pub no_build: bool,

    #[command(flatten)]
    pub configure: cmake::ConfigureArgs,

    /// Run the build and/or tests in verbose mode, printing commands
    #[arg(short, long)]
    pub verbose: bool,
}

// ---------------------------------------------------------------------------
// Implementation
// ---------------------------------------------------------------------------
impl ValgrindPolicy {
    /// Leak kinds that count as errors (valgrind's `--errors-for-leak-kinds`).
    fn error_leak_kinds(self) -> &'static str {
        match self {
            Self::Report | Self::Errors => "none",
            Self::Definite => "definite,indirect",
            Self::Leaks => "definite,indirect,possible",
            Self::Strict => "all",
        }
    }

    /// Leak kinds to show in the report (valgrind's `--show-leak-kinds`).
    ///
    /// Policies that fail on leaks show only the kinds they fail on: CTest
    /// counts every leak shown as a defect, so showing more would make its
    /// defect counts disagree with pass/fail.
    fn show_leak_kinds(self) -> &'static str {
        match self {
            Self::Report => "all",
            Self::Errors => "definite,possible",
            _ => self.error_leak_kinds(),
        }
    }

    /// Valgrind options implementing this policy.
    pub fn valgrind_args(self) -> Vec<String> {
        let mut args = vec![
            "--leak-check=full".to_string(),
            format!("--show-leak-kinds={}", self.show_leak_kinds()),
            format!("--errors-for-leak-kinds={}", self.error_leak_kinds()),
        ];
        // Without this, valgrind exits with the test's own status, so a test
        // that passes passes under memcheck too, whatever valgrind finds.
        if self != Self::Report {
            args.push("--error-exitcode=1".to_string());
        }
        args
    }
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------
pub fn run(ctx: &runner::Context, args: TestArgs) -> anyhow::Result<()> {
    preset::ensure_project_root(ctx)?;

    debug!("Begin");
    let preset = preset::resolve(ctx, None)?;

    let bdir = cmake::ensure_configured(&ctx, &preset, &args.configure)?;
    if !ctx.dry_run {
        cmake::ensure_libra_feature_enabled(ctx, &preset, "LIBRA_TESTS")?;
    }

    if !args.no_build {
        let mut cmd = cmake::base_build(&preset);
        cmd.args(["--target", "all-tests"]);
        if args.verbose {
            cmd.arg("--verbose");
        }
        ctx.run(&mut cmd)?;
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
    if args.verbose {
        cmd.arg("--verbose");
    }
    if let Some(filter) = &args.filter {
        cmd.args(["--tests-regex", filter]);
    }
    if args.stop_on_failure {
        cmd.arg("--stop-on-failure");
    }
    if args.rerun_failed {
        cmd.arg("--rerun-failed");
    }
    if let Some(policy) = args.valgrind {
        cmd.args(["-T", "memcheck"]);
        cmd.arg("--test-dir").arg(bdir);
        cmd.arg("--overwrite").arg(format!(
            "MemoryCheckCommandOptions={}",
            policy.valgrind_args().join(" ")
        ));
    }

    ctx.run(&mut cmd)?;

    Ok(())
}
