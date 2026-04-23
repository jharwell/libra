#!/usr/bin/env bats
#
# BATS tests for LIBRA_ERL (Event Reporting Level / Logging Level)
#
# LIBRA_ERL controls logging/event reporting levels:
#   - NONE:    No logging
#   - ERROR:   Error level only
#   - WARN:    Warning and above
#   - INFO:    Info and above
#   - DEBUG:   Debug and above
#   - TRACE:   Trace and above
#   - ALL:     All logging levels
#   - INHERIT: Inherit from parent project (default)
#
# All eight values go through the same _gen_erl_defs macro, so representative
# boundary values (NONE, a middle value, ALL, INHERIT) provide the same
# confidence as testing every level individually at a fraction of the cost.
#

load test_helpers

setup() {
    setup_libra_test
}

# ==============================================================================
# Cache variable — boundary values cover the full enum
# ==============================================================================

@test "ERL: LIBRA_ERL=NONE stores value in cache" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_ERL=NONE)

    run cache_value_equals "$test_dir" "LIBRA_ERL" "NONE"
    [ "$status" -eq 0 ]
}

@test "ERL: LIBRA_ERL=DEBUG stores value in cache" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_ERL=DEBUG)

    run cache_value_equals "$test_dir" "LIBRA_ERL" "DEBUG"
    [ "$status" -eq 0 ]
}

@test "ERL: LIBRA_ERL=ALL stores value in cache" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_ERL=ALL)

    run cache_value_equals "$test_dir" "LIBRA_ERL" "ALL"
    [ "$status" -eq 0 ]
}

@test "ERL: LIBRA_ERL=INHERIT stores value in cache" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_ERL=INHERIT)

    run cache_value_equals "$test_dir" "LIBRA_ERL" "INHERIT"
    [ "$status" -eq 0 ]
}

@test "ERL: Default value is INHERIT" {
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

    run cache_value_equals "$test_dir" "LIBRA_ERL" "ERROR"
    [ "$status" -eq 0 ]

    cd "$test_dir"
    run cmake "$BATS_TEST_DIRNAME/sample_build_info" --log-level=ERROR
    [ "$status" -eq 0 ]

    run cache_value_equals "$test_dir" "LIBRA_ERL" "ERROR"
    [ "$status" -eq 0 ]
}

@test "ERL: Can change value on reconfiguration" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_ERL=ERROR)

    run cache_value_equals "$test_dir" "LIBRA_ERL" "ERROR"
    [ "$status" -eq 0 ]

    cd "$test_dir"
    run cmake "$BATS_TEST_DIRNAME/sample_build_info" -DLIBRA_ERL=DEBUG --log-level=ERROR
    [ "$status" -eq 0 ]

    run cache_value_equals "$test_dir" "LIBRA_ERL" "DEBUG"
    [ "$status" -eq 0 ]
}

# ==============================================================================
# Compile-time define propagation
#
# The cache variable being set is necessary but not sufficient — these tests
# verify the value actually reaches the compiler as a define.  Boundary values
# (NONE, a middle level, ALL) exercise the macro; every intermediate level
# uses identical codegen so testing each individually adds no coverage.
# ==============================================================================

@test "ERL: LIBRA_ERL=NONE sets LIBRA_ERL=LIBRA_ERL_NONE define on target" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_ERL=NONE)

    assert_define_present "$test_dir" "c" "LIBRA_ERL=LIBRA_ERL_NONE"
}

@test "ERL: LIBRA_ERL=DEBUG sets LIBRA_ERL=LIBRA_ERL_DEBUG define on target" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_ERL=DEBUG)

    assert_define_present "$test_dir" "c" "LIBRA_ERL=LIBRA_ERL_DEBUG"
}

@test "ERL: LIBRA_ERL=ALL sets LIBRA_ERL=LIBRA_ERL_ALL define on target" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_ERL=ALL)

    assert_define_present "$test_dir" "c" "LIBRA_ERL=LIBRA_ERL_ALL"
}

@test "ERL: LIBRA_ERL=INHERIT does not set a LIBRA_ERL define on target" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_ERL=INHERIT)

    assert_define_absent "$test_dir" "c" "LIBRA_ERL"
}

@test "ERL: define propagates to C++ targets" {
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_ERL=DEBUG)

    assert_define_present "$test_dir" "cxx" "LIBRA_ERL=LIBRA_ERL_DEBUG"
}
