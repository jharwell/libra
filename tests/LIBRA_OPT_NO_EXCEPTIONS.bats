#!/usr/bin/env bats
#
# BATS tests for LIBRA_OPT_NO_EXCEPTIONS
#
# Build type: Release
#

load test_helpers

setup() {
    setup_libra_test
    export CMAKE_BUILD_TYPE=Release
}

# ==============================================================================
# LIBRA_OPT_NO_EXCEPTIONS
# ==============================================================================

# ------------------------------------------------------------------------------
# GNU compiler - C++
# ------------------------------------------------------------------------------

@test "OPT_NO_EXCEPTIONS: GNU/C++ ON adds -fno-exceptions" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_NO_EXCEPTIONS=ON)

    assert_compile_flag_present "$test_dir" "cxx" "-fno-exceptions"
}

@test "OPT_NO_EXCEPTIONS: GNU/C++ OFF does not add -fno-exceptions" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_NO_EXCEPTIONS=OFF)

    assert_compile_flag_absent "$test_dir" "cxx" "-fno-exceptions"
}

# ------------------------------------------------------------------------------
# Clang compiler - C++
# ------------------------------------------------------------------------------

@test "OPT_NO_EXCEPTIONS: Clang/C++ ON adds -fno-exceptions" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_NO_EXCEPTIONS=ON)

    assert_compile_flag_present "$test_dir" "cxx" "-fno-exceptions"
}

@test "OPT_NO_EXCEPTIONS: Clang/C++ OFF does not add -fno-exceptions" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_NO_EXCEPTIONS=OFF)

    assert_compile_flag_absent "$test_dir" "cxx" "-fno-exceptions"
}

# ------------------------------------------------------------------------------
# Intel compiler - C++
# ------------------------------------------------------------------------------

@test "OPT_NO_EXCEPTIONS: Intel/C++ ON adds -fno-exceptions" {
    skip_if_compiler_missing "intel" "cxx"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_NO_EXCEPTIONS=ON)

    assert_compile_flag_present "$test_dir" "cxx" "-fno-exceptions"
}

@test "OPT_NO_EXCEPTIONS: Intel/C++ OFF does not add -fno-exceptions" {
    skip_if_compiler_missing "intel" "cxx"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_NO_EXCEPTIONS=OFF)

    assert_compile_flag_absent "$test_dir" "cxx" "-fno-exceptions"
}

# ------------------------------------------------------------------------------
# Default behaviour
# ------------------------------------------------------------------------------

@test "OPT_NO_EXCEPTIONS: Default (unset) does not add -fno-exceptions" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx")

    assert_compile_flag_absent "$test_dir" "cxx" "-fno-exceptions"
}

@test "OPT_NO_EXCEPTIONS: Cache variable persists across reconfiguration" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_NO_EXCEPTIONS=ON)

    run cache_value_equals "$test_dir" "LIBRA_OPT_NO_EXCEPTIONS" "ON"
    [ "$status" -eq 0 ]

    cd "$test_dir"
    run cmake "$BATS_TEST_DIRNAME/sample_build_info" --log-level=ERROR
    [ "$status" -eq 0 ]

    run cache_value_equals "$test_dir" "LIBRA_OPT_NO_EXCEPTIONS" "ON"
    [ "$status" -eq 0 ]
}

@test "OPT_NO_EXCEPTIONS: Can change value on reconfiguration" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_NO_EXCEPTIONS=ON)

    run cache_value_equals "$test_dir" "LIBRA_OPT_NO_EXCEPTIONS" "ON"
    [ "$status" -eq 0 ]

    cd "$test_dir"
    run cmake "$BATS_TEST_DIRNAME/sample_build_info" -DLIBRA_OPT_NO_EXCEPTIONS=OFF --log-level=ERROR
    [ "$status" -eq 0 ]

    run cache_value_equals "$test_dir" "LIBRA_OPT_NO_EXCEPTIONS" "OFF"
    [ "$status" -eq 0 ]
}

