#!/usr/bin/env bats
#
# BATS tests for LIBRA_NATIVE_OPT
#
# LIBRA_NATIVE_OPT controls whether the compiler optimises for the host CPU:
#   - ON:  Adds compiler-specific native-tuning flags (compile flags)
#   - OFF: No native-tuning flags added (default)
#
# Per-compiler flags when ON:
#   GNU:   -march=native -mtune=native
#   Clang: -march=native -mtune=native
#   Intel: -xHost
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

@test "NATIVE_OPT: GNU/C ON adds -march=native" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_NATIVE_OPT=ON)

    assert_compile_flag_present "$test_dir" "c" "-march=native"
}

@test "NATIVE_OPT: GNU/C ON adds -mtune=native" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_NATIVE_OPT=ON)

    assert_compile_flag_present "$test_dir" "c" "-mtune=native"
}

@test "NATIVE_OPT: GNU/C OFF does not add -march=native" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_NATIVE_OPT=OFF)

    assert_compile_flag_absent "$test_dir" "c" "-march=native"
}

@test "NATIVE_OPT: GNU/C OFF does not add -mtune=native" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_NATIVE_OPT=OFF)

    assert_compile_flag_absent "$test_dir" "c" "-mtune=native"
}

# ------------------------------------------------------------------------------
# GNU compiler - C++
# ------------------------------------------------------------------------------

@test "NATIVE_OPT: GNU/C++ ON adds -march=native" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_NATIVE_OPT=ON)

    assert_compile_flag_present "$test_dir" "cxx" "-march=native"
}

@test "NATIVE_OPT: GNU/C++ ON adds -mtune=native" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_NATIVE_OPT=ON)

    assert_compile_flag_present "$test_dir" "cxx" "-mtune=native"
}

@test "NATIVE_OPT: GNU/C++ OFF does not add -march=native" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_NATIVE_OPT=OFF)

    assert_compile_flag_absent "$test_dir" "cxx" "-march=native"
}

@test "NATIVE_OPT: GNU/C++ OFF does not add -mtune=native" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_NATIVE_OPT=OFF)

    assert_compile_flag_absent "$test_dir" "cxx" "-mtune=native"
}

# ------------------------------------------------------------------------------
# Clang compiler - C
# ------------------------------------------------------------------------------

@test "NATIVE_OPT: Clang/C ON adds -march=native" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_NATIVE_OPT=ON)

    assert_compile_flag_present "$test_dir" "c" "-march=native"
}

@test "NATIVE_OPT: Clang/C ON adds -mtune=native" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_NATIVE_OPT=ON)

    assert_compile_flag_present "$test_dir" "c" "-mtune=native"
}

@test "NATIVE_OPT: Clang/C OFF does not add -march=native" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_NATIVE_OPT=OFF)

    assert_compile_flag_absent "$test_dir" "c" "-march=native"
}

@test "NATIVE_OPT: Clang/C OFF does not add -mtune=native" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_NATIVE_OPT=OFF)

    assert_compile_flag_absent "$test_dir" "c" "-mtune=native"
}

# ------------------------------------------------------------------------------
# Clang compiler - C++
# ------------------------------------------------------------------------------

@test "NATIVE_OPT: Clang/C++ ON adds -march=native" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_NATIVE_OPT=ON)

    assert_compile_flag_present "$test_dir" "cxx" "-march=native"
}

@test "NATIVE_OPT: Clang/C++ ON adds -mtune=native" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_NATIVE_OPT=ON)

    assert_compile_flag_present "$test_dir" "cxx" "-mtune=native"
}

@test "NATIVE_OPT: Clang/C++ OFF does not add -march=native" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_NATIVE_OPT=OFF)

    assert_compile_flag_absent "$test_dir" "cxx" "-march=native"
}

@test "NATIVE_OPT: Clang/C++ OFF does not add -mtune=native" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_NATIVE_OPT=OFF)

    assert_compile_flag_absent "$test_dir" "cxx" "-mtune=native"
}

# ------------------------------------------------------------------------------
# Intel compiler - C
# ------------------------------------------------------------------------------

@test "NATIVE_OPT: Intel/C ON adds -xHost" {
    skip_if_compiler_missing "intel" "c"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_NATIVE_OPT=ON)

    assert_compile_flag_present "$test_dir" "c" "-xHost"
}

@test "NATIVE_OPT: Intel/C OFF does not add -xHost" {
    skip_if_compiler_missing "intel" "c"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_NATIVE_OPT=OFF)

    assert_compile_flag_absent "$test_dir" "c" "-xHost"
}

# ------------------------------------------------------------------------------
# Intel compiler - C++
# ------------------------------------------------------------------------------

@test "NATIVE_OPT: Intel/C++ ON adds -xHost" {
    skip_if_compiler_missing "intel" "cxx"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_NATIVE_OPT=ON)

    assert_compile_flag_present "$test_dir" "cxx" "-xHost"
}

@test "NATIVE_OPT: Intel/C++ OFF does not add -xHost" {
    skip_if_compiler_missing "intel" "cxx"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_NATIVE_OPT=OFF)

    assert_compile_flag_absent "$test_dir" "cxx" "-xHost"
}

# ------------------------------------------------------------------------------
# Default behaviour
# ------------------------------------------------------------------------------

@test "NATIVE_OPT: Default (unset) does not add native flags" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c")

    assert_compile_flag_absent "$test_dir" "c" "-march=native"
    assert_compile_flag_absent "$test_dir" "c" "-mtune=native"
}
