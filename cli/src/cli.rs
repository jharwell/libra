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
    /// CMake preset name. Must be specified if a default preset cannot be
    /// loaded from CMakeUserPresets.json or CMakePresets.json.
    #[arg(long, global = true)]
    pub preset: Option<String>,

    #[arg(long, value_enum, default_value = "warn", global=true)]
    pub log: LogLevel,

    /// Print {cmake,ctest} commands without executing them or otherwise doing
    /// anything.
    #[arg(long, global = true)]
    pub dry_run: bool,

    /// Include color in outputs where applicable.
    #[arg(long, value_enum, default_value = "auto", global=true)]
    pub color: ColorMode,

    #[command(subcommand)]
    pub command: Command,
}

#[derive(clap::ValueEnum, Clone, Debug)]
pub enum LogLevel {
    Error,
    Warn,
    Info,
    Debug,
    Trace,
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
    /// Configure (if needed) and generate a coverage report/check
    /// coverage. Fails if neither of those operations are possible.
    Coverage(coverage::CoverageArgs),
    /// Configure (if needed) and build documentation.
    Docs(docs::DocsArgs),
    /// Clean build artifacts for the active preset.
    Clean(clean::CleanArgs),
    /// Show resolved build configuration, available targets.
    Info(info::InfoArgs),

    /// Check tool availability project layout conformance.
    ///
    /// Inclues tool versions.
    Doctor(doctor::DoctorArgs),

    /// Generate shell completions or a manpage.
    #[command(hide = true)]
    Generate(generate::GenerateArgs),
}
