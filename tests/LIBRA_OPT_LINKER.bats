#!/usr/bin/env bats
#
# BATS tests for LIBRA_OPT_LINKER
#
# LIBRA_OPT_LINKER controls whether the linker dead-strips unused sections:
#   - ON:  Adds -ffunction-sections -fdata-sections (compile flags) and
#               -Wl,--gc-sections (link flags) for all compilers
#   - OFF: No flags added (default)
#
# -ffunction-sections / -fdata-sections land in COMPILE_FLAGS.
# -Wl,--gc-sections lands in LINK_FLAGS in the generated build_info file.
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

@test "OPT_LINKER: GNU/C ON adds -ffunction-sections to compile flags" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_LINKER=ON)

    assert_compile_flag_present "$test_dir" "c" "-ffunction-sections"
}

@test "OPT_LINKER: GNU/C ON adds -fdata-sections to compile flags" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_LINKER=ON)

    assert_compile_flag_present "$test_dir" "c" "-fdata-sections"
}

@test "OPT_LINKER: GNU/C ON adds -Wl,--gc-sections to link flags" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_LINKER=ON)

    assert_link_flag_present "$test_dir" "c" "-Wl,--gc-sections"
}

@test "OPT_LINKER: GNU/C OFF does not add -ffunction-sections" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_LINKER=OFF)

    assert_compile_flag_absent "$test_dir" "c" "-ffunction-sections"
}

@test "OPT_LINKER: GNU/C OFF does not add -fdata-sections" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_LINKER=OFF)

    assert_compile_flag_absent "$test_dir" "c" "-fdata-sections"
}

@test "OPT_LINKER: GNU/C OFF does not add -Wl,--gc-sections to link flags" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_LINKER=OFF)

    assert_link_flag_absent "$test_dir" "c" "-Wl,--gc-sections"
}

# ------------------------------------------------------------------------------
# GNU compiler - C++
# ------------------------------------------------------------------------------

@test "OPT_LINKER: GNU/C++ ON adds -ffunction-sections to compile flags" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_LINKER=ON)

    assert_compile_flag_present "$test_dir" "cxx" "-ffunction-sections"
}

@test "OPT_LINKER: GNU/C++ ON adds -fdata-sections to compile flags" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_LINKER=ON)

    assert_compile_flag_present "$test_dir" "cxx" "-fdata-sections"
}

@test "OPT_LINKER: GNU/C++ ON adds -Wl,--gc-sections to link flags" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_LINKER=ON)

    assert_link_flag_present "$test_dir" "cxx" "-Wl,--gc-sections"
}

@test "OPT_LINKER: GNU/C++ OFF does not add -ffunction-sections" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_LINKER=OFF)

    assert_compile_flag_absent "$test_dir" "cxx" "-ffunction-sections"
}

@test "OPT_LINKER: GNU/C++ OFF does not add -Wl,--gc-sections to link flags" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_LINKER=OFF)

    assert_link_flag_absent "$test_dir" "cxx" "-Wl,--gc-sections"
}

# ------------------------------------------------------------------------------
# Clang compiler - C
# ------------------------------------------------------------------------------

@test "OPT_LINKER: Clang/C ON adds -ffunction-sections to compile flags" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_LINKER=ON)

    assert_compile_flag_present "$test_dir" "c" "-ffunction-sections"
}

@test "OPT_LINKER: Clang/C ON adds -fdata-sections to compile flags" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_LINKER=ON)

    assert_compile_flag_present "$test_dir" "c" "-fdata-sections"
}

@test "OPT_LINKER: Clang/C ON adds -Wl,--gc-sections to link flags" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_LINKER=ON)

    assert_link_flag_present "$test_dir" "c" "-Wl,--gc-sections"
}

@test "OPT_LINKER: Clang/C OFF does not add -ffunction-sections" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_LINKER=OFF)

    assert_compile_flag_absent "$test_dir" "c" "-ffunction-sections"
}

@test "OPT_LINKER: Clang/C OFF does not add -Wl,--gc-sections to link flags" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_LINKER=OFF)

    assert_link_flag_absent "$test_dir" "c" "-Wl,--gc-sections"
}

# ------------------------------------------------------------------------------
# Clang compiler - C++
# ------------------------------------------------------------------------------

@test "OPT_LINKER: Clang/C++ ON adds -ffunction-sections to compile flags" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_LINKER=ON)

    assert_compile_flag_present "$test_dir" "cxx" "-ffunction-sections"
}

@test "OPT_LINKER: Clang/C++ ON adds -Wl,--gc-sections to link flags" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_LINKER=ON)

    assert_link_flag_present "$test_dir" "cxx" "-Wl,--gc-sections"
}

