#!/usr/bin/env bats
#
# BATS tests for LIBRA_OPT_REPORT
#
# LIBRA_OPT_REPORT controls whether the compiler emits optimisation reports:
#   - ON:  Adds compiler-specific optimisation-report flags (compile flags)
#   - OFF: No optimisation-report flags added (default)
#
# Per-compiler flags when ON:
#   Clang: -Rpass=.* -Rpass-missed=.* -Rpass-analysis=.* -fsave-optimization-record
#   Intel: -qopt-report=3 -qopt-report-phase=all
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
# Clang compiler - C
# ------------------------------------------------------------------------------

@test "OPT_REPORT: Clang/C ON adds -Rpass=.*" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_REPORT=ON)

    assert_compile_flag_present "$test_dir" "c" "-Rpass=.*"
}

@test "OPT_REPORT: Clang/C ON adds -Rpass-missed=.*" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_REPORT=ON)

    assert_compile_flag_present "$test_dir" "c" "-Rpass-missed=.*"
}

@test "OPT_REPORT: Clang/C ON adds -Rpass-analysis=.*" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_REPORT=ON)

    assert_compile_flag_present "$test_dir" "c" "-Rpass-analysis=.*"
}

@test "OPT_REPORT: Clang/C ON adds -fsave-optimization-record" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_REPORT=ON)

    assert_compile_flag_present "$test_dir" "c" "-fsave-optimization-record"
}

@test "OPT_REPORT: Clang/C OFF does not add -Rpass" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_REPORT=OFF)

    assert_compile_flag_absent "$test_dir" "c" "-Rpass"
}

@test "OPT_REPORT: Clang/C OFF does not add -fsave-optimization-record" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_REPORT=OFF)

    assert_compile_flag_absent "$test_dir" "c" "-fsave-optimization-record"
}

# ------------------------------------------------------------------------------
# Clang compiler - C++
# ------------------------------------------------------------------------------

@test "OPT_REPORT: Clang/C++ ON adds -Rpass=.*" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_REPORT=ON)

    assert_compile_flag_present "$test_dir" "cxx" "-Rpass=.*"
}

@test "OPT_REPORT: Clang/C++ ON adds -Rpass-missed=.*" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_REPORT=ON)

    assert_compile_flag_present "$test_dir" "cxx" "-Rpass-missed=.*"
}

@test "OPT_REPORT: Clang/C++ ON adds -Rpass-analysis=.*" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_REPORT=ON)

    assert_compile_flag_present "$test_dir" "cxx" "-Rpass-analysis=.*"
}

@test "OPT_REPORT: Clang/C++ ON adds -fsave-optimization-record" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_REPORT=ON)

    assert_compile_flag_present "$test_dir" "cxx" "-fsave-optimization-record"
}

@test "OPT_REPORT: Clang/C++ OFF does not add -Rpass" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_REPORT=OFF)

    assert_compile_flag_absent "$test_dir" "cxx" "-Rpass"
}

@test "OPT_REPORT: Clang/C++ OFF does not add -fsave-optimization-record" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_REPORT=OFF)

    assert_compile_flag_absent "$test_dir" "cxx" "-fsave-optimization-record"
}

# ------------------------------------------------------------------------------
# Intel compiler - C
# ------------------------------------------------------------------------------

@test "OPT_REPORT: Intel/C ON adds -qopt-report=3" {
    skip_if_compiler_missing "intel" "c"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_REPORT=ON)

    assert_compile_flag_present "$test_dir" "c" "-qopt-report=3"
}

@test "OPT_REPORT: Intel/C ON adds -qopt-report-phase=all" {
    skip_if_compiler_missing "intel" "c"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_REPORT=ON)

    assert_compile_flag_present "$test_dir" "c" "-qopt-report-phase=all"
}

@test "OPT_REPORT: Intel/C OFF does not add -qopt-report=3" {
    skip_if_compiler_missing "intel" "c"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_REPORT=OFF)

    assert_compile_flag_absent "$test_dir" "c" "-qopt-report=3"
}

@test "OPT_REPORT: Intel/C OFF does not add -qopt-report-phase=all" {
    skip_if_compiler_missing "intel" "c"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_REPORT=OFF)

    assert_compile_flag_absent "$test_dir" "c" "-qopt-report-phase=all"
}

# ------------------------------------------------------------------------------
# Intel compiler - C++
# ------------------------------------------------------------------------------

