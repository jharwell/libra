#!/usr/bin/env bats
#
# BATS tests for LIBRA_DOCS (Documentation Generation)
#
# LIBRA_DOCS controls whether documentation targets are created:
#   - ON: Creates apidoc targets (apidoc, apidoc-check, etc.)
#   - OFF: No documentation targets created
#
# Expected targets when ON:
#   - apidoc: Generate API documentation with Doxygen
#   - apidoc-check: Parent target for documentation checks
#   - apidoc-check-doxygen: Check documentation with Doxygen warnings as errors
#   - apidoc-check-clang: Check doxygen markup with clang
#

load test_helpers

setup() {
    setup_libra_test
}

@test "DOCS: LIBRA_DOCS=ON creates all expected targets" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_DOCS=ON)

    # Check all targets in one test
    assert_target_exists "$test_dir" "apidoc"
    assert_target_exists "$test_dir" "apidoc-check"
    assert_target_exists "$test_dir" "apidoc-check-doxygen"
    assert_target_exists "$test_dir" "apidoc-check-clang"
}

@test "DOCS: LIBRA_DOCS=OFF ensures no documentation targets exist" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_DOCS=OFF)

    # Check all targets are absent in one test
    assert_target_absent "$test_dir" "apidoc"
    assert_target_absent "$test_dir" "apidoc-check"
    assert_target_absent "$test_dir" "apidoc-check-doxygen"
    assert_target_absent "$test_dir" "apidoc-check-clang"
}

@test "DOCS: Works with C++ projects when ON" {
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_DOCS=ON)

    assert_target_exists "$test_dir" "apidoc"
}

@test "DOCS: Works with C++ projects when OFF" {
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_DOCS=OFF)

    assert_target_absent "$test_dir" "apidoc"
}

@test "DOCS: Default behavior (no LIBRA_DOCS specified)" {
    # Test what happens when LIBRA_DOCS is not explicitly set
    # Based on LIBRA defaults, this should likely be OFF
    test_dir=$(run_libra_cmake_test "c")

    # Default is typically OFF, so targets should be absent
    assert_target_absent "$test_dir" "apidoc"
}

@test "DOCS: Cache variable persists across reconfiguration" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_DOCS=ON)

    run cache_value_equals "$test_dir" "LIBRA_DOCS" "ON"
    [ "$status" -eq 0 ]

    cd "$test_dir"
    run cmake "$BATS_TEST_DIRNAME/sample_build_info" --log-level=ERROR
    [ "$status" -eq 0 ]

    run cache_value_equals "$test_dir" "LIBRA_DOCS" "ON"
    [ "$status" -eq 0 ]
}

@test "DOCS: Can change value on reconfiguration" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_DOCS=ON)

    run cache_value_equals "$test_dir" "LIBRA_DOCS" "ON"
    [ "$status" -eq 0 ]

    cd "$test_dir"
    run cmake "$BATS_TEST_DIRNAME/sample_build_info" -DLIBRA_DOCS=OFF --log-level=ERROR
    [ "$status" -eq 0 ]

    run cache_value_equals "$test_dir" "LIBRA_DOCS" "OFF"
    [ "$status" -eq 0 ]
}
