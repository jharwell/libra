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
#[derive(clap::Parser, Debug)]
pub struct CoverageArgs {
    /// Generate HTML report.
    ///
    /// Tries gcovr and LLVM-based generation in order.
    #[arg(long)]
    pub html: bool,

    /// Check code coverage with gcovr.
    #[arg(long)]
    pub check: bool,

    /// Open the HTML report in the system browser after generation.
    #[arg(long)]
    pub open: bool,

    #[command(flatten)]
    pub configure: cmake::ConfigureArgs,
}

// Traits

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

pub fn run(ctx: &runner::Context, args: CoverageArgs) -> anyhow::Result<()> {
    preset::ensure_project_root(ctx)?;
    debug!("Begin");

    let preset = preset::resolve(ctx, Some("coverage"))?;

    cmake::ensure_configured(&ctx, &preset, &args.configure)?;
    let mut success = false;
    if !args.html && !args.check {
        anyhow::bail!("No coverage target specified: either --html or --check must be given");
    }
    if args.html {
        cmake::ensure_libra_feature_enabled(ctx, &preset, "LIBRA_COVERAGE")?;
        debug!("Checking ['gcovr-report','llvm-report'] existence");

        let target = if ctx.dry_run {
            "gcovr-report"
        } else {
            ["gcovr-report", "llvm-report"]
                .iter()
                .copied()
                .find_map(|t| match cmake::target_status(t, &preset) {
                    Ok(cmake::TargetStatus::Available) => Some(Ok(t)),
                    Ok(cmake::TargetStatus::Unavailable(_)) => None,
                    Err(e) => Some(Err(e)),
                })
                .ok_or_else(|| {
                    anyhow::anyhow!(
                        "no HTML-generating targets
                exist"
                    )
                })??
        };

        debug!("Found {target}");
        ctx.run(cmake::base_build(&preset).args(["--target", target]))?;

        if args.open && !ctx.dry_run {
            let bdir = cmake::binary_dir(&preset)
                .with_context(|| format!("Resolving binary directory for preset '{preset}'"))?;
            if !bdir.exists() {
                anyhow::bail!(
                    "Build directory '{}' does not exist for preset '{preset}'.\n\
         Run 'libra build --preset {preset}' first.",
                    bdir.display()
                );
            }
            open::that(bdir.join("coverage").join("index.html"))?;
        }
        success = true;
    }
    if args.check {
        cmake::ensure_libra_feature_enabled(ctx, &preset, "LIBRA_COVERAGE")?;
        debug!("Checking ['gcovr-check'] existence");

        let target = if ctx.dry_run {
            "gcovr-check"
        } else {
            ["gcovr-check"]
                .iter()
                .copied()
                .find_map(|t| match cmake::target_status(t, &preset) {
                    Ok(cmake::TargetStatus::Available) => Some(Ok(t)),
                    Ok(cmake::TargetStatus::Unavailable(_)) => None,
                    Err(e) => Some(Err(e)),
                })
                .ok_or_else(|| anyhow::anyhow!("no checking targets exist"))??
        };

        debug!("Found {target}");
        ctx.run(cmake::base_build(&preset).args(["--target", target]))?;

        success = true;
    }

    if !success {
        anyhow::bail!("Failed to run any coverage targets")
    }
    Ok(())
}
