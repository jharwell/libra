// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.
//!
//! Brief one-line summary.
//!
//! Longer description if needed.

// Imports
use clap::CommandFactory;
use clap_complete::{generate_to, Shell};
use clap_mangen::Man;
use std::{fs, path};

include!("src/cli.rs");   // re-use the same struct without a separate crate

// Public API
fn main() -> std::io::Result<()> {
    let out = path::PathBuf::from(std::env::var_os("OUT_DIR").unwrap());

    let mut cmd = Cli::command();

    // Manpage
    let man = Man::new(cmd.clone());
    let mut buf = Vec::new();
    man.render(&mut buf)?;
    fs::write(out.join("libra.1"), buf)?;

    // Shell completions
    for shell in [Shell::Bash, Shell::Zsh, Shell::Fish] {
        generate_to(shell, &mut cmd, "libra", &out)?;
    }

    Ok(())
}
