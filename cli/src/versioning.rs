// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.
/*!
 * Version resolution and dev-tag bumping.
 *
 * Two separate questions are answered here, from two separate sources:
 *
 * **"What version is this build?"** -- [`resolve`]. The authoritative answer
 * comes from LIBRA's `version.cmake` (`libra_extract_version()`), which parses
 * git state through its own four-tier resolution chain, documented canonically
 * in the `versioning` concept page under "Git tags as the single source of
 * truth". This is ancestry-based: an untagged commit is described relative to
 * its nearest *reachable* tag. This module reads the result back from the CMake
 * cache and never runs `git describe` itself.
 *
 * **"What is the next version?"** -- [`next`]. This is deliberately *not*
 * ancestry-based. LIBRA's versioning scheme assumes a single release line with
 * immutable tags, but allows the development branch to be force-pushed. A
 * force push can leave release tags pointing at commits that are no longer
 * reachable from any branch, so the nearest reachable tag can be stale (e.g.
 * `v0.13.12` reachable while `v0.13.13-dev.1` exists). Under the scheme's own
 * rules the *set of tags* is the release history, so [`next`] takes the
 * highest `vX.Y.Z[-pre]` tag in the repository by SemVer precedence and
 * applies [`increment`] to it. Only tag *names* are parsed (as plain SemVer);
 * git-describe output is never parsed here.
 *
 * [`increment`] is a pure structural transform, and always produces a version
 * with strictly higher SemVer precedence than its input:
 *
 *   - stable          vX.Y.Z         -> vX.Y.(Z+1)-dev.1
 *   - dev stream      vX.Y.Z-dev.N   -> vX.Y.Z-dev.(N+1)
 *   - earlier prerel. vX.Y.Z-alpha.M -> vX.Y.Z-dev.1       (alpha, beta < dev)
 *   - later prerel.   vX.Y.Z-rc.M    -> vX.Y.(Z+1)-dev.1   (rc > dev, so
 *                                       vX.Y.Z-dev.1 would sort *below* the rc)
 *   - no tags         (none)         -> v0.0.1-dev.1
 *
 * Build metadata on the input (`+meta`) is ignored.
 *
 * Because [`next`] only sees tags that exist locally, CI must fetch all tags
 * (`git fetch --tags`, or `fetch-depth: 0` on shallow checkouts) before
 * bumping. A tag that exists only on the remote is invisible here, and the
 * resulting collision is caught when `git push` rejects the duplicate tag.
 */

// Imports
use std::cmp::Ordering;
use std::process::Command;

use anyhow::Context;
use log::{debug, warn};

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

/// Compute the next development prerelease version for the repository at
/// `repo`.
///
/// Based on the highest version tag in the repository by SemVer precedence,
/// regardless of whether it is reachable from HEAD. See the module docs for
/// why.
pub fn next(repo: &std::path::Path) -> anyhow::Result<semver::Version> {
    match latest_tag(repo)? {
        Some(latest) => {
            debug!("Highest version tag by precedence: v{latest}");
            increment(&latest)
        }
        None => {
            debug!("No version tags found; bootstrapping");
            increment(&semver::Version::new(0, 0, 0))
        }
    }
}

/// Return the highest `vX.Y.Z[-pre]` tag in the repository at `repo` by SemVer
/// precedence, or `None` if there are none.
///
/// Tags that are not `v` + valid SemVer are skipped. Every local tag is
/// considered, including tags on commits unreachable from any branch.
pub fn latest_tag(repo: &std::path::Path) -> anyhow::Result<Option<semver::Version>> {
    let out = Command::new("git")
        .arg("-C")
        .arg(repo)
        .args(["tag", "--list", "v*"])
        .output()
        .context("failed to run git")
        .ok();
    match out {
        Some(tag) => {
            if !tag.status.success() {
                warn!(
                    "git tag --list in {} failed: {}",
                    repo.to_string_lossy(),
                    String::from_utf8_lossy(&tag.stderr).trim()
                );
            }

            let latest = String::from_utf8(tag.stdout)
                .context("git tag output not UTF-8")?
                .lines()
                .filter_map(|tag| {
                    let parsed = tag
                        .strip_prefix('v')
                        .and_then(|s| semver::Version::parse(s).ok());
                    if parsed.is_none() {
                        debug!("Ignoring non-SemVer tag {tag:?}");
                    }
                    parsed
                })
                .max_by(|a, b| a.cmp_precedence(b));

            Ok(latest)
        }
        None => Ok(semver::Version::parse("0.0.0").ok()),
    }
}

