#!/usr/bin/env bats
#
# BATS tests for LIBRA_ERL (Event Reporting Level / Logging Level)
#
# LIBRA_ERL controls logging/event reporting levels:
#   - NONE: No logging
#   - ERROR: Error level only
#   - WARN: Warning and above
#   - INFO: Info and above
#   - DEBUG: Debug and above
#   - TRACE: Trace and above
#   - ALL: All logging levels
#   - INHERIT: Inherit from parent project (default)
#

load test_helpers

setup() {
    setup_libra_test
}

@test "ERL: LIBRA_ERL=NONE sets cache variable" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_ERL=NONE)

    run cache_value_equals "$test_dir" "LIBRA_ERL" "NONE"
    [ "$status" -eq 0 ]
}

@test "ERL: LIBRA_ERL=ERROR sets cache variable" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_ERL=ERROR)

    run cache_value_equals "$test_dir" "LIBRA_ERL" "ERROR"
    [ "$status" -eq 0 ]
}

@test "ERL: LIBRA_ERL=WARN sets cache variable" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_ERL=WARN)

    run cache_value_equals "$test_dir" "LIBRA_ERL" "WARN"
    [ "$status" -eq 0 ]
}

@test "ERL: LIBRA_ERL=INFO sets cache variable" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_ERL=INFO)

    run cache_value_equals "$test_dir" "LIBRA_ERL" "INFO"
    [ "$status" -eq 0 ]
}

@test "ERL: LIBRA_ERL=DEBUG sets cache variable" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_ERL=DEBUG)

    run cache_value_equals "$test_dir" "LIBRA_ERL" "DEBUG"
    [ "$status" -eq 0 ]
}

@test "ERL: LIBRA_ERL=TRACE sets cache variable" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_ERL=TRACE)

    run cache_value_equals "$test_dir" "LIBRA_ERL" "TRACE"
    [ "$status" -eq 0 ]
}

@test "ERL: LIBRA_ERL=ALL sets cache variable" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_ERL=ALL)

    run cache_value_equals "$test_dir" "LIBRA_ERL" "ALL"
    [ "$status" -eq 0 ]
}

@test "ERL: LIBRA_ERL=INHERIT sets cache variable" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_ERL=INHERIT)

    run cache_value_equals "$test_dir" "LIBRA_ERL" "INHERIT"
    [ "$status" -eq 0 ]
}

@test "ERL: Default value is INHERIT" {
    # When LIBRA_ERL is not specified, it should default to INHERIT
    test_dir=$(run_libra_cmake_test "c")

    run cache_value_equals "$test_dir" "LIBRA_ERL" "INHERIT"
    [ "$status" -eq 0 ]
}

@test "ERL: Works with C++ projects" {
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_ERL=DEBUG)

    run cache_value_equals "$test_dir" "LIBRA_ERL" "DEBUG"
    [ "$status" -eq 0 ]
}

@test "ERL: Cache variable persists across reconfiguration" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_ERL=ERROR)

    # First check
    run cache_value_equals "$test_dir" "LIBRA_ERL" "ERROR"
    [ "$status" -eq 0 ]

    # Reconfigure without specifying LIBRA_ERL - should keep cached value
    cd "$test_dir"
    run cmake "$BATS_TEST_DIRNAME/sample_build_info" --log-level=ERROR
    [ "$status" -eq 0 ]

    # Should still be ERROR
    run cache_value_equals "$test_dir" "LIBRA_ERL" "ERROR"
    [ "$status" -eq 0 ]
}

@test "ERL: Can change value on reconfiguration" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_ERL=ERROR)

    # Verify initial value
    run cache_value_equals "$test_dir" "LIBRA_ERL" "ERROR"
    [ "$status" -eq 0 ]

    # Reconfigure with different value
    cd "$test_dir"
    run cmake "$BATS_TEST_DIRNAME/sample_build_info" -DLIBRA_ERL=DEBUG --log-level=ERROR
    [ "$status" -eq 0 ]

    # Should be DEBUG now
    run cache_value_equals "$test_dir" "LIBRA_ERL" "DEBUG"
    [ "$status" -eq 0 ]
}

# ==============================================================================
# Compile-time define propagation
#
# The cache variable being set is a necessary but not sufficient condition —
# these tests verify that the value actually reaches the compiler as a define.
# ==============================================================================

@test "ERL: LIBRA_ERL=NONE sets LIBRA_ERL=LIBRA_ERL_NONE define on target" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_ERL=NONE)

    assert_define_present "$test_dir" "c" "LIBRA_ERL=LIBRA_ERL_NONE"
}

@test "ERL: LIBRA_ERL=ERROR sets LIBRA_ERL=LIBRA_ERL_ERROR define on target" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_ERL=ERROR)

    assert_define_present "$test_dir" "c" "LIBRA_ERL=LIBRA_ERL_ERROR"
}

@test "ERL: LIBRA_ERL=WARN sets LIBRA_ERL=LIBRA_ERL_WARN define on target" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_ERL=WARN)

    assert_define_present "$test_dir" "c" "LIBRA_ERL=LIBRA_ERL_WARN"
}

@test "ERL: LIBRA_ERL=INFO sets LIBRA_ERL=LIBRA_ERL_INFO define on target" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_ERL=INFO)

    assert_define_present "$test_dir" "c" "LIBRA_ERL=LIBRA_ERL_INFO"
}

@test "ERL: LIBRA_ERL=DEBUG sets LIBRA_ERL=LIBRA_ERL_DEBUG define on target" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_ERL=DEBUG)

    assert_define_present "$test_dir" "c" "LIBRA_ERL=LIBRA_ERL_DEBUG"
}

@test "ERL: LIBRA_ERL=TRACE sets LIBRA_ERL=LIBRA_ERL_TRACE define on target" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_ERL=TRACE)

    assert_define_present "$test_dir" "c" "LIBRA_ERL=LIBRA_ERL_TRACE"
}

@test "ERL: LIBRA_ERL=ALL sets LIBRA_ERL=LIBRA_ERL_ALL define on target" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_ERL=ALL)

    assert_define_present "$test_dir" "c" "LIBRA_ERL=LIBRA_ERL_ALL"
}

@test "ERL: LIBRA_ERL=INHERIT does not set a LIBRA_ERL define on target" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_ERL=INHERIT)

    assert_define_absert "$test_dir" "c" "LIBRA_ERL"
}

@test "ERL: define propagates to C++ targets" {
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_ERL=DEBUG)

    assert_define_present "$test_dir" "cxx" "LIBRA_ERL=LIBRA_ERL_DEBUG"
}
