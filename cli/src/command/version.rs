// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.
/*!
 * Implementation of the version command.
 */

// Imports
use anyhow;
use clap;
use log::{debug, error};

use crate::{cmake, preset, runner, utils, versioning};

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
#[derive(clap::ValueEnum, Clone, Debug, Default)]
pub enum OutputFormat {
    #[default]
    Human,
    Json,
}

#[derive(clap::Parser, Debug)]
pub struct VersionArgs {
    /// Compare the resolved version against a specified one, for use in CI
    /// gating. Can be used in conjunction with --bump.
    #[arg(long, short)]
    pub check: Option<String>,

    /// Use/parse/manage full versions instead of numeric versions.
    #[arg(long)]
    pub full: bool,

    /// The output format to print the version in.
    #[arg(short, long)]
    pub output: Option<OutputFormat>,

    /// Bump the patch component of the resolved version (numeric only).
    #[arg(short, long)]
    pub bump: bool,

    /// Indicate that LIBRA's own version should be managed. Hidden, obviously.
    #[arg(long, hide = true)]
    pub self_: bool,

    /// Force the configure step even if the build directory exists.
    #[arg(short, long)]
    pub reconfigure: bool,

    /// Reconfigure with a --fresh build directory by wiping the CMake cache.
    #[arg(short, long)]
    pub fresh: bool,
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------
pub fn run(ctx: &runner::Context, args: VersionArgs) -> anyhow::Result<()> {
    debug!("Begin");

    let ver = if args.self_ {
        utils::versioning_resolve_self()?
    } else {
        let preset = preset::resolve(ctx, None)?;

        if args.reconfigure || args.fresh {
            debug!("Begin reconfigure");
            cmake::reconf(ctx, &preset, args.fresh, &[])?;
        }

        versioning::resolve(&preset)?
    };

    debug!(
        "Resolved version: numeric={},full={}",
        ver.numeric, ver.full
    );
    if let Some(to_check) = args.check {
        let as_ver = semver::Version::parse(&to_check)?;
        if args.full {
            if as_ver != ver.full {
                error!("Resolved version {} != {}", ver.full, as_ver);
                std::process::exit(1);
            }
            debug!("Resolved version match: full={}", ver.numeric);
        } else {
            if as_ver != ver.numeric {
                error!("Resolved version {} != {}", ver.numeric, as_ver);
                std::process::exit(1);
            }
            debug!("Resolved version match: numeric={}", ver.numeric);
        }
        return Ok(());
    }

    if args.bump {
        if ver.numeric != ver.full && args.full {
            error!(
                "Cannot bump full version {}: not in semver X.Y.Z format",
                ver.full
            );
            std::process::exit(1);
        }
        println!("{}", versioning::increment(&ver)?);
        return Ok(());
    }

    println!("{}", if args.full { ver.full } else { ver.numeric });

    Ok(())
}

// ---------------------------------------------------------------------------
// Private API
// ---------------------------------------------------------------------------
