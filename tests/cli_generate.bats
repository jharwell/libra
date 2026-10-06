#!/usr/bin/env bats
#
# BATS tests for `clibra generate`.
#
# generate is a hidden subcommand that emits shell completions, a manpage,
# or markdown docs.  It does not need a project root or cmake.
#

load test_helpers

setup() {
    setup_cli_test
}

# ==============================================================================
# Shell completions
# ==============================================================================

@test "GENERATE: --shell=bash exits 0" {
    run_clibra generate --shell=bash
    assert_success
}

@test "GENERATE: --shell=bash produces output" {
    run_clibra generate --shell=bash
    assert_success
    assert_output
}

@test "GENERATE: --shell=bash output contains clibra" {
    run_clibra generate --shell=bash
    assert_success
    assert_output --partial "clibra"
}

@test "GENERATE: --shell=zsh exits 0" {
    run_clibra generate --shell=zsh
    assert_success
}

@test "GENERATE: --shell=fish exits 0" {
    run_clibra generate --shell=fish
    assert_success
}

# ==============================================================================
# Manpage
# ==============================================================================

@test "GENERATE: --manpage exits 0" {
    run_clibra generate --manpage
    assert_success
}

@test "GENERATE: --manpage output contains clibra name" {
    run_clibra generate --manpage
    assert_success
    assert_output --partial "clibra"
}

@test "GENERATE: --manpage output looks like troff format" {
    run_clibra generate --manpage
    assert_success
    # roff macros start with .TH or similar
    assert_output --partial ".TH"
}

# ==============================================================================
# Markdown
# ==============================================================================

@test "GENERATE: --markdown exits 0" {
    run_clibra generate --markdown
    assert_success
}

@test "GENERATE: --markdown --subcommand=build exits 0" {
    run_clibra generate --markdown --subcommand=build
    assert_success
}

@test "GENERATE: --markdown --subcommand=build output mentions build" {
    run_clibra generate --markdown --subcommand=build
    assert_success
    assert_output --partial "build"
}

@test "GENERATE: --markdown --subcommand with unknown name fails" {
    run_clibra generate --markdown --subcommand=no_such_subcommand_xyzzy
    assert_failure
    assert_output --partial "unknown subcommand"
}

@test "GENERATE: --subcommand requires --markdown" {
    # clap enforces requires = "markdown" on --subcommand
    run_clibra generate --subcommand=build
    assert_failure
}

# ==============================================================================
# No arguments
# ==============================================================================

@test "GENERATE: no arguments exits 0 (no-op)" {
    run_clibra generate
    assert_success
}

@test "GENERATE: works outside a project root" {
    cd /tmp
    run_clibra generate --shell=bash
    assert_success
}
