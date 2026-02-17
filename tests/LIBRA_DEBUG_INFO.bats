#!/usr/bin/env bats
#
# BATS tests for LIBRA_DEBUG_INFO
#
# LIBRA_DEBUG_INFO controls debug symbol generation, independent of build type:
#   - ON:  Adds -g2 (default)
#   - OFF: Adds -g0
#
# The flag is identical across all supported compilers (GNU, Clang, Intel).
# Flags appear in COMPILE_FLAGS in the generated build_info file.
# Build type: Release (matches the shell test).
#

load test_helpers

setup() {
    setup_libra_test
    export CMAKE_BUILD_TYPE=Release
}

# ------------------------------------------------------------------------------
# GNU compiler - C
# ------------------------------------------------------------------------------

@test "DEBUG_INFO: GNU/C ON adds -g2" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_DEBUG_INFO=ON)

    assert_compile_flag_present "$test_dir" "c" "-g2"
}

@test "DEBUG_INFO: GNU/C OFF adds -g0" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_DEBUG_INFO=OFF)

    assert_compile_flag_present "$test_dir" "c" "-g0"
}

@test "DEBUG_INFO: GNU/C ON does not add -g0" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_DEBUG_INFO=ON)

    assert_compile_flag_absent "$test_dir" "c" "-g0"
}

@test "DEBUG_INFO: GNU/C OFF does not add -g2" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_DEBUG_INFO=OFF)

    assert_compile_flag_absent "$test_dir" "c" "-g2"
}

# ------------------------------------------------------------------------------
# GNU compiler - C++
# ------------------------------------------------------------------------------

@test "DEBUG_INFO: GNU/C++ ON adds -g2" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_DEBUG_INFO=ON)

    assert_compile_flag_present "$test_dir" "cxx" "-g2"
}

@test "DEBUG_INFO: GNU/C++ OFF adds -g0" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_DEBUG_INFO=OFF)

    assert_compile_flag_present "$test_dir" "cxx" "-g0"
}

# ------------------------------------------------------------------------------
# Clang compiler - C
# ------------------------------------------------------------------------------

@test "DEBUG_INFO: Clang/C ON adds -g2" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_DEBUG_INFO=ON)

    assert_compile_flag_present "$test_dir" "c" "-g2"
}

@test "DEBUG_INFO: Clang/C OFF adds -g0" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_DEBUG_INFO=OFF)

    assert_compile_flag_present "$test_dir" "c" "-g0"
}

# ------------------------------------------------------------------------------
# Clang compiler - C++
# ------------------------------------------------------------------------------

@test "DEBUG_INFO: Clang/C++ ON adds -g2" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_DEBUG_INFO=ON)

    assert_compile_flag_present "$test_dir" "cxx" "-g2"
}

@test "DEBUG_INFO: Clang/C++ OFF adds -g0" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_DEBUG_INFO=OFF)

    assert_compile_flag_present "$test_dir" "cxx" "-g0"
}

# ------------------------------------------------------------------------------
# Intel compiler - C
# ------------------------------------------------------------------------------

@test "DEBUG_INFO: Intel/C ON adds -g2" {
    skip_if_compiler_missing "intel" "c"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_DEBUG_INFO=ON)

    assert_compile_flag_present "$test_dir" "c" "-g2"
}

@test "DEBUG_INFO: Intel/C OFF adds -g0" {
    skip_if_compiler_missing "intel" "c"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_DEBUG_INFO=OFF)

    assert_compile_flag_present "$test_dir" "c" "-g0"
}

# ------------------------------------------------------------------------------
# Intel compiler - C++
# ------------------------------------------------------------------------------

@test "DEBUG_INFO: Intel/C++ ON adds -g2" {
    skip_if_compiler_missing "intel" "cxx"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_DEBUG_INFO=ON)

    assert_compile_flag_present "$test_dir" "cxx" "-g2"
}

@test "DEBUG_INFO: Intel/C++ OFF adds -g0" {
    skip_if_compiler_missing "intel" "cxx"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_DEBUG_INFO=OFF)

    assert_compile_flag_present "$test_dir" "cxx" "-g0"
}

# ------------------------------------------------------------------------------
# Default behaviour
# ------------------------------------------------------------------------------

@test "DEBUG_INFO: Default (unset) adds -g2" {
    # LIBRA_DEBUG_INFO defaults to ON
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c")

    assert_compile_flag_present "$test_dir" "c" "-g2"
}

@test "DEBUG_INFO: Cache variable persists across reconfiguration" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_DEBUG_INFO=OFF)

    run cache_value_equals "$test_dir" "LIBRA_DEBUG_INFO" "OFF"
    [ "$status" -eq 0 ]

    cd "$test_dir"
    run cmake "$BATS_TEST_DIRNAME/sample_build_info" --log-level=ERROR
    [ "$status" -eq 0 ]

    run cache_value_equals "$test_dir" "LIBRA_DEBUG_INFO" "OFF"
    [ "$status" -eq 0 ]
}

@test "DEBUG_INFO: Can change value on reconfiguration" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_DEBUG_INFO=OFF)

    run cache_value_equals "$test_dir" "LIBRA_DEBUG_INFO" "OFF"
    [ "$status" -eq 0 ]

    cd "$test_dir"
    run cmake "$BATS_TEST_DIRNAME/sample_build_info" -DLIBRA_DEBUG_INFO=ON --log-level=ERROR
    [ "$status" -eq 0 ]

    run cache_value_equals "$test_dir" "LIBRA_DEBUG_INFO" "ON"
    [ "$status" -eq 0 ]
}
