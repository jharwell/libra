#!/usr/bin/env bats
#
# BATS tests for LIBRA_VALGRIND_COMPAT
#
# LIBRA_VALGRIND_COMPAT controls whether flags are added for Valgrind
# compatibility:
#   - ON:  Adds -mno-sse3 to disable SSE3 instructions Valgrind can't handle
#   - OFF: No Valgrind compatibility flags added (default)
#
# Supported compilers: gnu, clang
# Note: Intel compiler does not support LIBRA_VALGRIND_COMPAT
#

load test_helpers

setup() {
    setup_libra_test
}

# ------------------------------------------------------------------------------
# GNU compiler - C
# ------------------------------------------------------------------------------

@test "VALGRIND_COMPAT: GNU/C ON adds -mno-sse3" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_VALGRIND_COMPAT=ON)

    assert_compile_flag_present "$test_dir" "c" "-mno-sse3"
}

@test "VALGRIND_COMPAT: GNU/C OFF does not add -mno-sse3" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_VALGRIND_COMPAT=OFF)

    assert_compile_flag_absent "$test_dir" "c" "-mno-sse3"
}

# ------------------------------------------------------------------------------
# GNU compiler - C++
# ------------------------------------------------------------------------------

@test "VALGRIND_COMPAT: GNU/C++ ON adds -mno-sse3" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_VALGRIND_COMPAT=ON)

    assert_compile_flag_present "$test_dir" "cxx" "-mno-sse3"
}

@test "VALGRIND_COMPAT: GNU/C++ OFF does not add -mno-sse3" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_VALGRIND_COMPAT=OFF)

    assert_compile_flag_absent "$test_dir" "cxx" "-mno-sse3"
}

# ------------------------------------------------------------------------------
# Clang compiler - C
# ------------------------------------------------------------------------------

@test "VALGRIND_COMPAT: Clang/C ON adds -mno-sse3" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_VALGRIND_COMPAT=ON)

    assert_compile_flag_present "$test_dir" "c" "-mno-sse3"
}

@test "VALGRIND_COMPAT: Clang/C OFF does not add -mno-sse3" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_VALGRIND_COMPAT=OFF)

    assert_compile_flag_absent "$test_dir" "c" "-mno-sse3"
}

# ------------------------------------------------------------------------------
# Clang compiler - C++
# ------------------------------------------------------------------------------

@test "VALGRIND_COMPAT: Clang/C++ ON adds -mno-sse3" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_VALGRIND_COMPAT=ON)

    assert_compile_flag_present "$test_dir" "cxx" "-mno-sse3"
}

@test "VALGRIND_COMPAT: Clang/C++ OFF does not add -mno-sse3" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_VALGRIND_COMPAT=OFF)

    assert_compile_flag_absent "$test_dir" "cxx" "-mno-sse3"
}

# ------------------------------------------------------------------------------
# Default behaviour
# ------------------------------------------------------------------------------

@test "VALGRIND_COMPAT: Default (unset) does not add -mno-sse3" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c")

    assert_compile_flag_absent "$test_dir" "c" "-mno-sse3"
}
