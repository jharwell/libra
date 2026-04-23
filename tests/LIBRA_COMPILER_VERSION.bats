#!/usr/bin/env bats
#
# BATS tests for libra_require_compiler (compile/version.cmake)
#
# libra_require_compiler() enforces a minimum major compiler version.
# Signature:
#
#   libra_require_compiler(
#       [LANG  <C|CXX> ...]   # defaults to both C and CXX if omitted
#       ID      <compiler-id> # GNU, Clang, AppleClang, IntelLLVM
#       VERSION <major>       # minimum required major version (integer)
#   )
#
# Behaviour under test:
#   - ID mismatch: silently skipped (not an error)
#   - Version satisfied: cmake exits 0 and emits a STATUS message
#   - Version too old: cmake exits non-zero (FATAL_ERROR)
#   - LANG omitted: checks both C and CXX
#   - LANG=CXX only: C compiler version is not checked
#   - Unknown/missing args: cmake exits non-zero
#
# Strategy: project-local.cmake in sample_build_info accepts
# LIBRA_TEST_REQUIRE_COMPILER_* variables that cause it to call
# libra_require_compiler() with the supplied arguments.  cmake configure
# exit status is the observable.
#
# A "guaranteed old" version (1) always passes; a "guaranteed future" version
# (9999) always fails, regardless of what compiler is installed.
#

load test_helpers

setup() {
    setup_libra_test
}

# ==============================================================================
# Version satisfied — configure succeeds
# ==============================================================================

@test "COMPILER_VERSION: GNU version >= 1 satisfied (C)" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" \
        -DLIBRA_TEST_REQUIRE_COMPILER_ID=GNU \
        -DLIBRA_TEST_REQUIRE_COMPILER_VERSION=1 \
        -DLIBRA_TEST_REQUIRE_COMPILER_LANG=C)

    [ -n "$test_dir" ]
}

@test "COMPILER_VERSION: GNU version >= 1 satisfied (CXX)" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" \
        -DLIBRA_TEST_REQUIRE_COMPILER_ID=GNU \
        -DLIBRA_TEST_REQUIRE_COMPILER_VERSION=1 \
        -DLIBRA_TEST_REQUIRE_COMPILER_LANG=CXX)

    [ -n "$test_dir" ]
}

@test "COMPILER_VERSION: Clang version >= 1 satisfied (C)" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" \
        -DLIBRA_TEST_REQUIRE_COMPILER_ID=Clang \
        -DLIBRA_TEST_REQUIRE_COMPILER_VERSION=1 \
        -DLIBRA_TEST_REQUIRE_COMPILER_LANG=C)

    [ -n "$test_dir" ]
}

@test "COMPILER_VERSION: Clang version >= 1 satisfied (CXX)" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" \
        -DLIBRA_TEST_REQUIRE_COMPILER_ID=Clang \
        -DLIBRA_TEST_REQUIRE_COMPILER_VERSION=1 \
        -DLIBRA_TEST_REQUIRE_COMPILER_LANG=CXX)

    [ -n "$test_dir" ]
}

@test "COMPILER_VERSION: LANG omitted checks both C and CXX — satisfiable version passes" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" \
        -DLIBRA_TEST_REQUIRE_COMPILER_ID=GNU \
        -DLIBRA_TEST_REQUIRE_COMPILER_VERSION=1)

    [ -n "$test_dir" ]
}

# ==============================================================================
# Version too old — configure must fail
#
# VERSION=9999 is guaranteed to exceed any real compiler version, so the
# FATAL_ERROR branch fires on every CI machine without knowing which compiler
# version is installed.
# ==============================================================================

