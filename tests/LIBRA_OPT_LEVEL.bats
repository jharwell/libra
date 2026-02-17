#!/usr/bin/env bats
#
# BATS tests for LIBRA_OPT_LEVEL
#
# LIBRA_OPT_LEVEL sets the optimisation level, overriding the cmake build-type
# default.  The value is passed directly as the compiler flag (e.g. -O2).
#
# Supported levels: -O0, -O1, -O2, -O3, -Os
# All three compilers (GNU, Clang, Intel) use identical flag names.
#
# The flag appears in BOTH COMPILE_FLAGS and LINK_FLAGS in the generated
# build_info file (see LIBRA_COMMON_COMPILE_OPTIONS / LIBRA_COMMON_LINK_OPTIONS
# in build-types.cmake).
#
# Build-type defaults when LIBRA_OPT_LEVEL is not set:
#   Debug:   -O0
#   Release: -O3
#

load test_helpers

setup() {
    setup_libra_test
}

# Helper: assert opt flag present in both compile and link flags
assert_opt_level_present() {
    local test_dir="$1"
    local lang="$2"
    local flag="$3"

    assert_compile_flag_present "$test_dir" "$lang" "$flag"
    assert_link_flag_present    "$test_dir" "$lang" "$flag"
}

# ==============================================================================
# Build-type defaults (no explicit LIBRA_OPT_LEVEL)
# ==============================================================================

@test "OPT_LEVEL: GNU/C Debug defaults to -O0" {
    COMPILER_TYPE=gnu
    CMAKE_BUILD_TYPE=Debug
    test_dir=$(run_libra_cmake_test "c")

    assert_opt_level_present "$test_dir" "c" "-O0"
}

@test "OPT_LEVEL: GNU/C Release defaults to -O3" {
    COMPILER_TYPE=gnu
    CMAKE_BUILD_TYPE=Release
    test_dir=$(run_libra_cmake_test "c")

    assert_opt_level_present "$test_dir" "c" "-O3"
}

@test "OPT_LEVEL: GNU/C++ Debug defaults to -O0" {
    COMPILER_TYPE=gnu
    CMAKE_BUILD_TYPE=Debug
    test_dir=$(run_libra_cmake_test "cxx")

    assert_opt_level_present "$test_dir" "cxx" "-O0"
}

@test "OPT_LEVEL: GNU/C++ Release defaults to -O3" {
    COMPILER_TYPE=gnu
    CMAKE_BUILD_TYPE=Release
    test_dir=$(run_libra_cmake_test "cxx")

    assert_opt_level_present "$test_dir" "cxx" "-O3"
}

# ==============================================================================
# GNU - explicit levels
# ==============================================================================

@test "OPT_LEVEL: GNU/C -O0 in compile and link flags" {
    COMPILER_TYPE=gnu
    CMAKE_BUILD_TYPE=Release
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_LEVEL=-O0)

    assert_opt_level_present "$test_dir" "c" "-O0"
}

@test "OPT_LEVEL: GNU/C -O1 in compile and link flags" {
    COMPILER_TYPE=gnu
    CMAKE_BUILD_TYPE=Release
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_LEVEL=-O1)

    assert_opt_level_present "$test_dir" "c" "-O1"
}

@test "OPT_LEVEL: GNU/C -O2 in compile and link flags" {
    COMPILER_TYPE=gnu
    CMAKE_BUILD_TYPE=Debug
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_LEVEL=-O2)

    assert_opt_level_present "$test_dir" "c" "-O2"
}

@test "OPT_LEVEL: GNU/C -O3 in compile and link flags" {
    COMPILER_TYPE=gnu
    CMAKE_BUILD_TYPE=Debug
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_LEVEL=-O3)

    assert_opt_level_present "$test_dir" "c" "-O3"
}

@test "OPT_LEVEL: GNU/C -Os in compile and link flags" {
    COMPILER_TYPE=gnu
    CMAKE_BUILD_TYPE=Release
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_LEVEL=-Os)

    assert_opt_level_present "$test_dir" "c" "-Os"
}

@test "OPT_LEVEL: GNU/C++ -O2 in compile and link flags" {
    COMPILER_TYPE=gnu
    CMAKE_BUILD_TYPE=Debug
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_LEVEL=-O2)

    assert_opt_level_present "$test_dir" "cxx" "-O2"
}

@test "OPT_LEVEL: GNU/C++ -Os in compile and link flags" {
    COMPILER_TYPE=gnu
    CMAKE_BUILD_TYPE=Release
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_LEVEL=-Os)

    assert_opt_level_present "$test_dir" "cxx" "-Os"
}

# ==============================================================================
# Clang - explicit levels
# ==============================================================================

@test "OPT_LEVEL: Clang/C -O0 in compile and link flags" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    CMAKE_BUILD_TYPE=Release
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_LEVEL=-O0)

    assert_opt_level_present "$test_dir" "c" "-O0"
}

@test "OPT_LEVEL: Clang/C -O2 in compile and link flags" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    CMAKE_BUILD_TYPE=Debug
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_LEVEL=-O2)

    assert_opt_level_present "$test_dir" "c" "-O2"
}

