// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.
/*!
 * Brief one-line summary.
 *
 * Longer description if needed.
 */


// Imports
use anyhow;
use std::process;
use crate::cli;

// Types
pub struct Context {
    pub preset:  Option<String>,
    pub verbose: bool,
    pub quiet:   bool,
    pub dry_run: bool,
}

// Traits

// Implementation

// Public API
impl Context {
    pub fn run(&self, cmd: &mut std::process::Command) -> anyhow::Result<()> {
        if self.verbose || self.dry_run {
            eprintln!("+ {}", format_cmd(cmd));
        }
        if self.dry_run {
            return Ok(());
        }
        let status = cmd.status()?;
        if !status.success() {
            anyhow::bail!(
                "command failed with exit code {}: {}",
                status.code().unwrap_or(-1),
                format_cmd(cmd)
            );
        }
        Ok(())
    }
}

fn format_cmd(cmd: &crate::cli::Command) -> String {
    let prog = cmd.get_program().to_string_lossy();
    let args: Vec<_> = cmd.get_args()
        .map(|a| a.to_string_lossy().into_owned())
        .collect();
    if args.is_empty() {
        prog.into_owned()
    } else {
        format!("{prog} {}", args.join(" "))
    }
}
