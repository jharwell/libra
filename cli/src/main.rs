// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.
//!
//! Entrypoint for LIBRA CLI.

// Imports
mod cli;
mod command;
mod utils;
mod preset;
mod runner;

use anyhow::Result;
use clap::Parser;
use cli::{Cli, Command};

// Public API
fn main() -> Result<()> {
    let cli = Cli::parse();

    let ctx = runner::Context {
        preset:  cli.preset,
        verbose: cli.verbose,
        quiet:   cli.quiet,
        dry_run: cli.dry_run,
    };

    match cli.command {
        // Command::Build(args)    => command::build::run(&ctx, args),
        // Command::Test(args)     => command::test::run(&ctx, args),
        // Command::Ci(args)       => command::ci::run(&ctx, args),
        // Command::Analyze(args)  => command::analyze::run(&ctx, args),
        // Command::Coverage(args) => command::coverage::run(&ctx, args),
        // Command::Docs(args)     => command::docs::run(&ctx, args),
        // Command::Clean(args)    => command::clean::run(&ctx, args),
        Command::Info(ctx)        => command::info::run(&ctx),
        // Command::Doctor         => command::doctor::run(),
    }
}
