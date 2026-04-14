#!/usr/bin/env bats
#
# BATS tests for LIBRA_ANALYSIS (Static Analysis)
#
# LIBRA_ANALYSIS controls whether static analysis targets are created:
#   - ON: Creates analysis, format, and fix targets
#   - OFF: No analysis targets created
#
# Expected targets when ON:
#   - analyze: Run all static analyzers
#   - format: Run all code formatters
#   - fix: Run all auto-fixers
#   - analyze-clang-check: Clang static analyzer
#   - analyze-clang-tidy: Clang-tidy checker
#   - analyze-cppcheck: Cppcheck analyzer
#   - analyze-cmake-format: CMake formatter checker
#   - format-clang-format: Clang-format formatter
#   - format-cmake-format: CMake formatter
#   - fix-clang-tidy: Clang-tidy auto-fixer
#   - fix-clang-check: Clang-check auto-fixer
#

load test_helpers

setup() {
    setup_libra_test
}

@test "ANALYSIS: LIBRA_ANALYSIS=ON creates analyze target" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_ANALYSIS=ON)

    assert_target_exists "$test_dir" "analyze"
}

@test "ANALYSIS: LIBRA_ANALYSIS=ON creates format target" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_ANALYSIS=ON)

    assert_target_exists "$test_dir" "format"
}

@test "ANALYSIS: LIBRA_ANALYSIS=ON creates fix target" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_ANALYSIS=ON)

    assert_target_exists "$test_dir" "fix"
}

@test "ANALYSIS: LIBRA_ANALYSIS=ON creates analyze-clang-check target" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_ANALYSIS=ON)

    assert_target_exists "$test_dir" "analyze-clang-check"
}

@test "ANALYSIS: LIBRA_ANALYSIS=ON creates analyze-clang-tidy target" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_ANALYSIS=ON)

    assert_target_exists "$test_dir" "analyze-clang-tidy"
}

@test "ANALYSIS: LIBRA_ANALYSIS=ON creates analyze-cppcheck target" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_ANALYSIS=ON)

    assert_target_exists "$test_dir" "analyze-cppcheck"
}

@test "ANALYSIS: LIBRA_ANALYSIS=ON creates analyze-cmake-format target" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_ANALYSIS=ON)

    assert_target_exists "$test_dir" "analyze-cmake-format"
}

@test "ANALYSIS: LIBRA_ANALYSIS=ON creates format-clang-format target" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_ANALYSIS=ON)

    assert_target_exists "$test_dir" "format-clang-format"
}

@test "ANALYSIS: LIBRA_ANALYSIS=ON creates format-cmake-format target" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_ANALYSIS=ON)

    assert_target_exists "$test_dir" "format-cmake-format"
}

@test "ANALYSIS: LIBRA_ANALYSIS=ON creates fix-clang-tidy target" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_ANALYSIS=ON)

    assert_target_exists "$test_dir" "fix-clang-tidy"
}

@test "ANALYSIS: LIBRA_ANALYSIS=ON creates fix-clang-check target" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_ANALYSIS=ON)

    assert_target_exists "$test_dir" "fix-clang-check"
}

@test "ANALYSIS: LIBRA_ANALYSIS=ON creates all expected targets" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_ANALYSIS=ON)

    # Check all targets in one test
    assert_target_exists "$test_dir" "analyze"
    assert_target_exists "$test_dir" "format"
    assert_target_exists "$test_dir" "fix"
    assert_target_exists "$test_dir" "analyze-clang-check"
    assert_target_exists "$test_dir" "analyze-clang-tidy"
    assert_target_exists "$test_dir" "analyze-cppcheck"
    assert_target_exists "$test_dir" "analyze-cmake-format"
    assert_target_exists "$test_dir" "format-clang-format"
    assert_target_exists "$test_dir" "format-cmake-format"
    assert_target_exists "$test_dir" "fix-clang-tidy"
    assert_target_exists "$test_dir" "fix-clang-check"
}

@test "ANALYSIS: LIBRA_ANALYSIS=OFF does not create analyze target" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_ANALYSIS=OFF)

    assert_target_absent "$test_dir" "analyze"
}

@test "ANALYSIS: LIBRA_ANALYSIS=OFF does not create format target" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_ANALYSIS=OFF)

    assert_target_absent "$test_dir" "format"
}

@test "ANALYSIS: LIBRA_ANALYSIS=OFF does not create fix target" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_ANALYSIS=OFF)

    assert_target_absent "$test_dir" "fix"
}

