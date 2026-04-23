#!/usr/bin/env bats
#
# BATS tests for LIBRA_ANALYSIS (Static Analysis)
#
# LIBRA_ANALYSIS controls whether static analysis targets are created:
#   - ON:  Creates analyze and fix umbrella targets plus per-tool subtargets
#   - OFF: No analysis targets created (default)
#
# Analysis targets when ON:
#   - analyze:              Run all static analyzers
#   - fix:                  Run all auto-fixers
#   - analyze-clang-check:  Clang static analyzer
#   - analyze-clang-tidy:   Clang-tidy checker (with per-category subtargets)
#   - analyze-cppcheck:     Cppcheck analyzer
#   - fix-clang-tidy:       Clang-tidy auto-fixer
#   - fix-clang-check:      Clang-check auto-fixer
#
# Format targets (format, format-check, format-clang, format-cmake, etc.)
# are controlled by LIBRA_FORMAT and are tested in LIBRA_FORMAT.bats.
#
# Note: LIBRA_ANALYSIS=ON also enables LIBRA_FORMAT internally, so format
# targets ARE present when LIBRA_ANALYSIS=ON.  Those assertions live in
# LIBRA_FORMAT.bats, not here.
#

load test_helpers

setup() {
    setup_libra_test
}

# ==============================================================================
# ON — analysis targets created
# ==============================================================================

@test "ANALYSIS: LIBRA_ANALYSIS=ON creates all analysis targets (C)" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_ANALYSIS=ON)

    assert_target_exists "$test_dir" "analyze"
    assert_target_exists "$test_dir" "fix"
    assert_target_exists "$test_dir" "analyze-clang-check"
    assert_target_exists "$test_dir" "analyze-clang-tidy"
    assert_target_exists "$test_dir" "analyze-cppcheck"
    assert_target_exists "$test_dir" "fix-clang-tidy"
    assert_target_exists "$test_dir" "fix-clang-check"
}

@test "ANALYSIS: LIBRA_ANALYSIS=ON creates all analysis targets (C++)" {
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_ANALYSIS=ON)

    assert_target_exists "$test_dir" "analyze"
    assert_target_exists "$test_dir" "fix"
    assert_target_exists "$test_dir" "analyze-clang-check"
    assert_target_exists "$test_dir" "analyze-clang-tidy"
    assert_target_exists "$test_dir" "analyze-cppcheck"
    assert_target_exists "$test_dir" "fix-clang-tidy"
    assert_target_exists "$test_dir" "fix-clang-check"
}

# ==============================================================================
# OFF — analysis targets absent
# ==============================================================================

@test "ANALYSIS: LIBRA_ANALYSIS=OFF creates no analysis targets (C)" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_ANALYSIS=OFF)

    assert_target_absent "$test_dir" "analyze"
    assert_target_absent "$test_dir" "fix"
    assert_target_absent "$test_dir" "analyze-clang-check"
    assert_target_absent "$test_dir" "analyze-clang-tidy"
    assert_target_absent "$test_dir" "analyze-cppcheck"
    assert_target_absent "$test_dir" "fix-clang-tidy"
    assert_target_absent "$test_dir" "fix-clang-check"
}

@test "ANALYSIS: LIBRA_ANALYSIS=OFF creates no analysis targets (C++)" {
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_ANALYSIS=OFF)

    assert_target_absent "$test_dir" "analyze"
    assert_target_absent "$test_dir" "fix"
    assert_target_absent "$test_dir" "analyze-clang-check"
    assert_target_absent "$test_dir" "analyze-clang-tidy"
    assert_target_absent "$test_dir" "analyze-cppcheck"
    assert_target_absent "$test_dir" "fix-clang-tidy"
    assert_target_absent "$test_dir" "fix-clang-check"
}

@test "ANALYSIS: Default (unset) creates no analysis targets" {
    test_dir=$(run_libra_cmake_test "c")

    assert_target_absent "$test_dir" "analyze"
    assert_target_absent "$test_dir" "fix"
}

# ==============================================================================
# Per-category clang-tidy subtargets
# ==============================================================================

@test "ANALYSIS: LIBRA_ANALYSIS=ON creates all clang-tidy category subtargets" {
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_ANALYSIS=ON)

    for category in clang-analyzer-core abseil cppcoreguidelines readability hicpp \
                    bugprone cert performance portability concurrency modernize misc google; do
        assert_target_exists "$test_dir" "analyze-clang-tidy-${category}"
    done
}

@test "ANALYSIS: LIBRA_ANALYSIS=OFF creates no clang-tidy category subtargets" {
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_ANALYSIS=OFF)

    for category in clang-analyzer-core abseil cppcoreguidelines readability hicpp \
                    bugprone cert performance portability concurrency modernize misc google; do
        assert_target_absent "$test_dir" "analyze-clang-tidy-${category}"
    done
}

# ==============================================================================
# LIBRA_USE_COMPDB interaction
# ==============================================================================

@test "ANALYSIS: LIBRA_USE_COMPDB=YES creates analysis targets" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" \
        -DLIBRA_ANALYSIS=ON \
        -DLIBRA_USE_COMPDB=YES)

    assert_target_exists "$test_dir" "analyze"
    assert_target_exists "$test_dir" "analyze-clang-tidy"
    assert_target_exists "$test_dir" "analyze-clang-check"
}

