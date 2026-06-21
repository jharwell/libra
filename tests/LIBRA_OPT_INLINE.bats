#!/usr/bin/env bats
#
# BATS tests for LIBRA_OPT_INLINE
#
# LIBRA_OPT_INLINE controls whether the compiler adds flags that improve
# inlining and symbol-visibility optimisations:
#   - ON:  Adds -fno-semantic-interposition -fvisibility=hidden
#               -fvisibility-inlines-hidden (compile flags, all compilers)
#   - OFF: No flags added (default)
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

@test "OPT_INLINE: GNU/C ON adds -fno-semantic-interposition" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_INLINE=ON)

    assert_compile_flag_present "$test_dir" "c" "-fno-semantic-interposition"
}

@test "OPT_INLINE: GNU/C ON adds -fvisibility=hidden" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_INLINE=ON)

    assert_compile_flag_present "$test_dir" "c" "-fvisibility=hidden"
}

@test "OPT_INLINE: GNU/C ON adds -fvisibility-inlines-hidden" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_INLINE=ON)

    assert_compile_flag_present "$test_dir" "c" "-fvisibility-inlines-hidden"
}

@test "OPT_INLINE: GNU/C OFF does not add -fno-semantic-interposition" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_INLINE=OFF)

    assert_compile_flag_absent "$test_dir" "c" "-fno-semantic-interposition"
}

@test "OPT_INLINE: GNU/C OFF does not add -fvisibility=hidden" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_INLINE=OFF)

    assert_compile_flag_absent "$test_dir" "c" "-fvisibility=hidden"
}

@test "OPT_INLINE: GNU/C OFF does not add -fvisibility-inlines-hidden" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_INLINE=OFF)

    assert_compile_flag_absent "$test_dir" "c" "-fvisibility-inlines-hidden"
}

# ------------------------------------------------------------------------------
# GNU compiler - C++
# ------------------------------------------------------------------------------

@test "OPT_INLINE: GNU/C++ ON adds -fno-semantic-interposition" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_INLINE=ON)

    assert_compile_flag_present "$test_dir" "cxx" "-fno-semantic-interposition"
}

@test "OPT_INLINE: GNU/C++ ON adds -fvisibility=hidden" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_INLINE=ON)

    assert_compile_flag_present "$test_dir" "cxx" "-fvisibility=hidden"
}

@test "OPT_INLINE: GNU/C++ ON adds -fvisibility-inlines-hidden" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_INLINE=ON)

    assert_compile_flag_present "$test_dir" "cxx" "-fvisibility-inlines-hidden"
}

@test "OPT_INLINE: GNU/C++ OFF does not add -fno-semantic-interposition" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_INLINE=OFF)

    assert_compile_flag_absent "$test_dir" "cxx" "-fno-semantic-interposition"
}

@test "OPT_INLINE: GNU/C++ OFF does not add -fvisibility=hidden" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_INLINE=OFF)

    assert_compile_flag_absent "$test_dir" "cxx" "-fvisibility=hidden"
}

@test "OPT_INLINE: GNU/C++ OFF does not add -fvisibility-inlines-hidden" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_INLINE=OFF)

    assert_compile_flag_absent "$test_dir" "cxx" "-fvisibility-inlines-hidden"
}

# ------------------------------------------------------------------------------
# Clang compiler - C
# ------------------------------------------------------------------------------

@test "OPT_INLINE: Clang/C ON adds -fno-semantic-interposition" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_INLINE=ON)

    assert_compile_flag_present "$test_dir" "c" "-fno-semantic-interposition"
}

@test "OPT_INLINE: Clang/C ON adds -fvisibility=hidden" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_INLINE=ON)

    assert_compile_flag_present "$test_dir" "c" "-fvisibility=hidden"
}

@test "OPT_INLINE: Clang/C ON adds -fvisibility-inlines-hidden" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_INLINE=ON)

    assert_compile_flag_present "$test_dir" "c" "-fvisibility-inlines-hidden"
}

@test "OPT_INLINE: Clang/C OFF does not add -fno-semantic-interposition" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_INLINE=OFF)

    assert_compile_flag_absent "$test_dir" "c" "-fno-semantic-interposition"
}

@test "OPT_INLINE: Clang/C OFF does not add -fvisibility=hidden" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_INLINE=OFF)

    assert_compile_flag_absent "$test_dir" "c" "-fvisibility=hidden"
}

# ------------------------------------------------------------------------------
# Clang compiler - C++
# ------------------------------------------------------------------------------

@test "OPT_INLINE: Clang/C++ ON adds -fno-semantic-interposition" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_INLINE=ON)

    assert_compile_flag_present "$test_dir" "cxx" "-fno-semantic-interposition"
}

@test "OPT_INLINE: Clang/C++ ON adds -fvisibility=hidden" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_INLINE=ON)

    assert_compile_flag_present "$test_dir" "cxx" "-fvisibility=hidden"
}

@test "OPT_INLINE: Clang/C++ ON adds -fvisibility-inlines-hidden" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_INLINE=ON)

    assert_compile_flag_present "$test_dir" "cxx" "-fvisibility-inlines-hidden"
}

