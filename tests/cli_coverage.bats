#!/usr/bin/env bats
#
# BATS tests for `clibra coverage`.
#
# Flag-forwarding tests use --dry-run.
# Feature-disabled error message tests require a real configured build.
#
# Note: --html and --check are independent flags; at least one must be given
# or the command fails with "Failed to run any coverage targets".
#

load test_helpers

setup() {
    setup_cli_test
}

# ==============================================================================
# Default preset
# ==============================================================================

@test "COVERAGE: defaults to 'coverage' preset when --preset not given" {
    assert_dry_run_contains "--preset coverage" coverage --html
}

@test "COVERAGE: --preset flag is forwarded" {
    assert_dry_run_contains "--preset release" coverage --preset release --html
}

# ==============================================================================
# Flag forwarding (--dry-run, fast)
# ==============================================================================

@test "COVERAGE: --html invokes cmake --build" {
    assert_dry_run_contains "cmake --build" coverage --html
}

@test "COVERAGE: --html targets gcovr-report" {
    assert_dry_run_contains "gcovr-report" coverage --html
}

@test "COVERAGE: --check targets gcovr-check" {
    assert_dry_run_contains "gcovr-check" coverage --check
}

@test "COVERAGE: --html and --check together invoke cmake --build twice" {
    run_clibra --dry-run coverage --html --check
    assert_clibra_success
    # Both report and check targets should appear in output
    assert_output_contains "gcovr-report"
    assert_output_contains "gcovr-check"
}

@test "COVERAGE: --open flag is accepted without error in dry-run" {
    run_clibra --dry-run coverage --html --open
    assert_clibra_success
}

@test "COVERAGE: --reconfigure invokes configure step" {
    assert_dry_run_contains "cmake --preset" coverage --reconfigure --html
}

@test "COVERAGE: -D defines forwarded to configure step with --reconfigure" {
    assert_dry_run_contains "-DFOO=BAR" coverage --reconfigure -DFOO=BAR --html
}

@test "COVERAGE: neither --html nor --check fails with actionable error" {
    run_clibra --dry-run coverage
    assert_clibra_failure
    assert_output_contains "No coverage target specified"
}

# ==============================================================================
# Feature-disabled error message (real build required)
# ==============================================================================

@test "COVERAGE: fails with clear error when LIBRA_CODE_COV not enabled in preset" {
    skip_if_compiler_missing gnu c
    run_clibra build --preset debug $CLI_CMAKE_DEFINES
    assert_clibra_success
    run_clibra coverage --preset debug --html
    assert_clibra_failure
    assert_output_contains "LIBRA_CODE_COV"
}

@test "COVERAGE: error message names the preset when LIBRA_CODE_COV disabled" {
    skip_if_compiler_missing gnu c
    run_clibra build --preset debug $CLI_CMAKE_DEFINES
    assert_clibra_success
    run_clibra coverage --preset debug --html
    assert_clibra_failure
    assert_output_contains "debug"
}

@test "COVERAGE: error message suggests fix when LIBRA_CODE_COV disabled" {
    skip_if_compiler_missing gnu c
    run_clibra build --preset debug $CLI_CMAKE_DEFINES
    assert_clibra_success
    run_clibra coverage --preset debug --html
    assert_clibra_failure
    assert_output_contains "LIBRA_CODE_COV=ON"
}

# ==============================================================================
# Failure
# ==============================================================================

@test "COVERAGE: non-existent preset causes failure" {
    run_clibra coverage --preset no_such_preset_xyzzy --html
    assert_clibra_failure
}
