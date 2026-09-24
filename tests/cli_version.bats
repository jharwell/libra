#!/usr/bin/env bats
#
# BATS tests for `clibra version`.
#
# version reads the resolved project version out of the configured CMake cache
# (via libra_extract_version / version.cmake), so like `info` every test that
# expects a real version pre-builds in setup().
#

load test_helpers

setup() {
    setup_cli_test
    skip_if_compiler_missing gnu c
    "$CLIBRA_BIN" build --preset debug $CLI_CMAKE_DEFINES
}

# A permissive semver-ish matcher: MAJOR.MINOR.PATCH with an optional
# -prerelease and +build. Used to assert we printed *a* version, not which one.
SEMVER_RE='[0-9]+\.[0-9]+\.[0-9]+'

# ==============================================================================
# Default output (human, numeric)
# ==============================================================================

@test "VERSION: succeeds with a configured preset" {
    run_clibra version --preset debug
    assert_clibra_success
}

@test "VERSION: default output prints a semver-shaped version" {
    run_clibra version --preset debug
    assert_clibra_success
    [[ "$output" =~ $SEMVER_RE ]]
}

@test "VERSION: default output is numeric (no prerelease suffix)" {
    # Numeric is the default; the human numeric form should not carry a
    # -dev.N / -rc.N prerelease tag.
    run_clibra version --preset debug
    assert_clibra_success
    assert_output_not_contains "-dev."
    assert_output_not_contains "-rc."
}

# ==============================================================================
# --full flag
# ==============================================================================

@test "VERSION: --full succeeds" {
    run_clibra version --preset debug --full
    assert_clibra_success
}

@test "VERSION: --full prints a semver-shaped version" {
    run_clibra version --preset debug --full
    assert_clibra_success
    [[ "$output" =~ $SEMVER_RE ]]
}

# ==============================================================================
# --check (CI gating)
# ==============================================================================

@test "VERSION: --check passes when the version matches" {
    # Resolve first, then feed the resolved value back into --check.
    run_clibra version --preset debug
    assert_clibra_success
    resolved="$output"

    run_clibra version --preset debug --check "$resolved"
    assert_clibra_success
}

@test "VERSION: --check fails on a mismatching version" {
    run_clibra version --preset debug --check 999.999.999
    assert_clibra_failure
}

@test "VERSION: --check fails on a non-semver argument" {
    run_clibra version --preset debug --check not-a-version
    assert_clibra_failure
}

@test "VERSION: -c is accepted as short form of --check" {
    run_clibra version --preset debug -c 999.999.999
    assert_clibra_failure
}

# ==============================================================================
# --bump (numeric patch bump)
# ==============================================================================

@test "VERSION: --bump succeeds" {
    run_clibra version --preset debug --bump
    assert_clibra_success
}

@test "VERSION: --bump prints a semver-shaped version" {
    run_clibra version --preset debug --bump
    assert_clibra_success
    [[ "$output" =~ $SEMVER_RE ]]
}

@test "VERSION: --bump output differs from the un-bumped version" {
    run_clibra version --preset debug
    assert_clibra_success
    base="$output"

    run_clibra version --preset debug --bump
    assert_clibra_success
    [ "$output" != "$base" ]
}

# ==============================================================================
# --dry-run
# ==============================================================================

@test "VERSION: --dry-run succeeds" {
    run_clibra version --preset debug --dry-run
    assert_clibra_success
}

# ==============================================================================
# Failure
# ==============================================================================

@test "VERSION: fails when build directory does not exist" {
    run_clibra version --preset release
    assert_clibra_failure
    assert_output_contains "Build directory"
}

@test "VERSION: fails when no preset files exist" {
    rm -f CMakePresets.json CMakeUserPresets.json
    run_clibra version --preset debug
    assert_clibra_failure
}

@test "VERSION: rejects an invalid --output value" {
    run_clibra version --preset debug --output yaml
    assert_clibra_failure
}