@test "OPT_LEVEL: Clang/C -O3 in compile and link flags" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    CMAKE_BUILD_TYPE=Debug
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_LEVEL=-O3)

    assert_opt_level_present "$test_dir" "c" "-O3"
}

@test "OPT_LEVEL: Clang/C -Os in compile and link flags" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    CMAKE_BUILD_TYPE=Release
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_LEVEL=-Os)

    assert_opt_level_present "$test_dir" "c" "-Os"
}

@test "OPT_LEVEL: Clang/C++ -O2 in compile and link flags" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    CMAKE_BUILD_TYPE=Debug
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_LEVEL=-O2)

    assert_opt_level_present "$test_dir" "cxx" "-O2"
}

@test "OPT_LEVEL: Clang/C++ -Os in compile and link flags" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    CMAKE_BUILD_TYPE=Release
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_LEVEL=-Os)

    assert_opt_level_present "$test_dir" "cxx" "-Os"
}

# ==============================================================================
# Intel - explicit levels
# ==============================================================================

@test "OPT_LEVEL: Intel/C -O0 in compile and link flags" {
    skip_if_compiler_missing "intel" "c"
    COMPILER_TYPE=intel
    CMAKE_BUILD_TYPE=Release
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_LEVEL=-O0)

    assert_opt_level_present "$test_dir" "c" "-O0"
}

@test "OPT_LEVEL: Intel/C -O2 in compile and link flags" {
    skip_if_compiler_missing "intel" "c"
    COMPILER_TYPE=intel
    CMAKE_BUILD_TYPE=Debug
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_LEVEL=-O2)

    assert_opt_level_present "$test_dir" "c" "-O2"
}

@test "OPT_LEVEL: Intel/C -O3 in compile and link flags" {
    skip_if_compiler_missing "intel" "c"
    COMPILER_TYPE=intel
    CMAKE_BUILD_TYPE=Debug
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_LEVEL=-O3)

    assert_opt_level_present "$test_dir" "c" "-O3"
}

@test "OPT_LEVEL: Intel/C -Os in compile and link flags" {
    skip_if_compiler_missing "intel" "c"
    COMPILER_TYPE=intel
    CMAKE_BUILD_TYPE=Release
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_LEVEL=-Os)

    assert_opt_level_present "$test_dir" "c" "-Os"
}

@test "OPT_LEVEL: Intel/C++ -O2 in compile and link flags" {
    skip_if_compiler_missing "intel" "cxx"
    COMPILER_TYPE=intel
    CMAKE_BUILD_TYPE=Debug
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_LEVEL=-O2)

    assert_opt_level_present "$test_dir" "cxx" "-O2"
}

@test "OPT_LEVEL: Intel/C++ -Os in compile and link flags" {
    skip_if_compiler_missing "intel" "cxx"
    COMPILER_TYPE=intel
    CMAKE_BUILD_TYPE=Release
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_LEVEL=-Os)

    assert_opt_level_present "$test_dir" "cxx" "-Os"
}

# ==============================================================================
# Override: explicit level beats build-type default
# ==============================================================================

@test "OPT_LEVEL: GNU/C -O2 overrides Debug default of -O0" {
    COMPILER_TYPE=gnu
    CMAKE_BUILD_TYPE=Debug
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_LEVEL=-O2)

    assert_opt_level_present "$test_dir" "c" "-O2"
    assert_compile_flag_absent "$test_dir" "c" "-O0"
}

@test "OPT_LEVEL: GNU/C -O1 overrides Release default of -O3" {
    COMPILER_TYPE=gnu
    CMAKE_BUILD_TYPE=Release
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_LEVEL=-O1)

    assert_opt_level_present "$test_dir" "c" "-O1"
    assert_compile_flag_absent "$test_dir" "c" "-O3"
}

@test "OPT_LEVEL: Cache variable persists across reconfiguration" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_LEVEL=-O2)

    run cache_value_equals "$test_dir" "LIBRA_OPT_LEVEL" "-O2"
    [ "$status" -eq 0 ]

    cd "$test_dir"
    run cmake "$BATS_TEST_DIRNAME/sample_build_info" --log-level=ERROR
    [ "$status" -eq 0 ]

    run cache_value_equals "$test_dir" "LIBRA_OPT_LEVEL" "-O2"
    [ "$status" -eq 0 ]
}

@test "OPT_LEVEL: Can change value on reconfiguration" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_LEVEL=-O2)

    run cache_value_equals "$test_dir" "LIBRA_OPT_LEVEL" "-O2"
    [ "$status" -eq 0 ]

    cd "$test_dir"
    run cmake "$BATS_TEST_DIRNAME/sample_build_info" -DLIBRA_OPT_LEVEL=-O3 --log-level=ERROR
    [ "$status" -eq 0 ]

    run cache_value_equals "$test_dir" "LIBRA_OPT_LEVEL" "-O3"
    [ "$status" -eq 0 ]
}
