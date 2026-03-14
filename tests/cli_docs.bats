#!/usr/bin/env bats
#
# BATS tests for `clibra docs`.
#
# Flag-forwarding tests use --dry-run.
# Feature-disabled tests require a real configured build.
#
# Design note: when LIBRA_DOCS=OFF, docs skips targets with a warning and
# exits 0 — it does NOT fail. Failure only occurs for preset resolution errors.
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

@test "DOCS: --reconfigure invokes configure step" {
    assert_dry_run_contains "cmake --preset" docs --reconfigure
}

@test "DOCS: -D defines forwarded to configure step with --reconfigure" {
    assert_dry_run_contains "-DFOO=BAR" docs --reconfigure -DFOO=BAR
}

# ==============================================================================
# Failure
# ==============================================================================

@test "DOCS: non-existent preset causes failure" {
    run_clibra docs --preset no_such_preset_xyzzy
    assert_clibra_failure
}
