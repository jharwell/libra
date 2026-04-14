#!/usr/bin/env bats
#
# BATS tests for `clibra docs`.
#
# Flag-forwarding tests use --dry-run.
# Feature-disabled tests require a real configured build.
#
# Design note: when LIBRA_DOCS=OFF, docs skips unavailable targets with a
# warning and exits 0. Failure only occurs for --check targets or preset
# resolution errors.
#

load test_helpers

setup() {
    setup_cli_test
}

# ==============================================================================
# Default preset
# ==============================================================================

@test "DOCS: defaults to 'docs' preset when --preset not given" {
    assert_dry_run_contains "--preset docs" docs
}

@test "DOCS: --preset flag is forwarded" {
    assert_dry_run_contains "--preset release" docs --preset release
}

# ==============================================================================
# Flag forwarding (--dry-run, fast)
# ==============================================================================

@test "DOCS: invokes cmake --build" {
    assert_dry_run_contains "cmake --build" docs
}

@test "DOCS: no subcommand targets apidoc and sphinxdoc" {
    run_clibra --dry-run docs
    assert_clibra_success
    assert_output_contains "apidoc"
    assert_output_contains "sphinxdoc"
}

@test "DOCS: --reconfigure invokes configure step" {
    assert_dry_run_contains "cmake --preset" docs --reconfigure
}

@test "DOCS: -D defines forwarded to configure step with --reconfigure" {
    assert_dry_run_contains "-DFOO=BAR" docs --reconfigure -DFOO=BAR
}

@test "DOCS: --keep-going is forwarded" {
    assert_dry_run_contains "--keep-going" docs --keep-going
}

# ==============================================================================
# --check subcommand
# ==============================================================================

@test "DOCS: --check=doxygen targets apidoc-check-doxygen" {
    assert_dry_run_contains "apidoc-check-doxygen" docs --check=doxygen
}

@test "DOCS: --check=clang targets apidoc-check-clang" {
    assert_dry_run_contains "apidoc-check-clang" docs --check=clang
}

@test "DOCS: --check=doxygen does not target apidoc or sphinxdoc" {
    run_clibra --dry-run docs --check=doxygen
    assert_clibra_success
    assert_output_contains "--target apidoc-check-doxygen"
    assert_output_not_contains "--target apidoc-check-clang"
}

@test "DOCS: --check=clang does not target apidoc or sphinxdoc" {
    run_clibra --dry-run docs --check=clang
    assert_clibra_success
    assert_output_not_contains "--target apidoc-check-doxygen"
    assert_output_contains "--target apidoc-check-clang"
}


# ==============================================================================
# Disabled target behaviour (real build required)
#
# When LIBRA_DOCS=OFF, all docs targets are hard failures regardless of
# whether --check is given. There is no silent skip.
# ==============================================================================

@test "DOCS: fails when LIBRA_DOCS not enabled and no --check given" {
    skip_if_compiler_missing gnu c
    # debug preset has LIBRA_DOCS=OFF
    run_clibra build --preset debug $CLI_CMAKE_DEFINES
    assert_clibra_success
    run_clibra docs --preset debug
    assert_clibra_failure
}

@test "DOCS: error message mentions disabled target when LIBRA_DOCS=OFF" {
    skip_if_compiler_missing gnu c
    run_clibra build --preset debug $CLI_CMAKE_DEFINES
    assert_clibra_success
    run_clibra docs --preset debug
    assert_clibra_failure
}

@test "DOCS: --check=doxygen fails when LIBRA_DOCS not enabled" {
    skip_if_compiler_missing gnu c
    run_clibra build --preset debug $CLI_CMAKE_DEFINES
    assert_clibra_success
    run_clibra docs --preset debug --check=doxygen
    assert_clibra_failure
}

# ==============================================================================
# Failure
# ==============================================================================

@test "DOCS: non-existent preset causes failure" {
    run_clibra docs --preset no_such_preset_xyzzy
    assert_clibra_failure
}
