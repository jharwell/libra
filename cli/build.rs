// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.
/*!
 * Internal build-time machinery.
 */

// Imports
include!("src/utils.rs");

// ---------------------------------------------------------------------------
// Private API
// ---------------------------------------------------------------------------

// Public API
fn main() {
    let from_git = versioning_resolve_self();

    let resolved = from_git.ok().unwrap_or_else(|| {
        // Fallback: parse CARGO_PKG_VERSION, or 0.0.0 if that fails/absent.
        let v = std::env::var("CARGO_PKG_VERSION")
            .ok()
            .and_then(|s| semver::Version::parse(&s).ok())
            .unwrap_or_else(|| semver::Version::new(0, 0, 0));

        ResolvedVersion {
            numeric: semver::Version::new(v.major, v.minor, v.patch),
            prerelease: v.pre.as_str().to_owned(),
            full: v,
        }
    });

    eprintln!("build.rs: full version={}", resolved.full);
    eprintln!("build.rs: numeric version={}", resolved.numeric);

    eprintln!("build.rs: resolved version={}", resolved.full);
    println!("cargo:rustc-env=LIBRA_VERSION={}", resolved.full);
    println!("cargo:rerun-if-changed=.git/HEAD");
    println!("cargo:rerun-if-changed=.git/refs");
    println!("cargo:rerun-if-changed=.git/packed_refs");
}
