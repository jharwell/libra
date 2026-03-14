#!/usr/bin/env bats
#
# BATS tests for `clibra test`.
#
# Label mapping and flag forwarding use --dry-run.
# Cold-start test performs a real build against sample_cli.
#

load test_helpers

setup() {
    setup_cli_test
}

# ==============================================================================
# Flag forwarding (--dry-run, fast)
# ==============================================================================

@test "TEST: invokes ctest" {
    assert_dry_run_contains "ctest" test --preset debug
}

@test "TEST: passes --preset to ctest" {
    assert_dry_run_contains "--preset debug" test --preset debug
}

@test "TEST: --preset flag is forwarded to ctest" {
    assert_dry_run_contains "--preset release" test --preset release
}

@test "TEST: --parallel is forwarded to ctest" {
    assert_dry_run_contains "--parallel 2" test --parallel=2 --preset debug
}

@test "TEST: --stop-on-failure is forwarded to ctest" {
    assert_dry_run_contains "--stop-on-failure" test --stop-on-failure --preset debug
}

@test "TEST: --filter is forwarded as --tests-regex" {
    assert_dry_run_contains "--tests-regex mytest" test --filter=mytest --preset debug
}

@test "TEST: --rerun-failed is forwarded to ctest" {
    assert_dry_run_contains "--rerun-failed" test --rerun-failed --preset debug
}

# ==============================================================================
# ctest label mapping
# ==============================================================================

@test "TEST: --type=unit passes -L unit to ctest" {
    assert_dry_run_contains "-L unit" test --type=unit --preset debug
}

@test "TEST: --type=integration passes -L integration to ctest" {
    assert_dry_run_contains "-L integration" test --type=integration --preset debug
}

@test "TEST: --type=regression passes -L regression to ctest" {
    assert_dry_run_contains "-L regression" test --type=regression --preset debug
}

@test "TEST: --type=all passes no -L flag to ctest" {
    run_clibra --dry-run test --type=all --preset debug
    assert_clibra_success
    assert_output_not_contains " -L "
}

@test "TEST: default type (no --type) passes no -L flag to ctest" {
    run_clibra --dry-run test --preset debug
    assert_clibra_success
    assert_output_not_contains " -L "
}

@test "TEST: -L unit and -L integration are separate flags not combined" {
    # Ensure -L is followed by the label as a separate token
    run_clibra --dry-run test --type=unit --preset debug
    assert_clibra_success
    assert_output_contains "-L unit"
    assert_output_not_contains "-Lunit"
}

# ==============================================================================
# --no-build
# ==============================================================================

@test "TEST: --no-build skips cmake --build invocation" {
    run_clibra --dry-run test --no-build --preset debug
    assert_clibra_success
    assert_output_not_contains "cmake --build"
}

@test "TEST: without --no-build cmake --build is invoked" {
    run_clibra --dry-run test --preset debug
    assert_clibra_success
    assert_output_contains "cmake --build"
}

# ==============================================================================
# --reconfigure
# ==============================================================================

@test "TEST: --reconfigure invokes configure step" {
    assert_dry_run_contains "cmake --preset" test --reconfigure --preset debug
}

@test "TEST: -D defines forwarded to configure step with --reconfigure" {
    assert_dry_run_contains "-DFOO=BAR" test --reconfigure -DFOO=BAR --preset debug
}

# ==============================================================================
# Cold start (real cmake)
# ==============================================================================

@test "TEST: cold start configures and builds before running ctest" {
    skip_if_compiler_missing gnu c
    # sample_cli has no tests so ctest exits 0 with no tests run
    run_clibra test --preset debug $CLI_CMAKE_DEFINES
    assert_clibra_success
    assert_build_dir_exists "debug"
}

# ==============================================================================
# Failure
# ==============================================================================

@test "TEST: non-existent preset causes failure" {
    run_clibra test --preset no_such_preset_xyzzy
    assert_clibra_failure
}
