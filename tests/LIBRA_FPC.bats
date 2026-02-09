#!/usr/bin/env bats
#
# BATS tests for LIBRA_FPC (Function Precondition Checking)
#
# LIBRA_FPC controls function precondition checking behavior:
#   - RETURN: Return from function on precondition failure (default)
#   - ABORT: Abort program on precondition failure
#   - NONE: No precondition checking
#   - INHERIT: Uses parent's value
#
# These map to compile-time defines:
#   - LIBRA_FPC=LIBRA_FPC_RETURN
#   - LIBRA_FPC=LIBRA_FPC_ABORT
#   - LIBRA_FPC=LIBRA_FPC_NONE
#

load test_helpers

setup() {
    setup_libra_test
}

@test "FPC: LIBRA_FPC=RETURN defines LIBRA_FPC_RETURN" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_FPC=RETURN)

    assert_define_present "$test_dir" "c" "LIBRA_FPC=LIBRA_FPC_RETURN"
}

@test "FPC: LIBRA_FPC=ABORT defines LIBRA_FPC_ABORT" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_FPC=ABORT)

    assert_define_present "$test_dir" "c" "LIBRA_FPC=LIBRA_FPC_ABORT"
}

@test "FPC: LIBRA_FPC=NONE defines LIBRA_FPC_NONE" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_FPC=NONE)

    assert_define_present "$test_dir" "c" "LIBRA_FPC=LIBRA_FPC_NONE"
}

@test "FPC: Default value sets nothing" {
    # When LIBRA_FPC is not specified, it should default to INHERIT
    test_dir=$(run_libra_cmake_test "c")

    assert_define_absert "$test_dir" "c" "LIBRA_FPC"
}

@test "FPC: Works with C++ projects" {
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_FPC=ABORT)

    assert_define_present "$test_dir" "cxx" "LIBRA_FPC=LIBRA_FPC_ABORT"
}

@test "FPC: Multiple values can be tested sequentially" {
    # Test RETURN
    test_dir_return=$(run_libra_cmake_test "c" -DLIBRA_FPC=RETURN)
    assert_define_present "$test_dir_return" "c" "LIBRA_FPC=LIBRA_FPC_RETURN"

    # Test ABORT
    test_dir_abort=$(run_libra_cmake_test "c" -DLIBRA_FPC=ABORT)
    assert_define_present "$test_dir_abort" "c" "LIBRA_FPC=LIBRA_FPC_ABORT"

    # Test NONE
    test_dir_none=$(run_libra_cmake_test "c" -DLIBRA_FPC=NONE)
    assert_define_present "$test_dir_none" "c" "LIBRA_FPC=LIBRA_FPC_NONE"
}

@test "FPC: Define appears in build_info.c" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_FPC=RETURN)

    # Verify the define is actually in the generated file
    build_info="$test_dir/build_info.c"
    [ -f "$build_info" ]

    run grep "LIBRA_FPC=LIBRA_FPC_RETURN" "$build_info"
    [ "$status" -eq 0 ]
}

@test "FPC: Define appears in build_info.cpp for C++" {
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_FPC=ABORT)

    build_info="$test_dir/build_info.cpp"
    [ -f "$build_info" ]

    run grep "LIBRA_FPC=LIBRA_FPC_ABORT" "$build_info"
    [ "$status" -eq 0 ]
}