@test "ANALYSIS: LIBRA_USE_COMPDB=NO creates analysis targets" {
    test_dir=$(run_libra_cmake_test "c" \
        -DLIBRA_ANALYSIS=ON \
        -DLIBRA_USE_COMPDB=NO)

    assert_target_exists "$test_dir" "analyze"
    assert_target_exists "$test_dir" "analyze-clang-tidy"
    assert_target_exists "$test_dir" "analyze-clang-check"
}

# ==============================================================================
# LIBRA_CLANG_TOOLS_USE_FIXED_DB
# ==============================================================================

@test "ANALYSIS: LIBRA_CLANG_TOOLS_USE_FIXED_DB=YES creates analysis targets" {
    test_dir=$(run_libra_cmake_test "cxx" \
        -DLIBRA_ANALYSIS=ON \
        -DLIBRA_USE_COMPDB=NO \
        -DLIBRA_CLANG_TOOLS_USE_FIXED_DB=YES)

    assert_target_exists "$test_dir" "analyze"
    assert_target_exists "$test_dir" "analyze-clang-tidy"
    assert_target_exists "$test_dir" "analyze-clang-check"
}

@test "ANALYSIS: LIBRA_CLANG_TOOLS_USE_FIXED_DB=NO creates analysis targets" {
    test_dir=$(run_libra_cmake_test "cxx" \
        -DLIBRA_ANALYSIS=ON \
        -DLIBRA_USE_COMPDB=NO \
        -DLIBRA_CLANG_TOOLS_USE_FIXED_DB=NO)

    assert_target_exists "$test_dir" "analyze"
    assert_target_exists "$test_dir" "analyze-clang-tidy"
    assert_target_exists "$test_dir" "analyze-clang-check"
}

@test "ANALYSIS: LIBRA_CLANG_TOOLS_USE_FIXED_DB stored in cache" {
    test_dir=$(run_libra_cmake_test "cxx" \
        -DLIBRA_ANALYSIS=ON \
        -DLIBRA_CLANG_TOOLS_USE_FIXED_DB=YES)

    run cache_value_equals "$test_dir" "LIBRA_CLANG_TOOLS_USE_FIXED_DB" "YES"
    [ "$status" -eq 0 ]
}

# ==============================================================================
# Cache persistence
# ==============================================================================

@test "ANALYSIS: Cache variable persists across reconfiguration" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_ANALYSIS=ON)

    run cache_value_equals "$test_dir" "LIBRA_ANALYSIS" "ON"
    [ "$status" -eq 0 ]

    cd "$test_dir"
    run cmake "$BATS_TEST_DIRNAME/sample_build_info" --log-level=ERROR
    [ "$status" -eq 0 ]

    run cache_value_equals "$test_dir" "LIBRA_ANALYSIS" "ON"
    [ "$status" -eq 0 ]
}

@test "ANALYSIS: Can change value on reconfiguration" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_ANALYSIS=ON)

    run cache_value_equals "$test_dir" "LIBRA_ANALYSIS" "ON"
    [ "$status" -eq 0 ]

    cd "$test_dir"
    run cmake "$BATS_TEST_DIRNAME/sample_build_info" -DLIBRA_ANALYSIS=OFF --log-level=ERROR
    [ "$status" -eq 0 ]

    run cache_value_equals "$test_dir" "LIBRA_ANALYSIS" "OFF"
    [ "$status" -eq 0 ]
}

# ==============================================================================
# Header stub generation
# ==============================================================================

@test "ANALYSIS: stub directory created when project has public headers" {
    test_dir=$(run_libra_cmake_test "cxx" \
        -DLIBRA_ANALYSIS=ON \
        -DLIBRA_TEST_STUBS=ON)

    [ -d "$test_dir/libra_header_stubs" ]
}

@test "ANALYSIS: stub file generated for uncovered public header" {
    test_dir=$(run_libra_cmake_test "cxx" \
        -DLIBRA_ANALYSIS=ON \
        -DLIBRA_TEST_STUBS=ON)

    run find "$test_dir/libra_header_stubs" -name "*.cpp" -o -name "*.c"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "ANALYSIS: stub file is included in analysis stubs library target" {
    test_dir=$(run_libra_cmake_test "cxx" \
        -DLIBRA_ANALYSIS=ON \
        -DLIBRA_TEST_STUBS=ON)

    assert_target_exists "$test_dir" "_sample_build_info_analysis_stubs"
}

@test "ANALYSIS: no stub files created when project has no public headers" {
    # Default sample_build_info has no INTERFACE_INCLUDE_DIRECTORIES
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_ANALYSIS=ON)

    # Either no stubs dir, or it exists but contains no stub files
    if [ -d "$test_dir/libra_header_stubs" ]; then
        run find "$test_dir/libra_header_stubs" -name "*.cpp" -o -name "*.c"
        [ -z "$output" ]
    fi
}

@test "ANALYSIS: stale stub pruning does not break reconfiguration" {
    # First configure with stubs enabled
    test_dir=$(run_libra_cmake_test "cxx" \
        -DLIBRA_ANALYSIS=ON \
        -DLIBRA_TEST_STUBS=ON)

    # Reconfigure — _libra_prune_stale_stubs must not error
    run reconfigure_libra_test "$test_dir" "cxx" \
        -DLIBRA_ANALYSIS=ON \
        -DLIBRA_TEST_STUBS=ON
    [ "$status" -eq 0 ]
}
