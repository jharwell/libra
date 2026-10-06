#!/usr/bin/env bats
#
# BATS tests for `clibra info`.
#
# info requires a configured build directory so all tests pre-build in setup().
# Output content is checked structurally, not formatting details.
#

load test_helpers

setup() {
    setup_cli_test
    skip_if_compiler_missing gnu c
    "$CLIBRA_BIN" build --preset debug $CLI_CMAKE_DEFINES
}

# ==============================================================================
# Output sections — default (--all)
# ==============================================================================

@test "INFO: output contains 'Build configuration' section" {
    run_clibra info --preset debug
    assert_success
    assert_output --partial "Build configuration"
}

@test "INFO: output contains CMAKE_BUILD_TYPE" {
    run_clibra info --preset debug --log=trace
    assert_success
    assert_output --partial "CMAKE_BUILD_TYPE"
}

@test "INFO: output contains correct build type for preset" {
    run_clibra info --preset debug
    assert_success
    assert_output --partial "Debug"
}

@test "INFO: output contains generator name" {
    run_clibra info --preset debug
    assert_success
    assert_output --partial "Generator"
}

@test "INFO: output contains build directory path" {
    run_clibra info --preset debug
    assert_success
    assert_output --partial "Build dir"
}

@test "INFO: build directory path contains preset name" {
    run_clibra info --preset debug
    assert_success
    assert_output --partial "debug"
}

@test "INFO: output contains LIBRA feature flags section" {
    run_clibra info --preset debug
    assert_success
    assert_output --partial "LIBRA feature flags"
}

@test "INFO: output contains 'Available LIBRA targets' section" {
    run_clibra info --preset debug
    assert_success
    assert_output --partial "Available LIBRA targets"
}

# ==============================================================================
# --build flag
# ==============================================================================

@test "INFO: --build shows build configuration section" {
    run_clibra info --preset debug --build
    assert_success
    assert_output --partial "Build configuration"
}

@test "INFO: --build shows LIBRA feature flags section" {
    run_clibra info --preset debug --build
    assert_success
    assert_output --partial "LIBRA feature flags"
}

@test "INFO: --build does not show targets section" {
    run_clibra info --preset debug --build
    assert_success
    refute_output --partial "Available LIBRA targets"
}

# ==============================================================================
# --targets flag
# ==============================================================================

@test "INFO: --targets shows targets section" {
    run_clibra info --preset debug --targets
    assert_success
    assert_output --partial "Available LIBRA targets"
}

@test "INFO: --targets shows tests group" {
    run_clibra info --preset debug --targets
    assert_success
    assert_output --partial "tests"
}

@test "INFO: --targets shows analysis group" {
    run_clibra info --preset debug --targets
    assert_success
    assert_output --partial "analysis"
}

@test "INFO: --targets does not show build configuration section" {
    run_clibra info --preset debug --targets
    assert_success
    refute_output --partial "CMAKE_BUILD_TYPE"
}

@test "INFO: --targets does not show LIBRA feature flags section" {
    run_clibra info --preset debug --targets
    assert_success
    refute_output --partial "LIBRA feature flags"
}

# ==============================================================================
# Failure
# ==============================================================================

@test "INFO: fails when build directory does not exist" {
    run_clibra info --preset release
    assert_failure
    assert_output --partial "Build directory"
}

@test "INFO: fails when no preset files exist" {
    rm -f CMakePresets.json CMakeUserPresets.json
    run_clibra info --preset debug
    assert_failure
}
