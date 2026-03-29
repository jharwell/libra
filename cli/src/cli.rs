// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.
//
// CLAP struct for LIBRA CLI.
//
// Because this is included in build.rs, ONLY type definitions in here.

// Imports
use crate::command::{
    analyze, build, ci, clean, coverage, docs, doctor, generate, info, install, test,
};
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
    /// CMake preset name. Resolved via vendor field rules in
    /// [CmakePresets.json,CMakeUserPresets.json] if absent.
    #[arg(long, global = true)]
    pub preset: Option<String>,

    /// Log verbosity.
    #[arg(long, value_enum, default_value = "warn", global = true)]
    pub log: LogLevel,

    /// Print the cmake/ctest commands that would be run, then exit
    /// without executing. Target availability checks and filesystem
    /// checks are skipped.
    #[arg(long, global = true)]
    pub dry_run: bool,

    /// Control ANSI color output. Defaults to 'auto' (color when stdout is a
    /// TTY).
    #[arg(long, value_enum, default_value = "auto", global = true)]
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

    /// Configure (if needed), build, and install the project.
    Install(install::InstallArgs),

    /// Build (if needed) and run tests via ctest. Requires LIBRA_TESTS=ON in
    /// the resolved preset's CMake cache.
    Test(test::TestArgs),

    /// Run the CI pipeline: build with coverage, run tests, and check
    /// coverage.
    ///
    /// The resolved preset defaults to `ci` if `--preset` is not given
    /// and no default is configured.
    ///
    /// If a workflow preset named <n> exists, delegates to
    /// `cmake --workflow --preset <n>`. Otherwise sequences individual
    /// cmake/ctest invocations and emits a warning.
    ///
    /// The fallback requires `LIBRA_TESTS=ON` and `LIBRA_CODE_COV=ON`
    /// and the targets `all-tests` and `gcovr-check` to be present.
    Ci(ci::CiArgs),

    /// Configure (if needed) and run static analysis.
    ///
    /// The resolved preset defaults to `analyze` if
    /// `--preset` is not given and no default is configured.
    ///
    /// Requires `LIBRA_ANALYSIS=ON` in the preset's CMake cache. Without a
    /// subcommand, runs the analyze umbrella target. With a subcommand,
    /// runs only the corresponding target (e.g. `analyze-clang-tidy`). Emits
    /// an error with the reason from the build system if the target is
    /// unavailable.
    Analyze(analyze::AnalyzeArgs),

    /// Configure (if needed) and generate a coverage report/check
    /// coverage.
    ///
    /// Fails if neither of those operations are possible. Requires
    /// `LIBRA_CODE_COV=ON` in the preset's CMake cache. The preset defaults to
    /// `coverage` if not given.
    ///
    Coverage(coverage::CoverageArgs),

    /// Configure (if needed) and build documentation.
    ///
    /// Requires `LIBRA_DOCS=ON` in the preset's CMake cache. The preset
    /// defaults to docs if not given.
    ///
    /// Attempts to build both `apidoc` and `sphinxdoc` targets
    /// independently. If a target is listed as unavailable by the build system,
    /// it is skipped with a warning rather than an error.
    Docs(docs::DocsArgs),

    /// Clean build artifacts for the active preset.
    Clean(clean::CleanArgs),

    /// Show resolved build configuration, available targets.
    ///
    /// Requires a prior clibra build to have configured the build
    /// directory. Output is paged through `less -rFX` when the content
    /// exceeds the terminal height. Color output follows the global `--color`
    /// setting regardless of the TTY, to ensure correct display through the
    /// pager.
    ///
    /// Sections:
    ///
    /// - **Build configuration**: build directory path, generator, and
    ///   selected CMAKE_* cache variables (build type, compilers, flags,
    ///   install prefix, project name, compile-commands export).
    ///
    /// - **LIBRA feature flags**: all LIBRA_ cache variables with
    ///   non-default values highlighted.
    ///
    /// - **Available LIBRA targets**: grouped by feature area (Tests, Docs,
    ///   Coverage, Analysis) with per-target availability and, for unavailable
    ///   targets, the reason reported by the build system.
    Info(info::InfoArgs),

    /// Check tool availability and minimum versions, and validate the project
    /// layout.
    Doctor(doctor::DoctorArgs),

    /// Generate shell completions or a manpage. This subcommand is hidden from
    /// normal help output.
    ///
    /// - clibra generate --shell=bash|zsh|fish|elvish|powershell
    ///
    /// - clibra generate --manpage
    #[command(hide = true)]
    Generate(generate::GenerateArgs),
}
