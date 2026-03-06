// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.
//!
//! Entrypoint for LIBRA CLI.

// Imports
mod cli;
mod cmake;
mod command;
mod preset;
mod runner;
mod utils;

use anyhow::Result;
use clap::Parser;
use cli::{Cli, ColorMode, Command};

// Public API
fn main() -> Result<()> {
    let cli = Cli::parse();

    match cli.color {
        ColorMode::Always => colored::control::set_override(true),
        ColorMode::Never => colored::control::set_override(false),
        ColorMode::Auto => {}
    }
    let ctx = runner::Context {
        preset: cli.preset,
        verbose: cli.verbose,
        quiet: cli.quiet,
        dry_run: cli.dry_run,
        reconfigure: cli.reconfigure,
    };

    match cli.command {
        Command::Build(args) => command::build::run(&ctx, args),
        Command::Test(args) => command::test::run(&ctx, args),
        Command::Ci(args) => command::ci::run(&ctx, args),
        Command::Analyze(args) => command::analyze::run(&ctx, args),
        Command::Coverage(args) => command::coverage::run(&ctx, args),
        Command::Docs(args) => command::docs::run(&ctx, args),
        Command::Clean(args) => command::clean::run(&ctx, args),
        Command::Info(args) => command::info::run(&ctx, args),
        Command::Doctor(args) => command::doctor::run(args),
        Command::Generate(args) => command::generate::run(args),
    }
}
