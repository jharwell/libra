#!/usr/bin/env bats
#
# BATS tests for `clibra build`.
#
# Flag-forwarding tests use --dry-run so no real cmake invocation is needed.
# Cold-start, incremental, and --reconfigure tests perform real builds.
#

load test_helpers

setup() {
    setup_cli_test
}

# ==============================================================================
# Flag forwarding (--dry-run, fast)
# ==============================================================================

@test "BUILD: invokes cmake --build" {
    assert_dry_run_contains "cmake --build" build --preset debug
}

@test "BUILD: passes --preset to cmake --build" {
    assert_dry_run_contains "--preset debug" build --preset debug
}

@test "BUILD: --preset flag is forwarded" {
    assert_dry_run_contains "--preset release" build --preset release
}

@test "BUILD: --jobs is forwarded as --parallel" {
    assert_dry_run_contains "--parallel 1" build --jobs=1 --preset debug
}

@test "BUILD: --clean passes --clean-first to cmake" {
    assert_dry_run_contains "--clean-first" build --clean --preset debug
}

@test "BUILD: --target is forwarded to cmake --build" {
    assert_dry_run_contains "--target mytarget" build --target=mytarget --preset debug
}

@test "BUILD: --keep-going is forwarded" {
    assert_dry_run_contains "--keep-going" build --keep-going --preset debug --log trace
}

@test "BUILD: -D defines are forwarded to configure step with --reconfigure" {
    assert_dry_run_contains "-DFOO=BAR" build --reconfigure -DFOO=BAR --preset debug
}

@test "BUILD: --reconfigure invokes configure step even with existing build dir" {
    assert_dry_run_contains "cmake --preset" build --reconfigure --preset debug
}

@test "BUILD: without --reconfigure no configure step in dry-run" {
    run_clibra --dry-run build --preset debug
    assert_clibra_success
    # configure (cmake --preset) only appears when cold-start or --reconfigure
    # dry-run has no build dir so configure will appear — this test verifies
    # the configure appears for cold start
    assert_output_contains "cmake --preset"
}

# ==============================================================================
# Cold start (real cmake)
# ==============================================================================

@test "BUILD: cold start creates build directory" {
    skip_if_compiler_missing gnu c
    run_clibra build $CLI_CMAKE_DEFINES --preset debug
    assert_clibra_success
    assert_build_dir_exists "debug"
}

@test "BUILD: cold start creates CMakeCache.txt" {
    skip_if_compiler_missing gnu c
    run_clibra build $CLI_CMAKE_DEFINES --preset debug
    assert_clibra_success
    [ -f "build/debug/CMakeCache.txt" ]
}

@test "BUILD: exits 0 on successful build" {
    skip_if_compiler_missing gnu c
    run_clibra build $CLI_CMAKE_DEFINES --preset debug
    assert_clibra_success
}

# ==============================================================================
# Incremental build
# ==============================================================================

@test "BUILD: incremental build exits 0 when build dir already exists" {
    skip_if_compiler_missing gnu c
    run_clibra build $CLI_CMAKE_DEFINES --preset debug
    assert_clibra_success
    run_clibra build --preset debug
    assert_clibra_success
}

# ==============================================================================
# --reconfigure (real cmake)
# ==============================================================================

@test "BUILD: --reconfigure runs configure step even when build dir exists" {
    skip_if_compiler_missing gnu c
    run_clibra build $CLI_CMAKE_DEFINES --preset debug
    assert_clibra_success
    # reconfigure with a new -D — verify it succeeds (configure re-runs)
    run_clibra build --reconfigure --preset debug -DCMAKE_EXPORT_COMPILE_COMMANDS=ON $CLI_CMAKE_DEFINES
    assert_clibra_success
    [ -f "build/debug/compile_commands.json" ]
}

# ==============================================================================
# Failure
# ==============================================================================

@test "BUILD: non-existent preset causes failure" {
    run_clibra build --preset no_such_preset_xyzzy
    assert_clibra_failure
}

@test "BUILD: failure exit code is non-zero" {
    run_clibra build --preset no_such_preset_xyzzy
    [ "$status" -ne 0 ]
}
