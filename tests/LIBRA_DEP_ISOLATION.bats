#!/usr/bin/env bats
#
# BATS tests for LIBRA dependency isolation
#
# Verifies correct behavior when a root project and one of its dependencies
# both use LIBRA.  The structure under test is:
#
#   sample_dep_isolation/root/   <- root project, uses LIBRA directly
#   sample_dep_isolation/dep/    <- dependency, also uses LIBRA, pulled in via
#                                   add_subdirectory() from root
#
# Three properties are verified:
#
#   (a) ROOT TARGETS PRESENT: All LIBRA special targets (analyze, fix,
#       coverage, etc.) are created for the root project as normal.
#
#   (b) DEP TARGET ISOLATION: No duplicate LIBRA special targets are created
#       for the dep project.  LIBRA uses NOT TARGET guards to skip creating
#       targets that already exist.  This verifies those guards fire correctly
#       -- if they didn't, cmake would error with "target already exists".
#
#   (c) FLAG ISOLATION: Build flags set on the root (sanitizers, etc.) are
#       scoped to the root target and do not appear on dep targets unless
#       explicitly propagated.
#

load test_helpers

setup() {
    setup_libra_test
    export CMAKE_BUILD_TYPE=Debug
}

# ==============================================================================
# Basic structure: cmake configure + build succeeds
# ==============================================================================

@test "DEP_ISOLATION: C - root+dep project configures and builds" {
    test_dir=$(run_libra_cmake_dep_test "c")
    [ -n "$test_dir" ]
}

@test "DEP_ISOLATION: C++ - root+dep project configures and builds" {
    test_dir=$(run_libra_cmake_dep_test "cxx")
    [ -n "$test_dir" ]
}

# ==============================================================================
# (a) Root targets present: LIBRA_ANALYSIS
# ==============================================================================

@test "DEP_ISOLATION: LIBRA_ANALYSIS=ON - root has analyze target" {
    test_dir=$(run_libra_cmake_dep_test "c" -DLIBRA_ANALYSIS=ON)

    assert_target_exists "$test_dir" "analyze"
}

@test "DEP_ISOLATION: LIBRA_ANALYSIS=ON - root has fix target" {
    test_dir=$(run_libra_cmake_dep_test "c" -DLIBRA_ANALYSIS=ON)

    assert_target_exists "$test_dir" "fix"
}

@test "DEP_ISOLATION: LIBRA_ANALYSIS=ON - all root analysis targets present" {
    test_dir=$(run_libra_cmake_dep_test "c" -DLIBRA_ANALYSIS=ON)

    assert_target_exists "$test_dir" "analyze"
    assert_target_exists "$test_dir" "fix"
    assert_target_exists "$test_dir" "analyze-clang-check"
    assert_target_exists "$test_dir" "analyze-clang-tidy"
    assert_target_exists "$test_dir" "analyze-cppcheck"
    assert_target_exists "$test_dir" "fix-clang-tidy"
    assert_target_exists "$test_dir" "fix-clang-check"
}

@test "DEP_ISOLATION: LIBRA_ANALYSIS=ON - works with C++ root project" {
    test_dir=$(run_libra_cmake_dep_test "cxx" -DLIBRA_ANALYSIS=ON)

    assert_target_exists "$test_dir" "analyze"
    assert_target_exists "$test_dir" "fix"
}

# ==============================================================================
# (b) Dep target isolation: configure succeeds (no duplicate target errors)
#
# If LIBRA's NOT TARGET guards are missing or broken, cmake will hard-error:
#   "add_custom_target cannot create target 'analyze' because another target
#    with the same name already exists"
# A successful configure+build here proves the guards are working.
# ==============================================================================

@test "DEP_ISOLATION: LIBRA_ANALYSIS=ON - no duplicate target cmake error (C)" {
    run run_libra_cmake_dep_test "c" -DLIBRA_ANALYSIS=ON
    [ "$status" -eq 0 ]
}

@test "DEP_ISOLATION: LIBRA_ANALYSIS=ON - no duplicate target cmake error (C++)" {
    run run_libra_cmake_dep_test "cxx" -DLIBRA_ANALYSIS=ON
    [ "$status" -eq 0 ]
}

# ==============================================================================
# (c) Flag isolation: root flags do not bleed into dep
# ==============================================================================

@test "DEP_ISOLATION: LIBRA_SAN=ASAN - root has sanitizer compile flags" {
    test_dir=$(run_libra_cmake_dep_test "c" -DLIBRA_SAN=ASAN)

    assert_compile_flag_present "$test_dir" "c" "-fsanitize=address"
}

@test "DEP_ISOLATION: LIBRA_SAN=ASAN - root has sanitizer link flags" {
    test_dir=$(run_libra_cmake_dep_test "c" -DLIBRA_SAN=ASAN)

    assert_link_flag_present "$test_dir" "c" "-fsanitize=address"
}

@test "DEP_ISOLATION: LIBRA_SAN=ASAN - dep does not inherit root sanitizer flags" {
    test_dir=$(run_libra_cmake_dep_test "c" -DLIBRA_SAN=ASAN)

    local dep_flags="$test_dir/dep/CMakeFiles/sample_dep_lib.dir/flags.make"

    # ASAN must NOT appear in dep's compile flags - it was not set for dep
    run grep -q -- "-fsanitize=address" "$dep_flags"
    [ "$status" -ne 0 ]
}

# ==============================================================================
# Root coverage targets present + dep does not cause dup target error
# ==============================================================================

@test "DEP_ISOLATION: GNU/C CODE_COV=ON - root has lcov targets" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_dep_test "c" \
        -DLIBRA_CODE_COV=ON \
        -DLIBRA_CODE_COV_NATIVE=YES)

    assert_target_exists "$test_dir" "lcov-preinfo"
    assert_target_exists "$test_dir" "lcov-report"
    assert_target_exists "$test_dir" "gcovr-report"
    assert_target_exists "$test_dir" "gcovr-check"
}

@test "DEP_ISOLATION: GNU/C CODE_COV=ON - no dup lcov target error" {
    COMPILER_TYPE=gnu
    run run_libra_cmake_dep_test "c" \
        -DLIBRA_CODE_COV=ON \
        -DLIBRA_CODE_COV_NATIVE=YES
    [ "$status" -eq 0 ]
}

@test "DEP_ISOLATION: GNU/C++ CODE_COV=ON - root has lcov targets" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_dep_test "cxx" \
        -DLIBRA_CODE_COV=ON \
        -DLIBRA_CODE_COV_NATIVE=YES)

    assert_target_exists "$test_dir" "lcov-preinfo"
    assert_target_exists "$test_dir" "gcovr-report"
}

@test "DEP_ISOLATION: GNU/C++ CODE_COV=ON - no dup lcov target error" {
    COMPILER_TYPE=gnu
    run run_libra_cmake_dep_test "cxx" \
        -DLIBRA_CODE_COV=ON \
        -DLIBRA_CODE_COV_NATIVE=YES
    [ "$status" -eq 0 ]
}

# ==============================================================================
# Default/cache behavior
# ==============================================================================

@test "DEP_ISOLATION: Default (no options) - configures and builds cleanly (C)" {
    run run_libra_cmake_dep_test "c"
    [ "$status" -eq 0 ]
}

@test "DEP_ISOLATION: Default (no options) - configures and builds cleanly (C++)" {
    run run_libra_cmake_dep_test "cxx"
    [ "$status" -eq 0 ]
}
