#!/usr/bin/env bats
#
# BATS tests for LIBRA_GLOBAL_32BIT
#

load test_helpers

setup() {
    setup_libra_test
}

# ------------------------------------------------------------------------------
# GNU compiler - C
# ------------------------------------------------------------------------------

@test "32BIT: GNU/C ON injects 32BIT flags into flags.make" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_GLOBAL_32BIT=ON)

    assert_compile_command_flag_present "$test_dir"  -m32
}

@test "32BIT: GNU/C OFF does not inject 32BIT flags into flags.make" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_GLOBAL_32BIT=OFF)

    assert_compile_command_flag_absent "$test_dir"  -m32
}

# ------------------------------------------------------------------------------
# GNU compiler - C++
# ------------------------------------------------------------------------------

@test "32BIT: GNU/C++ ON injects 32BIT flags into flags.make" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_GLOBAL_32BIT=ON)

    assert_compile_command_flag_present "$test_dir"  -m32
}

@test "32BIT: GNU/C++ OFF does not inject 32BIT flags into flags.make" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_GLOBAL_32BIT=OFF)

    assert_compile_command_flag_absent "$test_dir"  -m32
}

# ------------------------------------------------------------------------------
# Clang compiler - C
# ------------------------------------------------------------------------------

@test "32BIT: CLANG/C ON injects 32BIT flags into flags.make" {
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_GLOBAL_32BIT=ON)

    assert_compile_command_flag_present "$test_dir"  -m32
}

@test "32BIT: CLANG/C OFF does not inject 32BIT flags into flags.make" {
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_GLOBAL_32BIT=OFF)

    assert_compile_command_flag_absent "$test_dir"  -m32
}

# ------------------------------------------------------------------------------
# CLANG compiler - C++
# ------------------------------------------------------------------------------

@test "32BIT: CLANG/C++ ON injects 32BIT flags into flags.make" {
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_GLOBAL_32BIT=ON)

    assert_compile_command_flag_present "$test_dir"  -m32
}

@test "32BIT: CLANG/C++ OFF does not inject 32BIT flags into flags.make" {
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_GLOBAL_32BIT=OFF)

    assert_compile_command_flag_absent "$test_dir" -m32
}

# ------------------------------------------------------------------------------
# Default behaviour
# ------------------------------------------------------------------------------

@test "32BIT: Default (unset) does not inject 32BIT flags" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c")

    assert_compile_command_flag_absent "$test_dir"  -m32
}

@test "32BIT: Cache variable persists across reconfiguration" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_GLOBAL_32BIT=ON)

    assert_cache_value "$test_dir" "LIBRA_GLOBAL_32BIT" "ON"

    cd "$test_dir"
    run cmake "$BATS_TEST_DIRNAME/sample_build_info" --log-level=ERROR
    assert_success

    assert_cache_value "$test_dir" "LIBRA_GLOBAL_32BIT" "ON"
}

@test "32BIT: Can change value on reconfiguration" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_GLOBAL_32BIT=ON)

    assert_cache_value "$test_dir" "LIBRA_GLOBAL_32BIT" "ON"

    cd "$test_dir"
    run cmake "$BATS_TEST_DIRNAME/sample_build_info" -DLIBRA_GLOBAL_32BIT=OFF --log-level=ERROR
    assert_success

    assert_cache_value "$test_dir" "LIBRA_GLOBAL_32BIT" "OFF"
}

# ==============================================================================
# build-types.cmake iterates over all four cmake build types; 32BIT must work
# correctly for all.
# ==============================================================================

@test "32BIT: GNU/C ON injects 32BIT flags in Debug build" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" \
                                    -DLIBRA_GLOBAL_32BIT=ON \
                                    -DCMAKE_BUILD_TYPE=Debug)

    assert_compile_command_flag_present "$test_dir"  -m32
}

