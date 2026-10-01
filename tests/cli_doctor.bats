#!/usr/bin/env bats
#
# BATS tests for `clibra doctor`.
#

load test_helpers

setup() {
    setup_cli_test
}

# ==============================================================================
# Output structure
# ==============================================================================

@test "DOCTOR: exits 0 in a valid project with cmake present" {
    run_clibra doctor --log=trace
    assert_success
}

@test "DOCTOR: output contains 'Tools' section header" {
    run_clibra doctor
    assert_output --partial "Tools"
}

@test "DOCTOR: output lists cmake with checkmark" {
    run_clibra doctor
    assert_output --partial "cmake"
    assert_output --partial "✓"
}

@test "DOCTOR: output contains 'Project structure' section header" {
    run_clibra doctor
    assert_output --partial "Project structure"
}

@test "DOCTOR: output contains summary line" {
    run_clibra doctor
    assert_output --partial "Checked"
}

@test "DOCTOR: summary line contains error count" {
    run_clibra doctor
    assert_output --partial "errors"
}

@test "DOCTOR: summary line contains warning count" {
    run_clibra doctor
    assert_output --partial "warnings"
}

@test "DOCTOR: summary line contains ok count" {
    run_clibra doctor
    assert_output --partial "ok"
}

# ==============================================================================
# Tool checks
# ==============================================================================

@test "DOCTOR: optional tools missing produce warnings not errors" {
    # doctor should still exit 0 even when optional tools are absent
    run_clibra doctor
    assert_success
}

@test "DOCTOR: optional missing tools show warning symbol" {
    run_clibra doctor
    # At least one optional tool is likely absent in the test environment
    # This test is skipped if all optional tools happen to be present
    if echo "$output" | grep -q "(optional)"; then
        assert_output --partial "⚠"
    fi
}

# ==============================================================================
# Project structure checks
# ==============================================================================

@test "DOCTOR: notes CMakePresets.json exists when present" {
    run_clibra doctor
    assert_output --partial "CMakePresets.json"
    assert_output --partial "✓"
}

@test "DOCTOR: warns when src/ directory absent" {
    rm -rf src
    run_clibra doctor
    assert_output --partial "src"
    assert_output --partial "⚠"
}

@test "DOCTOR: warns when include/ directory absent" {
    rm -rf include
    run_clibra doctor
    assert_output --partial "include"
    assert_output --partial "⚠"
}

@test "DOCTOR: still exits 0 when optional structure items absent" {
    rm -rf src include tests docs
    run_clibra doctor
    assert_success
}

# ==============================================================================
# Failure
# ==============================================================================

@test "DOCTOR: fails when run outside a project root" {
    cd /tmp
    run_clibra doctor
    assert_failure
    assert_output --partial "CMakeLists.txt"
}
