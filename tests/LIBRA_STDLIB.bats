#!/usr/bin/env bats
#
# BATS tests for LIBRA_STDLIB
#
# LIBRA_STDLIB selects the C/C++ standard library to link against:
#   - NONE:      Links with -nostdlib (all compilers, C and C++)
#   - STDCXX:    Links and compiles with -stdlib=libstdc++ (Clang and Intel, C++ only)
#   - CXX:       Links and compiles with -stdlib=libc++    (Clang and Intel, C++ only)
#   - UNDEFINED: Default — no stdlib flags applied
#
# GNU only supports NONE. STDCXX and CXX with GNU produce a cmake warning and
# apply no flags. Flags appear in both COMPILE_FLAGS and LINK_FLAGS in the
# generated build_info file (except NONE which is link-only).
#

load test_helpers

setup() {
    setup_libra_test
}

# ==============================================================================
# NONE mode — all compilers, C and C++
# ==============================================================================

@test "STDLIB: GNU/C NONE adds -nostdlib to link flags" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_STDLIB=NONE)

    assert_link_flag_present "$test_dir" "c" "-nostdlib"
}

@test "STDLIB: GNU/C++ NONE adds -nostdlib to link flags" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_STDLIB=NONE)

    assert_link_flag_present "$test_dir" "cxx" "-nostdlib"
}

@test "STDLIB: Clang/C NONE adds -nostdlib to link flags" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_STDLIB=NONE)

    assert_link_flag_present "$test_dir" "c" "-nostdlib"
}

@test "STDLIB: Clang/C++ NONE adds -nostdlib to link flags" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_STDLIB=NONE)

    assert_link_flag_present "$test_dir" "cxx" "-nostdlib"
}

@test "STDLIB: Intel/C NONE adds -nostdlib to link flags" {
    skip_if_compiler_missing "intel" "c"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_STDLIB=NONE)

    assert_link_flag_present "$test_dir" "c" "-nostdlib"
}

@test "STDLIB: Intel/C++ NONE adds -nostdlib to link flags" {
    skip_if_compiler_missing "intel" "cxx"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_STDLIB=NONE)

    assert_link_flag_present "$test_dir" "cxx" "-nostdlib"
}

# ==============================================================================
# STDCXX mode — Clang and Intel, C++ only (link + compile flags)
# ==============================================================================

@test "STDLIB: Clang/C++ STDCXX adds -stdlib=libstdc++ to link flags" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_STDLIB=STDCXX)

    assert_link_flag_present "$test_dir" "cxx" "-stdlib=libstdc++"
}

@test "STDLIB: Clang/C++ STDCXX adds -stdlib=libstdc++ to compile flags" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_STDLIB=STDCXX)

    assert_compile_flag_present "$test_dir" "cxx" "-stdlib=libstdc++"
}

@test "STDLIB: Intel/C++ STDCXX adds -stdlib=libstdc++ to link flags" {
    skip_if_compiler_missing "intel" "cxx"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_STDLIB=STDCXX)

    assert_link_flag_present "$test_dir" "cxx" "-stdlib=libstdc++"
}

@test "STDLIB: Intel/C++ STDCXX adds -stdlib=libstdc++ to compile flags" {
    skip_if_compiler_missing "intel" "cxx"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_STDLIB=STDCXX)

    assert_compile_flag_present "$test_dir" "cxx" "-stdlib=libstdc++"
}

# ==============================================================================
# CXX mode — Clang and Intel, C++ only (link + compile flags)
# ==============================================================================

@test "STDLIB: Clang/C++ CXX adds -stdlib=libc++ to link flags" {
    skip_if_compiler_missing "clang" "cxx"
    skip_if_clang_older_than 17
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_STDLIB=CXX)

    assert_link_flag_present "$test_dir" "cxx" "-stdlib=libc++"
}

@test "STDLIB: Clang/C++ CXX adds -stdlib=libc++ to compile flags" {
    skip_if_compiler_missing "clang" "cxx"
    skip_if_clang_older_than 17
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_STDLIB=CXX)

    assert_compile_flag_present "$test_dir" "cxx" "-stdlib=libc++"
}

