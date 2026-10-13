// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.
/*!
 * Implementation of the coverage command.
 */

// Imports
use anyhow::Context;
use clap;
use log::debug;
use open;

use crate::cmake;
use crate::preset;
use crate::runner;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
#[derive(clap::ValueEnum, Clone, Copy, Debug, Default)]
pub enum HtmlType {
    #[default]
    /// Generate an HTML report with gcovr. Requires GNU compilers to have been
    /// used.
    Gcovr,

    /// Generate an HTML report with lcov. Requires GNU compilers to have been
    /// used.
    Lcov,

    /// Generate an HTML report with llvm. Requires clang compilers/LLVM
    /// coverage to have been gathered.
    Llvm,
}
#[derive(clap::ValueEnum, Clone, Copy, Debug, Default)]
pub enum CheckType {
    #[default]
    /// Check coverage with with gcovr. Requires GNU compilers to have been
    /// used.
    Gcovr,
}

#[derive(clap::Parser, Debug)]
pub struct CoverageArgs {
    /// Generate HTML report using BUILDER (default: gcovr).
    #[arg(long, value_enum,
        value_name = "BUILDER",
        num_args = 0..=1,
        require_equals = true,
        default_missing_value = "gcovr")]
    pub html: Option<HtmlType>,

    /// Check code coverage using the specified tool.
    #[arg(long,
        value_enum,
        value_name = "TOOL",
        num_args = 0..=1,
        require_equals = true,
        default_missing_value = "gcovr")]
    pub check: Option<CheckType>,

    /// Open the HTML report in the system browser after generation.
    #[arg(long)]
    pub open: bool,

    #[command(flatten)]
    pub configure: cmake::ConfigureArgs,
}

// Traits

// ---------------------------------------------------------------------------
// Private API
// ---------------------------------------------------------------------------
fn ensure_target<T: clap::ValueEnum>(
    preset: &str,
    is_report: bool,
    dry_run: bool,
    slug: &T,
) -> anyhow::Result<String> {
    let target = format!(
        "{}-{}",
        slug.to_possible_value()
            .expect("No skipped variants")
            .get_name(),
        if is_report { "report" } else { "check" }
    );

    if dry_run {
        debug!("Skip target '{target}' existence check (dry run)");
        return Ok(target);
    }
    debug!("Checking target '{target}' existence");

    let status = cmake::target_status(&target, preset)
        .with_context(|| format!("Failed to get status for target '{:?}'", target))?;

    match status {
        cmake::TargetStatus::Available => {
            debug!("Target '{target}' is available");
            Ok(target)
        }
        cmake::TargetStatus::Unavailable(reason) => {
            anyhow::bail!("Target '{target}' is unavailable: {reason}")
        }
    }
}

fn run_html(ctx: &runner::Context, preset: &str, html: HtmlType, open: bool) -> anyhow::Result<()> {
    let target = ensure_target(preset, true, ctx.dry_run, &html)?;

    ctx.run(cmake::base_build(preset).args(["--target", &target]))?;

    if open && !ctx.dry_run {
        let bdir = cmake::binary_dir(preset)
            .with_context(|| format!("Resolving binary directory for preset '{preset}'"))?;
        anyhow::ensure!(
            bdir.exists(),
            "Build directory '{}' does not exist for preset '{preset}'.\n\
         Run 'libra build --preset {preset}' first.",
            bdir.display()
        );
        open::that(bdir.join("coverage").join("index.html"))?;
    }
    Ok(())
}

fn run_check(ctx: &runner::Context, preset: &str, check: CheckType) -> anyhow::Result<()> {
    let target = ensure_target(preset, false, ctx.dry_run, &check)?;

    ctx.run(cmake::base_build(preset).args(["--target", &target]))?;
    Ok(())
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

pub fn run(ctx: &runner::Context, args: CoverageArgs) -> anyhow::Result<()> {
    preset::ensure_project_root(ctx)?;
    debug!("Begin");

    let preset = preset::resolve(ctx, Some("coverage"))?;

    cmake::ensure_configured(ctx, &preset, &args.configure)?;

    if !ctx.dry_run {
        cmake::ensure_libra_feature_enabled(ctx, &preset, "LIBRA_COVERAGE")?;
    }

    let mut m = false;
    if let Some(html) = args.html {
        run_html(ctx, &preset, html, args.open)?;
        m = true;
    }
    if let Some(check) = args.check {
        run_check(ctx, &preset, check)?;
        m = true;
    }
    anyhow::ensure!(
        m,
        "No coverage target specified: either --html or --check must be given"
    );

    Ok(())
}
