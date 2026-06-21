#!/usr/bin/env bats
#
# BATS tests for LIBRA_PERF_OPT
#
# LIBRA_PERF_OPT controls whether the compiler optimises for the host CPU:
#   - ON:  Adds compiler-specific flags (compile flags)
#   - OFF: No native-tuning flags added (default)
#
# All flags land in COMPILE_FLAGS in the generated build_info file.
# Build type: Release (same as the shell test)
#

load test_helpers

setup() {
    setup_libra_test
    export CMAKE_BUILD_TYPE=Release
}

# ------------------------------------------------------------------------------
# GNU compiler - C
# ------------------------------------------------------------------------------

@test "PERF_OPT: GNU/C ON adds -fno-stack-protector" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_NO_GUARDS=ON)

    assert_compile_flag_present "$test_dir" "c" "-fno-stack-protector"
}

@test "PERF_OPT: GNU/C ON adds -fomit-frame-pointer" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_NO_GUARDS=ON)

    assert_compile_flag_present "$test_dir" "c" "-fomit-frame-pointer"
}

@test "PERF_OPT: GNU/C OFF does not add -fno-stack-protector" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_NO_GUARDS=OFF)

    assert_compile_flag_absent "$test_dir" "c" "-fno-stack-protector"
}

@test "PERF_OPT: GNU/C OFF does not add -fomit-frame-pointer" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_NO_GUARDS=OFF)

    assert_compile_flag_absent "$test_dir" "c" "-fomit-frame-pointer"
}

# ------------------------------------------------------------------------------
# GNU compiler - C++
# ------------------------------------------------------------------------------

@test "PERF_OPT: GNU/C++ ON adds -fno-stack-protector" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_NO_GUARDS=ON)

    assert_compile_flag_present "$test_dir" "cxx" "-fno-stack-protector"
}

@test "PERF_OPT: GNU/C++ ON adds -fomit-frame-pointer" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_NO_GUARDS=ON)

    assert_compile_flag_present "$test_dir" "cxx" "-fomit-frame-pointer"
}

@test "PERF_OPT: GNU/C++ OFF does not add -fno-stack-protector" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_NO_GUARDS=OFF)

    assert_compile_flag_absent "$test_dir" "cxx" "-fno-stack-protector"
}

@test "PERF_OPT: GNU/C++ OFF does not add -fomit-frame-pointer" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_NO_GUARDS=OFF)

    assert_compile_flag_absent "$test_dir" "cxx" "-fomit-frame-pointer"
}

# ------------------------------------------------------------------------------
# Clang compiler - C
# ------------------------------------------------------------------------------

@test "PERF_OPT: Clang/C ON adds -fno-stack-protector" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_NO_GUARDS=ON)

    assert_compile_flag_present "$test_dir" "c" "-fno-stack-protector"
}

@test "PERF_OPT: Clang/C ON adds -fomit-frame-pointer" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_NO_GUARDS=ON)

    assert_compile_flag_present "$test_dir" "c" "-fomit-frame-pointer"
}

@test "PERF_OPT: Clang/C OFF does not add -fno-stack-protector" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_NO_GUARDS=OFF)

    assert_compile_flag_absent "$test_dir" "c" "-fno-stack-protector"
}

@test "PERF_OPT: Clang/C OFF does not add -fomit-frame-pointer" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_NO_GUARDS=OFF)

    assert_compile_flag_absent "$test_dir" "c" "-fomit-frame-pointer"
}

# ------------------------------------------------------------------------------
# Clang compiler - C++
# ------------------------------------------------------------------------------

@test "PERF_OPT: Clang/C++ ON adds -fno-stack-protector" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_NO_GUARDS=ON)

    assert_compile_flag_present "$test_dir" "cxx" "-fno-stack-protector"
}

@test "PERF_OPT: Clang/C++ ON adds -fomit-frame-pointer" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_NO_GUARDS=ON)

    assert_compile_flag_present "$test_dir" "cxx" "-fomit-frame-pointer"
}

@test "PERF_OPT: Clang/C++ OFF does not add -fno-stack-protector" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_NO_GUARDS=OFF)

    assert_compile_flag_absent "$test_dir" "cxx" "-fno-stack-protector"
}

