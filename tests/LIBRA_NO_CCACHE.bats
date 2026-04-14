#!/usr/bin/env bats
#
# BATS tests for LIBRA_NO_CCACHE
#
# LIBRA_NO_CCACHE controls whether ccache is used as a compiler launcher:
#   - OFF (default): ccache is used if found on PATH
#   - ON:            ccache is never used, even if found
#
# When ccache is not installed the ON/OFF distinction is unobservable from
# outside cmake (CMAKE_C_COMPILER_LAUNCHER stays unset either way).  Tests
# that verify launcher state are therefore skipped when ccache is absent.
#
# Tests that do not depend on ccache being present (cache persistence,
# configure success) run unconditionally.
#

load test_helpers

setup() {
    setup_libra_test
}

# ==============================================================================
# Configure succeeds for both values
# ==============================================================================

@test "NO_CCACHE: LIBRA_NO_CCACHE=OFF configures without error" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_NO_CCACHE=OFF)
    [ -n "$test_dir" ]
}

@test "NO_CCACHE: LIBRA_NO_CCACHE=ON configures without error" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_NO_CCACHE=ON)
    [ -n "$test_dir" ]
}

@test "NO_CCACHE: Works with C++ projects" {
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_NO_CCACHE=ON)
    [ -n "$test_dir" ]
}

# ==============================================================================
# Cache persistence
# ==============================================================================

@test "NO_CCACHE: ON value stored in cache" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_NO_CCACHE=ON)

    run cache_value_equals "$test_dir" "LIBRA_NO_CCACHE" "ON"
    [ "$status" -eq 0 ]
}

@test "NO_CCACHE: OFF value stored in cache" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_NO_CCACHE=OFF)

    run cache_value_equals "$test_dir" "LIBRA_NO_CCACHE" "OFF"
    [ "$status" -eq 0 ]
}

@test "NO_CCACHE: ON persists across reconfiguration" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_NO_CCACHE=ON)

    run cache_value_equals "$test_dir" "LIBRA_NO_CCACHE" "ON"
    [ "$status" -eq 0 ]

    cd "$test_dir"
    run cmake "$BATS_TEST_DIRNAME/sample_build_info" --log-level=ERROR
    [ "$status" -eq 0 ]

    run cache_value_equals "$test_dir" "LIBRA_NO_CCACHE" "ON"
    [ "$status" -eq 0 ]
}

@test "NO_CCACHE: Can change from ON to OFF on reconfiguration" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_NO_CCACHE=ON)

    cd "$test_dir"
    run cmake "$BATS_TEST_DIRNAME/sample_build_info" -DLIBRA_NO_CCACHE=OFF --log-level=ERROR
    [ "$status" -eq 0 ]

    run cache_value_equals "$test_dir" "LIBRA_NO_CCACHE" "OFF"
    [ "$status" -eq 0 ]
}

# ==============================================================================
# Launcher state (only meaningful when ccache is installed)
# ==============================================================================

@test "NO_CCACHE: ON prevents ccache from being set as C compiler launcher" {
    if ! command -v ccache &>/dev/null; then
        skip "ccache not found on PATH"
    fi
    # When NO_CCACHE=ON, LIBRA skips the set_property(RULE_LAUNCH_COMPILE) call.
    # Verify cmake's configure output does NOT mention ccache.
    local test_dir="$TEST_BUILD_DIR/ccache_off_${RANDOM}"
    mkdir -p "$test_dir"
    local compiler
    compiler=$(get_compiler "${COMPILER_TYPE:-gnu}" "c")

    pushd "$test_dir" > /dev/null
    run cmake "$LIBRA_TESTS_DIR/sample_build_info" \
        -DCMAKE_C_COMPILER="$compiler" \
        -DLIBRA_TEST_LANGUAGE=C \
        -DLIBRA_NO_CCACHE=ON \
        --log-level=STATUS \
        $(_consume_mode_cmake_args 2>/dev/null || echo "-DLIBRA_SOURCE_ROOT=${LIBRA_SOURCE_ROOT}")
    popd > /dev/null

    [ "$status" -eq 0 ]
    assert_output_contains "Disabling ccache by request"
}

@test "NO_CCACHE: ON prevents ccache from being set as C++ compiler launcher" {
    if ! command -v ccache &>/dev/null; then
        skip "ccache not found on PATH"
    fi
    local test_dir="$TEST_BUILD_DIR/ccache_off_cxx_${RANDOM}"
    mkdir -p "$test_dir"
    local compiler
    compiler=$(get_compiler "${COMPILER_TYPE:-gnu}" "cxx")

    pushd "$test_dir" > /dev/null
    run cmake "$LIBRA_TESTS_DIR/sample_build_info" \
        -DCMAKE_CXX_COMPILER="$compiler" \
        -DLIBRA_TEST_LANGUAGE=CXX \
        -DLIBRA_NO_CCACHE=ON \
        --log-level=STATUS \
        $(_consume_mode_cmake_args 2>/dev/null || echo "-DLIBRA_SOURCE_ROOT=${LIBRA_SOURCE_ROOT}")
    popd > /dev/null

    [ "$status" -eq 0 ]
    assert_output_contains "Disabling ccache by request"
}

@test "NO_CCACHE: OFF allows ccache to be used as C compiler launcher" {
    if ! command -v ccache &>/dev/null; then
        skip "ccache not found on PATH"
    fi
    # LIBRA uses set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE) rather than
    # CMAKE_C_COMPILER_LAUNCHER, so the launcher does not appear in the cache.
    # Verify instead that cmake reports ccache usage in its configure output.
    local test_dir="$TEST_BUILD_DIR/ccache_on_${RANDOM}"
    mkdir -p "$test_dir"
    local compiler
    compiler=$(get_compiler "${COMPILER_TYPE:-gnu}" "c")

    pushd "$test_dir" > /dev/null
    run cmake "$LIBRA_TESTS_DIR/sample_build_info" \
        -DCMAKE_C_COMPILER="$compiler" \
        -DLIBRA_TEST_LANGUAGE=C \
        -DLIBRA_NO_CCACHE=OFF \
        --log-level=STATUS \
        $(_consume_mode_cmake_args 2>/dev/null || echo "-DLIBRA_SOURCE_ROOT=${LIBRA_SOURCE_ROOT}")
    popd > /dev/null

    [ "$status" -eq 0 ]
    assert_output_contains "ccache"
}
