// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.
//
// CLAP struct for LIBRA CLI.
//
// Because this is included in build.rs, ONLY type definitions in here.

// Imports
use crate::command::{analyze, build, ci, clean, coverage, docs, doctor, generate, info, test};
use clap::{Parser, Subcommand};

#[derive(clap::ValueEnum, Clone, Debug, Default)]
pub enum ColorMode {
    #[default]
    Auto,
    Always,
    Never,
}

///
/// LIBRA CMake automation framework CLI.
///
/// Wraps cmake, cmake --build, ctest, and cmake --workflow with
/// preset-aware defaults.
///
#[derive(Parser, Debug)]
#[command(
    name = "clibra",
    version,
    about,
    propagate_version = true,
    term_width = 120
)]
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

    /// Include color in outputs where applicable.
    #[arg(long, value_enum, default_value = "auto")]
    pub color: ColorMode,

    /// Force the configure step even if the build directory exists.
    #[arg(short, long, global = true)]
    pub reconfigure: bool,

    #[command(subcommand)]
    pub command: Command,
}

#[derive(Subcommand, Debug)]
pub enum Command {
    /// Configure (if needed) and build the project.
    Build(build::BuildArgs),
    /// Build (if needed) and run tests via ctest.
    Test(test::TestArgs),
    /// Run the CI pipeline: build with coverage, run tests, and check
    /// coverage.
    Ci(ci::CiArgs),
    /// Configure (if needed) and run static analysis.
    Analyze(analyze::AnalyzeArgs),
    /// Configure (if needed) and generate a coverage report.
    Coverage(coverage::CoverageArgs),
    /// Configure (if needed) and build documentation.
    Docs(docs::DocsArgs),
    /// Clean build artifacts for the active preset.
    Clean(clean::CleanArgs),
    /// Show resolved preset configuration.
    Info(info::InfoArgs),

    /// Check tool availability project layout conformance.
    ///
    /// Inclues tool versions.
    Doctor(doctor::DoctorArgs),

    /// Generate shell completions or a manpage.
    #[command(hide = true)]
    Generate(generate::GenerateArgs),
}
