#!/usr/bin/env bats
#
# BATS tests for LIBRA_CODE_COV
#
# LIBRA_CODE_COV enables code coverage instrumentation:
#   - OFF: No coverage instrumentation (default)
#   - ON:  Adds coverage flags (compiler-specific, see below)
#
# LIBRA_CODE_COV_NATIVE controls output format (only relevant when ON):
#   - YES: Use compiler's native format (default)
#   - NO:  Use GNU gcov format (for cross-compiler compatibility)
#
# Supported compilers: gnu, clang only (Intel does not support LIBRA_CODE_COV).
# Build type: Debug (matches the shell test).
#
# Flags go to BOTH compile and link flags.
#
# Per-compiler flags when LIBRA_CODE_COV=ON and LIBRA_CODE_COV_NATIVE=YES:
#
#   GNU compile:  -fprofile-arcs -ftest-coverage -fno-inline -fprofile-update=atomic
#   GNU link:     -fprofile-arcs
#
#   Clang compile: -fprofile-instr-generate -fcoverage-mapping -fno-inline
#   Clang link:    -fprofile-instr-generate
#
# When LIBRA_CODE_COV_NATIVE=NO, both compilers use GNU gcov format (--coverage).
#
# Makefile targets created when LIBRA_CODE_COV=ON:
#   GNU:   lcov-preinfo, lcov-report, gcovr-report, gcovr-check
#   Clang: llvm-summary, llvm-report, llvm-show, llvm-export-lcov, llvm-coverage
#

load test_helpers

setup() {
    setup_libra_test
    export CMAKE_BUILD_TYPE=Debug
    export LIBRA_DIR="${LIBRA_DIR:-$(cd "$BATS_TEST_DIRNAME/.." && pwd)}"
}

# Helper: assert flag present in both compile and link flags
assert_cov_flag_present() {
    local test_dir="$1"
    local lang="$2"
    local flag="$3"

    assert_compile_flag_present "$test_dir" "$lang" "$flag"
    assert_link_flag_present    "$test_dir" "$lang" "$flag"
}

# ==============================================================================
# OFF — no coverage
# ==============================================================================

@test "CODE_COV: GNU/C OFF does not add -fprofile-arcs" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_CODE_COV=OFF)

    assert_compile_flag_absent "$test_dir" "c" "-fprofile-arcs"
}

@test "CODE_COV: GNU/C OFF does not add -ftest-coverage" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_CODE_COV=OFF)

    assert_compile_flag_absent "$test_dir" "c" "-ftest-coverage"
}

@test "CODE_COV: GNU/C OFF does not add -fno-inline" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_CODE_COV=OFF)

    assert_compile_flag_absent "$test_dir" "c" "-fno-inline"
}

@test "CODE_COV: GNU/C OFF does not add -fprofile-update=atomic" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_CODE_COV=OFF)

    assert_compile_flag_absent "$test_dir" "c" "-fprofile-update=atomic"
}

@test "CODE_COV: GNU/C OFF does not create lcov targets" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_CODE_COV=OFF)

    assert_target_absent "$test_dir" "lcov-preinfo"
    assert_target_absent "$test_dir" "lcov-report"
    assert_target_absent "$test_dir" "gcovr-report"
    assert_target_absent "$test_dir" "gcovr-check"
}

@test "CODE_COV: Clang/C OFF does not add -fprofile-instr-generate" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_CODE_COV=OFF)

    assert_compile_flag_absent "$test_dir" "c" "-fprofile-instr-generate"
}

@test "CODE_COV: Clang/C OFF does not add -fcoverage-mapping" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_CODE_COV=OFF)

    assert_compile_flag_absent "$test_dir" "c" "-fcoverage-mapping"
}

@test "CODE_COV: Clang/C OFF does not create llvm targets" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_CODE_COV=OFF)

    assert_target_absent "$test_dir" "llvm-summary"
    assert_target_absent "$test_dir" "llvm-report"
    assert_target_absent "$test_dir" "llvm-show"
    assert_target_absent "$test_dir" "llvm-export-lcov"
    assert_target_absent "$test_dir" "llvm-coverage"
}

# ==============================================================================
# GNU - native format (LIBRA_CODE_COV=ON, LIBRA_CODE_COV_NATIVE=YES)
# ==============================================================================

@test "CODE_COV: GNU/C native ON - full workflow" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_CODE_COV=ON -DLIBRA_CODE_COV_NATIVE=YES)

    # Verify flags
    assert_cov_flag_present "$test_dir" "c" "-fprofile-arcs"
    assert_compile_flag_present "$test_dir" "c" "-ftest-coverage"
    assert_compile_flag_present "$test_dir" "c" "-fno-inline"
    assert_compile_flag_present "$test_dir" "c" "-fprofile-update=atomic"

    # Verify targets exist
    assert_target_exists "$test_dir" "lcov-preinfo"
    assert_target_exists "$test_dir" "lcov-report"
    assert_target_exists "$test_dir" "gcovr-report"
    assert_target_exists "$test_dir" "gcovr-check"

    # Run the binary to generate coverage data
    run "$test_dir/bin/sample_build_info"
    [ "$status" -eq 0 ]

    # Run coverage targets to verify they work
    cd "$test_dir"
    for target in lcov-preinfo lcov-report gcovr-report gcovr-check; do
        # Run binary again before each target
        run "$test_dir/bin/sample_build_info"
        [ "$status" -eq 0 ]

        run make "$target"
        [ "$status" -eq 0 ]
    done
}

