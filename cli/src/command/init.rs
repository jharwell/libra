// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.
/*!
 * Implementation of the init command.
 */

// Imports
use crate::cmake;
use crate::runner;

use anyhow;
use clap;
use log::{debug, info, warn};
use std::path;

// Types
#[derive(clap::Parser, Debug)]
pub struct InitArgs {
    /// Overwrite all existing files.
    #[arg(long)]
    pub force: bool,

    /// The name of the project to scaffold.
    #[arg(long, short)]
    pub name: String,
}

// Implementation

fn write_template(
    path: &path::Path,
    content: &str,
    force: bool,
    dry_run: bool,
) -> anyhow::Result<()> {
    if !path.exists() {
        info!("Writing {}", path.display());
        if !dry_run {
            std::fs::write(path, content)?;
        }
        return Ok(());
    }

    if force {
        warn!("Overwriting existing {}", path.display());
        if !dry_run {
            std::fs::write(path, content)?;
        }
    } else {
        debug!(
            "Skipping existing {}; use --force to overwrite",
            path.display()
        );
    }
    Ok(())
}

// Public API

pub fn run(ctx: &runner::Context, args: InitArgs) -> anyhow::Result<()> {
    debug!("Begin");

    write_template(
        path::Path::new("CMakeLists.txt"),
        &cmake::cmakelists_template(&args.name),
        args.force,
        ctx.dry_run,
    )?;
    write_template(
        path::Path::new("CMakePresets.json"),
        cmake::cmakepresets_template(),
        args.force,
        ctx.dry_run,
    )?;

    if !ctx.dry_run {
        std::fs::create_dir_all("cmake")?;
    }

    write_template(
        path::Path::new("cmake/project-local.cmake"),
        cmake::projectlocal_template(),
        args.force,
        ctx.dry_run,
    )?;

    for d in ["src", "include", "docs"] {
        if !std::fs::exists(d)? {
            info!("Creating directory {d}/");
            if !ctx.dry_run {
                std::fs::create_dir_all(d)?;
            }
        }
    }

    debug!("End");
    Ok(())
}
