#!/usr/bin/env bats
#
# BATS tests for LIBRA_STDLIB
#
# LIBRA_STDLIB selects the C/C++ standard library to link against:
#   - NONE:   Links with -nostdlib (all compilers, C and C++)
#   - STDCXX: Links with -stdlib=libstdc++ (Clang and Intel, C++ only)
#   - CXX:    Links with -stdlib=libc++    (Clang and Intel, C++ only)
#
# GNU only supports NONE; STDCXX and CXX are skipped for GNU.
# Flags appear in LINK_FLAGS in the generated build_info file.
#

load test_helpers

setup() {
    setup_libra_test
}

# ------------------------------------------------------------------------------
# NONE mode - all compilers, C and C++
# ------------------------------------------------------------------------------

@test "STDLIB: GNU/C NONE adds -nostdlib" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_STDLIB=NONE)

    assert_link_flag_present "$test_dir" "c" "-nostdlib"
}

@test "STDLIB: GNU/C++ NONE adds -nostdlib" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_STDLIB=NONE)

    assert_link_flag_present "$test_dir" "cxx" "-nostdlib"
}

@test "STDLIB: Clang/C NONE adds -nostdlib" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_STDLIB=NONE)

    assert_link_flag_present "$test_dir" "c" "-nostdlib"
}

@test "STDLIB: Clang/C++ NONE adds -nostdlib" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_STDLIB=NONE)

    assert_link_flag_present "$test_dir" "cxx" "-nostdlib"
}

@test "STDLIB: Intel/C NONE adds -nostdlib" {
    skip_if_compiler_missing "intel" "c"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_STDLIB=NONE)

    assert_link_flag_present "$test_dir" "c" "-nostdlib"
}

@test "STDLIB: Intel/C++ NONE adds -nostdlib" {
    skip_if_compiler_missing "intel" "cxx"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_STDLIB=NONE)

    assert_link_flag_present "$test_dir" "cxx" "-nostdlib"
}

# ------------------------------------------------------------------------------
# STDCXX mode - Clang and Intel, C++ only
# ------------------------------------------------------------------------------

@test "STDLIB: Clang/C++ STDCXX adds -stdlib=libstdc++" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_STDLIB=STDCXX)

    assert_link_flag_present "$test_dir" "cxx" "-stdlib=libstdc++"
}

@test "STDLIB: Intel/C++ STDCXX adds -stdlib=libstdc++" {
    skip_if_compiler_missing "intel" "cxx"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_STDLIB=STDCXX)

    assert_link_flag_present "$test_dir" "cxx" "-stdlib=libstdc++"
}

# ------------------------------------------------------------------------------
# CXX mode - Clang and Intel, C++ only
# ------------------------------------------------------------------------------

@test "STDLIB: Clang/C++ CXX adds -stdlib=libc++" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_STDLIB=CXX)

    assert_link_flag_present "$test_dir" "cxx" "-stdlib=libc++"
}

@test "STDLIB: Intel/C++ CXX adds -stdlib=libc++" {
    skip_if_compiler_missing "intel" "cxx"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_STDLIB=CXX)

    assert_link_flag_present "$test_dir" "cxx" "-stdlib=libc++"
}

# ------------------------------------------------------------------------------
# Mutual exclusion - STDCXX and CXX flags don't bleed into each other
# ------------------------------------------------------------------------------

@test "STDLIB: Clang/C++ STDCXX does not add -stdlib=libc++" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_STDLIB=STDCXX)

    run has_link_flag "$test_dir" "cxx" "-stdlib=libc++"
    [ "$status" -ne 0 ]
}

@test "STDLIB: Clang/C++ CXX does not add -stdlib=libstdc++" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_STDLIB=CXX)

    run has_link_flag "$test_dir" "cxx" "-stdlib=libstdc++"
    [ "$status" -ne 0 ]
}

@test "STDLIB: Cache variable persists across reconfiguration" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_STDLIB=NONE)

    run cache_value_equals "$test_dir" "LIBRA_STDLIB" "NONE"
    [ "$status" -eq 0 ]

    cd "$test_dir"
    run cmake "$BATS_TEST_DIRNAME/sample_build_info" --log-level=ERROR
    [ "$status" -eq 0 ]

    run cache_value_equals "$test_dir" "LIBRA_STDLIB" "NONE"
    [ "$status" -eq 0 ]
}

@test "STDLIB: Can change value on reconfiguration" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_STDLIB=CXX)

    run cache_value_equals "$test_dir" "LIBRA_STDLIB" "CXX"
    [ "$status" -eq 0 ]

    cd "$test_dir"
    run cmake "$BATS_TEST_DIRNAME/sample_build_info" -DLIBRA_STDLIB=STDCXX --log-level=ERROR
    [ "$status" -eq 0 ]

    run cache_value_equals "$test_dir" "LIBRA_STDLIB" "STDCXX"
    [ "$status" -eq 0 ]
}