@test "CODE_COV: GNU/C++ native ON - full workflow" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_CODE_COV=ON -DLIBRA_CODE_COV_NATIVE=YES)

    # Verify flags
    assert_cov_flag_present "$test_dir" "cxx" "-fprofile-arcs"

    # Verify targets exist
    assert_target_exists "$test_dir" "lcov-preinfo"
    assert_target_exists "$test_dir" "gcovr-report"

    # Run the binary to generate coverage data
    run "$test_dir/bin/sample_build_info"
    [ "$status" -eq 0 ]

    # Run coverage targets to verify they work
    cd "$test_dir"
    for target in lcov-preinfo gcovr-report; do
        run "$test_dir/bin/sample_build_info"
        [ "$status" -eq 0 ]

        run make "$target"
        [ "$status" -eq 0 ]
    done
}

# ==============================================================================
# Clang - native format (LIBRA_CODE_COV=ON, LIBRA_CODE_COV_NATIVE=YES)
# ==============================================================================

@test "CODE_COV: Clang/C native ON - full workflow" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_CODE_COV=ON -DLIBRA_CODE_COV_NATIVE=YES)

    # Verify flags
    assert_cov_flag_present "$test_dir" "c" "-fprofile-instr-generate"
    assert_compile_flag_present "$test_dir" "c" "-fcoverage-mapping"
    assert_compile_flag_present "$test_dir" "c" "-fno-inline"

    # Verify LLVM targets exist
    assert_target_exists "$test_dir" "llvm-summary"
    assert_target_exists "$test_dir" "llvm-report"
    assert_target_exists "$test_dir" "llvm-show"
    assert_target_exists "$test_dir" "llvm-export-lcov"
    assert_target_exists "$test_dir" "llvm-coverage"

    # Run the binary to generate coverage data
    run "$test_dir/bin/sample_build_info"
    [ "$status" -eq 0 ]

    # Run coverage targets to verify they work
    cd "$test_dir"
    for target in llvm-summary llvm-report llvm-show llvm-export-lcov llvm-coverage; do
        run "$test_dir/bin/sample_build_info"
        [ "$status" -eq 0 ]

        run make "$target"
        [ "$status" -eq 0 ]
    done
}

@test "CODE_COV: Clang/C++ native ON - full workflow" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_CODE_COV=ON -DLIBRA_CODE_COV_NATIVE=YES)

    # Verify flags
    assert_cov_flag_present "$test_dir" "cxx" "-fprofile-instr-generate"

    # Verify LLVM targets exist
    assert_target_exists "$test_dir" "llvm-summary"
    assert_target_exists "$test_dir" "llvm-coverage"

    # Run the binary to generate coverage data
    run "$test_dir/bin/sample_build_info"
    [ "$status" -eq 0 ]

    # Run coverage targets to verify they work
    cd "$test_dir"
    for target in llvm-summary llvm-coverage; do
        run "$test_dir/bin/sample_build_info"
        [ "$status" -eq 0 ]

        run make "$target"
        [ "$status" -eq 0 ]
    done
}

# ==============================================================================
# Clang - non-native format (LIBRA_CODE_COV_NATIVE=NO uses GNU gcov format)
# ==============================================================================

@test "CODE_COV: Clang/C non-native ON - verify GNU format" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_CODE_COV=ON -DLIBRA_CODE_COV_NATIVE=NO)

    # Verify --coverage flag (GNU gcov format)
    assert_cov_flag_present "$test_dir" "c" "--coverage"

    # Non-native clang creates GNU targets
    assert_target_exists "$test_dir" "lcov-preinfo"
    assert_target_exists "$test_dir" "gcovr-report"

    # Non-native means no LLVM-specific targets
    assert_target_absent "$test_dir" "llvm-summary"
    assert_target_absent "$test_dir" "llvm-coverage"

    # Shell script comment: "Don't try to run the targets--they won't work for clang
    # because it detects its coverage tool differently."
    # So we only verify targets exist, not that they execute successfully
}

@test "CODE_COV: Clang/C++ non-native ON - verify GNU format" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_CODE_COV=ON -DLIBRA_CODE_COV_NATIVE=NO)

    # Verify --coverage flag (GNU gcov format)
    assert_cov_flag_present "$test_dir" "cxx" "--coverage"

    # Verify GNU targets exist but don't run them
    assert_target_exists "$test_dir" "lcov-preinfo"
}

# ==============================================================================
# Default behaviour
# ==============================================================================

@test "CODE_COV: Default (OFF) does not add coverage flags" {
    # LIBRA_CODE_COV defaults to OFF
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c")

    assert_compile_flag_absent "$test_dir" "c" "-fprofile-arcs"
    assert_compile_flag_absent "$test_dir" "c" "-ftest-coverage"
}

@test "CODE_COV: Default (OFF) does not create coverage targets" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c")

    assert_target_absent "$test_dir" "lcov-report"
    assert_target_absent "$test_dir" "gcovr-report"
}
