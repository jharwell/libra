#!/usr/bin/env bats
#
# BATS tests for LIBRA_OPT_NATIVE
#
# LIBRA_OPT_NATIVE controls whether the compiler optimises for the host CPU:
#   - ON:  Adds compiler-specific native-tuning flags (compile flags)
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

@test "OPT_NATIVE: GNU/C ON adds -march=native" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_NATIVE=ON)

    assert_compile_flag_present "$test_dir" "c" "-march=native"
}

@test "OPT_NATIVE: GNU/C ON adds -mtune=native" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_NATIVE=ON)

    assert_compile_flag_present "$test_dir" "c" "-mtune=native"
}

@test "OPT_NATIVE: GNU/C OFF does not add -march=native" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_NATIVE=OFF)

    assert_compile_flag_absent "$test_dir" "c" "-march=native"
}

@test "OPT_NATIVE: GNU/C OFF does not add -mtune=native" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_NATIVE=OFF)

    assert_compile_flag_absent "$test_dir" "c" "-mtune=native"
}

# ------------------------------------------------------------------------------
# GNU compiler - C++
# ------------------------------------------------------------------------------

@test "OPT_NATIVE: GNU/C++ ON adds -march=native" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_NATIVE=ON)

    assert_compile_flag_present "$test_dir" "cxx" "-march=native"
}

@test "OPT_NATIVE: GNU/C++ ON adds -mtune=native" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_NATIVE=ON)

    assert_compile_flag_present "$test_dir" "cxx" "-mtune=native"
}

@test "OPT_NATIVE: GNU/C++ OFF does not add -march=native" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_NATIVE=OFF)

    assert_compile_flag_absent "$test_dir" "cxx" "-march=native"
}

@test "OPT_NATIVE: GNU/C++ OFF does not add -mtune=native" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_NATIVE=OFF)

    assert_compile_flag_absent "$test_dir" "cxx" "-mtune=native"
}

# ------------------------------------------------------------------------------
# Clang compiler - C
# ------------------------------------------------------------------------------

@test "OPT_NATIVE: Clang/C ON adds -march=native" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_NATIVE=ON)

    assert_compile_flag_present "$test_dir" "c" "-march=native"
}

@test "OPT_NATIVE: Clang/C ON adds -mtune=native" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_NATIVE=ON)

    assert_compile_flag_present "$test_dir" "c" "-mtune=native"
}

@test "OPT_NATIVE: Clang/C OFF does not add -march=native" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_NATIVE=OFF)

    assert_compile_flag_absent "$test_dir" "c" "-march=native"
}

@test "OPT_NATIVE: Clang/C OFF does not add -mtune=native" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_NATIVE=OFF)

    assert_compile_flag_absent "$test_dir" "c" "-mtune=native"
}

# ------------------------------------------------------------------------------
# Clang compiler - C++
# ------------------------------------------------------------------------------

@test "OPT_NATIVE: Clang/C++ ON adds -march=native" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_NATIVE=ON)

    assert_compile_flag_present "$test_dir" "cxx" "-march=native"
}

@test "OPT_NATIVE: Clang/C++ ON adds -mtune=native" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_NATIVE=ON)

    assert_compile_flag_present "$test_dir" "cxx" "-mtune=native"
}

@test "OPT_NATIVE: Clang/C++ OFF does not add -march=native" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_NATIVE=OFF)

    assert_compile_flag_absent "$test_dir" "cxx" "-march=native"
}

@test "OPT_NATIVE: Clang/C++ OFF does not add -mtune=native" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_NATIVE=OFF)

    assert_compile_flag_absent "$test_dir" "cxx" "-mtune=native"
}

# ------------------------------------------------------------------------------
# Intel compiler - C
# ------------------------------------------------------------------------------

@test "OPT_NATIVE: Intel/C ON adds optimization options" {
    skip_if_compiler_missing "intel" "c"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_NATIVE=ON)

    # -xHost is rejected on non-intel CPUs
    assert_compile_flag_present "$test_dir" "c" "-xHost" ||
        assert_compile_flag_present "$test_dir" "c" "-march=native"
}

@test "OPT_NATIVE: Intel/C OFF does not add optimization options" {
    skip_if_compiler_missing "intel" "c"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_NATIVE=OFF)

    assert_compile_flag_absent "$test_dir" "c" "-xHost" &&
        assert_compile_flag_absent "$test_dir" "c" "-march=native"
}

# ------------------------------------------------------------------------------
# Intel compiler - C++
# ------------------------------------------------------------------------------

@test "OPT_NATIVE: Intel/C++ ON adds optimization options" {
    skip_if_compiler_missing "intel" "cxx"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_NATIVE=ON)

    # -xHost is rejected on non-intel CPUs
    assert_compile_flag_present "$test_dir" "cxx" "-xHost" ||
        assert_compile_flag_present "$test_dir" "cxx" "-march=native"
}

@test "OPT_NATIVE: Intel/C++ OFF does not add optimization options" {
    skip_if_compiler_missing "intel" "cxx"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_NATIVE=OFF)

    assert_compile_flag_absent "$test_dir" "cxx" "-xHost" &&
        assert_compile_flag_absent "$test_dir" "cxx" "-march=native"
}

# ------------------------------------------------------------------------------
# Default behaviour
# ------------------------------------------------------------------------------

@test "OPT_NATIVE: Default (unset) does not add native flags" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c")

    assert_compile_flag_absent "$test_dir" "c" "-march=native"
    assert_compile_flag_absent "$test_dir" "c" "-mtune=native"
}

@test "OPT_NATIVE: Cache variable persists across reconfiguration" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_NATIVE=ON)

    assert_cache_value "$test_dir" "LIBRA_OPT_NATIVE" "ON"

    cd "$test_dir"
    run cmake "$BATS_TEST_DIRNAME/sample_build_info" --log-level=ERROR
    assert_success

    assert_cache_value "$test_dir" "LIBRA_OPT_NATIVE" "ON"
}

@test "OPT_NATIVE: Can change value on reconfiguration" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_NATIVE=ON)

    assert_cache_value "$test_dir" "LIBRA_OPT_NATIVE" "ON"

    cd "$test_dir"
    run cmake "$BATS_TEST_DIRNAME/sample_build_info" -DLIBRA_OPT_NATIVE=OFF --log-level=ERROR
    assert_success

    assert_cache_value "$test_dir" "LIBRA_OPT_NATIVE" "OFF"
}