@test "COMPILER_VERSION: GNU version < 9999 causes fatal error (C)" {
    COMPILER_TYPE=gnu
    local test_dir_local="$TEST_BUILD_DIR/ver_fail_gnu_c_${RANDOM}"
    mkdir -p "$test_dir_local"

    local compiler
    compiler=$(get_compiler "gnu" "c")

    cd "$test_dir_local"
    run cmake "$LIBRA_TESTS_DIR/sample_build_info" \
        -DCMAKE_C_COMPILER="$compiler" \
        -DLIBRA_TEST_LANGUAGE=C \
        -DLIBRA_TEST_REQUIRE_COMPILER_ID=GNU \
        -DLIBRA_TEST_REQUIRE_COMPILER_VERSION=9999 \
        -DLIBRA_TEST_REQUIRE_COMPILER_LANG=C \
        --log-level=ERROR \
        $(_consume_mode_cmake_args 2>/dev/null || echo "-DLIBRA_SOURCE_ROOT=${LIBRA_SOURCE_ROOT}")
    cd - > /dev/null

    [ "$status" -ne 0 ]
}

@test "COMPILER_VERSION: GNU version < 9999 causes fatal error (CXX)" {
    COMPILER_TYPE=gnu
    local test_dir_local="$TEST_BUILD_DIR/ver_fail_gnu_cxx_${RANDOM}"
    mkdir -p "$test_dir_local"

    local compiler
    compiler=$(get_compiler "gnu" "cxx")

    cd "$test_dir_local"
    run cmake "$LIBRA_TESTS_DIR/sample_build_info" \
        -DCMAKE_CXX_COMPILER="$compiler" \
        -DLIBRA_TEST_LANGUAGE=CXX \
        -DLIBRA_TEST_REQUIRE_COMPILER_ID=GNU \
        -DLIBRA_TEST_REQUIRE_COMPILER_VERSION=9999 \
        -DLIBRA_TEST_REQUIRE_COMPILER_LANG=CXX \
        --log-level=ERROR \
        $(_consume_mode_cmake_args 2>/dev/null || echo "-DLIBRA_SOURCE_ROOT=${LIBRA_SOURCE_ROOT}")
    cd - > /dev/null

    [ "$status" -ne 0 ]
}

@test "COMPILER_VERSION: Clang version < 9999 causes fatal error (C)" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    local test_dir_local="$TEST_BUILD_DIR/ver_fail_clang_c_${RANDOM}"
    mkdir -p "$test_dir_local"

    local compiler
    compiler=$(get_compiler "clang" "c")

    cd "$test_dir_local"
    run cmake "$LIBRA_TESTS_DIR/sample_build_info" \
        -DCMAKE_C_COMPILER="$compiler" \
        -DLIBRA_TEST_LANGUAGE=C \
        -DLIBRA_TEST_REQUIRE_COMPILER_ID=Clang \
        -DLIBRA_TEST_REQUIRE_COMPILER_VERSION=9999 \
        -DLIBRA_TEST_REQUIRE_COMPILER_LANG=C \
        --log-level=ERROR \
        $(_consume_mode_cmake_args 2>/dev/null || echo "-DLIBRA_SOURCE_ROOT=${LIBRA_SOURCE_ROOT}")
    cd - > /dev/null

    [ "$status" -ne 0 ]
}

@test "COMPILER_VERSION: LANG omitted with unsatisfiable version causes fatal error" {
    COMPILER_TYPE=gnu
    local test_dir_local="$TEST_BUILD_DIR/ver_fail_both_${RANDOM}"
    mkdir -p "$test_dir_local"

    local compiler
    compiler=$(get_compiler "gnu" "cxx")

    cd "$test_dir_local"
    run cmake "$LIBRA_TESTS_DIR/sample_build_info" \
        -DCMAKE_CXX_COMPILER="$compiler" \
        -DLIBRA_TEST_LANGUAGE=CXX \
        -DLIBRA_TEST_REQUIRE_COMPILER_ID=GNU \
        -DLIBRA_TEST_REQUIRE_COMPILER_VERSION=9999 \
        --log-level=ERROR \
        $(_consume_mode_cmake_args 2>/dev/null || echo "-DLIBRA_SOURCE_ROOT=${LIBRA_SOURCE_ROOT}")
    cd - > /dev/null

    [ "$status" -ne 0 ]
}

# ==============================================================================
# ID mismatch — silently skipped, configure succeeds
#
# When the active compiler's ID does not match the requested ID, the check
# is a no-op.  An unsatisfiable version (9999) with the wrong ID must not
# cause an error.
# ==============================================================================

