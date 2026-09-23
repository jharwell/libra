// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.
/*!
 * Version resolution and dev-tag bumping.
 *
 * The authoritative source of the *current* version is LIBRA's
 * `version.cmake` (`libra_extract_version()`), which parses git state through
 * its own four-tier resolution chain. That chain (and the exact shape of each
 * resulting version string) is documented canonically in the `versioning`
 * concept page under "Git tags as the single source of truth"; it is not
 * restated here. This module shells out to it via [`resolve`] and never parses
 * git tags itself.
 *
 * [`increment`] then derives the *next* development prerelease tag from a
 * resolved version, purely as a structural operation:
 *
 *   - stable        vX.Y.Z         -> vX.Y.(Z+1)-dev.1
 *   - dev stream    vX.Y.Z-dev.N   -> vX.Y.Z-dev.(N+1)
 *   - other prerel.  vX.Y.Z-rc.M   -> vX.Y.Z-dev.1   (start dev for this numeric)
 *   - fallback       0.0.0         -> v0.0.1-dev.1
 *
 * Build metadata (`+meta`, i.e. HEAD is past its most recent tag) is ignored:
 * the next version depends only on the most recent tag. So a merge on top of
 * `vX.Y.Z-dev.N` (resolved as `vX.Y.Z-dev.N+meta`) continues the dev stream to
 * `dev.(N+1)`, and a commit past stable `vX.Y.Z` still yields
 * `vX.Y.(Z+1)-dev.1`.
 */

// Imports
use anyhow::Context;
use log::debug;

use crate::cmake;
use crate::utils;

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/// Resolve the LIBRA project version from a configured preset's CMake cache.
///
/// `libra_extract_version()` runs at configure time and writes the version
/// components into the cache, so this just reads them back — the repo's own
/// CMake already handled libra discovery (submodule / CPM / system) during
/// configure.
pub fn resolve(preset: &str) -> anyhow::Result<utils::ResolvedVersion> {
    let bdir = cmake::binary_dir(preset).ok_or_else(|| {
        anyhow::anyhow!(
            "Build directory does not exist for preset '{}'.\n\
             Run 'clibra build --preset {}' first to configure the project.",
            preset,
            preset
        )
    })?;

    let full_str = cmake::cache_value(&bdir, "LIBRA_PROJECT_VERSION")?.ok_or_else(|| {
        anyhow::anyhow!("LIBRA_PROJECT_VERSION not in cache; is this a LIBRA project?")
    })?;
    let numeric_str = cmake::cache_value(&bdir, "LIBRA_PROJECT_VERSION_NUMERIC")?
        .ok_or_else(|| anyhow::anyhow!("LIBRA_PROJECT_VERSION_NUMERIC not in cache"))?;
    let prerelease =
        cmake::cache_value(&bdir, "LIBRA_PROJECT_VERSION_PRERELEASE")?.unwrap_or_default();

    let full = semver::Version::parse(full_str.trim())
        .with_context(|| format!("LIBRA_PROJECT_VERSION not valid semver: {full_str:?}"))?;
    let numeric = semver::Version::parse(numeric_str.trim()).with_context(|| {
        format!("LIBRA_PROJECT_VERSION_NUMERIC not valid semver: {numeric_str:?}")
    })?;

    Ok(utils::ResolvedVersion {
        full,
        numeric,
        prerelease,
    })
}

/// Compute the next development prerelease version from a resolved version.
///
/// This is a pure structural transform on `current.full` -- it does not consult
/// git, because version resolution already happened in cmake. See the module
/// docs for the mapping of each input shape to its output.
pub fn increment(current: &utils::ResolvedVersion) -> anyhow::Result<semver::Version> {
    let v = &current.full;
    let dev1 = semver::Prerelease::new("dev.1").expect("literal is valid");

    // Build metadata (`+dist.gsha`) only says HEAD is past its tag; it does
    // not change what the next dev version should be, so it is ignored and
    // the decision is made on the prerelease of the last tag alone.
    if !v.build.is_empty() {
        debug!("HEAD is past its tag ({v}); ignoring build metadata");
    }

    let next = if v.pre.is_empty() {
        debug!("Stable release {v}; advancing patch series");
        let mut n = semver::Version::new(v.major, v.minor, v.patch + 1);
        n.pre = dev1;
        n
    } else if let Some(counter) = dev_counter(&v.pre) {
        debug!("Continuing existing development series from {v}");
        let mut n = semver::Version::new(v.major, v.minor, v.patch);
        n.pre = semver::Prerelease::new(&format!("dev.{}", counter + 1))?;
        n
    } else {
        // Some other prerelease (e.g. rc.1): start the dev stream for this
        // same numeric rather than bumping the patch.
        debug!("Non-dev prerelease {v}; starting dev stream for this numeric");
        let mut n = semver::Version::new(v.major, v.minor, v.patch);
        n.pre = dev1;
        n
    };

    Ok(next)
}

// ---------------------------------------------------------------------------
// Private API
// ---------------------------------------------------------------------------

/// Extract the `N` from a `dev.N` prerelease, or `None` if it isn't one.
fn dev_counter(pre: &semver::Prerelease) -> Option<u64> {
    pre.as_str().strip_prefix("dev.")?.parse().ok()
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

#[cfg(test)]
mod tests {
    use super::*;

    /// Build a ResolvedVersion from a full version string, deriving numeric
    /// and prerelease the way cmake would.
    fn rv(full: &str) -> utils::ResolvedVersion {
        let full: semver::Version = full.parse().unwrap();
        let numeric = semver::Version::new(full.major, full.minor, full.patch);
        utils::ResolvedVersion {
            prerelease: full.pre.as_str().to_owned(),
            full,
            numeric,
        }
    }

    fn v(s: &str) -> semver::Version {
        s.parse().unwrap()
    }

    #[test]
    fn stable_advances_patch() {
        assert_eq!(increment(&rv("1.2.3")).unwrap(), v("1.2.4-dev.1"));
    }

    #[test]
    fn dev_stream_continues() {
        assert_eq!(increment(&rv("1.2.4-dev.4")).unwrap(), v("1.2.4-dev.5"));
    }

    #[test]
    fn dev_counter_double_digit() {
        assert_eq!(increment(&rv("1.2.4-dev.9")).unwrap(), v("1.2.4-dev.10"));
    }

    #[test]
    fn rc_starts_dev_stream_same_numeric() {
        assert_eq!(increment(&rv("1.2.4-rc.1")).unwrap(), v("1.2.4-dev.1"));
    }

    #[test]
    fn untagged_commit_advances_patch() {
        // git-describe style build metadata: HEAD is 2 commits past the tag.
        assert_eq!(
            increment(&rv("1.2.3+2.gabcdef1")).unwrap(),
            v("1.2.4-dev.1")
        );
    }

    #[test]
    fn untagged_dev_commit_continues_dev_stream() {
        // A merge on top of a dev tag continues that dev stream.
        assert_eq!(
            increment(&rv("0.13.11-dev.1+3.gabcdef1")).unwrap(),
            v("0.13.11-dev.2")
        );
    }

    #[test]
    fn untagged_rc_commit_starts_dev_stream_same_numeric() {
        assert_eq!(
            increment(&rv("1.2.4-rc.1+2.gabcdef1")).unwrap(),
            v("1.2.4-dev.1")
        );
    }

    #[test]
    fn zero_fallback_bootstraps() {
        assert_eq!(increment(&rv("0.0.0")).unwrap(), v("0.0.1-dev.1"));
    }
}
