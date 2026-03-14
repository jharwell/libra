#!/usr/bin/env bats
#
# BATS tests for `clibra clean`.
#
# Default clean uses --dry-run for flag verification.
# --all and filesystem tests require a real prior build.
#

load test_helpers

setup() {
    setup_cli_test
}

# ==============================================================================
# Flag forwarding (--dry-run, fast)
# ==============================================================================

@test "CLEAN: invokes cmake --build --target clean by default" {
    assert_dry_run_contains "--target clean" --preset debug clean
}

@test "CLEAN: passes --preset to cmake --build" {
    assert_dry_run_contains "--preset debug" --preset debug clean
}

@test "CLEAN: --preset flag is forwarded" {
    assert_dry_run_contains "--preset release" clean --preset release
}

@test "CLEAN: does not invoke configure step" {
    run_clibra --dry-run --preset debug clean
    assert_clibra_success
    assert_output_not_contains "cmake --preset"
}

# ==============================================================================
# --all (requires real build)
# ==============================================================================

@test "CLEAN: --all removes the build directory" {
    skip_if_compiler_missing gnu c
    run_clibra build --preset debug $CLI_CMAKE_DEFINES
    assert_clibra_success
    assert_build_dir_exists "debug"

    run_clibra clean --all --preset debug
    assert_clibra_success
    assert_build_dir_absent "debug"
}

@test "CLEAN: default clean does not remove the build directory" {
    skip_if_compiler_missing gnu c
    run_clibra build --preset debug $CLI_CMAKE_DEFINES
    assert_clibra_success

    run_clibra clean --preset debug
    assert_clibra_success
    assert_build_dir_exists "debug"
}

@test "CLEAN: --all on non-existent build directory fails gracefully" {
    run_clibra clean --all --preset debug
    assert_clibra_failure
}

# ==============================================================================
# Failure
# ==============================================================================

@test "CLEAN: non-existent preset causes failure" {
    run_clibra clean --preset no_such_preset_xyzzy
    assert_clibra_failure
}