/// Compute the next development prerelease version after `v`.
///
/// Pure structural transform; does not consult git. The result always has
/// strictly higher SemVer precedence than `v`. See the module docs for the
/// mapping of each input shape to its output.
pub fn increment(v: &semver::Version) -> anyhow::Result<semver::Version> {
    if !v.build.is_empty() {
        debug!("HEAD is past its tag ({v}); ignoring build metadata");
    }

    let next = if v.pre.is_empty() {
        debug!("Stable release {v}; advancing patch series");
        next_patch_dev1(v)
    } else if let Some(counter) = dev_counter(&v.pre) {
        debug!("Continuing existing development series from {v}");
        let mut n = semver::Version::new(v.major, v.minor, v.patch);
        n.pre = semver::Prerelease::new(&format!("dev.{}", counter + 1))?;
        n
    } else {
        // Some other prerelease. Starting dev.1 on the same numeric is only
        // valid if it sorts *above* the current prerelease (alpha, beta);
        // otherwise (rc) it would go backwards, so advance the patch instead.
        let mut same = semver::Version::new(v.major, v.minor, v.patch);
        same.pre = dev1();
        if same.cmp_precedence(v) == Ordering::Greater {
            debug!("Prerelease {v} sorts below dev; starting dev stream for this numeric");
            same
        } else {
            debug!("Prerelease {v} sorts above dev; advancing patch series");
            next_patch_dev1(v)
        }
    };

    debug_assert_eq!(next.cmp_precedence(v), Ordering::Greater);
    Ok(next)
}

// ---------------------------------------------------------------------------
// Private API
// ---------------------------------------------------------------------------

fn dev1() -> semver::Prerelease {
    semver::Prerelease::new("dev.1").expect("literal is valid")
}