@test "32BIT: GNU/C ON injects 32BIT flags in RelWithDebInfo build" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" \
                                    -DLIBRA_GLOBAL_32BIT=ON \
                                    -DCMAKE_BUILD_TYPE=RelWithDebInfo)

    assert_compile_command_flag_present "$test_dir"  -m32
}
@test "32BIT: GNU/C ON injects 32BIT flags in Release build" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" \
                                    -DLIBRA_GLOBAL_32BIT=ON \
                                    -DCMAKE_BUILD_TYPE=Release)

    assert_compile_command_flag_present "$test_dir"  -m32
}
@test "32BIT: GNU/C ON injects 32BIT flags in MinSizeRel build" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" \
                                    -DLIBRA_GLOBAL_32BIT=ON \
                                    -DCMAKE_BUILD_TYPE=MinSizeRel)

    assert_compile_command_flag_present "$test_dir"  -m32
}

@test "32BIT: GNU/C OFF does not inject 32BIT flags in Debug build" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" \
                                    -DLIBRA_GLOBAL_32BIT=OFF \
                                    -DCMAKE_BUILD_TYPE=Debug)

    assert_compile_command_flag_absent "$test_dir"  -m32
}

@test "32BIT: GNU/C OFF does not inject 32BIT flags in RelWithDebInfo build" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" \
                                    -DLIBRA_GLOBAL_32BIT=OFF \
                                    -DCMAKE_BUILD_TYPE=RelWithDebInfo)

    assert_compile_command_flag_absent "$test_dir"  -m32
}
@test "32BIT: GNU/C OFF does not inject 32BIT flags in Release build" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" \
                                    -DLIBRA_GLOBAL_32BIT=OFF \
                                    -DCMAKE_BUILD_TYPE=Release)

    assert_compile_command_flag_absent "$test_dir"  -m32
}
@test "32BIT: GNU/C OFF does not inject 32BIT flags in MinSizeRel build" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" \
                                    -DLIBRA_GLOBAL_32BIT=OFF \
                                    -DCMAKE_BUILD_TYPE=MinSizeRel)

    assert_compile_command_flag_absent "$test_dir"  -m32
}

@test "32BIT: CLANG/C ON injects 32BIT flags in Debug build" {
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" \
                                    -DLIBRA_GLOBAL_32BIT=ON \
                                    -DCMAKE_BUILD_TYPE=Debug)

    assert_compile_command_flag_present "$test_dir"  -m32
}

@test "32BIT: CLANG/C ON injects 32BIT flags in RelWithDebInfo build" {
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" \
                                    -DLIBRA_GLOBAL_32BIT=ON \
                                    -DCMAKE_BUILD_TYPE=RelWithDebInfo)

    assert_compile_command_flag_present "$test_dir"  -m32
}
@test "32BIT: CLANG/C ON injects 32BIT flags in Release build" {
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" \
                                    -DLIBRA_GLOBAL_32BIT=ON \
                                    -DCMAKE_BUILD_TYPE=Release)

    assert_compile_command_flag_present "$test_dir"  -m32
}
@test "32BIT: CLANG/C ON injects 32BIT flags in MinSizeRel build" {
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" \
                                    -DLIBRA_GLOBAL_32BIT=ON \
                                    -DCMAKE_BUILD_TYPE=MinSizeRel)

    assert_compile_command_flag_present "$test_dir"  -m32
}

@test "32BIT: CLANG/C OFF does not inject 32BIT flags in Debug build" {
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" \
                                    -DLIBRA_GLOBAL_32BIT=OFF \
                                    -DCMAKE_BUILD_TYPE=Debug)

    assert_compile_command_flag_absent "$test_dir"  -m32
}

@test "32BIT: CLANG/C OFF does not inject 32BIT flags in RelWithDebInfo build" {
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" \
                                    -DLIBRA_GLOBAL_32BIT=OFF \
                                    -DCMAKE_BUILD_TYPE=RelWithDebInfo)

    assert_compile_command_flag_absent "$test_dir"  -m32
}
@test "32BIT: CLANG/C OFF does not inject 32BIT flags in Release build" {
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" \
                                    -DLIBRA_GLOBAL_32BIT=OFF \
                                    -DCMAKE_BUILD_TYPE=Release)

    assert_compile_command_flag_absent "$test_dir"  -m32
}
@test "32BIT: CLANG/C OFF does not inject 32BIT flags in MinSizeRel build" {
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" \
                                    -DLIBRA_GLOBAL_32BIT=OFF \
                                    -DCMAKE_BUILD_TYPE=MinSizeRel)

    assert_compile_command_flag_absent "$test_dir"  -m32
}

