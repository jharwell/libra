// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.
//
// CLAP struct for LIBRA CLI.
//
// Because this is included in build.rs, ONLY type definitions in here.

// Imports
use clap::{Parser, Subcommand, ValueEnum};

/**
 * LIBRA CMake automation framework CLI.
 *
 * Wraps cmake, cmake --build, ctest, and cmake --workflow with
 * preset-aware defaults.
 */
#[derive(Parser, Debug)]
#[command(name = "clibra", version, about, propagate_version = true)]
pub struct Cli {

    /// CMake preset name. Defaults to 'debug'.
    #[arg(long, global = true)]
    pub preset: Option<String>,

    /// Print cmake/ctest commands before executing them.
    #[arg(short, long, global = true)]
    pub verbose: bool,

    /// Suppress cmake/ctest stdout; stderr always passes through.
    #[arg(short, long, global = true)]
    pub quiet: bool,

    /// Print commands without executing them.
    #[arg(long, global = true)]
    pub dry_run: bool,

    #[command(subcommand)]
    pub command: Command,
}

#[derive(Subcommand, Debug)]
pub enum Command {
    /// Configure (if needed) and build the project.
    Build(BuildArgs),
    /// Build (if needed) and run tests via ctest.
    Test(TestArgs),
    /// Run the CI pipeline via cmake --workflow.
    Ci(CiArgs),
    /// Configure (if needed) and run static analysis.
    Analyze(AnalyzeArgs),
    /// Configure (if needed) and generate a coverage report.
    Coverage(CoverageArgs),
    /// Configure (if needed) and build documentation.
    Docs(DocsArgs),
    /// Clean build artifacts for the active preset.
    Clean(CleanArgs),
    /// Show resolved preset configuration.
    Info(InfoArgs),
    /// Check tool availability and versions.
    Doctor,
}

#[derive(Parser, Debug)]
pub struct BuildArgs {
    /// Parallel job count.
    #[arg(short = 'j', long, default_value_t = num_cpus())]
    pub jobs: u32,

    /// Build a specific CMake target.
    #[arg(short, long)]
    pub target: Option<String>,

    /// Pass --clean-first to cmake --build.
    #[arg(long)]
    pub clean: bool,

    /// Force the configure step even if the build directory exists.
    #[arg(short, long)]
    pub reconfigure: bool,

    /// Continue building after errors.
    #[arg(short = 'k', long)]
    pub keep_going: bool,

    /// Forward -DVAR=VALUE to the cmake configure step.
    #[arg(short = 'D', value_name = "VAR=VALUE")]
    pub defines: Vec<String>,
}

#[derive(Parser, Debug)]
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

    /// Run N tests in parallel.
    #[arg(long, default_value_t = num_cpus())]
    pub parallel: u32,

    /// Skip the build step.
    #[arg(long)]
    pub no_build: bool,

    /// Forward -DVAR=VALUE to the cmake configure step when building.
    #[arg(short = 'D', value_name = "VAR=VALUE")]
    pub defines: Vec<String>,
}

#[derive(ValueEnum, Clone, Debug, Default)]
pub enum TestType {
    #[default]
    All,
    Unit,
    Integration,
    Regression,
}

#[derive(Parser, Debug)]
pub struct CiArgs {
}

#[derive(Parser, Debug)]
pub struct AnalyzeArgs {
    #[arg(short = 'j', long, default_value_t = num_cpus())]
    pub jobs: u32,

    #[arg(short = 'k', long)]
    pub keep_going: bool,

    #[arg(short = 'D', value_name = "VAR=VALUE")]
    pub defines: Vec<String>,
}

#[derive(Parser, Debug)]
pub struct CoverageArgs {
    /// Open the HTML report in the system browser after generation.
    #[arg(long)]
    pub open: bool,

    #[arg(short = 'D', value_name = "VAR=VALUE")]
    pub defines: Vec<String>,
}

#[derive(Parser, Debug)]
pub struct DocsArgs {
    #[arg(short = 'D', value_name = "VAR=VALUE")]
    pub defines: Vec<String>,
}

#[derive(Parser, Debug)]
pub struct CleanArgs {
    /// Remove the entire build directory instead of running the clean target.
    #[arg(long)]
    pub all: bool,
}

#[derive(Parser, Debug)]
pub struct InfoArgs {}

fn num_cpus() -> u32 {
    std::thread::available_parallelism()
        .map(|n| n.get() as u32)
        .unwrap_or(4)
}
