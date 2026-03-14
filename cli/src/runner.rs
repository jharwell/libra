// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.
/*!
 * Brief one-line summary.
 *
 * Longer description if needed.
 */

// Imports
use log::debug;

// Types
#[derive(Clone)]
pub struct Context {
    pub preset: Option<String>,
    pub dry_run: bool,
}

// Traits

// Implementation

// Public API
impl Context {
    pub fn run(&self, cmd: &mut std::process::Command) -> anyhow::Result<()> {
        if self.dry_run {
            eprintln!("+ {}", format_cmd(cmd));
            return Ok(());
        } else {
            debug!("+ {}", format_cmd(cmd));
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

    pub fn run_capture(&self, cmd: &mut std::process::Command) -> anyhow::Result<(String, String)> {
        if self.dry_run {
            eprintln!("+ {}", format_cmd(cmd));
            return Ok((String::new(), String::new()));
        } else {
            debug!("+ {}", format_cmd(cmd));
        }
        let output = cmd.output()?;
        if !output.status.success() {
            anyhow::bail!(
                "command failed with exit code {}: {}",
                output.status.code().unwrap_or(-1),
                format_cmd(cmd)
            );
        }

        Ok((
            strip_ansi_escapes::strip_str(String::from_utf8_lossy(&output.stdout).into_owned()),
            strip_ansi_escapes::strip_str(String::from_utf8_lossy(&output.stderr).into_owned()),
        ))
    }
}
fn format_cmd(cmd: &std::process::Command) -> String {
    let prog = cmd.get_program().to_string_lossy();
    let args: Vec<_> = cmd
        .get_args()
        .map(|a| a.to_string_lossy().into_owned())
        .collect();
    if args.is_empty() {
        prog.into_owned()
    } else {
        format!("{prog} {}", args.join(" "))
    }
}
