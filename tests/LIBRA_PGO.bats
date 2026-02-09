#!/usr/bin/env bats
#
# BATS tests for LIBRA_PGO (Profile-Guided Optimization)
#
# LIBRA_PGO controls profile-guided optimization:
#   - NONE: No PGO (default)
#   - GEN:  Adds -fprofile-generate (compile and link)
#   - USE:  Adds -fprofile-use (compile and link)
#
# All three compilers (GNU, Clang, Intel) use identical flags.
# Flags appear in BOTH COMPILE_FLAGS and LINK_FLAGS.
# Build type: Release (matches the shell test).
#
# Typical workflow:
#   1. Build with LIBRA_PGO=GEN
#   2. Run the binary to generate profile data (*.profraw, default.profdata, etc.)
#   3. Rebuild with LIBRA_PGO=USE (consuming the profile data)
#
# These tests only check flag presence/absence, not the full workflow.
#

load test_helpers

setup() {
    setup_libra_test
    export CMAKE_BUILD_TYPE=Release
    export LIBRA_DIR="${LIBRA_DIR:-$(cd "$BATS_TEST_DIRNAME/.." && pwd)}"
}

# Helper: assert flag present in both compile and link flags
assert_pgo_flag_present() {
    local test_dir="$1"
    local lang="$2"
    local flag="$3"

    assert_compile_flag_present "$test_dir" "$lang" "$flag"
    assert_link_flag_present    "$test_dir" "$lang" "$flag"
}

# ==============================================================================
# NONE — no PGO
# ==============================================================================

@test "PGO: GNU/C NONE does not add -fprofile-generate" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_PGO=NONE)

    assert_compile_flag_absent "$test_dir" "c" "-fprofile-generate"
    assert_link_flag_absent "$test_dir" "c" "-fprofile-generate"
}

@test "PGO: GNU/C NONE does not add -fprofile-use" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_PGO=NONE)

    assert_compile_flag_absent "$test_dir" "c" "-fprofile-use"
    assert_link_flag_absent "$test_dir" "c" "-fprofile-use"
}

@test "PGO: GNU/C++ NONE does not add -fprofile-generate" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_PGO=NONE)

    assert_compile_flag_absent "$test_dir" "cxx" "-fprofile-generate"
    assert_link_flag_absent "$test_dir" "cxx" "-fprofile-generate"
}

@test "PGO: GNU/C++ NONE does not add -fprofile-use" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_PGO=NONE)

    assert_compile_flag_absent "$test_dir" "cxx" "-fprofile-use"
    assert_link_flag_absent "$test_dir" "cxx" "-fprofile-use"
}

# ==============================================================================
# GNU - full PGO workflow (GEN → run binary → USE)
# ==============================================================================

@test "PGO: GNU/C full workflow - GEN then USE" {
    COMPILER_TYPE=gnu
    CMAKE_BUILD_TYPE=Release
    
    # Use same test_dir for both GEN and USE phases
    test_dir="$BATS_TEST_TMPDIR/pgo_gnu_c"
    rm -rf "$test_dir"
    
    # Phase 1: GEN - generate profile data
    mkdir -p "$test_dir" && cd "$test_dir"
    run cmake "$LIBRA_DIR/tests/sample_build_info" \
        -DCMAKE_C_COMPILER=gcc \
        -DCMAKE_BUILD_TYPE=Release \
        -DLIBRA_PGO=GEN \
        -DLIBRA_TEST_LANGUAGE=C
    [ "$status" -eq 0 ]
    
    run make
    [ "$status" -eq 0 ]
    
    # Verify GEN flags
    assert_pgo_flag_present "$test_dir" "c" "-fprofile-generate"
    assert_compile_flag_absent "$test_dir" "c" "-fprofile-use"
    
    # Run binary to generate profile data
    run "$test_dir/bin/sample_build_info"
    [ "$status" -eq 0 ]
    
    # Phase 2: USE - rebuild with profile data
    # Clean build artifacts but keep profile data
    rm -rf "$test_dir/CMakeFiles" "$test_dir/CMakeCache.txt" "$test_dir/Makefile"
    rm -rf "$test_dir/bin" "$test_dir/build_info"
    
    cd "$test_dir"
    run cmake "$LIBRA_DIR/tests/sample_build_info" \
        -DCMAKE_C_COMPILER=gcc \
        -DCMAKE_BUILD_TYPE=Release \
        -DLIBRA_PGO=USE \
        -DLIBRA_TEST_LANGUAGE=C
    [ "$status" -eq 0 ]
    
    # Verify USE flags (don't need to make, just check flags)
    assert_pgo_flag_present "$test_dir" "c" "-fprofile-use"
    assert_compile_flag_absent "$test_dir" "c" "-fprofile-generate"
}

