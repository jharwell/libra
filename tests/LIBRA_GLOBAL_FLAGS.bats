#!/usr/bin/env bats
#
# BATS tests for LIBRA_GLOBAL_C_FLAGS and LIBRA_GLOBAL_CXX_FLAGS
#
# These options control whether LIBRA applies compiler flags globally via
# add_compile_options() / add_link_options() in addition to per-target:
#   - OFF (default): flags are set on targets only
#   - ON:            flags are also applied globally via add_compile_options(),
#                    affecting ALL targets in the directory (including those not
#                    registered with libra_add_library/executable)
#
# Note: add_compile_options() does NOT set CMAKE_C_FLAGS/CMAKE_CXX_FLAGS in
# the cmake cache.  The observable effect is that the flags appear in the
# compiled target's COMPILE_OPTIONS (and thus in the generated build_info
# file) regardless of whether LIBRA_SAN/LIBRA_FORTIFY etc. are also on the
# target.
#

load test_helpers

setup() {
    setup_libra_test
    export CMAKE_BUILD_TYPE=Debug
}

# ==============================================================================
# LIBRA_GLOBAL_C_FLAGS
# ==============================================================================

@test "GLOBAL_C_FLAGS: OFF configures without error" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_GLOBAL_C_FLAGS=OFF)
    [ -n "$test_dir" ]
}

@test "GLOBAL_C_FLAGS: ON configures without error" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_GLOBAL_C_FLAGS=ON)
    [ -n "$test_dir" ]
}

@test "GLOBAL_C_FLAGS: OFF value stored in cache" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_GLOBAL_C_FLAGS=OFF)

    run cache_value_equals "$test_dir" "LIBRA_GLOBAL_C_FLAGS" "OFF"
    [ "$status" -eq 0 ]
}

@test "GLOBAL_C_FLAGS: ON value stored in cache" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_GLOBAL_C_FLAGS=ON)

    run cache_value_equals "$test_dir" "LIBRA_GLOBAL_C_FLAGS" "ON"
    [ "$status" -eq 0 ]
}

@test "GLOBAL_C_FLAGS: ON with LIBRA_SAN=ASAN adds -fsanitize=address to target compile flags" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" \
        -DLIBRA_GLOBAL_C_FLAGS=ON \
        -DLIBRA_SAN=ASAN)

    assert_compile_flag_present "$test_dir" "c" "-fsanitize=address"
}

@test "GLOBAL_C_FLAGS: OFF with LIBRA_SAN=ASAN still adds -fsanitize=address to registered target" {
    # OFF means per-target only — the LIBRA-registered target still gets the flag
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" \
        -DLIBRA_GLOBAL_C_FLAGS=OFF \
        -DLIBRA_SAN=ASAN)

    assert_compile_flag_present "$test_dir" "c" "-fsanitize=address"
}

@test "GLOBAL_C_FLAGS: ON persists across reconfiguration" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_GLOBAL_C_FLAGS=ON)

    cd "$test_dir"
    run cmake "$BATS_TEST_DIRNAME/sample_build_info" --log-level=ERROR
    [ "$status" -eq 0 ]

    run cache_value_equals "$test_dir" "LIBRA_GLOBAL_C_FLAGS" "ON"
    [ "$status" -eq 0 ]
}

@test "GLOBAL_C_FLAGS: Can change from ON to OFF on reconfiguration" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_GLOBAL_C_FLAGS=ON)

    cd "$test_dir"
    run cmake "$BATS_TEST_DIRNAME/sample_build_info" -DLIBRA_GLOBAL_C_FLAGS=OFF --log-level=ERROR
    [ "$status" -eq 0 ]

    run cache_value_equals "$test_dir" "LIBRA_GLOBAL_C_FLAGS" "OFF"
    [ "$status" -eq 0 ]
}

# ==============================================================================
# LIBRA_GLOBAL_CXX_FLAGS
# ==============================================================================

@test "GLOBAL_CXX_FLAGS: OFF configures without error" {
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_GLOBAL_CXX_FLAGS=OFF)
    [ -n "$test_dir" ]
}

@test "GLOBAL_CXX_FLAGS: ON configures without error" {
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_GLOBAL_CXX_FLAGS=ON)
    [ -n "$test_dir" ]
}

@test "GLOBAL_CXX_FLAGS: OFF value stored in cache" {
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_GLOBAL_CXX_FLAGS=OFF)

    run cache_value_equals "$test_dir" "LIBRA_GLOBAL_CXX_FLAGS" "OFF"
    [ "$status" -eq 0 ]
}

@test "GLOBAL_CXX_FLAGS: ON value stored in cache" {
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_GLOBAL_CXX_FLAGS=ON)

    run cache_value_equals "$test_dir" "LIBRA_GLOBAL_CXX_FLAGS" "ON"
    [ "$status" -eq 0 ]
}

@test "GLOBAL_CXX_FLAGS: ON with LIBRA_SAN=ASAN adds -fsanitize=address to target compile flags" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" \
        -DLIBRA_GLOBAL_CXX_FLAGS=ON \
        -DLIBRA_SAN=ASAN)

    assert_compile_flag_present "$test_dir" "cxx" "-fsanitize=address"
}

@test "GLOBAL_CXX_FLAGS: OFF with LIBRA_SAN=ASAN still adds -fsanitize=address to registered target" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" \
        -DLIBRA_GLOBAL_CXX_FLAGS=OFF \
        -DLIBRA_SAN=ASAN)

    assert_compile_flag_present "$test_dir" "cxx" "-fsanitize=address"
}

@test "GLOBAL_CXX_FLAGS: ON persists across reconfiguration" {
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_GLOBAL_CXX_FLAGS=ON)

    cd "$test_dir"
    run cmake "$BATS_TEST_DIRNAME/sample_build_info" --log-level=ERROR
    [ "$status" -eq 0 ]

    run cache_value_equals "$test_dir" "LIBRA_GLOBAL_CXX_FLAGS" "ON"
    [ "$status" -eq 0 ]
}

@test "GLOBAL_CXX_FLAGS: Can change from ON to OFF on reconfiguration" {
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_GLOBAL_CXX_FLAGS=ON)

    cd "$test_dir"
    run cmake "$BATS_TEST_DIRNAME/sample_build_info" -DLIBRA_GLOBAL_CXX_FLAGS=OFF --log-level=ERROR
    [ "$status" -eq 0 ]

    run cache_value_equals "$test_dir" "LIBRA_GLOBAL_CXX_FLAGS" "OFF"
    [ "$status" -eq 0 ]
}

# ==============================================================================
# Interaction: both ON together
# ==============================================================================

@test "GLOBAL_FLAGS: both ON simultaneously configures without error" {
    test_dir=$(run_libra_cmake_test "cxx" \
        -DLIBRA_GLOBAL_C_FLAGS=ON \
        -DLIBRA_GLOBAL_CXX_FLAGS=ON)

    run cache_value_equals "$test_dir" "LIBRA_GLOBAL_C_FLAGS" "ON"
    [ "$status" -eq 0 ]
    run cache_value_equals "$test_dir" "LIBRA_GLOBAL_CXX_FLAGS" "ON"
    [ "$status" -eq 0 ]
}
