// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.
/*!
 * Implementation of the docs command.
 */

// Imports
use log::debug;

use crate::cmake;
use crate::preset;
use crate::runner;

// Types

#[derive(clap::Args, Debug)]
pub struct CommonArgs {
    /// Continue building after errors. Only valid with {Ninja, Unix Makefiles}
    /// generators.
    #[arg(short = 'k', long, global = true)]
    pub keep_going: bool,
}

#[derive(clap::ValueEnum, Debug, Clone)]
pub enum BuildTarget {
    Sphinx,
    Api,
}

#[derive(clap::ValueEnum, Debug, Clone)]
pub enum CheckKind {
    Clang,
    Doxygen,
}

#[derive(clap::Parser, Debug)]
pub struct BuildArgs {
    #[arg(short, long)]
    pub target: Option<BuildTarget>, // None = all
}

#[derive(clap::Parser, Debug)]
pub struct CheckArgs {
    /// Check doxygen markup.
    #[arg(long, required = true)]
    pub kind: CheckKind,
}

#[derive(clap::Subcommand, Debug)]
pub enum DocsSubCommand {
    /// Build API/sphinx documentation targets.
    Build(BuildArgs),

    /// Check API docs for consistency/content validity.
    Check(CheckArgs),
}

#[derive(clap::Parser, Debug)]
pub struct DocsArgs {
    #[arg(short = 'D', value_name = "VAR=VALUE")]
    pub defines: Vec<String>,

    #[command(flatten)]
    pub common: CommonArgs,

    /// Force the configure step even if the build directory exists.
    #[arg(short, long, global = true)]
    pub reconfigure: bool,

    /// Reconfigure with a --fresh cmake build directory.
    #[arg(short, long, global = true)]
    pub fresh: bool,

    #[command(subcommand)]
    pub command: DocsSubCommand,
}

// Traits

// Implementation
fn run_target(ctx: &runner::Context, args: &DocsArgs, target: &str) -> anyhow::Result<()> {
    preset::ensure_project_root(ctx)?;
    let preset = preset::resolve(ctx, Some("docs"))?;

    debug!("Begin");

    if args.reconfigure || args.fresh {
        debug!("Begin reconfigure");
        cmake::reconf(ctx, &preset, args.fresh, &args.defines)?;
    }

    if !ctx.dry_run {
        cmake::ensure_libra_feature_enabled(ctx, &preset, "LIBRA_DOCS")?;

        match cmake::target_status(target, &preset)? {
            cmake::TargetStatus::Unavailable(reason) => {
                anyhow::bail!("Docs target {} disabled (reason: {})", &target, reason);
            }
            cmake::TargetStatus::Available => {}
        }
    }

    let mut cmd = cmake::base_build(&preset);
    cmd.args(["--target", target]);
    if args.common.keep_going {
        cmd = cmake::with_keep_going(cmd, &preset)?;
    }
    ctx.run(&mut cmd)?;
    Ok(())
}

fn run_build_all(ctx: &runner::Context, args: &DocsArgs) -> anyhow::Result<()> {
    run_target(ctx, args, "apidoc")?;
    run_target(ctx, args, "sphinxdoc")?;
    Ok(())
}

// Public API
pub fn run(ctx: &runner::Context, args: DocsArgs) -> anyhow::Result<()> {
    preset::ensure_project_root(ctx)?;

    debug!("Begin");

    match &args.command {
        DocsSubCommand::Build(build_args) => match &build_args.target {
            Some(BuildTarget::Api) => run_target(ctx, &args, "apidoc")?,
            Some(BuildTarget::Sphinx) => run_target(ctx, &args, "sphinxdoc")?,
            None => run_build_all(ctx, &args)?,
        },
        DocsSubCommand::Check(check_args) => match &check_args.kind {
            CheckKind::Clang => run_target(ctx, &args, "apidoc-check-clang")?,
            CheckKind::Doxygen => run_target(ctx, &args, "apidoc-check-doxygen")?,
        },
    }

    Ok(())
}
