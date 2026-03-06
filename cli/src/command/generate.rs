// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.
/*!
 * Implementation of the info command.
 */

// Imports
use anyhow;
use clap;
use clap_mangen;

use crate::cli::Cli;

// Types
#[derive(clap::Args, Debug)]
pub struct GenerateArgs {
    #[arg(long, value_enum)]
    pub shell: Option<clap_complete::Shell>,

    #[arg(long)]
    pub manpage: bool,
}

// Traits

// Implementation

// Public API
pub fn run(args: GenerateArgs) -> anyhow::Result<()> {
    if let Some(shell) = args.shell {
        clap_complete::generate(
            shell,
            &mut <Cli as clap::CommandFactory>::command(),
            "clibra",
            &mut std::io::stdout(),
        );
    }
    // manpage
    if args.manpage {
        let man = clap_mangen::Man::new(<Cli as clap::CommandFactory>::command());
        let mut buf = Vec::new();
        man.render(&mut buf)?;
        std::io::Write::write_all(&mut std::io::stdout(), &buf)?;
    }
    Ok(())
}
