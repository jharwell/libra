#!/usr/bin/env bats
#
# BATS tests for LIBRA_SAN (Sanitizers)
#
# LIBRA_SAN selects one or more sanitizers ('+'-separated for combinations):
#   - NONE:      No sanitizer (default)
#   - MSAN:      Memory/leak sanitizer
#   - ASAN:      Address sanitizer
#   - SSAN:      Stack sanitizer (stack-protector flags)
#   - UBSAN:     Undefined behaviour sanitizer
#   - TSAN:      Thread sanitizer
#   - ASAN+UBSAN: Combination example
#
# Sanitizer flags appear in BOTH COMPILE_FLAGS and LINK_FLAGS.
# Build type: Debug (matches the shell test).
#
# Per-compiler flag sets:
#
#   GNU MSAN:  -fno-omit-frame-pointer -fno-optimize-sibling-calls
#              -fsanitize=leak -fsanitize-recover=all
#   GNU ASAN:  -fno-omit-frame-pointer -fno-optimize-sibling-calls
#              -fsanitize=address -fsanitize-address-use-after-scope
#              -fsanitize=pointer-compare -fsanitize=pointer-subtract
#              -fsanitize-recover=all
#   GNU SSAN:  -fno-omit-frame-pointer -fstack-protector-all
#              -fstack-protector-strong -fsanitize-recover=all
#   GNU UBSAN: -fno-omit-frame-pointer -fsanitize=undefined
#              -fsanitize=float-divide-by-zero -fsanitize=float-cast-overflow
#              -fsanitize=null -fsanitize=signed-integer-overflow
#              -fsanitize=bool -fsanitize=enum -fsanitize=builtin
#              -fsanitize=bounds -fsanitize=vptr -fsanitize=pointer-overflow
#              -fsanitize-recover=all
#   GNU TSAN:  -fno-omit-frame-pointer -fsanitize=thread -fsanitize-recover=all
#
#   Clang MSAN:  -fno-omit-frame-pointer -fno-optimize-sibling-calls
#                -fsanitize=memory -fsanitize-memory-track-origins
#   Clang ASAN:  -fno-omit-frame-pointer -fno-optimize-sibling-calls
#                -fsanitize=address
#   Clang SSAN:  -fno-omit-frame-pointer -fstack-protector-all
#                -fstack-protector-strong
#   Clang UBSAN: -fno-omit-frame-pointer -fsanitize=undefined
#                -fsanitize=float-divide-by-zero
#                -fsanitize=unsigned-integer-overflow -fsanitize=local-bounds
#                -fsanitize=nullability
#   Clang TSAN:  -fno-omit-frame-pointer -fsanitize=thread
#
#   Intel MSAN:  -fno-omit-frame-pointer -fno-optimize-sibling-calls
#                -fsanitize=memory -fsanitize-memory-track-origins
#   Intel ASAN:  -fno-omit-frame-pointer -fno-optimize-sibling-calls
#                -fsanitize=address
#   Intel SSAN:  -fno-omit-frame-pointer -fstack-protector-all
#                -fstack-protector-strong
#   Intel UBSAN: -fno-omit-frame-pointer -fsanitize=undefined
#   Intel TSAN:  -fsanitize=thread
#

load test_helpers

setup() {
    setup_libra_test
    export CMAKE_BUILD_TYPE=Debug
}

# Helper: assert flag present in both compile and link flags
assert_san_flag_present() {
    local test_dir="$1"
    local lang="$2"
    local flag="$3"

    assert_compile_flag_present "$test_dir" "$lang" "$flag"
    assert_link_flag_present    "$test_dir" "$lang" "$flag"
}

# ==============================================================================
# NONE — no sanitizer flags
# ==============================================================================

@test "SAN: GNU/C NONE does not add -fsanitize=leak" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_SAN=NONE)

    assert_compile_flag_absent "$test_dir" "c" "-fsanitize=leak"
}

@test "SAN: GNU/C NONE does not add -fsanitize=address" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_SAN=NONE)

    assert_compile_flag_absent "$test_dir" "c" "-fsanitize=address"
}

@test "SAN: GNU/C NONE does not add -fsanitize=thread" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_SAN=NONE)

    assert_compile_flag_absent "$test_dir" "c" "-fsanitize=thread"
}

@test "SAN: GNU/C NONE does not add -fstack-protector-all" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_SAN=NONE)

    assert_compile_flag_absent "$test_dir" "c" "-fstack-protector-all"
}

