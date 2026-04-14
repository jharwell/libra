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
    assert_dry_run_contains "--workflow --preset ci" ci
}

@test "CI: passes --preset to cmake --workflow" {
    assert_dry_run_contains "--preset ci" ci
}

@test "CI: does not invoke cmake --build when workflow preset found" {
    run_clibra --dry-run ci
    assert_clibra_success
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
    assert_output_contains "workflow"
    assert_output_not_contains "--workflow --preset"
}

@test "CI: fallback invokes ctest with --preset" {
    assert_dry_run_contains "ctest --preset" ci --preset release
}

@test "CI: fallback invokes cmake --build before ctest" {
    run_clibra --dry-run ci --preset release
    assert_clibra_success
    # Both build and test must appear; output order matters
    local build_pos test_pos
    build_pos=$(echo "$output" | grep -n "cmake --build" | head -1 | cut -d: -f1)
    test_pos=$(echo "$output" | grep -n "ctest" | head -1 | cut -d: -f1)
    [ -n "$build_pos" ] && [ -n "$test_pos" ] && [ "$build_pos" -lt "$test_pos" ]
}

# ==============================================================================
# --reconfigure and --fresh in fallback path
# ==============================================================================

@test "CI: --reconfigure invokes configure step in fallback path" {
    assert_dry_run_contains "cmake --preset" ci --reconfigure --preset release
}

@test "CI: --fresh invokes configure step in fallback path" {
    # --fresh alone (without --reconfigure) must still trigger the configure step
    assert_dry_run_contains "cmake --preset" ci --fresh --preset release
}

@test "CI: --fresh passes --fresh to cmake configure in fallback path" {
    assert_dry_run_contains "--fresh" ci --fresh --preset release
}

# ==============================================================================
# Feature gate (real build required)
# ==============================================================================

@test "CI: fallback fails with error when LIBRA_TESTS not enabled in preset" {
    skip_if_compiler_missing gnu c
    # 'release' preset has neither LIBRA_TESTS nor LIBRA_CODE_COV
    run_clibra build --preset release $CLI_CMAKE_DEFINES
    assert_clibra_success
    run_clibra ci --preset release
    assert_clibra_failure
    assert_output_contains "LIBRA"
}

@test "CI: fallback fails with error when LIBRA_CODE_COV not enabled in preset" {
    skip_if_compiler_missing gnu c
    run_clibra build --preset release $CLI_CMAKE_DEFINES
    assert_clibra_success
    run_clibra ci --preset release
    assert_clibra_failure
    assert_output_contains "CODE_COV"
}

# ==============================================================================
# Failure
# ==============================================================================

@test "CI: non-existent preset causes failure" {
    run_clibra ci --preset no_such_preset_xyzzy
    assert_clibra_failure
}