@test "STDLIB: Intel/C++ CXX adds -stdlib=libc++ to link flags" {
    skip_if_compiler_missing "intel" "cxx"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_STDLIB=CXX)

    assert_link_flag_present "$test_dir" "cxx" "-stdlib=libc++"
}

@test "STDLIB: Intel/C++ CXX adds -stdlib=libc++ to compile flags" {
    skip_if_compiler_missing "intel" "cxx"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_STDLIB=CXX)

    assert_compile_flag_present "$test_dir" "cxx" "-stdlib=libc++"
}

# ==============================================================================
# GNU + STDCXX/CXX — should warn and apply no flags
# ==============================================================================

@test "STDLIB: GNU/C++ STDCXX warns and does not add -stdlib=libstdc++ to link flags" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_STDLIB=STDCXX)

    assert_link_flag_absent "$test_dir" "cxx" "-stdlib=libstdc++"
}

@test "STDLIB: GNU/C++ STDCXX warns and does not add -stdlib=libstdc++ to compile flags" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_STDLIB=STDCXX)

    assert_compile_flag_absent "$test_dir" "cxx" "-stdlib=libstdc++"
}

@test "STDLIB: GNU/C++ CXX warns and does not add -stdlib=libc++ to link flags" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_STDLIB=CXX)

    assert_link_flag_absent "$test_dir" "cxx" "-stdlib=libc++"
}

@test "STDLIB: GNU/C++ CXX warns and does not add -stdlib=libc++ to compile flags" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_STDLIB=CXX)

    assert_compile_flag_absent "$test_dir" "cxx" "-stdlib=libc++"
}

# ==============================================================================
# UNDEFINED default — no stdlib flags applied
# ==============================================================================

@test "STDLIB: Default (UNDEFINED) does not add -nostdlib to GNU link flags" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx")

    assert_link_flag_absent "$test_dir" "cxx" "-nostdlib"
}

@test "STDLIB: Default (UNDEFINED) does not add -stdlib= to Clang link flags" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx")

    assert_link_flag_absent "$test_dir" "cxx" "-stdlib="
}

# ==============================================================================
# Mutual exclusion
# ==============================================================================

@test "STDLIB: Clang/C++ STDCXX does not add -stdlib=libc++" {
    skip_if_compiler_missing "clang" "cxx"
    skip_if_clang_older_than 17
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_STDLIB=STDCXX)

    assert_link_flag_absent "$test_dir" "cxx" "-stdlib=libc++"
}

@test "STDLIB: Clang/C++ CXX does not add -stdlib=libstdc++" {
    skip_if_compiler_missing "clang" "cxx"
    skip_if_clang_older_than 17
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_STDLIB=CXX)

    assert_link_flag_absent "$test_dir" "cxx" "-stdlib=libstdc++"
}

# ==============================================================================
# Cache persistence
# ==============================================================================

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
    skip_if_clang_older_than 17
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

# ==============================================================================
# __nostdlib__ preprocessor define
#
# When LIBRA_STDLIB=NONE, compiler.cmake adds -D__nostdlib__ to the PUBLIC
# compile definitions so downstream consumers can detect the freestanding
# environment.  This is distinct from the -nostdlib linker flag.
# ==============================================================================

@test "STDLIB: GNU/C NONE sets __nostdlib__ define on target" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_STDLIB=NONE)

    assert_define_present "$test_dir" "c" "__nostdlib__"
}

@test "STDLIB: GNU/C++ NONE sets __nostdlib__ define on target" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_STDLIB=NONE)

    assert_define_present "$test_dir" "cxx" "__nostdlib__"
}

@test "STDLIB: Clang/C NONE sets __nostdlib__ define on target" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_STDLIB=NONE)

    assert_define_present "$test_dir" "c" "__nostdlib__"
}

@test "STDLIB: Clang/C++ NONE sets __nostdlib__ define on target" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_STDLIB=NONE)

    assert_define_present "$test_dir" "cxx" "__nostdlib__"
}

@test "STDLIB: Default (UNDEFINED) does not set __nostdlib__ define" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx")

    assert_define_absent "$test_dir" "cxx" "__nostdlib__"
}

@test "STDLIB: GNU/C++ STDCXX does not set __nostdlib__ define" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_STDLIB=STDCXX)

    assert_define_absent "$test_dir" "cxx" "__nostdlib__"
}
