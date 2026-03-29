// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.
//!
//! Entrypoint for LIBRA CLI.

// Imports
use anyhow::Result;
use clap::Parser;
use cli::{Cli, ColorMode, Command, LogLevel};
use std::io::Write;

mod cli;
mod cmake;
mod command;
mod preset;
mod runner;
mod utils;

// Public API
fn main() -> Result<()> {
    let cli = Cli::parse();

    let global_level = cli.log;
    let level = match global_level {
        LogLevel::Error => log::LevelFilter::Error,
        LogLevel::Warn => log::LevelFilter::Warn,
        LogLevel::Info => log::LevelFilter::Info,
        LogLevel::Debug => log::LevelFilter::Debug,
        LogLevel::Trace => log::LevelFilter::Trace,
    };

    pretty_env_logger::formatted_builder()
        .filter_level(level)
        .parse_env("RUST_LOG")
        .format(move |buf, record| {
            use pretty_env_logger::env_logger::fmt::Color;
            let mut style = buf.style();
            let level = match record.level() {
                log::Level::Error => style.set_color(Color::Red).set_bold(true).value("ERROR"),
                log::Level::Warn => style.set_color(Color::Yellow).set_bold(true).value("WARN"),
                log::Level::Info => style.set_color(Color::Green).value("INFO"),
                log::Level::Debug => style.set_color(Color::Blue).set_dimmed(true).value("DEBUG"),
                log::Level::Trace => style
                    .set_color(Color::White)
                    .set_dimmed(true)
                    .value("TRACE"),
            };
            let module = record
                .module_path()
                .unwrap_or("?")
                .split("::")
                .last()
                .unwrap_or("?");

            match global_level {
                LogLevel::Debug | LogLevel::Trace => {
                    writeln!(buf, "[{:<5} {:<8}] {}", level, module, record.args())
                }
                _ => writeln!(buf, "[{} {:<8}] {}", level, module, record.args()),
            }
        })
        .init();

    match cli.color {
        ColorMode::Always => colored::control::set_override(true),
        ColorMode::Never => colored::control::set_override(false),
        ColorMode::Auto => {}
    }
    let ctx = runner::Context {
        preset: cli.preset,
        dry_run: cli.dry_run,
    };

    match cli.command {
        Command::Build(args) => command::build::run(&ctx, args),
        Command::Test(args) => command::test::run(&ctx, args),
        Command::Ci(args) => command::ci::run(&ctx, args),
        Command::Analyze(args) => command::analyze::run(&ctx, args),
        Command::Coverage(args) => command::coverage::run(&ctx, args),
        Command::Docs(args) => command::docs::run(&ctx, args),
        Command::Clean(args) => command::clean::run(&ctx, args),
        Command::Install(args) => command::install::run(&ctx, args),
        Command::Info(args) => command::info::run(&ctx, args),
        Command::Doctor(args) => command::doctor::run(&ctx, args),
        Command::Generate(args) => command::generate::run(args),
    }
}
