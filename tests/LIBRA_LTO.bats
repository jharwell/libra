#!/usr/bin/env bats
#
# BATS tests for LIBRA_LTO (Link-Time Optimisation)
#
# LIBRA_LTO controls whether inter-procedural/link-time optimisation is enabled:
#   - ON:  Sets INTERPROCEDURAL_OPTIMIZATION=TRUE on the target, which causes
#          cmake to inject -flto (GNU/Clang) or -ipo (Intel) into flags.make
#   - OFF: INTERPROCEDURAL_OPTIMIZATION is not set; no LTO/IPO flags added
#
# Unlike most flags, LTO is not recorded in build_info — it is injected by
# cmake directly into CMakeFiles/<target>.dir/flags.make.  The target in
# sample_build_info is always named "sample_build_info".
#
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

@test "LTO: GNU/C ON injects LTO flags into flags.make" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_LTO=ON)

    run has_lto_flag "$test_dir"
    [ "$status" -eq 0 ]
}

@test "LTO: GNU/C OFF does not inject LTO flags into flags.make" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_LTO=OFF)

    run has_lto_flag "$test_dir"
    [ "$status" -ne 0 ]
}

# ------------------------------------------------------------------------------
# GNU compiler - C++
# ------------------------------------------------------------------------------

@test "LTO: GNU/C++ ON injects LTO flags into flags.make" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_LTO=ON)

    run has_lto_flag "$test_dir"
    [ "$status" -eq 0 ]
}

@test "LTO: GNU/C++ OFF does not inject LTO flags into flags.make" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_LTO=OFF)

    run has_lto_flag "$test_dir"
    [ "$status" -ne 0 ]
}

# ------------------------------------------------------------------------------
# Clang compiler - C
# ------------------------------------------------------------------------------

@test "LTO: Clang/C ON injects LTO flags into flags.make" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_LTO=ON)

    run has_lto_flag "$test_dir"
    [ "$status" -eq 0 ]
}

@test "LTO: Clang/C OFF does not inject LTO flags into flags.make" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_LTO=OFF)

    run has_lto_flag "$test_dir"
    [ "$status" -ne 0 ]
}

# ------------------------------------------------------------------------------
# Clang compiler - C++
# ------------------------------------------------------------------------------

@test "LTO: Clang/C++ ON injects LTO flags into flags.make" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_LTO=ON)

    run has_lto_flag "$test_dir"
    [ "$status" -eq 0 ]
}

@test "LTO: Clang/C++ OFF does not inject LTO flags into flags.make" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_LTO=OFF)

    run has_lto_flag "$test_dir"
    [ "$status" -ne 0 ]
}

# ------------------------------------------------------------------------------
# Intel compiler - C
# ------------------------------------------------------------------------------

@test "LTO: Intel/C ON injects LTO flags into flags.make" {
    skip_if_compiler_missing "intel" "c"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_LTO=ON)

    run has_lto_flag "$test_dir"
    [ "$status" -eq 0 ]
}

@test "LTO: Intel/C OFF does not inject LTO flags into flags.make" {
    skip_if_compiler_missing "intel" "c"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_LTO=OFF)

    run has_lto_flag "$test_dir"
    [ "$status" -ne 0 ]
}

# ------------------------------------------------------------------------------
# Intel compiler - C++
# ------------------------------------------------------------------------------

@test "LTO: Intel/C++ ON injects LTO flags into flags.make" {
    skip_if_compiler_missing "intel" "cxx"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_LTO=ON)

    run has_lto_flag "$test_dir"
    [ "$status" -eq 0 ]
}

@test "LTO: Intel/C++ OFF does not inject LTO flags into flags.make" {
    skip_if_compiler_missing "intel" "cxx"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_LTO=OFF)

    run has_lto_flag "$test_dir"
    [ "$status" -ne 0 ]
}

# ------------------------------------------------------------------------------
# Default behaviour
# ------------------------------------------------------------------------------

@test "LTO: Default (unset) does not inject LTO flags" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c")

    run has_lto_flag "$test_dir"
    [ "$status" -ne 0 ]
}