# ==============================================================================
# GNU - MSAN (leak sanitizer on GNU)
# ==============================================================================

@test "SAN: GNU/C MSAN adds -fsanitize=leak in compile and link flags" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_SAN=MSAN)

    assert_san_flag_present "$test_dir" "c" "-fsanitize=leak"
}

@test "SAN: GNU/C MSAN adds -fno-omit-frame-pointer" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_SAN=MSAN)

    assert_san_flag_present "$test_dir" "c" "-fno-omit-frame-pointer"
}

@test "SAN: GNU/C MSAN adds -fno-optimize-sibling-calls" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_SAN=MSAN)

    assert_san_flag_present "$test_dir" "c" "-fno-optimize-sibling-calls"
}

@test "SAN: GNU/C MSAN adds -fsanitize-recover=all" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_SAN=MSAN)

    assert_san_flag_present "$test_dir" "c" "-fsanitize-recover=all"
}

@test "SAN: GNU/C++ MSAN adds -fsanitize=leak in compile and link flags" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_SAN=MSAN)

    assert_san_flag_present "$test_dir" "cxx" "-fsanitize=leak"
}

# ==============================================================================
# GNU - ASAN
# ==============================================================================

@test "SAN: GNU/C ASAN adds -fsanitize=address in compile and link flags" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_SAN=ASAN)

    assert_san_flag_present "$test_dir" "c" "-fsanitize=address"
}

@test "SAN: GNU/C ASAN adds -fsanitize-address-use-after-scope" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_SAN=ASAN)

    assert_san_flag_present "$test_dir" "c" "-fsanitize-address-use-after-scope"
}

@test "SAN: GNU/C ASAN adds -fsanitize=pointer-compare" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_SAN=ASAN)

    assert_san_flag_present "$test_dir" "c" "-fsanitize=pointer-compare"
}

@test "SAN: GNU/C ASAN adds -fsanitize=pointer-subtract" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_SAN=ASAN)

    assert_san_flag_present "$test_dir" "c" "-fsanitize=pointer-subtract"
}

@test "SAN: GNU/C++ ASAN adds -fsanitize=address in compile and link flags" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_SAN=ASAN)

    assert_san_flag_present "$test_dir" "cxx" "-fsanitize=address"
}

# ==============================================================================
# GNU - SSAN
# ==============================================================================

@test "SAN: GNU/C SSAN adds -fstack-protector-all in compile and link flags" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_SAN=SSAN)

    assert_san_flag_present "$test_dir" "c" "-fstack-protector-all"
}

@test "SAN: GNU/C SSAN adds -fstack-protector-strong" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_SAN=SSAN)

    assert_san_flag_present "$test_dir" "c" "-fstack-protector-strong"
}

@test "SAN: GNU/C++ SSAN adds -fstack-protector-all in compile and link flags" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_SAN=SSAN)

    assert_san_flag_present "$test_dir" "cxx" "-fstack-protector-all"
}

# ==============================================================================
# GNU - UBSAN
# ==============================================================================

@test "SAN: GNU/C UBSAN adds -fsanitize=undefined in compile and link flags" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_SAN=UBSAN)

    assert_san_flag_present "$test_dir" "c" "-fsanitize=undefined"
}

@test "SAN: GNU/C UBSAN adds -fsanitize=float-divide-by-zero" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_SAN=UBSAN)

    assert_san_flag_present "$test_dir" "c" "-fsanitize=float-divide-by-zero"
}

@test "SAN: GNU/C UBSAN adds -fsanitize=bool" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_SAN=UBSAN)

    assert_san_flag_present "$test_dir" "c" "-fsanitize=bool"
}

@test "SAN: GNU/C UBSAN adds -fsanitize=vptr" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_SAN=UBSAN)

    assert_san_flag_present "$test_dir" "c" "-fsanitize=vptr"
}

@test "SAN: GNU/C++ UBSAN adds -fsanitize=undefined in compile and link flags" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_SAN=UBSAN)

    assert_san_flag_present "$test_dir" "cxx" "-fsanitize=undefined"
}

# ==============================================================================
# GNU - TSAN
# ==============================================================================

@test "SAN: GNU/C TSAN adds -fsanitize=thread in compile and link flags" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_SAN=TSAN)

    assert_san_flag_present "$test_dir" "c" "-fsanitize=thread"
}

