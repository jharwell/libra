#!/usr/bin/env bats
#
# BATS tests for `clibra ci`.
#
# cmake --workflow preferred path and fallback sequencing verified with --dry-run.
#

load test_helpers

setup() {
    setup_cli_test
}

# ==============================================================================
# Default preset
# ==============================================================================

@test "CI: defaults to 'ci' preset when --preset not given" {
    assert_dry_run_contains "--preset ci" ci
}

@test "CI: --preset flag overrides the default" {
    assert_dry_run_contains "--preset release" ci --preset release
}

# ==============================================================================
# cmake --workflow preferred path
# ==============================================================================

@test "CI: uses cmake --workflow when workflow preset exists for resolved preset" {
    # sample_cli/CMakePresets.json ships a 'ci' workflow preset
    assert_dry_run_contains "--workflow" ci
}

@test "CI: cmake --workflow invocation has correct argument order" {
    # Must be: cmake --workflow --preset ci  (not cmake --preset ci --workflow ci)
    assert_dry_run_contains "--workflow --preset ci" ci
}

@test "CI: passes --preset to cmake --workflow" {
    assert_dry_run_contains "--preset ci" ci
}

@test "CI: does not invoke cmake --build when workflow preset found" {
    run_clibra --dry-run ci
    assert_clibra_success
    # workflow path delegates entirely to cmake --workflow; no separate build step
    assert_output_not_contains "cmake --build"
}

# ==============================================================================
# Fallback sequencing
# ==============================================================================

@test "CI: falls back to individual steps when no workflow preset exists for preset" {
    run_clibra --dry-run ci --preset release
    assert_clibra_success
    assert_output_contains "cmake --build"
}

@test "CI: fallback emits warning mentioning workflow preset" {
    run_clibra --dry-run ci --preset release
    assert_clibra_success
    # Warning should mention workflow and suggest adding one
    assert_output_contains "workflow"
    assert_output_not_contains "--workflow --preset"
}

@test "CI: fallback invokes ctest with --preset" {
    assert_dry_run_contains "ctest --preset" ci --preset release
}

# ==============================================================================
# --reconfigure
# ==============================================================================

@test "CI: --reconfigure invokes configure step in fallback path" {
    assert_dry_run_contains "cmake --preset" ci --reconfigure --preset release
}

# ==============================================================================
# Failure
# ==============================================================================

@test "CI: non-existent preset causes failure" {
    run_clibra ci --preset no_such_preset_xyzzy
    assert_clibra_failure
}
