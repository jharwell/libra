// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.

// ---------------------------------------------------------------------------
// Imports
// ---------------------------------------------------------------------------
use std::io::Write;

use anyhow::Context;
use log::debug;
use regex::Regex;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
#[derive(Debug)]
pub struct ResolvedVersion {
    /// Full version, including any prerelease and build metadata
    /// (`LIBRA_PROJECT_VERSION`).
    pub full: semver::Version,
    /// Numeric component only -- major.minor.patch, no prerelease
    /// (`LIBRA_PROJECT_VERSION_NUMERIC`).
    pub numeric: semver::Version,
    /// Prerelease component alone, e.g. `dev.3` or `rc.1`, empty if none
    /// (`LIBRA_PROJECT_VERSION_PRERELEASE`).
    pub prerelease: String,
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------
pub fn num_cpus() -> u32 {
    std::thread::available_parallelism()
        .map(|n| n.get() as u32)
        .unwrap_or(4)
}

/// Parse the `VERSION*=` lines emitted by the cmake script into a
/// [`ResolvedVersion`]. Split out from [`resolve_self`] so it can be unit-tested
/// without invoking cmake. Only for retrieving LIBRA's own version.
pub fn versioning_parse_cmake_output(stderr: &str) -> anyhow::Result<ResolvedVersion> {
    // Anchored so a substring like "MY_VERSION=" can't match the numeric line.
    let numeric_re = Regex::new(r"(?m)^VERSION_NUMERIC=(.*)$")?;
    let full_re = Regex::new(r"(?m)^VERSION=(.*)$")?;

    let full_str = full_re
        .captures(stderr)
        .map(|c| c[1].trim().to_owned())
        .context("cmake output missing VERSION= line")?;

    let numeric_str = numeric_re
        .captures(stderr)
        .map(|c| c[1].trim().to_owned())
        .context("cmake output missing VERSION_NUMERIC= line")?;

    let full = semver::Version::parse(&full_str)
        .with_context(|| format!("cmake VERSION was not valid semver: {full_str:?}"))?;
    let numeric = semver::Version::parse(&numeric_str)
        .with_context(|| format!("cmake VERSION_NUMERIC was not valid semver: {numeric_str:?}"))?;

    Ok(ResolvedVersion {
        full,
        numeric,
        prerelease: "".to_string(),
    })
}

/// Shell out to cmake to resolve LIBRA's current version via
/// `libra_extract_version()`.
pub fn versioning_resolve_self() -> anyhow::Result<ResolvedVersion> {
    let cwd = std::env::current_dir()?;
    let script = format!(
        r#"list(APPEND CMAKE_MODULE_PATH "{}/cmake")
include(libra/version)
libra_extract_version()
# Distinctive prefixes so we can pick our lines out of any STATUS/WARNING noise.
message("VERSION_NUMERIC=${{LIBRA_PROJECT_VERSION_NUMERIC}}")
message("VERSION=${{LIBRA_PROJECT_VERSION}}")"#,
        cwd.to_string_lossy()
    );

    let mut temp = tempfile::NamedTempFile::new()?;
    temp.disable_cleanup(true);
    write!(temp, "{}", script)?;

    let temp_path = temp.path().to_str().unwrap_or("/tmp/resolve.cmake");

    let output = std::process::Command::new("cmake")
        .args(["-P", temp_path])
        .output()?;
    debug!(
        "CMake output for self version extraction: stdout={},stderr={}",
        String::from_utf8_lossy(&output.stdout),
        String::from_utf8_lossy(&output.stderr)
    );
    if !output.status.success() {
        anyhow::bail!(
            "cmake version extraction failed: {}",
            String::from_utf8_lossy(&output.stderr).trim()
        );
    }

    // cmake message()s go to stderr, not stdout.
    let stderr = String::from_utf8_lossy(&output.stderr);
    versioning_parse_cmake_output(&stderr)
}
