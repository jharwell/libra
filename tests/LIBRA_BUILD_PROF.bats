#!/usr/bin/env bats
#
# BATS tests for LIBRA_BUILD_PROF
#
# LIBRA_BUILD_PROF controls whether compiler build-time profiling is enabled:
#   - ON:  Adds compiler-specific profiling flag (compile flags only)
#   - OFF: No profiling flag added (default)
#
# Per-compiler flag when ON:
#   GNU:   -ftime-report
#   Clang: -ftime-trace
#   Intel: (no flag defined — ON is a no-op for Intel)
#
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

@test "BUILD_PROF: GNU/C ON adds -ftime-report" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_BUILD_PROF=ON)

    assert_compile_flag_present "$test_dir" "c" "-ftime-report"
}

@test "BUILD_PROF: GNU/C OFF does not add -ftime-report" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_BUILD_PROF=OFF)

    assert_compile_flag_absent "$test_dir" "c" "-ftime-report"
}

# ------------------------------------------------------------------------------
# GNU compiler - C++
# ------------------------------------------------------------------------------

@test "BUILD_PROF: GNU/C++ ON adds -ftime-report" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_BUILD_PROF=ON)

    assert_compile_flag_present "$test_dir" "cxx" "-ftime-report"
}

@test "BUILD_PROF: GNU/C++ OFF does not add -ftime-report" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_BUILD_PROF=OFF)

    assert_compile_flag_absent "$test_dir" "cxx" "-ftime-report"
}

# ------------------------------------------------------------------------------
# Clang compiler - C
# ------------------------------------------------------------------------------

@test "BUILD_PROF: Clang/C ON adds -ftime-trace" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_BUILD_PROF=ON)

    assert_compile_flag_present "$test_dir" "c" "-ftime-trace"
}

@test "BUILD_PROF: Clang/C OFF does not add -ftime-trace" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_BUILD_PROF=OFF)

    assert_compile_flag_absent "$test_dir" "c" "-ftime-trace"
}

# ------------------------------------------------------------------------------
# Clang compiler - C++
# ------------------------------------------------------------------------------

@test "BUILD_PROF: Clang/C++ ON adds -ftime-trace" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_BUILD_PROF=ON)

    assert_compile_flag_present "$test_dir" "cxx" "-ftime-trace"
}

@test "BUILD_PROF: Clang/C++ OFF does not add -ftime-trace" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_BUILD_PROF=OFF)

    assert_compile_flag_absent "$test_dir" "cxx" "-ftime-trace"
}

# ------------------------------------------------------------------------------
# Intel compiler — OFF only (no flag defined for ON)
# ------------------------------------------------------------------------------

@test "BUILD_PROF: Intel/C OFF does not add -ftime-report or -ftime-trace" {
    skip_if_compiler_missing "intel" "c"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_BUILD_PROF=OFF)

    assert_compile_flag_absent "$test_dir" "c" "-ftime-report"
    assert_compile_flag_absent "$test_dir" "c" "-ftime-trace"
}

@test "BUILD_PROF: Intel/C++ OFF does not add -ftime-report or -ftime-trace" {
    skip_if_compiler_missing "intel" "cxx"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_BUILD_PROF=OFF)

    assert_compile_flag_absent "$test_dir" "cxx" "-ftime-report"
    assert_compile_flag_absent "$test_dir" "cxx" "-ftime-trace"
}

# ------------------------------------------------------------------------------
# Default behaviour
# ------------------------------------------------------------------------------

@test "BUILD_PROF: Default (unset) does not add profiling flags" {
    # LIBRA_BUILD_PROF defaults to OFF
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c")

    assert_compile_flag_absent "$test_dir" "c" "-ftime-report"
}

@test "BUILD_PROF: Cache variable persists across reconfiguration" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_BUILD_PROF=ON)

    run cache_value_equals "$test_dir" "LIBRA_BUILD_PROF" "ON"
    [ "$status" -eq 0 ]

    cd "$test_dir"
    run cmake "$BATS_TEST_DIRNAME/sample_build_info" --log-level=ERROR
    [ "$status" -eq 0 ]

    run cache_value_equals "$test_dir" "LIBRA_BUILD_PROF" "ON"
    [ "$status" -eq 0 ]
}

@test "BUILD_PROF: Can change value on reconfiguration" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_BUILD_PROF=ON)

    run cache_value_equals "$test_dir" "LIBRA_BUILD_PROF" "ON"
    [ "$status" -eq 0 ]

    cd "$test_dir"
    run cmake "$BATS_TEST_DIRNAME/sample_build_info" -DLIBRA_BUILD_PROF=OFF --log-level=ERROR
    [ "$status" -eq 0 ]

    run cache_value_equals "$test_dir" "LIBRA_BUILD_PROF" "OFF"
    [ "$status" -eq 0 ]
}