@test "COMPILER_VERSION: wrong ID with unsatisfiable version is silently skipped (GNU compiler, Clang ID)" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" \
        -DLIBRA_TEST_REQUIRE_COMPILER_ID=Clang \
        -DLIBRA_TEST_REQUIRE_COMPILER_VERSION=9999 \
        -DLIBRA_TEST_REQUIRE_COMPILER_LANG=C)

    [ -n "$test_dir" ]
}

@test "COMPILER_VERSION: wrong ID with unsatisfiable version is silently skipped (Clang compiler, GNU ID)" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" \
        -DLIBRA_TEST_REQUIRE_COMPILER_ID=GNU \
        -DLIBRA_TEST_REQUIRE_COMPILER_VERSION=9999 \
        -DLIBRA_TEST_REQUIRE_COMPILER_LANG=C)

    [ -n "$test_dir" ]
}

# ==============================================================================
# LANG scoping
#
# LANG=CXX means the C compiler is not checked, so an unsatisfiable version
# constraint scoped to CXX only must not trigger on a C-only configure.
# ==============================================================================

@test "COMPILER_VERSION: LANG=CXX does not check C compiler" {
    COMPILER_TYPE=gnu
    # Configure a C project; the CXX version requirement must be ignored
    # because the CXX language is not enabled.
    test_dir=$(run_libra_cmake_test "c" \
        -DLIBRA_TEST_REQUIRE_COMPILER_ID=GNU \
        -DLIBRA_TEST_REQUIRE_COMPILER_VERSION=9999 \
        -DLIBRA_TEST_REQUIRE_COMPILER_LANG=CXX)

    [ -n "$test_dir" ]
}

@test "COMPILER_VERSION: LANG=C does not check CXX compiler" {
    COMPILER_TYPE=gnu
    # Configure a C++ project; the C version requirement must be ignored
    # because we're checking LANG=C only and the C language is not enabled.
    test_dir=$(run_libra_cmake_test "cxx" \
        -DLIBRA_TEST_REQUIRE_COMPILER_ID=GNU \
        -DLIBRA_TEST_REQUIRE_COMPILER_VERSION=9999 \
        -DLIBRA_TEST_REQUIRE_COMPILER_LANG=C)

    [ -n "$test_dir" ]
}

# ==============================================================================
# Error handling — missing required arguments
# ==============================================================================

@test "COMPILER_VERSION: missing ID argument causes cmake error" {
    COMPILER_TYPE=gnu
    local test_dir_local="$TEST_BUILD_DIR/ver_no_id_${RANDOM}"
    mkdir -p "$test_dir_local"

    local compiler
    compiler=$(get_compiler "gnu" "cxx")

    cd "$test_dir_local"
    run cmake "$LIBRA_TESTS_DIR/sample_build_info" \
        -DCMAKE_CXX_COMPILER="$compiler" \
        -DLIBRA_TEST_LANGUAGE=CXX \
        -DLIBRA_TEST_REQUIRE_COMPILER_MISSING_ID=ON \
        --log-level=ERROR \
        $(_consume_mode_cmake_args 2>/dev/null || echo "-DLIBRA_SOURCE_ROOT=${LIBRA_SOURCE_ROOT}")
    cd - > /dev/null

    [ "$status" -ne 0 ]
}

@test "COMPILER_VERSION: missing VERSION argument causes cmake error" {
    COMPILER_TYPE=gnu
    local test_dir_local="$TEST_BUILD_DIR/ver_no_ver_${RANDOM}"
    mkdir -p "$test_dir_local"

    local compiler
    compiler=$(get_compiler "gnu" "cxx")

    cd "$test_dir_local"
    run cmake "$LIBRA_TESTS_DIR/sample_build_info" \
        -DCMAKE_CXX_COMPILER="$compiler" \
        -DLIBRA_TEST_LANGUAGE=CXX \
        -DLIBRA_TEST_REQUIRE_COMPILER_MISSING_VERSION=ON \
        --log-level=ERROR \
        $(_consume_mode_cmake_args 2>/dev/null || echo "-DLIBRA_SOURCE_ROOT=${LIBRA_SOURCE_ROOT}")
    cd - > /dev/null

    [ "$status" -ne 0 ]
}
