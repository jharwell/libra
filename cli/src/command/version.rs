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
#[derive(clap::Parser, Debug)]
pub struct VersionArgs {
    /// Compare the resolved version against a specified one, for use in CI
    /// gating. Reads from CMake Cache.
    #[arg(long, short)]
    pub check: Option<String>,

    /// Show full versions instead of numeric versions. Reads from CMake cache.
    #[arg(long)]
    pub full: bool,

    /// Bump the patch component of the resolved version (numeric only). Reads
    /// git tags (single source of truth). Does not read CMake Cache.
    #[arg(short, long)]
    pub bump: bool,

    /// Force the configure step even if the build directory exists.
    #[arg(short, long)]
    pub reconfigure: bool,

    /// Reconfigure with a --fresh build directory by wiping the CMake cache.
    #[arg(short, long)]
    pub fresh: bool,

    /// Indicate that LIBRA's own version should be managed. Hidden, obviously.
    #[arg(long, hide = true)]
    pub self_: bool,
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------
pub fn run(ctx: &runner::Context, args: VersionArgs) -> anyhow::Result<()> {
    debug!("Begin");

    if args.bump {
        anyhow::ensure!(!args.full, "--full not valid with --bump");
        let bumped = versioning::next(std::path::Path::new("."))?;
        println!("{}", bumped);
        return Ok(());
    }

    // This is the version that will ship with the project (or LIBRA itself), as
    // it is read from the CMake cache and therefore can be baked into the
    // compiled binary.
    let baked = if args.self_ {
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
        "Resolved version from CMake cache: numeric={},full={}",
        baked.numeric, baked.full
    );

    if let Some(to_check) = args.check {
        let as_ver = semver::Version::parse(&to_check)?;
        if as_ver != baked.numeric {
            error!("Resolved version {} != {}", baked.numeric, as_ver);
            std::process::exit(1);
        }
        debug!("Resolved version match: numeric={}", baked.numeric);
        return Ok(());
    }

    println!("{}", if args.full { baked.full } else { baked.numeric });

    Ok(())
}

// ---------------------------------------------------------------------------
// Private API
// ---------------------------------------------------------------------------
