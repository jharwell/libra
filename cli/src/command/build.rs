// SPDX-License-Identifier: MIT
// Copyright 2026 John Harwell, All rights reserved.
/*!
 * Implementation of the build command.
 */


// Imports
use clap;

// Types
#[derive(clap::Parser, Debug)]
pub struct BuildArgs {
    /// Parallel job count.
    #[arg(short = 'j', long, default_value_t = utils::num_cpus())]
    pub jobs: u32,

    /// Build a specific CMake target.
    #[arg(short, long)]
    pub target: Option<String>,

    /// Pass --clean-first to cmake --build.
    #[arg(long)]
    pub clean: bool,

    /// Force the configure step even if the build directory exists.
    #[arg(short, long)]
    pub reconfigure: bool,

    /// Continue building after errors.
    #[arg(short = 'k', long)]
    pub keep_going: bool,

    /// Forward -DVAR=VALUE to the cmake configure step.
    #[arg(short = 'D', value_name = "VAR=VALUE")]
    pub defines: Vec<String>,
}

// Traits

// Implementation

// Public API
