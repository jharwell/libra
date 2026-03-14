#!/usr/bin/env bats
#
# BATS tests for `clibra analyze`.
#
# All flag-forwarding tests use --dry-run since analysis targets require
# a full LIBRA project with LIBRA_ANALYSIS=ON.
# Feature-disabled error message tests require a real configured build.
#

load test_helpers

setup() {
    setup_cli_test
}

# ==============================================================================
# Default preset and target
# ==============================================================================

@test "ANALYZE: defaults to 'analyze' preset when --preset not given" {
    assert_dry_run_contains "--preset analyze" analyze
}

@test "ANALYZE: invokes cmake --build" {
    assert_dry_run_contains "cmake --build" analyze
}

@test "ANALYZE: no subcommand targets the 'analyze' target" {
    assert_dry_run_contains "--target analyze" analyze
}

# ==============================================================================
# Tool subcommands
# ==============================================================================

@test "ANALYZE: clang-tidy subcommand targets analyze-clang-tidy" {
    assert_dry_run_contains "--target analyze-clang-tidy" analyze clang-tidy
}

@test "ANALYZE: clang-check subcommand targets analyze-clang-check" {
    assert_dry_run_contains "--target analyze-clang-check" analyze clang-check
}

@test "ANALYZE: cppcheck subcommand targets analyze-cppcheck" {
    assert_dry_run_contains "--target analyze-cppcheck" analyze cppcheck
}

@test "ANALYZE: clang-format subcommand targets analyze-clang-format" {
    assert_dry_run_contains "--target analyze-clang-format" analyze clang-format
}

@test "ANALYZE: cmake-format subcommand targets analyze-cmake-format" {
    assert_dry_run_contains "--target analyze-cmake-format" analyze cmake-format
}

# ==============================================================================
# Flag forwarding
# ==============================================================================

@test "ANALYZE: --preset flag is forwarded" {
    assert_dry_run_contains "--preset release" analyze --preset release
}

@test "ANALYZE: --jobs is forwarded as --parallel" {
    assert_dry_run_contains "--parallel 1" analyze --jobs=1
}

@test "ANALYZE: --keep-going is forwarded" {
    assert_dry_run_contains "-k" analyze --keep-going
}

@test "ANALYZE: --reconfigure invokes configure step" {
    assert_dry_run_contains "cmake --preset" analyze --reconfigure --preset analyze
}

@test "ANALYZE: -D defines forwarded to configure step with --reconfigure" {
    assert_dry_run_contains "-DFOO=BAR" analyze --reconfigure -DFOO=BAR
}

# ==============================================================================
# Feature-disabled error message (real build required)
# ==============================================================================

@test "ANALYZE: fails with clear error when LIBRA_ANALYSIS not enabled in preset" {
    skip_if_compiler_missing gnu c
    # Build with debug preset which has LIBRA_ANALYSIS=OFF
    run_clibra build --preset debug $CLI_CMAKE_DEFINES
    assert_clibra_success
    run_clibra analyze --preset debug
    assert_clibra_failure
    assert_output_contains "LIBRA_ANALYSIS"
}

@test "ANALYZE: error message names the preset when LIBRA_ANALYSIS disabled" {
    skip_if_compiler_missing gnu c
    run_clibra build --preset debug $CLI_CMAKE_DEFINES
    assert_clibra_success
    run_clibra analyze --preset debug
    assert_clibra_failure
    assert_output_contains "debug"
}

@test "ANALYZE: error message suggests fix when LIBRA_ANALYSIS disabled" {
    skip_if_compiler_missing gnu c
    run_clibra build --preset debug $CLI_CMAKE_DEFINES
    assert_clibra_success
    run_clibra analyze --preset debug
    assert_clibra_failure
    assert_output_contains "LIBRA_ANALYSIS=ON"
}

# ==============================================================================
# Failure
# ==============================================================================

@test "ANALYZE: non-existent preset causes failure" {
    run_clibra analyze --preset no_such_preset_xyzzy
    assert_clibra_failure
}