@test "ANALYSIS: LIBRA_ANALYSIS=OFF ensures no analysis targets exist" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_ANALYSIS=OFF)

    # Check all targets are absent
    assert_target_absent "$test_dir" "analyze"
    assert_target_absent "$test_dir" "format"
    assert_target_absent "$test_dir" "fix"
    assert_target_absent "$test_dir" "analyze-clang-check"
    assert_target_absent "$test_dir" "analyze-clang-tidy"
    assert_target_absent "$test_dir" "analyze-cppcheck"
    assert_target_absent "$test_dir" "analyze-cmake-format"
    assert_target_absent "$test_dir" "format-clang-format"
    assert_target_absent "$test_dir" "format-cmake-format"
    assert_target_absent "$test_dir" "fix-clang-tidy"
    assert_target_absent "$test_dir" "fix-clang-check"
}

@test "ANALYSIS: Works with C++ projects when ON" {
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_ANALYSIS=ON)

    assert_target_exists "$test_dir" "analyze"
    assert_target_exists "$test_dir" "format"
    assert_target_exists "$test_dir" "fix"
}

@test "ANALYSIS: Works with C++ projects when OFF" {
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_ANALYSIS=OFF)

    assert_target_absent "$test_dir" "analyze"
    assert_target_absent "$test_dir" "format"
    assert_target_absent "$test_dir" "fix"
}

@test "ANALYSIS: Works with compilation database enabled" {
    skip_if_compiler_missing "clang" "c"

    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" \
        -DLIBRA_ANALYSIS=ON \
        -DLIBRA_USE_COMPDB=YES)

    # Should still create all targets
    assert_target_exists "$test_dir" "analyze"
    assert_target_exists "$test_dir" "format"
    assert_target_exists "$test_dir" "fix"
}

@test "ANALYSIS: Works without compilation database" {
    test_dir=$(run_libra_cmake_test "c" \
        -DLIBRA_ANALYSIS=ON \
        -DLIBRA_USE_COMPDB=NO)

    # Should still create all targets
    assert_target_exists "$test_dir" "analyze"
    assert_target_exists "$test_dir" "format"
    assert_target_exists "$test_dir" "fix"
}

@test "ANALYSIS: Default behavior (no LIBRA_ANALYSIS specified)" {
    # Test what happens when LIBRA_ANALYSIS is not explicitly set
    test_dir=$(run_libra_cmake_test "c")

    # Default is typically OFF
    assert_target_absent "$test_dir" "analyze"
}

@test "ANALYSIS: Cache variable persists across reconfiguration" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_ANALYSIS=ON)

    run cache_value_equals "$test_dir" "LIBRA_ANALYSIS" "ON"
    [ "$status" -eq 0 ]

    # Reconfigure without specifying LIBRA_ANALYSIS - should keep cached value
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
# Per-category clang-tidy subtargets
# ==============================================================================

@test "ANALYSIS: LIBRA_ANALYSIS=ON creates analyze-clang-tidy-bugprone subtarget" {
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_ANALYSIS=ON)

    assert_target_exists "$test_dir" "analyze-clang-tidy-bugprone"
}

@test "ANALYSIS: LIBRA_ANALYSIS=ON creates analyze-clang-tidy-readability subtarget" {
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_ANALYSIS=ON)

    assert_target_exists "$test_dir" "analyze-clang-tidy-readability"
}

@test "ANALYSIS: LIBRA_ANALYSIS=ON creates analyze-clang-tidy-cppcoreguidelines subtarget" {
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_ANALYSIS=ON)

    assert_target_exists "$test_dir" "analyze-clang-tidy-cppcoreguidelines"
}

@test "ANALYSIS: LIBRA_ANALYSIS=ON creates analyze-clang-tidy-modernize subtarget" {
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_ANALYSIS=ON)

    assert_target_exists "$test_dir" "analyze-clang-tidy-modernize"
}

@test "ANALYSIS: LIBRA_ANALYSIS=ON creates all expected clang-tidy category subtargets" {
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_ANALYSIS=ON)

    for category in clang-analyzer-core abseil cppcoreguidelines readability hicpp \
                    bugprone cert performance portability concurrency modernize misc google; do
        assert_target_exists "$test_dir" "analyze-clang-tidy-${category}"
    done
}

@test "ANALYSIS: LIBRA_ANALYSIS=OFF does not create any clang-tidy category subtargets" {
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_ANALYSIS=OFF)

    for category in bugprone readability modernize; do
        assert_target_absent "$test_dir" "analyze-clang-tidy-${category}"
    done
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

    # The stub directory must contain at least one generated .cpp stub
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

@test "ANALYSIS: no stub directory created when project has no public headers" {
    # Default sample_build_info has no INTERFACE_INCLUDE_DIRECTORIES
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_ANALYSIS=ON)

    # Either no stubs dir, or it exists but is empty
    if [ -d "$test_dir/libra_header_stubs" ]; then
        run find "$test_dir/libra_header_stubs" -name "*.cpp" -o -name "*.c"
        [ -z "$output" ]
    fi
}
