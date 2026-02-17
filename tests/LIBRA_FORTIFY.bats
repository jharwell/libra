#!/usr/bin/env bats
#
# BATS tests for LIBRA_FORTIFY
#
# LIBRA_FORTIFY controls security hardening flags:
#   - NONE:   No hardening flags (default)
#   - STACK:  -fstack-protector
#   - SOURCE: -D_FORTIFY_SOURCE=2
#   - ALL:    -D_FORTIFY_SOURCE=2 -fstack-protector
#
# Supported compilers: gnu, clang only (Intel does not support LIBRA_FORTIFY).
# Flags appear in COMPILE_FLAGS in the generated build_info file.
# Build type: Release (matches the shell test).
#

load test_helpers

setup() {
    setup_libra_test
    export CMAKE_BUILD_TYPE=Release
}

# ------------------------------------------------------------------------------
# GNU compiler - NONE
# ------------------------------------------------------------------------------

@test "FORTIFY: GNU/C NONE does not add -fstack-protector" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_FORTIFY=NONE)

    assert_compile_flag_absent "$test_dir" "c" "-fstack-protector"
}

@test "FORTIFY: GNU/C NONE does not add -D_FORTIFY_SOURCE" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_FORTIFY=NONE)

    assert_compile_flag_absent "$test_dir" "c" "-D_FORTIFY_SOURCE"
}

@test "FORTIFY: GNU/C++ NONE does not add -fstack-protector" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_FORTIFY=NONE)

    assert_compile_flag_absent "$test_dir" "cxx" "-fstack-protector"
}

@test "FORTIFY: GNU/C++ NONE does not add -D_FORTIFY_SOURCE" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_FORTIFY=NONE)

    assert_compile_flag_absent "$test_dir" "cxx" "-D_FORTIFY_SOURCE"
}

# ------------------------------------------------------------------------------
# GNU compiler - STACK
# ------------------------------------------------------------------------------

@test "FORTIFY: GNU/C STACK adds -fstack-protector" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_FORTIFY=STACK)

    assert_compile_flag_present "$test_dir" "c" "-fstack-protector"
}

@test "FORTIFY: GNU/C++ STACK adds -fstack-protector" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_FORTIFY=STACK)

    assert_compile_flag_present "$test_dir" "cxx" "-fstack-protector"
}

# ------------------------------------------------------------------------------
# GNU compiler - SOURCE
# ------------------------------------------------------------------------------

@test "FORTIFY: GNU/C SOURCE adds -D_FORTIFY_SOURCE=2" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_FORTIFY=SOURCE)

    assert_compile_flag_present "$test_dir" "c" "-D_FORTIFY_SOURCE=2"
}

@test "FORTIFY: GNU/C++ SOURCE adds -D_FORTIFY_SOURCE=2" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_FORTIFY=SOURCE)

    assert_compile_flag_present "$test_dir" "cxx" "-D_FORTIFY_SOURCE=2"
}

# ------------------------------------------------------------------------------
# GNU compiler - ALL
# ------------------------------------------------------------------------------

@test "FORTIFY: GNU/C ALL adds -D_FORTIFY_SOURCE=2" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_FORTIFY=ALL)

    assert_compile_flag_present "$test_dir" "c" "-D_FORTIFY_SOURCE=2"
}

@test "FORTIFY: GNU/C ALL adds -fstack-protector" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_FORTIFY=ALL)

    assert_compile_flag_present "$test_dir" "c" "-fstack-protector"
}

@test "FORTIFY: GNU/C++ ALL adds -D_FORTIFY_SOURCE=2" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_FORTIFY=ALL)

    assert_compile_flag_present "$test_dir" "cxx" "-D_FORTIFY_SOURCE=2"
}

@test "FORTIFY: GNU/C++ ALL adds -fstack-protector" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_FORTIFY=ALL)

    assert_compile_flag_present "$test_dir" "cxx" "-fstack-protector"
}

# ------------------------------------------------------------------------------
# Clang compiler - NONE
# ------------------------------------------------------------------------------

@test "FORTIFY: Clang/C NONE does not add -fstack-protector" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_FORTIFY=NONE)

    assert_compile_flag_absent "$test_dir" "c" "-fstack-protector"
}