@test "PGO: GNU/C++ full workflow - GEN then USE" {
    COMPILER_TYPE=gnu
    CMAKE_BUILD_TYPE=Release
    
    test_dir="$BATS_TEST_TMPDIR/pgo_gnu_cxx"
    rm -rf "$test_dir"
    
    # Phase 1: GEN
    mkdir -p "$test_dir" && cd "$test_dir"
    run cmake "$LIBRA_DIR/tests/sample_build_info" \
        -DCMAKE_CXX_COMPILER=g++ \
        -DCMAKE_BUILD_TYPE=Release \
        -DLIBRA_PGO=GEN \
        -DLIBRA_TEST_LANGUAGE=CXX
    [ "$status" -eq 0 ]
    
    run make
    [ "$status" -eq 0 ]
    
    assert_pgo_flag_present "$test_dir" "cxx" "-fprofile-generate"
    
    # Run binary to generate profile data
    run "$test_dir/bin/sample_build_info"
    [ "$status" -eq 0 ]
    
    # Phase 2: USE
    rm -rf "$test_dir/CMakeFiles" "$test_dir/CMakeCache.txt" "$test_dir/Makefile"
    rm -rf "$test_dir/bin" "$test_dir/build_info"
    
    cd "$test_dir"
    run cmake "$LIBRA_DIR/tests/sample_build_info" \
        -DCMAKE_CXX_COMPILER=g++ \
        -DCMAKE_BUILD_TYPE=Release \
        -DLIBRA_PGO=USE \
        -DLIBRA_TEST_LANGUAGE=CXX
    [ "$status" -eq 0 ]
    
    assert_pgo_flag_present "$test_dir" "cxx" "-fprofile-use"
}

# ==============================================================================
# Clang - full PGO workflow (GEN → run binary → merge profiles → USE)
# ==============================================================================

@test "PGO: Clang/C full workflow - GEN then USE with profdata merge" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    CMAKE_BUILD_TYPE=Release
    
    test_dir="$BATS_TEST_TMPDIR/pgo_clang_c"
    rm -rf "$test_dir"
    
    # Phase 1: GEN
    mkdir -p "$test_dir" && cd "$test_dir"
    run cmake "$LIBRA_DIR/tests/sample_build_info" \
        -DCMAKE_C_COMPILER=clang \
        -DCMAKE_BUILD_TYPE=Release \
        -DLIBRA_PGO=GEN \
        -DLIBRA_TEST_LANGUAGE=C
    [ "$status" -eq 0 ]
    
    run make
    [ "$status" -eq 0 ]
    
    assert_pgo_flag_present "$test_dir" "c" "-fprofile-generate"
    assert_compile_flag_absent "$test_dir" "c" "-fprofile-use"
    
    # Run binary to generate .profraw files
    run "$test_dir/bin/sample_build_info"
    [ "$status" -eq 0 ]
    
    # Merge profile data (Clang-specific step)
    # Try common llvm-profdata names
    cd "$test_dir"
    if command -v llvm-profdata-17 &> /dev/null; then
        run llvm-profdata-17 merge -o default.profdata default*.profraw
    elif command -v llvm-profdata &> /dev/null; then
        run llvm-profdata merge -o default.profdata default*.profraw
    else
        skip "llvm-profdata not found"
    fi
    [ "$status" -eq 0 ]
    
    # Phase 2: USE
    rm -rf "$test_dir/CMakeFiles" "$test_dir/CMakeCache.txt" "$test_dir/Makefile"
    rm -rf "$test_dir/bin" "$test_dir/build_info"
    
    cd "$test_dir"
    run cmake "$LIBRA_DIR/tests/sample_build_info" \
        -DCMAKE_C_COMPILER=clang \
        -DCMAKE_BUILD_TYPE=Release \
        -DLIBRA_PGO=USE \
        -DLIBRA_TEST_LANGUAGE=C
    [ "$status" -eq 0 ]
    
    assert_pgo_flag_present "$test_dir" "c" "-fprofile-use"
    assert_compile_flag_absent "$test_dir" "c" "-fprofile-generate"
}

@test "PGO: Clang/C++ full workflow - GEN then USE with profdata merge" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    CMAKE_BUILD_TYPE=Release
    
    test_dir="$BATS_TEST_TMPDIR/pgo_clang_cxx"
    rm -rf "$test_dir"
    
    # Phase 1: GEN
    mkdir -p "$test_dir" && cd "$test_dir"
    run cmake "$LIBRA_DIR/tests/sample_build_info" \
        -DCMAKE_CXX_COMPILER=clang++ \
        -DCMAKE_BUILD_TYPE=Release \
        -DLIBRA_PGO=GEN \
        -DLIBRA_TEST_LANGUAGE=CXX
    [ "$status" -eq 0 ]
    
    run make
    [ "$status" -eq 0 ]
    
    assert_pgo_flag_present "$test_dir" "cxx" "-fprofile-generate"
    
    # Run binary
    run "$test_dir/bin/sample_build_info"
    [ "$status" -eq 0 ]
    
    # Merge profile data
    cd "$test_dir"
    if command -v llvm-profdata-17 &> /dev/null; then
        run llvm-profdata-17 merge -o default.profdata default*.profraw
    elif command -v llvm-profdata &> /dev/null; then
        run llvm-profdata merge -o default.profdata default*.profraw
    else
        skip "llvm-profdata not found"
    fi
    [ "$status" -eq 0 ]
    
    # Phase 2: USE
    rm -rf "$test_dir/CMakeFiles" "$test_dir/CMakeCache.txt" "$test_dir/Makefile"
    rm -rf "$test_dir/bin" "$test_dir/build_info"
    
    cd "$test_dir"
    run cmake "$LIBRA_DIR/tests/sample_build_info" \
        -DCMAKE_CXX_COMPILER=clang++ \
        -DCMAKE_BUILD_TYPE=Release \
        -DLIBRA_PGO=USE \
        -DLIBRA_TEST_LANGUAGE=CXX
    [ "$status" -eq 0 ]
    
    assert_pgo_flag_present "$test_dir" "cxx" "-fprofile-use"
}