@test "PERF_OPT: Clang/C++ OFF does not add -fomit-frame-pointer" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_NO_GUARDS=OFF)

    assert_compile_flag_absent "$test_dir" "cxx" "-fomit-frame-pointer"
}

# ------------------------------------------------------------------------------
# Intel compiler - C
# ------------------------------------------------------------------------------

@test "PERF_OPT: Intel/C ON adds -fomit-frame-pointer" {
    skip_if_compiler_missing "intel" "c"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_NO_GUARDS=ON)

    assert_compile_flag_present "$test_dir" "c" "-fomit-frame-pointer"
}

@test "PERF_OPT: Intel/C ON adds -fno-stack-protector" {
    skip_if_compiler_missing "intel" "c"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_NO_GUARDS=ON)

    assert_compile_flag_present "$test_dir" "c" "-fno-stack-protector"
}

@test "PERF_OPT: Intel/C OFF does not add -fomit-frame-pointer" {
    skip_if_compiler_missing "intel" "c"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_NO_GUARDS=OFF)

    assert_compile_flag_absent "$test_dir" "c" "-fomit-frame-pointer"
}

@test "PERF_OPT: Intel/C OFF does not add -fno-stack-protector" {
    skip_if_compiler_missing "intel" "c"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_NO_GUARDS=OFF)

    assert_compile_flag_absent "$test_dir" "c" "-fno-stack-protector"
}

# ------------------------------------------------------------------------------
# Intel compiler - C++
# ------------------------------------------------------------------------------

@test "PERF_OPT: Intel/C++ ON adds -fomit-frame-pointer" {
    skip_if_compiler_missing "intel" "cxx"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_NO_GUARDS=ON)

    assert_compile_flag_present "$test_dir" "cxx" "-fomit-frame-pointer"
}

@test "PERF_OPT: Intel/C++ ON adds -fno-stack-protector" {
    skip_if_compiler_missing "intel" "cxx"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_NO_GUARDS=ON)

    assert_compile_flag_present "$test_dir" "cxx" "-fno-stack-protector"
}

@test "PERF_OPT: Intel/C++ OFF does not add -fomit-frame-pointer" {
    skip_if_compiler_missing "intel" "cxx"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_NO_GUARDS=OFF)

    assert_compile_flag_absent "$test_dir" "cxx" "-fomit-frame-pointer"
}

@test "PERF_OPT: Intel/C++ OFF does not add -fno-stack-protector" {
    skip_if_compiler_missing "intel" "cxx"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_NO_GUARDS=OFF)

    assert_compile_flag_absent "$test_dir" "cxx" "-fno-stack-protector"
}

# ------------------------------------------------------------------------------
# Default behaviour
# ------------------------------------------------------------------------------

@test "PERF_OPT: Default (unset) does not add native flags" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c")

    assert_compile_flag_absent "$test_dir" "c" "-fno-stack-protector"
    assert_compile_flag_absent "$test_dir" "c" "-fomit-frame-pointer"
}

@test "PERF_OPT: Cache variable persists across reconfiguration" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_NO_GUARDS=ON)

    run cache_value_equals "$test_dir" "LIBRA_OPT_NO_GUARDS" "ON"
    [ "$status" -eq 0 ]

    cd "$test_dir"
    run cmake "$BATS_TEST_DIRNAME/sample_build_info" --log-level=ERROR
    [ "$status" -eq 0 ]

    run cache_value_equals "$test_dir" "LIBRA_OPT_NO_GUARDS" "ON"
    [ "$status" -eq 0 ]
}

@test "PERF_OPT: Can change value on reconfiguration" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_NO_GUARDS=ON)

    run cache_value_equals "$test_dir" "LIBRA_OPT_NO_GUARDS" "ON"
    [ "$status" -eq 0 ]

    cd "$test_dir"
    run cmake "$BATS_TEST_DIRNAME/sample_build_info" -DLIBRA_OPT_NO_GUARDS=OFF --log-level=ERROR
    [ "$status" -eq 0 ]

    run cache_value_equals "$test_dir" "LIBRA_OPT_NO_GUARDS" "OFF"
    [ "$status" -eq 0 ]
}