@test "OPT_LINKER: Clang/C++ OFF does not add -ffunction-sections" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_LINKER=OFF)

    assert_compile_flag_absent "$test_dir" "cxx" "-ffunction-sections"
}

@test "OPT_LINKER: Clang/C++ OFF does not add -Wl,--gc-sections to link flags" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_LINKER=OFF)

    assert_link_flag_absent "$test_dir" "cxx" "-Wl,--gc-sections"
}

# ------------------------------------------------------------------------------
# Intel compiler - C
# ------------------------------------------------------------------------------

@test "OPT_LINKER: Intel/C ON adds -ffunction-sections to compile flags" {
    skip_if_compiler_missing "intel" "c"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_LINKER=ON)

    assert_compile_flag_present "$test_dir" "c" "-ffunction-sections"
}

@test "OPT_LINKER: Intel/C ON adds -fdata-sections to compile flags" {
    skip_if_compiler_missing "intel" "c"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_LINKER=ON)

    assert_compile_flag_present "$test_dir" "c" "-fdata-sections"
}

@test "OPT_LINKER: Intel/C ON adds -Wl,--gc-sections to link flags" {
    skip_if_compiler_missing "intel" "c"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_LINKER=ON)

    assert_link_flag_present "$test_dir" "c" "-Wl,--gc-sections"
}

@test "OPT_LINKER: Intel/C OFF does not add -ffunction-sections" {
    skip_if_compiler_missing "intel" "c"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_LINKER=OFF)

    assert_compile_flag_absent "$test_dir" "c" "-ffunction-sections"
}

@test "OPT_LINKER: Intel/C OFF does not add -Wl,--gc-sections to link flags" {
    skip_if_compiler_missing "intel" "c"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_LINKER=OFF)

    assert_link_flag_absent "$test_dir" "c" "-Wl,--gc-sections"
}

# ------------------------------------------------------------------------------
# Intel compiler - C++
# ------------------------------------------------------------------------------

@test "OPT_LINKER: Intel/C++ ON adds -ffunction-sections to compile flags" {
    skip_if_compiler_missing "intel" "cxx"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_LINKER=ON)

    assert_compile_flag_present "$test_dir" "cxx" "-ffunction-sections"
}

@test "OPT_LINKER: Intel/C++ ON adds -Wl,--gc-sections to link flags" {
    skip_if_compiler_missing "intel" "cxx"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_LINKER=ON)

    assert_link_flag_present "$test_dir" "cxx" "-Wl,--gc-sections"
}

@test "OPT_LINKER: Intel/C++ OFF does not add -ffunction-sections" {
    skip_if_compiler_missing "intel" "cxx"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_LINKER=OFF)

    assert_compile_flag_absent "$test_dir" "cxx" "-ffunction-sections"
}

@test "OPT_LINKER: Intel/C++ OFF does not add -Wl,--gc-sections to link flags" {
    skip_if_compiler_missing "intel" "cxx"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_LINKER=OFF)

    assert_link_flag_absent "$test_dir" "cxx" "-Wl,--gc-sections"
}

# ------------------------------------------------------------------------------
# Default behaviour
# ------------------------------------------------------------------------------

@test "OPT_LINKER: Default (unset) does not add section flags" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c")

    assert_compile_flag_absent "$test_dir" "c" "-ffunction-sections"
    assert_compile_flag_absent "$test_dir" "c" "-fdata-sections"
    assert_link_flag_absent    "$test_dir" "c" "-Wl,--gc-sections"
}

@test "OPT_LINKER: Cache variable persists across reconfiguration" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_LINKER=ON)

    run cache_value_equals "$test_dir" "LIBRA_OPT_LINKER" "ON"
    [ "$status" -eq 0 ]

    cd "$test_dir"
    run cmake "$BATS_TEST_DIRNAME/sample_build_info" --log-level=ERROR
    [ "$status" -eq 0 ]

    run cache_value_equals "$test_dir" "LIBRA_OPT_LINKER" "ON"
    [ "$status" -eq 0 ]
}

@test "OPT_LINKER: Can change value on reconfiguration" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_LINKER=ON)

    run cache_value_equals "$test_dir" "LIBRA_OPT_LINKER" "ON"
    [ "$status" -eq 0 ]

    cd "$test_dir"
    run cmake "$BATS_TEST_DIRNAME/sample_build_info" -DLIBRA_OPT_LINKER=OFF --log-level=ERROR
    [ "$status" -eq 0 ]

    run cache_value_equals "$test_dir" "LIBRA_OPT_LINKER" "OFF"
    [ "$status" -eq 0 ]
}