# ==============================================================================
# Intel - full PGO workflow (GEN → run binary → USE)
# ==============================================================================

@test "PGO: Intel/C full workflow - GEN then USE" {
    skip_if_compiler_missing "intel" "c"
    COMPILER_TYPE=intel
    CMAKE_BUILD_TYPE=Release
    
    test_dir="$BATS_TEST_TMPDIR/pgo_intel_c"
    rm -rf "$test_dir"
    
    # Phase 1: GEN
    mkdir -p "$test_dir" && cd "$test_dir"
    run cmake "$LIBRA_DIR/tests/sample_build_info" \
        -DCMAKE_C_COMPILER=icx \
        -DCMAKE_BUILD_TYPE=Release \
        -DLIBRA_PGO=GEN \
        -DLIBRA_TEST_LANGUAGE=C
    [ "$status" -eq 0 ]
    
    run make
    [ "$status" -eq 0 ]
    
    assert_pgo_flag_present "$test_dir" "c" "-fprofile-generate"
    assert_compile_flag_absent "$test_dir" "c" "-fprofile-use"
    
    # Run binary to generate profile data
    run "$test_dir/bin/sample_build_info"
    [ "$status" -eq 0 ]
    
    # Phase 2: USE
    rm -rf "$test_dir/CMakeFiles" "$test_dir/CMakeCache.txt" "$test_dir/Makefile"
    rm -rf "$test_dir/bin" "$test_dir/build_info"
    
    cd "$test_dir"
    run cmake "$LIBRA_DIR/tests/sample_build_info" \
        -DCMAKE_C_COMPILER=icx \
        -DCMAKE_BUILD_TYPE=Release \
        -DLIBRA_PGO=USE \
        -DLIBRA_TEST_LANGUAGE=C
    [ "$status" -eq 0 ]
    
    assert_pgo_flag_present "$test_dir" "c" "-fprofile-use"
    assert_compile_flag_absent "$test_dir" "c" "-fprofile-generate"
}

@test "PGO: Intel/C++ full workflow - GEN then USE" {
    skip_if_compiler_missing "intel" "cxx"
    COMPILER_TYPE=intel
    CMAKE_BUILD_TYPE=Release
    
    test_dir="$BATS_TEST_TMPDIR/pgo_intel_cxx"
    rm -rf "$test_dir"
    
    # Phase 1: GEN
    mkdir -p "$test_dir" && cd "$test_dir"
    run cmake "$LIBRA_DIR/tests/sample_build_info" \
        -DCMAKE_CXX_COMPILER=icpx \
        -DCMAKE_BUILD_TYPE=Release \
        -DLIBRA_PGO=GEN \
        -DLIBRA_TEST_LANGUAGE=CXX
    [ "$status" -eq 0 ]
    
    run make
    [ "$status" -eq 0 ]
    
    assert_pgo_flag_present "$test_dir" "cxx" "-fprofile-generate"
    
    # Run binary to generate profile data
    run "$test_dir/bin/sample_build_info"
    [ "$status" -eq 0 ]
    
    # Phase 2: USE
    rm -rf "$test_dir/CMakeFiles" "$test_dir/CMakeCache.txt" "$test_dir/Makefile"
    rm -rf "$test_dir/bin" "$test_dir/build_info"
    
    cd "$test_dir"
    run cmake "$LIBRA_DIR/tests/sample_build_info" \
        -DCMAKE_CXX_COMPILER=icpx \
        -DCMAKE_BUILD_TYPE=Release \
        -DLIBRA_PGO=USE \
        -DLIBRA_TEST_LANGUAGE=CXX
    [ "$status" -eq 0 ]
    
    assert_pgo_flag_present "$test_dir" "cxx" "-fprofile-use"
}

# ==============================================================================
# Default behaviour
# ==============================================================================

@test "PGO: Default (NONE) does not add PGO flags" {
    # LIBRA_PGO defaults to NONE
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c")

    assert_compile_flag_absent "$test_dir" "c" "-fprofile-generate"
    assert_compile_flag_absent "$test_dir" "c" "-fprofile-use"
}
