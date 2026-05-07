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

// Public API

fn main() {
    let dir = std::env::var("CARGO_MANIFEST_DIR").unwrap();
    let version_file = std::path::Path::new(&dir).join("cmake/libra/self.cmake");

    eprintln!("path: {:?}", version_file);

    let cmake = std::fs::read_to_string(&version_file).expect("cmake/libra/self.cmake not found");

    let version = cmake
        .lines()
        .find(|l| l.contains("set(LIBRA_VERSION "))
        .and_then(|l| l.split_whitespace().nth(1))
        .map(|s| s.trim_end_matches(')').to_string())
        .expect("LIBRA_VERSION not found");

    println!("cargo:rustc-env=CARGO_PKG_VERSION={}", version);
    println!("cargo:rerun-if-changed=cmake/libra/self.cmake");
}