fn next_patch_dev1(v: &semver::Version) -> semver::Version {
    let mut n = semver::Version::new(v.major, v.minor, v.patch + 1);
    n.pre = dev1();
    n
}

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

    fn v(s: &str) -> semver::Version {
        s.parse().unwrap()
    }

    fn inc(s: &str) -> semver::Version {
        increment(&v(s)).unwrap()
    }

    #[test]
    fn stable_advances_patch() {
        assert_eq!(inc("1.2.3"), v("1.2.4-dev.1"));
    }

    #[test]
    fn dev_stream_continues() {
        assert_eq!(inc("1.2.4-dev.4"), v("1.2.4-dev.5"));
    }

    #[test]
    fn dev_counter_double_digit() {
        assert_eq!(inc("1.2.4-dev.9"), v("1.2.4-dev.10"));
    }

    #[test]
    fn rc_advances_patch() {
        // 1.2.4-dev.1 < 1.2.4-rc.1, so staying on 1.2.4 would go backwards.
        assert_eq!(inc("1.2.4-rc.1"), v("1.2.5-dev.1"));
    }

    #[test]
    fn alpha_beta_start_dev_stream_same_numeric() {
        assert_eq!(inc("1.2.4-alpha.1"), v("1.2.4-dev.1"));
        assert_eq!(inc("1.2.4-beta.2"), v("1.2.4-dev.1"));
    }

    #[test]
    fn build_metadata_ignored() {
        assert_eq!(inc("1.2.3+2.gabcdef1"), v("1.2.4-dev.1"));
        assert_eq!(inc("0.13.11-dev.1+3.gabcdef1"), v("0.13.11-dev.2"));
    }

    #[test]
    fn zero_bootstraps() {
        assert_eq!(inc("0.0.0"), v("0.0.1-dev.1"));
    }

    #[test]
    fn increment_always_increases_precedence() {
        for s in [
            "0.0.0",
            "1.2.3",
            "1.2.3-dev.1",
            "1.2.3-alpha",
            "1.2.3-beta.7",
            "1.2.3-rc.1",
            "1.2.3-zzz",
            "1.2.3-0",
            "1.2.3+meta",
        ] {
            let before = v(s);
            let after = increment(&before).unwrap();
            assert_eq!(
                after.cmp_precedence(&before),
                Ordering::Greater,
                "{s} -> {after}"
            );
        }
    }

    // -- git-backed tests ---------------------------------------------------

    fn git(dir: &std::path::Path, args: &[&str]) {
        let st = Command::new("git")
            .arg("-C")
            .arg(dir)
            .args([
                "-c",
                "user.name=t",
                "-c",
                "user.email=t@t",
                "-c",
                "commit.gpgsign=false",
            ])
            .args(args)
            .output()
            .unwrap();
        assert!(
            st.status.success(),
            "git {args:?}: {}",
            String::from_utf8_lossy(&st.stderr)
        );
    }

    fn repo() -> tempfile::TempDir {
        let d = tempfile::tempdir().unwrap();
        git(d.path(), &["init", "-q", "-b", "devel"]);
        d
    }

    fn commit(dir: &std::path::Path, msg: &str) {
        git(dir, &["commit", "-q", "--allow-empty", "-m", msg]);
    }

    #[test]
    fn no_tags_bootstraps() {
        let d = repo();
        commit(d.path(), "init");
        assert_eq!(latest_tag(d.path()).unwrap(), None);
        assert_eq!(next(d.path()).unwrap(), v("0.0.1-dev.1"));
    }

    #[test]
    fn picks_highest_by_precedence_not_lexically() {
        let d = repo();
        commit(d.path(), "a");
        // Lexically "v0.13.9" > "v0.13.13"; and git's default version sort puts
        // "-dev.1" after the release. Neither should matter.
        for t in [
            "v0.13.9",
            "v0.13.13-dev.1",
            "v0.13.13-dev.10",
            "v0.13.12",
            "vbogus",
            "latest",
        ] {
            git(d.path(), &["tag", t]);
        }
        assert_eq!(latest_tag(d.path()).unwrap(), Some(v("0.13.13-dev.10")));
        assert_eq!(next(d.path()).unwrap(), v("0.13.13-dev.11"));
    }

    #[test]
    fn stable_release_supersedes_its_dev_tags() {
        let d = repo();
        commit(d.path(), "a");
        git(d.path(), &["tag", "v1.2.4-dev.3"]);
        commit(d.path(), "b");
        git(d.path(), &["tag", "v1.2.4"]);
        assert_eq!(next(d.path()).unwrap(), v("1.2.5-dev.1"));
    }

    #[test]
    fn force_pushed_orphan_tag_still_counts() {
        // Reproduces the real failure: v0.13.12 on-branch, CI tags a later
        // commit v0.13.13-dev.1, then devel is rewritten so that commit is no
        // longer reachable. git describe from HEAD would report v0.13.12.
        let d = repo();
        commit(d.path(), "base");
        git(d.path(), &["tag", "-a", "v0.13.12", "-m", "rel"]);
        commit(
            d.path(),
            "chore: update LIBRA_VERSION to v0.13.13-dev.1 [skip ci]",
        );
        git(d.path(), &["tag", "-a", "v0.13.13-dev.1", "-m", "dev"]);
        git(d.path(), &["reset", "-q", "--hard", "HEAD~1"]);
        commit(d.path(), "rewritten 1");
        commit(d.path(), "rewritten 2");
        commit(d.path(), "rewritten 3");

        assert_eq!(next(d.path()).unwrap(), v("0.13.13-dev.2"));
    }
}
