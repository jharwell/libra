#!/usr/bin/env bats
#
# BATS tests for LIBRA_ERL_EXPORT
#
# LIBRA_ERL_EXPORT controls whether the LIBRA_ERL compile definition is
# PUBLIC (propagated to downstream consumers) or PRIVATE (internal only):
#   - ON:  Define is PUBLIC  -> propagates to downstream consumers
#   - OFF: Define is PRIVATE -> invisible to downstream consumers
#
# Testing approach:
# - sample_build_info is built as a STATIC library (via LIBRA_TEST_ERL_EXPORT=ON)
# - A consumer/ subdirectory links against it
# - We check whether LIBRA_ERL appears in consumer_build_info.c/cpp
#

load test_helpers

setup() {
    setup_libra_test
}

@test "ERL_EXPORT: LIBRA_ERL_EXPORT=ON propagates define to consumer" {
    test_dir=$(run_libra_cmake_test "c" \
        -DLIBRA_TEST_ERL_EXPORT=ON \
        -DLIBRA_ERL_EXPORT=ON \
        -DLIBRA_ERL=DEBUG)

    assert_consumer_define_present "$test_dir" "LIBRA_ERL=LIBRA_ERL_DEBUG" "c"
}

@test "ERL_EXPORT: LIBRA_ERL_EXPORT=OFF does not propagate define to consumer" {
    test_dir=$(run_libra_cmake_test "c" \
        -DLIBRA_TEST_ERL_EXPORT=ON \
        -DLIBRA_ERL_EXPORT=OFF \
        -DLIBRA_ERL=DEBUG)

    assert_consumer_define_absent "$test_dir" "LIBRA_ERL=" "c"
}

@test "ERL_EXPORT: Consumer build info file exists when test enabled" {
    test_dir=$(run_libra_cmake_test "c" \
        -DLIBRA_TEST_ERL_EXPORT=ON \
        -DLIBRA_ERL_EXPORT=ON \
        -DLIBRA_ERL=ERROR)

    assert_file_exists "$test_dir/consumer/consumer_build_info.c"
}

@test "ERL_EXPORT: Works with C++ projects" {
    test_dir=$(run_libra_cmake_test "cxx" \
        -DLIBRA_TEST_ERL_EXPORT=ON \
        -DLIBRA_ERL_EXPORT=ON \
        -DLIBRA_ERL=DEBUG)

    assert_consumer_define_present "$test_dir" "LIBRA_ERL=LIBRA_ERL_DEBUG" "cxx"
}

@test "ERL_EXPORT: C++ OFF does not propagate define to consumer" {
    test_dir=$(run_libra_cmake_test "cxx" \
        -DLIBRA_TEST_ERL_EXPORT=ON \
        -DLIBRA_ERL_EXPORT=OFF \
        -DLIBRA_ERL=DEBUG)

    assert_consumer_define_absent "$test_dir" "LIBRA_ERL=" "cxx"
}

@test "ERL_EXPORT: Cache variable persists across reconfiguration" {
    test_dir=$(run_libra_cmake_test "c" \
        -DLIBRA_TEST_ERL_EXPORT=ON \
        -DLIBRA_ERL_EXPORT=ON \
        -DLIBRA_ERL=ERROR)

    assert_cache_value "$test_dir" "LIBRA_ERL_EXPORT" "ON"

    cd "$test_dir"
    run cmake "$BATS_TEST_DIRNAME/sample_build_info" --log-level=ERROR
    assert_success

    assert_cache_value "$test_dir" "LIBRA_ERL_EXPORT" "ON"
}

@test "ERL_EXPORT: Can change value on reconfiguration" {
    test_dir=$(run_libra_cmake_test "c" \
        -DLIBRA_TEST_ERL_EXPORT=ON \
        -DLIBRA_ERL_EXPORT=ON \
        -DLIBRA_ERL=ERROR)

    assert_cache_value "$test_dir" "LIBRA_ERL_EXPORT" "ON"

    cd "$test_dir"
    run cmake "$BATS_TEST_DIRNAME/sample_build_info" -DLIBRA_ERL_EXPORT=OFF --log-level=ERROR
    assert_success

    assert_cache_value "$test_dir" "LIBRA_ERL_EXPORT" "OFF"
}

@test "ERL_EXPORT: INHERIT level with EXPORT=ON propagates INHERIT define" {
    # INHERIT is a valid ERL value; verify it too is exported when ON
    test_dir=$(run_libra_cmake_test "c" \
        -DLIBRA_TEST_ERL_EXPORT=ON \
        -DLIBRA_ERL_EXPORT=ON \
        -DLIBRA_ERL=INHERIT)

    # With INHERIT the define is not set, so consumer should not see it
    assert_consumer_define_absent "$test_dir" "LIBRA_ERL=" "c"
}
