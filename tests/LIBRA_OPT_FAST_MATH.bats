#!/usr/bin/env bats
#
# BATS tests for LIBRA_OPT_FAST_MATH
#
# All flags land in COMPILE_FLAGS in the generated build_info file.
# Build type: Release
#

load test_helpers

setup() {
    setup_libra_test
    export CMAKE_BUILD_TYPE=Release
}

# ------------------------------------------------------------------------------
# GNU compiler - C
# ------------------------------------------------------------------------------
@test "OPT_FAST_MATH: GNU/C ON adds -ffast-math" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_FAST_MATH=ON)

    assert_compile_flag_present "$test_dir" "c" "-ffast-math"
}

@test "OPT_FAST_MATH: GNU/C OFF does not add -ffast-math" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_FAST_MATH=OFF)

    assert_compile_flag_absent "$test_dir" "c" "-ffast-math"
}


# ------------------------------------------------------------------------------
# GNU compiler - C++
# ------------------------------------------------------------------------------
@test "OPT_FAST_MATH: GNU/C++ ON adds -ffast-math" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_FAST_MATH=ON)

    assert_compile_flag_present "$test_dir" "cxx" "-ffast-math"
}

@test "OPT_FAST_MATH: GNU/C++ OFF does not add -ffast-math" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_FAST_MATH=OFF)

    assert_compile_flag_absent "$test_dir" "cxx" "-ffast-math"
}

# ------------------------------------------------------------------------------
# clang compiler - C
# ------------------------------------------------------------------------------
@test "OPT_FAST_MATH: clang/C ON adds -ffast-math" {
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_FAST_MATH=ON)

    assert_compile_flag_present "$test_dir" "c" "-ffast-math"
}

@test "OPT_FAST_MATH: clang/C OFF does not add -ffast-math" {
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_FAST_MATH=OFF)

    assert_compile_flag_absent "$test_dir" "c" "-ffast-math"
}


# ------------------------------------------------------------------------------
# clang compiler - C++
# ------------------------------------------------------------------------------
@test "OPT_FAST_MATH: clang/C++ ON adds -ffast-math" {
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_FAST_MATH=ON)

    assert_compile_flag_present "$test_dir" "cxx" "-ffast-math"
}

@test "OPT_FAST_MATH: clang/C++ OFF does not add -ffast-math" {
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_FAST_MATH=OFF)

    assert_compile_flag_absent "$test_dir" "cxx" "-ffast-math"
}

# ------------------------------------------------------------------------------
# intel compiler - C
# ------------------------------------------------------------------------------
@test "OPT_FAST_MATH: intel/C ON adds -ffast-math" {
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_FAST_MATH=ON)

    assert_compile_flag_present "$test_dir" "c" "-ffast-math"
}

@test "OPT_FAST_MATH: intel/C OFF does not add -ffast-math" {
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_FAST_MATH=OFF)

    assert_compile_flag_absent "$test_dir" "c" "-ffast-math"
}


# ------------------------------------------------------------------------------
# intel compiler - C++
# ------------------------------------------------------------------------------
@test "OPT_FAST_MATH: intel/C++ ON adds -ffast-math" {
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_FAST_MATH=ON)

    assert_compile_flag_present "$test_dir" "cxx" "-ffast-math"
}

@test "OPT_FAST_MATH: intel/C++ OFF does not add -ffast-math" {
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_FAST_MATH=OFF)

    assert_compile_flag_absent "$test_dir" "cxx" "-ffast-math"
}
