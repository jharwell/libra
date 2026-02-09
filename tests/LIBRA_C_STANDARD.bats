#!/usr/bin/env bats
#
# BATS tests for LIBRA_C_STANDARD
#
# LIBRA_C_STANDARD controls the C language standard:
#   - Can be set to 99, 11, 17, 23, etc.
#   - CMAKE_C_STANDARD takes precedence over LIBRA_C_STANDARD
#

load test_helpers

setup() {
    setup_libra_test
}

@test "C_STANDARD: LIBRA_C_STANDARD=99 sets C99" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_C_STANDARD=99)

    assert_standard_equals "$test_dir" "c" "99"
}

@test "C_STANDARD: LIBRA_C_STANDARD=11 sets C11" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_C_STANDARD=11)

    assert_standard_equals "$test_dir" "c" "11"
}

@test "C_STANDARD: LIBRA_C_STANDARD=17 sets C17" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_C_STANDARD=17)

    assert_standard_equals "$test_dir" "c" "17"
}

@test "C_STANDARD: LIBRA_C_STANDARD=23 sets C23" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_C_STANDARD=23)

    assert_standard_equals "$test_dir" "c" "23"
}

@test "C_STANDARD: CMAKE_C_STANDARD overrides LIBRA_C_STANDARD" {
    test_dir=$(run_libra_cmake_test "c" \
        -DLIBRA_C_STANDARD=11 \
        -DCMAKE_C_STANDARD=17)

    # CMAKE_C_STANDARD should win
    assert_standard_equals "$test_dir" "c" "17"
}

@test "C_STANDARD: Default standard is set" {
    # When neither CMAKE_C_STANDARD nor LIBRA_C_STANDARD is specified,
    # LIBRA should set a default
    test_dir=$(run_libra_cmake_test "c")

    # Get whatever standard was set (should be something)
    std=$(get_standard "$test_dir" "c")

    # Should have SOME standard set
    [ -n "$std" ]
}

@test "C_STANDARD: Works with GNU compiler" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_C_STANDARD=11)

    assert_standard_equals "$test_dir" "c" "11"
}

@test "C_STANDARD: Works with Clang compiler" {
    COMPILER_TYPE=clang
    skip_if_compiler_missing "clang" "c"
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_C_STANDARD=17)

    assert_standard_equals "$test_dir" "c" "17"
}

@test "C_STANDARD: Works with Intel compiler" {
    COMPILER_TYPE=intel
    skip_if_compiler_missing "intel" "c"

    test_dir=$(run_libra_cmake_test "c" -DLIBRA_C_STANDARD=11)

    assert_standard_equals "$test_dir" "c" "11"
}