@test "OPT_REPORT: Intel/C++ ON adds -qopt-report=3" {
    skip_if_compiler_missing "intel" "cxx"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_REPORT=ON)

    assert_compile_flag_present "$test_dir" "cxx" "-qopt-report=3"
}

@test "OPT_REPORT: Intel/C++ ON adds -qopt-report-phase=all" {
    skip_if_compiler_missing "intel" "cxx"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_REPORT=ON)

    assert_compile_flag_present "$test_dir" "cxx" "-qopt-report-phase=all"
}

@test "OPT_REPORT: Intel/C++ OFF does not add -qopt-report=3" {
    skip_if_compiler_missing "intel" "cxx"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_REPORT=OFF)

    assert_compile_flag_absent "$test_dir" "cxx" "-qopt-report=3"
}

@test "OPT_REPORT: Intel/C++ OFF does not add -qopt-report-phase=all" {
    skip_if_compiler_missing "intel" "cxx"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_REPORT=OFF)

    assert_compile_flag_absent "$test_dir" "cxx" "-qopt-report-phase=all"
}

# ==============================================================================
# Clang — link flags with LIBRA_LTO=ON
#
# clang.cmake only sets _LIBRA_OPT_REPORT_LINK_OPTIONS when LIBRA_LTO is also
# enabled.  With LIBRA_LTO=OFF (default) the link flags are empty even when
# LIBRA_OPT_REPORT=ON.
# ==============================================================================

@test "OPT_REPORT: Clang/C ON+LTO adds -Rpass=.* to link flags" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" \
        -DLIBRA_OPT_REPORT=ON \
        -DLIBRA_LTO=ON \
        -DCMAKE_BUILD_TYPE=Release)

    assert_link_flag_present "$test_dir" "c" "-Rpass=.*"
}

@test "OPT_REPORT: Clang/C++ ON+LTO adds -Rpass=.* to link flags" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" \
        -DLIBRA_OPT_REPORT=ON \
        -DLIBRA_LTO=ON \
        -DCMAKE_BUILD_TYPE=Release)

    assert_link_flag_present "$test_dir" "cxx" "-Rpass=.*"
}

@test "OPT_REPORT: Clang/C ON without LTO does not add -Rpass to link flags" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" \
        -DLIBRA_OPT_REPORT=ON \
        -DLIBRA_LTO=OFF \
        -DCMAKE_BUILD_TYPE=Release)

    assert_link_flag_absent "$test_dir" "c" "-Rpass=.*"
}

# ==============================================================================
# GNU — documented no-op
#
# The GNU compiler has no optimisation-report flag equivalent.
# LIBRA_OPT_REPORT=ON with GNU must not add any extra flags.
# ==============================================================================

@test "OPT_REPORT: GNU/C ON does not add any optimisation-report flags" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_REPORT=ON)

    assert_compile_flag_absent "$test_dir" "c" "-Rpass"
    assert_compile_flag_absent "$test_dir" "c" "-fsave-optimization-record"
    assert_compile_flag_absent "$test_dir" "c" "-qopt-report"
}

@test "OPT_REPORT: GNU/C++ ON does not add any optimisation-report flags" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_OPT_REPORT=ON)

    assert_compile_flag_absent "$test_dir" "cxx" "-Rpass"
    assert_compile_flag_absent "$test_dir" "cxx" "-fsave-optimization-record"
    assert_compile_flag_absent "$test_dir" "cxx" "-qopt-report"
}

@test "OPT_REPORT: Cache variable persists across reconfiguration" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_REPORT=ON)

    run cache_value_equals "$test_dir" "LIBRA_OPT_REPORT" "ON"
    [ "$status" -eq 0 ]

    cd "$test_dir"
    run cmake "$BATS_TEST_DIRNAME/sample_build_info" --log-level=ERROR
    [ "$status" -eq 0 ]

    run cache_value_equals "$test_dir" "LIBRA_OPT_REPORT" "ON"
    [ "$status" -eq 0 ]
}

@test "OPT_REPORT: Can change value on reconfiguration" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_OPT_REPORT=ON)

    run cache_value_equals "$test_dir" "LIBRA_OPT_REPORT" "ON"
    [ "$status" -eq 0 ]

    cd "$test_dir"
    run cmake "$BATS_TEST_DIRNAME/sample_build_info" -DLIBRA_OPT_REPORT=OFF --log-level=ERROR
    [ "$status" -eq 0 ]

    run cache_value_equals "$test_dir" "LIBRA_OPT_REPORT" "OFF"
    [ "$status" -eq 0 ]
}
