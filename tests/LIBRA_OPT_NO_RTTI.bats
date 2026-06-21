#!/usr/bin/env bats
#
# BATS tests for LIBRA_OPT_NO_RTTI
#
# Build type: Release
#

load test_helpers

setup() {
    setup_libra_test
    export CMAKE_BUILD_TYPE=Release
}

# ------------------------------------------------------------------------------
# GNU compiler - C++
# ------------------------------------------------------------------------------

@test "OPT_NO_RTTI: GNU/C++ ON adds -fno-rtti" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_NO_RTTI=ON)

    assert_compile_flag_present "$test_dir" "cxx" "-fno-rtti"
}

@test "OPT_NO_RTTI: GNU/C++ OFF does not add -fno-rtti" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_NO_RTTI=OFF)

    assert_compile_flag_absent "$test_dir" "cxx" "-fno-rtti"
}

# ------------------------------------------------------------------------------
# Clang compiler - C++
# ------------------------------------------------------------------------------

@test "OPT_NO_RTTI: Clang/C++ ON adds -fno-rtti" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_NO_RTTI=ON)

    assert_compile_flag_present "$test_dir" "cxx" "-fno-rtti"
}

@test "OPT_NO_RTTI: Clang/C++ OFF does not add -fno-rtti" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_NO_RTTI=OFF)

    assert_compile_flag_absent "$test_dir" "cxx" "-fno-rtti"
}

# ------------------------------------------------------------------------------
# Intel compiler - C++
# ------------------------------------------------------------------------------

@test "OPT_NO_RTTI: Intel/C++ ON adds -fno-rtti" {
    skip_if_compiler_missing "intel" "cxx"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_NO_RTTI=ON)

    assert_compile_flag_present "$test_dir" "cxx" "-fno-rtti"
}

@test "OPT_NO_RTTI: Intel/C++ OFF does not add -fno-rtti" {
    skip_if_compiler_missing "intel" "cxx"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_NO_RTTI=OFF)

    assert_compile_flag_absent "$test_dir" "cxx" "-fno-rtti"
}

# ------------------------------------------------------------------------------
# Default behaviour
# ------------------------------------------------------------------------------

@test "OPT_NO_RTTI: Default (unset) does not add -fno-rtti" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx")

    assert_compile_flag_absent "$test_dir" "cxx" "-fno-rtti"
}

@test "OPT_NO_RTTI: Cache variable persists across reconfiguration" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_NO_RTTI=ON)

    run cache_value_equals "$test_dir" "LIBRA_OPT_NO_RTTI" "ON"
    [ "$status" -eq 0 ]

    cd "$test_dir"
    run cmake "$BATS_TEST_DIRNAME/sample_build_info" --log-level=ERROR
    [ "$status" -eq 0 ]

    run cache_value_equals "$test_dir" "LIBRA_OPT_NO_RTTI" "ON"
    [ "$status" -eq 0 ]
}

@test "OPT_NO_RTTI: Can change value on reconfiguration" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_NO_RTTI=ON)

    run cache_value_equals "$test_dir" "LIBRA_OPT_NO_RTTI" "ON"
    [ "$status" -eq 0 ]

    cd "$test_dir"
    run cmake "$BATS_TEST_DIRNAME/sample_build_info" -DLIBRA_OPT_NO_RTTI=OFF --log-level=ERROR
    [ "$status" -eq 0 ]

    run cache_value_equals "$test_dir" "LIBRA_OPT_NO_RTTI" "OFF"
    [ "$status" -eq 0 ]
}