@test "SAN: GNU/C++ TSAN adds -fsanitize=thread in compile and link flags" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_SAN=TSAN)

    assert_san_flag_present "$test_dir" "cxx" "-fsanitize=thread"
}

# ==============================================================================
# Clang - MSAN (true memory sanitizer on Clang)
# ==============================================================================

@test "SAN: Clang/C MSAN adds -fsanitize=memory in compile and link flags" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_SAN=MSAN)

    assert_san_flag_present "$test_dir" "c" "-fsanitize=memory"
}

@test "SAN: Clang/C MSAN adds -fsanitize-memory-track-origins" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_SAN=MSAN)

    assert_san_flag_present "$test_dir" "c" "-fsanitize-memory-track-origins"
}

@test "SAN: Clang/C++ MSAN adds -fsanitize=memory in compile and link flags" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_SAN=MSAN)

    assert_san_flag_present "$test_dir" "cxx" "-fsanitize=memory"
}

# ==============================================================================
# Clang - ASAN
# ==============================================================================

@test "SAN: Clang/C ASAN adds -fsanitize=address in compile and link flags" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_SAN=ASAN)

    assert_san_flag_present "$test_dir" "c" "-fsanitize=address"
}

@test "SAN: Clang/C++ ASAN adds -fsanitize=address in compile and link flags" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_SAN=ASAN)

    assert_san_flag_present "$test_dir" "cxx" "-fsanitize=address"
}

# ==============================================================================
# Clang - SSAN
# ==============================================================================

@test "SAN: Clang/C SSAN adds -fstack-protector-all in compile and link flags" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_SAN=SSAN)

    assert_san_flag_present "$test_dir" "c" "-fstack-protector-all"
}

@test "SAN: Clang/C++ SSAN adds -fstack-protector-all in compile and link flags" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_SAN=SSAN)

    assert_san_flag_present "$test_dir" "cxx" "-fstack-protector-all"
}

# ==============================================================================
# Clang - UBSAN
# ==============================================================================

@test "SAN: Clang/C UBSAN adds -fsanitize=undefined in compile and link flags" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_SAN=UBSAN)

    assert_san_flag_present "$test_dir" "c" "-fsanitize=undefined"
}

@test "SAN: Clang/C UBSAN adds -fsanitize=unsigned-integer-overflow" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_SAN=UBSAN)

    assert_san_flag_present "$test_dir" "c" "-fsanitize=unsigned-integer-overflow"
}

@test "SAN: Clang/C UBSAN adds -fsanitize=local-bounds" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_SAN=UBSAN)

    assert_san_flag_present "$test_dir" "c" "-fsanitize=local-bounds"
}

@test "SAN: Clang/C++ UBSAN adds -fsanitize=undefined in compile and link flags" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_SAN=UBSAN)

    assert_san_flag_present "$test_dir" "cxx" "-fsanitize=undefined"
}

# ==============================================================================
# Clang - TSAN
# ==============================================================================

@test "SAN: Clang/C TSAN adds -fsanitize=thread in compile and link flags" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_SAN=TSAN)

    assert_san_flag_present "$test_dir" "c" "-fsanitize=thread"
}

@test "SAN: Clang/C++ TSAN adds -fsanitize=thread in compile and link flags" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_SAN=TSAN)

    assert_san_flag_present "$test_dir" "cxx" "-fsanitize=thread"
}

# ==============================================================================
# Intel - MSAN
# ==============================================================================

@test "SAN: Intel/C MSAN adds -fsanitize=memory in compile and link flags" {
    skip_if_compiler_missing "intel" "c"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_SAN=MSAN)

    assert_san_flag_present "$test_dir" "c" "-fsanitize=memory"
}

@test "SAN: Intel/C++ MSAN adds -fsanitize=memory in compile and link flags" {
    skip_if_compiler_missing "intel" "cxx"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_SAN=MSAN)

    assert_san_flag_present "$test_dir" "cxx" "-fsanitize=memory"
}

# ==============================================================================
# Intel - ASAN
# ==============================================================================

@test "SAN: Intel/C ASAN adds -fsanitize=address in compile and link flags" {
    skip_if_compiler_missing "intel" "c"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_SAN=ASAN)

    assert_san_flag_present "$test_dir" "c" "-fsanitize=address"
}

@test "SAN: Intel/C++ ASAN adds -fsanitize=address in compile and link flags" {
    skip_if_compiler_missing "intel" "cxx"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_SAN=ASAN)

    assert_san_flag_present "$test_dir" "cxx" "-fsanitize=address"
}

