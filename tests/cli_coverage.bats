#!/usr/bin/env bats
#
# BATS tests for `clibra coverage`.
#
# Flag-forwarding tests use --dry-run.
# Feature-disabled error message tests require a real configured build.
#

load test_helpers

setup() {
    setup_cli_test
}

# ==============================================================================
# Default preset
# ==============================================================================

@test "COVERAGE: defaults to 'coverage' preset when --preset not given" {
    assert_dry_run_contains "--preset coverage" coverage
}

@test "COVERAGE: --preset flag is forwarded" {
    assert_dry_run_contains "--preset release" coverage --preset release
}

# ==============================================================================
# Flag forwarding (--dry-run, fast)
# ==============================================================================

@test "COVERAGE: invokes cmake --build" {
    assert_dry_run_contains "cmake --build" coverage
}

@test "COVERAGE: --html targets a coverage report target" {
    assert_dry_run_contains "gcovr-report" coverage
}

@test "COVERAGE: --check targets gcovr-check" {
    assert_dry_run_contains "gcovr-check" coverage --check
}

@test "COVERAGE: --open flag is accepted without error" {
    run_clibra --dry-run coverage --open
    assert_clibra_success
}

@test "COVERAGE: --reconfigure invokes configure step" {
    assert_dry_run_contains "cmake --preset" coverage --reconfigure
}

@test "COVERAGE: -D defines forwarded to configure step with --reconfigure" {
    assert_dry_run_contains "-DFOO=BAR" coverage --reconfigure -DFOO=BAR
}

# ==============================================================================
# Feature-disabled error message (real build required)
# ==============================================================================

@test "COVERAGE: fails with clear error when LIBRA_CODE_COV not enabled in preset" {
    skip_if_compiler_missing gnu c
    run_clibra build --preset debug $CLI_CMAKE_DEFINES
    assert_clibra_success
    run_clibra coverage --preset debug
    assert_clibra_failure
    assert_output_contains "LIBRA_CODE_COV"
}

@test "COVERAGE: error message names the preset when LIBRA_CODE_COV disabled" {
    skip_if_compiler_missing gnu c
    run_clibra build --preset debug $CLI_CMAKE_DEFINES
    assert_clibra_success
    run_clibra coverage --preset debug
    assert_clibra_failure
    assert_output_contains "debug"
}

@test "COVERAGE: error message suggests fix when LIBRA_CODE_COV disabled" {
    skip_if_compiler_missing gnu c
    run_clibra build --preset debug $CLI_CMAKE_DEFINES
    assert_clibra_success
    run_clibra coverage --preset debug
    assert_clibra_failure
    assert_output_contains "LIBRA_CODE_COV=ON"
}

# ==============================================================================
# Failure
# ==============================================================================

@test "COVERAGE: non-existent preset causes failure" {
    run_clibra coverage --preset no_such_preset_xyzzy
    assert_clibra_failure
}