@test "FORTIFY: Clang/C NONE does not add -D_FORTIFY_SOURCE" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_FORTIFY=NONE)

    assert_compile_flag_absent "$test_dir" "c" "-D_FORTIFY_SOURCE"
}

@test "FORTIFY: Clang/C++ NONE does not add -fstack-protector" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_FORTIFY=NONE)

    assert_compile_flag_absent "$test_dir" "cxx" "-fstack-protector"
}

@test "FORTIFY: Clang/C++ NONE does not add -D_FORTIFY_SOURCE" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_FORTIFY=NONE)

    assert_compile_flag_absent "$test_dir" "cxx" "-D_FORTIFY_SOURCE"
}

# ------------------------------------------------------------------------------
# Clang compiler - STACK
# ------------------------------------------------------------------------------

@test "FORTIFY: Clang/C STACK adds -fstack-protector" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_FORTIFY=STACK)

    assert_compile_flag_present "$test_dir" "c" "-fstack-protector"
}

@test "FORTIFY: Clang/C++ STACK adds -fstack-protector" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_FORTIFY=STACK)

    assert_compile_flag_present "$test_dir" "cxx" "-fstack-protector"
}

# ------------------------------------------------------------------------------
# Clang compiler - SOURCE
# ------------------------------------------------------------------------------

@test "FORTIFY: Clang/C SOURCE adds -D_FORTIFY_SOURCE=2" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_FORTIFY=SOURCE)

    assert_compile_flag_present "$test_dir" "c" "-D_FORTIFY_SOURCE=2"
}

@test "FORTIFY: Clang/C++ SOURCE adds -D_FORTIFY_SOURCE=2" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_FORTIFY=SOURCE)

    assert_compile_flag_present "$test_dir" "cxx" "-D_FORTIFY_SOURCE=2"
}

# ------------------------------------------------------------------------------
# Clang compiler - ALL
# ------------------------------------------------------------------------------

@test "FORTIFY: Clang/C ALL adds -D_FORTIFY_SOURCE=2" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_FORTIFY=ALL)

    assert_compile_flag_present "$test_dir" "c" "-D_FORTIFY_SOURCE=2"
}

@test "FORTIFY: Clang/C ALL adds -fstack-protector" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_FORTIFY=ALL)

    assert_compile_flag_present "$test_dir" "c" "-fstack-protector"
}

@test "FORTIFY: Clang/C++ ALL adds -D_FORTIFY_SOURCE=2" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_FORTIFY=ALL)

    assert_compile_flag_present "$test_dir" "cxx" "-D_FORTIFY_SOURCE=2"
}

@test "FORTIFY: Clang/C++ ALL adds -fstack-protector" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_FORTIFY=ALL)

    assert_compile_flag_present "$test_dir" "cxx" "-fstack-protector"
}

# ------------------------------------------------------------------------------
# Default behaviour
# ------------------------------------------------------------------------------

@test "FORTIFY: Default (unset) does not add hardening flags" {
    # LIBRA_FORTIFY defaults to NONE
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c")

    assert_compile_flag_absent "$test_dir" "c" "-fstack-protector"
    assert_compile_flag_absent "$test_dir" "c" "-D_FORTIFY_SOURCE"
}

@test "FORTIFY: Cache variable persists across reconfiguration" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_FORTIFY=STACK)

    run cache_value_equals "$test_dir" "LIBRA_FORTIFY" "STACK"
    [ "$status" -eq 0 ]

    cd "$test_dir"
    run cmake "$BATS_TEST_DIRNAME/sample_build_info" --log-level=ERROR
    [ "$status" -eq 0 ]

    run cache_value_equals "$test_dir" "LIBRA_FORTIFY" "STACK"
    [ "$status" -eq 0 ]
}

@test "FORTIFY: Can change value on reconfiguration" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_FORTIFY=STACK)

    run cache_value_equals "$test_dir" "LIBRA_FORTIFY" "STACK"
    [ "$status" -eq 0 ]

    cd "$test_dir"
    run cmake "$BATS_TEST_DIRNAME/sample_build_info" -DLIBRA_FORTIFY=SOURCE --log-level=ERROR
    [ "$status" -eq 0 ]

    run cache_value_equals "$test_dir" "LIBRA_FORTIFY" "SOURCE"
    [ "$status" -eq 0 ]
}
