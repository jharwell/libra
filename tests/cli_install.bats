#!/usr/bin/env bats
#
# BATS tests for `clibra install`.
#
# Flag-forwarding tests use --dry-run.
# Real-build tests perform an actual cmake configure + build + install.
#

load test_helpers

setup() {
    setup_cli_test
}

# ==============================================================================
# Flag forwarding (--dry-run, fast)
# ==============================================================================

@test "INSTALL: invokes cmake --build" {
    assert_dry_run_contains "cmake --build" install --preset debug
}

@test "INSTALL: passes --preset to cmake --build" {
    assert_dry_run_contains "--preset debug" install --preset debug
}

@test "INSTALL: --preset flag is forwarded" {
    assert_dry_run_contains "--preset release" install --preset release
}

@test "INSTALL: targets the install target" {
    assert_dry_run_contains "--target install" install --preset debug
}

@test "INSTALL: --reconfigure invokes configure step" {
    assert_dry_run_contains "cmake --preset" install --reconfigure --preset debug
}

@test "INSTALL: --fresh invokes configure step with --fresh" {
    assert_dry_run_contains "--fresh" install --fresh --preset debug
}

@test "INSTALL: -D defines forwarded to configure step with --reconfigure" {
    assert_dry_run_contains "-DFOO=BAR" install --reconfigure -DFOO=BAR --preset debug
}

# ==============================================================================
# Preset resolution — no per-command default
# ==============================================================================

@test "INSTALL: has no per-command default preset — fails without --preset" {
    python3 -c "
import json
with open('CMakePresets.json') as f: d = json.load(f)
d.pop('vendor', None)
print(json.dumps(d))
" > CMakePresets.json.tmp && mv CMakePresets.json.tmp CMakePresets.json
    rm -f CMakeUserPresets.json
    run_clibra install --dry-run
    assert_clibra_failure
    assert_output_contains "no preset"
}

# ==============================================================================
# -D with existing build dir and no --reconfigure
# ==============================================================================

@test "INSTALL: -D with existing build dir and no --reconfigure fails with error" {
    skip_if_compiler_missing gnu c
    run_clibra build $CLI_CMAKE_DEFINES --preset debug
    assert_clibra_success
    run_clibra install --preset debug -DFOO=BAR
    assert_clibra_failure
}

@test "INSTALL: -D error message mentions --reconfigure as fix" {
    skip_if_compiler_missing gnu c
    run_clibra build $CLI_CMAKE_DEFINES --preset debug
    assert_clibra_success
    run_clibra install --preset debug -DFOO=BAR
    assert_clibra_failure
    assert_output_contains "reconfigure"
}

# ==============================================================================
# Cold start (real cmake)
# ==============================================================================

@test "INSTALL: cold start exits 0" {
    skip_if_compiler_missing gnu c
    run_clibra install $CLI_CMAKE_DEFINES --preset debug
    assert_clibra_success
}

@test "INSTALL: cold start creates build directory" {
    skip_if_compiler_missing gnu c
    run_clibra install $CLI_CMAKE_DEFINES --preset debug
    assert_clibra_success
    assert_build_dir_exists "debug"
}

@test "INSTALL: cold start installs binary under CMAKE_INSTALL_PREFIX" {
    skip_if_compiler_missing gnu c
    run_clibra install $CLI_CMAKE_DEFINES --preset debug
    assert_clibra_success
    # Base preset sets CMAKE_INSTALL_PREFIX = binaryDir/install
    [ -d "build/debug/install" ]
}

# ==============================================================================
# Failure
# ==============================================================================

@test "INSTALL: non-existent preset causes failure" {
    run_clibra install --preset no_such_preset_xyzzy
    assert_clibra_failure
}

@test "INSTALL: fails when run outside project root" {
    cd /tmp
    run_clibra install --preset debug
    assert_clibra_failure
    assert_output_contains "CMakeLists.txt"
}
