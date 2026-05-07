// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.
/*!
 * Brief one-line summary.
 *
 * Longer description if needed.
 */

// Imports

// Types

// Traits

// Implementation
fn git(args: &[&str]) -> Option<String> {
    std::process::Command::new("git")
        .args(args)
        .output()
        .ok()
        .filter(|o| o.status.success())
        .and_then(|o| String::from_utf8(o.stdout).ok())
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty())
}

fn exact_tag() -> Option<String> {
    git(&["describe", "--exact-match", "--tags"]).map(|t| t.trim_start_matches('v').to_string())
}

fn described_version() -> Option<String> {
    // git describe --tags --long format: v1.5.0-dev.2-5-gabcdef1
    //                                                 ^^^^^^^^^^^
    //                                                 appended by git
    //
    // Mirrors the untagged fallback in libra_extract_version():
    // strip the trailing -N-gSHA, then reattach as .untagged.N+gSHA.
    let raw = git(&["describe", "--tags", "--long"])?;

    // Split off the trailing -gSHA component first.
    let (without_sha, sha) = raw.rsplit_once("-g")?;

    // Split off the distance component.
    let (base_with_v, distance) = without_sha.rsplit_once('-')?;

    let base = base_with_v.trim_start_matches('v');
    let distance: u32 = distance.parse().ok()?;

    if distance == 0 {
        // Exactly on a tag -- exact_tag() should have caught this,
        // but handle cleanly just in case.
        Some(base.to_string())
    } else if base.contains('-') {
        // Prerelease base: 1.5.0-dev.3 -> 1.5.0-dev.3.untagged.5+gabcdef1
        Some(format!("{}.untagged.{}+g{}", base, distance, sha))
    } else {
        // Stable base: 1.5.0 -> 1.5.0-untagged.5+gabcdef1
        Some(format!("{}-untagged.{}+g{}", base, distance, sha))
    }
}

// Public API
fn main() {
    let exact = exact_tag();
    let described = described_version();

    eprintln!("build.rs: exact_tag={:?}", exact);
    eprintln!("build.rs: described_version={:?}", described);

    let version = exact.or(described).unwrap_or_else(|| "0.0.0".to_string());

    eprintln!("build.rs: final version={:?}", version);
    println!("cargo:rustc-env=LIBRA_VERSION={}", version);
    println!("cargo:rerun-if-changed=.git/HEAD");
    println!("cargo:rerun-if-changed=.git/refs");
}
