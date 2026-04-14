#!/usr/bin/env bats
#
# BATS tests for LIBRA_FPC_EXPORT
#
# LIBRA_FPC_EXPORT controls whether LIBRA_FPC compile definitions
# are PUBLIC (exported to consumers) or PRIVATE (internal only):
#   - ON:  Define is PUBLIC  -> propagates to downstream consumers
#   - OFF: Define is PRIVATE -> invisible to downstream consumers
#
# Testing approach:
# - sample_build_info is built as a STATIC library (via LIBRA_TEST_FPC_EXPORT=ON)
# - A consumer/ subdirectory links against it
# - Consumer queries INTERFACE_COMPILE_DEFINITIONS (PUBLIC defines)
# - We check if the define appears in consumer_build_info.c
#

load test_helpers

setup() {
    setup_libra_test
}

@test "FPC_EXPORT: LIBRA_FPC_EXPORT=ON propagates define to consumer" {
    test_dir=$(run_libra_cmake_test "c" \
        -DLIBRA_TEST_FPC_EXPORT=ON \
        -DLIBRA_FPC_EXPORT=ON \
        -DLIBRA_FPC=ABORT)

    # The consumer should see the LIBRA_FPC define
    run consumer_has_define "$test_dir" "LIBRA_FPC=LIBRA_FPC_ABORT" "c"
    [ "$status" -eq 0 ]
}

@test "FPC_EXPORT: LIBRA_FPC_EXPORT=OFF does not propagate define" {
    test_dir=$(run_libra_cmake_test "c" \
        -DLIBRA_TEST_FPC_EXPORT=ON \
        -DLIBRA_FPC_EXPORT=OFF \
        -DLIBRA_FPC=ABORT)

    # The consumer should NOT see the LIBRA_FPC define
    run consumer_define_absent "$test_dir" "LIBRA_FPC=" "c"
    [ "$status" -eq 0 ]
}

@test "FPC_EXPORT: Consumer build info file exists when test enabled" {
    test_dir=$(run_libra_cmake_test "c" \
        -DLIBRA_TEST_FPC_EXPORT=ON \
        -DLIBRA_FPC_EXPORT=ON \
        -DLIBRA_FPC=ABORT)

    # Verify consumer_build_info.c was created
    [ -f "$test_dir/consumer/consumer_build_info.c" ]
}

@test "FPC_EXPORT: Works with C++ projects" {
    test_dir=$(run_libra_cmake_test "cxx" \
        -DLIBRA_TEST_FPC_EXPORT=ON \
        -DLIBRA_FPC_EXPORT=ON \
        -DLIBRA_FPC=ABORT)

    # Consumer should see the define
    run consumer_has_define "$test_dir" "LIBRA_FPC=LIBRA_FPC_ABORT" "c++"
    [ "$status" -eq 0 ]
}

@test "FPC_EXPORT: Cache variable persists across reconfiguration" {
    test_dir=$(run_libra_cmake_test "c" \
        -DLIBRA_TEST_FPC_EXPORT=ON \
        -DLIBRA_FPC_EXPORT=ON \
        -DLIBRA_FPC=ABORT)

    run cache_value_equals "$test_dir" "LIBRA_FPC_EXPORT" "ON"
    [ "$status" -eq 0 ]

    cd "$test_dir"
    run cmake "$BATS_TEST_DIRNAME/sample_build_info" --log-level=ERROR
    [ "$status" -eq 0 ]

    run cache_value_equals "$test_dir" "LIBRA_FPC_EXPORT" "ON"
    [ "$status" -eq 0 ]
}

@test "FPC_EXPORT: Can change value on reconfiguration" {
    test_dir=$(run_libra_cmake_test "c" \
        -DLIBRA_TEST_FPC_EXPORT=ON \
        -DLIBRA_FPC_EXPORT=ON \
        -DLIBRA_FPC=ABORT)

    run cache_value_equals "$test_dir" "LIBRA_FPC_EXPORT" "ON"
    [ "$status" -eq 0 ]

    cd "$test_dir"
    run cmake "$BATS_TEST_DIRNAME/sample_build_info" -DLIBRA_FPC_EXPORT=OFF --log-level=ERROR
    [ "$status" -eq 0 ]

    run cache_value_equals "$test_dir" "LIBRA_FPC_EXPORT" "OFF"
    [ "$status" -eq 0 ]
}
