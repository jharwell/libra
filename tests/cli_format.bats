#!/usr/bin/env bats
#
# BATS tests for `clibra format`.
#
# All flag-forwarding tests use --dry-run since format targets require
# a full LIBRA project with LIBRA_FORMAT=ON.
# Feature-disabled error message tests require a real configured build.
#

load test_helpers

setup() {
    setup_cli_test
}

# ==============================================================================
# Default preset and targets
# ==============================================================================

@test "FORMAT: defaults to 'format' preset when --preset not given" {
    assert_dry_run_contains "--preset format" format
}

@test "FORMAT: invokes cmake --build" {
    assert_dry_run_contains "cmake --build" format
}

@test "FORMAT: no --check runs both format-clang and format-cmake targets" {
    run_clibra --dry-run format
    assert_success
    assert_output --partial "--target format-clang"
    assert_output --partial "--target format-cmake"
}

@test "FORMAT: no --check does not run any format-check target" {
    run_clibra --dry-run format
    assert_success
    refute_output --partial "format-check"
}

# ==============================================================================
# Check mode (--check)
# ==============================================================================

@test "FORMAT: --check clang targets format-check-clang" {
    assert_dry_run_contains "--target format-check-clang" format --check clang
}

@test "FORMAT: --check cmake targets format-check-cmake" {
    assert_dry_run_contains "--target format-check-cmake" format --check cmake
}

@test "FORMAT: --check clang does not apply formatting" {
    run_clibra --dry-run format --check clang
    assert_success
    refute_output --partial "--target format-clang"
    refute_output --partial "--target format-cmake"
}

@test "FORMAT: invalid --check value causes failure" {
    run_clibra --dry-run format --check no_such_checker
    assert_failure
}

# ==============================================================================
# Flag forwarding
# ==============================================================================

@test "FORMAT: --preset flag is forwarded" {
    assert_dry_run_contains "--preset release" format --preset release
}

@test "FORMAT: --keep-going adds generator-appropriate flag" {
    # With Unix Makefiles (sample_cli base preset) --keep-going becomes --keep-going
    assert_dry_run_contains "--keep-going" format --keep-going --preset format --log trace
}

@test "FORMAT: --keep-going does not add Ninja-style -k0 for Unix Makefiles" {
    run_clibra --dry-run format --keep-going --preset format --log trace
    assert_success
    refute_output --partial "-k0"
}

@test "FORMAT: --reconfigure invokes configure step" {
    assert_dry_run_contains "cmake --preset" format --reconfigure --preset format
}

@test "FORMAT: --fresh passes --fresh to configure step" {
    assert_dry_run_contains "--fresh" format --fresh --preset format
}

@test "FORMAT: -D defines forwarded to configure step with --reconfigure" {
    assert_dry_run_contains "-DFOO=BAR" format --reconfigure -DFOO=BAR
}

# ==============================================================================
# Feature-disabled error message (real build required)
# ==============================================================================

@test "FORMAT: fails with clear error when LIBRA_FORMAT not enabled in preset" {
    skip_if_compiler_missing gnu c
    # debug preset does not set LIBRA_FORMAT, so it defaults to OFF
    run_clibra build --preset debug $CLI_CMAKE_DEFINES
    assert_success
    run_clibra format --preset debug
    assert_failure
    assert_output --partial "LIBRA_FORMAT"
}

@test "FORMAT: error message names the preset when LIBRA_FORMAT disabled" {
    skip_if_compiler_missing gnu c
    run_clibra build --preset debug $CLI_CMAKE_DEFINES
    assert_success
    run_clibra format --preset debug
    assert_failure
    assert_output --partial "debug"
}

@test "FORMAT: error message suggests fix when LIBRA_FORMAT disabled" {
    skip_if_compiler_missing gnu c
    run_clibra build --preset debug $CLI_CMAKE_DEFINES
    assert_success
    run_clibra format --preset debug
    assert_failure
    assert_output --partial "LIBRA_FORMAT=ON"
}

# ==============================================================================
# Failure
# ==============================================================================

@test "FORMAT: non-existent preset causes failure" {
    run_clibra format --preset no_such_preset_xyzzy
    assert_failure
}
