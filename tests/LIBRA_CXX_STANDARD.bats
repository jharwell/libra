#!/usr/bin/env bats
#
# BATS tests for LIBRA_CXX_STANDARD
#
# LIBRA_CXX_STANDARD controls the C++ language standard:
#   - Can be set to 11, 14, 17, 20, 23, etc.
#   - CMAKE_CXX_STANDARD takes precedence over LIBRA_CXX_STANDARD
#   - LIBRA_GLOBAL_CXX_STANDARD=YES prevents per-target override
#

load test_helpers

setup() {
    setup_libra_test
}


@test "CXX_STANDARD: LIBRA_CXX_STANDARD=11 sets C++11" {
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_CXX_STANDARD=11)

    assert_standard_equals "$test_dir" "cxx" "11"
}

@test "CXX_STANDARD: LIBRA_CXX_STANDARD=14 sets C++14" {
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_CXX_STANDARD=14)

    assert_standard_equals "$test_dir" "cxx" "14"
}

@test "CXX_STANDARD: LIBRA_CXX_STANDARD=17 sets C++17" {
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_CXX_STANDARD=17)

    assert_standard_equals "$test_dir" "cxx" "17"
}

@test "CXX_STANDARD: LIBRA_CXX_STANDARD=20 sets C++20" {
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_CXX_STANDARD=20)

    assert_standard_equals "$test_dir" "cxx" "20"
}

@test "CXX_STANDARD: LIBRA_CXX_STANDARD=23 sets C++23" {
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_CXX_STANDARD=23)

    assert_standard_equals "$test_dir" "cxx" "23"
}

@test "CXX_STANDARD: CMAKE_CXX_STANDARD overrides LIBRA_CXX_STANDARD" {
    test_dir=$(run_libra_cmake_test "cxx" \
        -DLIBRA_CXX_STANDARD=14 \
        -DCMAKE_CXX_STANDARD=20)

    # CMAKE_CXX_STANDARD should win
    assert_standard_equals "$test_dir" "cxx" "20"
}


@test "CXX_STANDARD: Default standard is set" {
    # When neither CMAKE_CXX_STANDARD nor LIBRA_CXX_STANDARD is specified,
    # LIBRA should set a default
    test_dir=$(run_libra_cmake_test "cxx")

    # Get whatever standard was set (should be something)
    std=$(get_standard "$test_dir" "cxx")

    # Should have SOME standard set
    [ -n "$std" ]
}

@test "CXX_STANDARD: Works with GNU compiler" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_CXX_STANDARD=17)

    assert_standard_equals "$test_dir" "cxx" "17"
}

@test "CXX_STANDARD: Works with Clang compiler" {
    COMPILER_TYPE=clang
    skip_if_compiler_missing "clang" "cxx"

    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_CXX_STANDARD=20)

    assert_standard_equals "$test_dir" "cxx" "20"
}

@test "CXX_STANDARD: Works with Intel compiler" {
    COMPILER_TYPE=intel
    skip_if_compiler_missing "intel" "cxx"

    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_CXX_STANDARD=17)

    assert_standard_equals "$test_dir" "cxx" "17"
}
