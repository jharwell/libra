// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.
/*!
 * Implementation of the info command.
 */

// Imports
use anyhow;
use clap;
use clap_mangen;
use clap_markdown;

use crate::cli::Cli;

// Types
#[derive(clap::Args, Debug)]
pub struct GenerateArgs {
    #[arg(long, value_enum)]
    pub shell: Option<clap_complete::Shell>,

    #[arg(long)]
    pub manpage: bool,

    #[arg(long)]
    pub markdown: bool,

    #[arg(long, requires = "markdown")]
    pub subcommand: Option<String>,
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

    if args.markdown {
        use clap::CommandFactory;
        let cmd = Cli::command();

        match &args.subcommand {
            None => {
                // Full reference
                clap_markdown::help_markdown_command(&cmd);
            }
            Some(name) => {
                let mut cmd = Cli::command();
                cmd.build(); // ← forces clap to populate all subcommand help text
                let sub = cmd
                    .get_subcommands()
                    .find(|s| s.get_name() == name.as_str())
                    .ok_or_else(|| anyhow::anyhow!("unknown subcommand: {}", name))?;
                eprintln!("name: {}", sub.get_name());
                eprintln!("about: {:?}", sub.get_about());
                eprintln!("args: {:?}", sub.get_arguments().count());
                eprintln!("subcommands: {:?}", sub.get_subcommands().count());

                print!("{}", clap_markdown::help_markdown_command(sub));
            }
        }
    }
    Ok(())
}