# ==============================================================================
# Intel - SSAN
# ==============================================================================

@test "SAN: Intel/C SSAN adds -fstack-protector-all in compile and link flags" {
    skip_if_compiler_missing "intel" "c"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_SAN=SSAN)

    assert_san_flag_present "$test_dir" "c" "-fstack-protector-all"
}

@test "SAN: Intel/C++ SSAN adds -fstack-protector-all in compile and link flags" {
    skip_if_compiler_missing "intel" "cxx"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_SAN=SSAN)

    assert_san_flag_present "$test_dir" "cxx" "-fstack-protector-all"
}

# ==============================================================================
# Intel - UBSAN
# ==============================================================================

@test "SAN: Intel/C UBSAN adds -fsanitize=undefined in compile and link flags" {
    skip_if_compiler_missing "intel" "c"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_SAN=UBSAN)

    assert_san_flag_present "$test_dir" "c" "-fsanitize=undefined"
}

@test "SAN: Intel/C++ UBSAN adds -fsanitize=undefined in compile and link flags" {
    skip_if_compiler_missing "intel" "cxx"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_SAN=UBSAN)

    assert_san_flag_present "$test_dir" "cxx" "-fsanitize=undefined"
}

# ==============================================================================
# Intel - TSAN
# ==============================================================================

@test "SAN: Intel/C TSAN adds -fsanitize=thread in compile and link flags" {
    skip_if_compiler_missing "intel" "c"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_SAN=TSAN)

    assert_san_flag_present "$test_dir" "c" "-fsanitize=thread"
}

@test "SAN: Intel/C++ TSAN adds -fsanitize=thread in compile and link flags" {
    skip_if_compiler_missing "intel" "cxx"
    COMPILER_TYPE=intel
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_SAN=TSAN)

    assert_san_flag_present "$test_dir" "cxx" "-fsanitize=thread"
}

# ==============================================================================
# Combined sanitizers
# ==============================================================================

@test "SAN: GNU/C ASAN+UBSAN adds -fsanitize=address in compile and link flags" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" "-DLIBRA_SAN=ASAN+UBSAN")

    assert_san_flag_present "$test_dir" "c" "-fsanitize=address"
}

@test "SAN: GNU/C ASAN+UBSAN adds -fsanitize=undefined in compile and link flags" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" "-DLIBRA_SAN=ASAN+UBSAN")

    assert_san_flag_present "$test_dir" "c" "-fsanitize=undefined"
}

@test "SAN: GNU/C++ ASAN+UBSAN adds both sanitizer flags in compile and link flags" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" "-DLIBRA_SAN=ASAN+UBSAN")

    assert_san_flag_present "$test_dir" "cxx" "-fsanitize=address"
    assert_san_flag_present "$test_dir" "cxx" "-fsanitize=undefined"
}

# ==============================================================================
# Default behaviour
# ==============================================================================

@test "SAN: Default (unset) does not add sanitizer flags" {
    # LIBRA_SAN defaults to NONE
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c")

    assert_compile_flag_absent "$test_dir" "c" "-fsanitize=leak"
    assert_compile_flag_absent "$test_dir" "c" "-fsanitize=address"
    assert_compile_flag_absent "$test_dir" "c" "-fsanitize=thread"
    assert_compile_flag_absent "$test_dir" "c" "-fstack-protector-all"
}

@test "SAN: Cache variable persists across reconfiguration" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_SAN=ASAN)

    run cache_value_equals "$test_dir" "LIBRA_SAN" "ASAN"
    [ "$status" -eq 0 ]

    cd "$test_dir"
    run cmake "$BATS_TEST_DIRNAME/sample_build_info" --log-level=ERROR
    [ "$status" -eq 0 ]

    run cache_value_equals "$test_dir" "LIBRA_SAN" "ASAN"
    [ "$status" -eq 0 ]
}

@test "SAN: Can change value on reconfiguration" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_SAN=ASAN)

    run cache_value_equals "$test_dir" "LIBRA_SAN" "ASAN"
    [ "$status" -eq 0 ]

    cd "$test_dir"
    run cmake "$BATS_TEST_DIRNAME/sample_build_info" -DLIBRA_SAN=UBSAN --log-level=ERROR
    [ "$status" -eq 0 ]

    run cache_value_equals "$test_dir" "LIBRA_SAN" "UBSAN"
    [ "$status" -eq 0 ]
}