@test "OPT_INLINE: Clang/C++ OFF does not add -fno-semantic-interposition" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_INLINE=OFF)

    assert_compile_flag_absent "$test_dir" "cxx" "-fno-semantic-interposition"
}

@test "OPT_INLINE: Clang/C++ OFF does not add -fvisibility=hidden" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_INLINE=OFF)

    assert_compile_flag_absent "$test_dir" "cxx" "-fvisibility=hidden"
}

# ------------------------------------------------------------------------------
# Intel compiler - C
# ------------------------------------------------------------------------------

@test "OPT_INLINE: Intel/C ON adds -fno-semantic-interposition" {
    skip_if_compiler_missing "intel" "c"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_INLINE=ON)

    assert_compile_flag_present "$test_dir" "c" "-fno-semantic-interposition"
}

@test "OPT_INLINE: Intel/C ON adds -fvisibility=hidden" {
    skip_if_compiler_missing "intel" "c"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_INLINE=ON)

    assert_compile_flag_present "$test_dir" "c" "-fvisibility=hidden"
}

@test "OPT_INLINE: Intel/C ON adds -fvisibility-inlines-hidden" {
    skip_if_compiler_missing "intel" "c"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_INLINE=ON)

    assert_compile_flag_present "$test_dir" "c" "-fvisibility-inlines-hidden"
}

@test "OPT_INLINE: Intel/C OFF does not add -fno-semantic-interposition" {
    skip_if_compiler_missing "intel" "c"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_INLINE=OFF)

    assert_compile_flag_absent "$test_dir" "c" "-fno-semantic-interposition"
}

@test "OPT_INLINE: Intel/C OFF does not add -fvisibility=hidden" {
    skip_if_compiler_missing "intel" "c"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_INLINE=OFF)

    assert_compile_flag_absent "$test_dir" "c" "-fvisibility=hidden"
}

# ------------------------------------------------------------------------------
# Intel compiler - C++
# ------------------------------------------------------------------------------

@test "OPT_INLINE: Intel/C++ ON adds -fno-semantic-interposition" {
    skip_if_compiler_missing "intel" "cxx"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_INLINE=ON)

    assert_compile_flag_present "$test_dir" "cxx" "-fno-semantic-interposition"
}

@test "OPT_INLINE: Intel/C++ ON adds -fvisibility=hidden" {
    skip_if_compiler_missing "intel" "cxx"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_INLINE=ON)

    assert_compile_flag_present "$test_dir" "cxx" "-fvisibility=hidden"
}

@test "OPT_INLINE: Intel/C++ ON adds -fvisibility-inlines-hidden" {
    skip_if_compiler_missing "intel" "cxx"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_INLINE=ON)

    assert_compile_flag_present "$test_dir" "cxx" "-fvisibility-inlines-hidden"
}

@test "OPT_INLINE: Intel/C++ OFF does not add -fno-semantic-interposition" {
    skip_if_compiler_missing "intel" "cxx"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_INLINE=OFF)

    assert_compile_flag_absent "$test_dir" "cxx" "-fno-semantic-interposition"
}

@test "OPT_INLINE: Intel/C++ OFF does not add -fvisibility=hidden" {
    skip_if_compiler_missing "intel" "cxx"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_INLINE=OFF)

    assert_compile_flag_absent "$test_dir" "cxx" "-fvisibility=hidden"
}

# ------------------------------------------------------------------------------
# Default behaviour
# ------------------------------------------------------------------------------

@test "OPT_INLINE: Default (unset) does not add visibility flags" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c")

    assert_compile_flag_absent "$test_dir" "c" "-fno-semantic-interposition"
    assert_compile_flag_absent "$test_dir" "c" "-fvisibility=hidden"
    assert_compile_flag_absent "$test_dir" "c" "-fvisibility-inlines-hidden"
}

@test "OPT_INLINE: Cache variable persists across reconfiguration" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_INLINE=ON)

    run cache_value_equals "$test_dir" "LIBRA_OPT_INLINE" "ON"
    [ "$status" -eq 0 ]

    cd "$test_dir"
    run cmake "$BATS_TEST_DIRNAME/sample_build_info" --log-level=ERROR
    [ "$status" -eq 0 ]

    run cache_value_equals "$test_dir" "LIBRA_OPT_INLINE" "ON"
    [ "$status" -eq 0 ]
}

@test "OPT_INLINE: Can change value on reconfiguration" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_INLINE=ON)

    run cache_value_equals "$test_dir" "LIBRA_OPT_INLINE" "ON"
    [ "$status" -eq 0 ]

    cd "$test_dir"
    run cmake "$BATS_TEST_DIRNAME/sample_build_info" -DLIBRA_OPT_INLINE=OFF --log-level=ERROR
    [ "$status" -eq 0 ]

    run cache_value_equals "$test_dir" "LIBRA_OPT_INLINE" "OFF"
    [ "$status" -eq 0 ]
}
