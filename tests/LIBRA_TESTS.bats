#!/usr/bin/env bats
#
# BATS tests for LIBRA_TESTS and the LIBRA_ testing variables consumed by
# cmake/libra/test/testing.cmake.
#
# Variables under test
# --------------------
#   LIBRA_TESTS                           – master switch; enables test machinery (default: OFF)
#   LIBRA_UNIT_TEST_MATCHER               – glob suffix for unit-test sources     (default: -utest)
#   LIBRA_INTEGRATION_TEST_MATCHER        – glob suffix for integration-test srcs (default: -itest)
#   LIBRA_REGRESSION_TEST_MATCHER         – glob suffix for regression-test srcs  (default: -rtest)
#   LIBRA_TEST_HARNESS_MATCHER            – glob suffix for test harness sources  (default: _test)
#   LIBRA_CTEST_INCLUDE_UNIT_TESTS        – register unit tests with CTest        (default: YES)
#   LIBRA_CTEST_INCLUDE_INTEGRATION_TESTS – register integration tests w/ CTest  (default: YES)
#   LIBRA_CTEST_INCLUDE_REGRESSION_TESTS  – register regression tests w/ CTest   (default: YES)
#
# Design note
# -----------
# The four MATCHER variables and three CTEST_INCLUDE_* variables are NOT cache
# variables.  They are intended to be set once in project-local.cmake for the
# lifetime of a project.  Tests for those variables therefore only check
# configure-time behaviour (discovery, CTest registration, labelling) — not
# cache persistence or reconfiguration, which would be the wrong contract.
#
# LIBRA_TESTS IS a cache variable (declared with option()), so its persistence
# across reconfiguration is legitimately tested.
#
# Sample project
# --------------
# All tests use sample_testing via run_libra_testing_cmake_test().  That project
# has real test stub sources under tests/ using the convention below:
#
#   cpp_alpha-utest.cpp / cpp_beta-utest.cpp    — default C++ unit tests
#   cpp_alpha-itest.cpp / cpp_beta-itest.cpp    — default C++ integration tests
#   cpp_alpha-rtest.cpp / cpp_beta-rtest.cpp    — default C++ regression tests
#   cpp_alpha-myutest.cpp                       — custom matcher unit test
#   cpp_alpha-myitest.cpp                       — custom matcher integration test
#   cpp_alpha-myrtest.cpp                       — custom matcher regression test
#   py_alpha-utest.py / py_alpha-itest.py / py_alpha-rtest.py  — Python stubs
#   sh_alpha-utest.sh / sh_alpha-itest.sh / sh_alpha-rtest.sh  — Shell stubs
#   bats_alpha-{utest,itest,rtest}.bats         — BATS stubs (skipped if bats absent)
#   harness_test.cpp                            — harness source (LIBRA_TEST_HARNESS_MATCHER)
#

load test_helpers

setup() {
    setup_libra_test
    export CMAKE_BUILD_TYPE=Debug
    export COMPILER_TYPE=gnu
}

# ==============================================================================
# LIBRA_TESTS — master on/off switch
# ==============================================================================

@test "TESTS: LIBRA_TESTS defaults to OFF" {
    test_dir=$(run_libra_testing_cmake_test)

    run cache_value_equals "$test_dir" "LIBRA_TESTS" "OFF"
    [ "$status" -eq 0 ]
}

@test "TESTS: LIBRA_TESTS=OFF stores value in cache" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=OFF)

    run cache_value_equals "$test_dir" "LIBRA_TESTS" "OFF"
    [ "$status" -eq 0 ]
}

@test "TESTS: LIBRA_TESTS=ON stores value in cache" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    run cache_value_equals "$test_dir" "LIBRA_TESTS" "ON"
    [ "$status" -eq 0 ]
}

@test "TESTS: LIBRA_TESTS=OFF produces no CTestTestfile" {
    # LIBRA_TESTS=OFF has no effect with conan driver
    skip_if_conan_driver
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=OFF)

    [ ! -f "$test_dir/CTestTestfile.cmake" ]
}

@test "TESTS: LIBRA_TESTS=ON produces a CTestTestfile" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    [ -f "$test_dir/CTestTestfile.cmake" ]
}

@test "TESTS: LIBRA_TESTS=ON creates unit-tests Makefile target" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_target_exists "$test_dir" "unit-tests"
}

@test "TESTS: LIBRA_TESTS=ON creates integration-tests Makefile target" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_target_exists "$test_dir" "integration-tests"
}

@test "TESTS: LIBRA_TESTS=ON creates regression-tests Makefile target" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_target_exists "$test_dir" "regression-tests"
}

@test "TESTS: LIBRA_TESTS=ON creates all-tests Makefile target" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_target_exists "$test_dir" "all-tests"
}

@test "TESTS: LIBRA_TESTS=ON creates build-and-test Makefile target" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_target_exists "$test_dir" "build-and-test"
}

@test "TESTS: LIBRA_TESTS=OFF does not create unit-tests Makefile target" {
    # LIBRA_TESTS=OFF has no effect with conan driver
    skip_if_conan_driver
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=OFF)

    assert_target_absent "$test_dir" "unit-tests"
}

@test "TESTS: LIBRA_TESTS=OFF does not create build-and-test Makefile target" {
    # LIBRA_TESTS=OFF has no effect with conan driver
    skip_if_conan_driver
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=OFF)

    assert_target_absent "$test_dir" "build-and-test"
}

@test "TESTS: LIBRA_TESTS persists across reconfiguration" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)
    reconfigure_libra_testing_test "$test_dir"

    run cache_value_equals "$test_dir" "LIBRA_TESTS" "ON"
    [ "$status" -eq 0 ]
}

@test "TESTS: LIBRA_TESTS can be changed from ON to OFF on reconfiguration" {
    # LIBRA_TESTS=OFF has no effect with conan driver
    skip_if_conan_driver
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)
    reconfigure_libra_testing_test "$test_dir" -DLIBRA_TESTS=OFF

    run cache_value_equals "$test_dir" "LIBRA_TESTS" "OFF"
    [ "$status" -eq 0 ]
}

# ==============================================================================
# LIBRA_UNIT_TEST_MATCHER — discovery and registration
# ==============================================================================

@test "UNIT_TEST_MATCHER: default -utest registers cpp_alpha-utest with CTest" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_ctest_test_registered "$test_dir" "cpp_alpha-utest"
}

@test "UNIT_TEST_MATCHER: default -utest registers cpp_beta-utest with CTest" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_ctest_test_registered "$test_dir" "cpp_beta-utest"
}

@test "UNIT_TEST_MATCHER: default -utest registers py_alpha-utest with CTest" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_ctest_test_registered "$test_dir" "py_alpha-utest"
}

@test "UNIT_TEST_MATCHER: default -utest registers sh_alpha-utest with CTest" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_ctest_test_registered "$test_dir" "sh_alpha-utest"
}

@test "UNIT_TEST_MATCHER: default -utest does not pick up itest files as unit tests" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_ctest_test_registered "$test_dir" "cpp_alpha-itest"
    run ctest_test_has_label "$test_dir" "cpp_alpha-itest" "unit"
    [ "$status" -ne 0 ]
}

@test "UNIT_TEST_MATCHER: custom -myutest discovers cpp_alpha-myutest and registers it" {
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        -DLIBRA_UNIT_TEST_MATCHER="-myutest")

    assert_ctest_test_registered "$test_dir" "cpp_alpha-myutest"
}

@test "UNIT_TEST_MATCHER: custom -myutest does not register default-matcher files" {
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        -DLIBRA_UNIT_TEST_MATCHER="-myutest")

    assert_ctest_test_absent "$test_dir" "cpp_alpha-utest"
    assert_ctest_test_absent "$test_dir" "cpp_beta-utest"
}

# ==============================================================================
# LIBRA_UNIT_TEST_MATCHER — CTest labels
# ==============================================================================

@test "UNIT_TEST_MATCHER: cpp_alpha-utest receives label 'unit'" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_ctest_test_label "$test_dir" "cpp_alpha-utest" "unit"
}

@test "UNIT_TEST_MATCHER: py_alpha-utest receives label 'unit'" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_ctest_test_label "$test_dir" "py_alpha-utest" "unit"
}

@test "UNIT_TEST_MATCHER: sh_alpha-utest receives label 'unit'" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_ctest_test_label "$test_dir" "sh_alpha-utest" "unit"
}

# ==============================================================================
# LIBRA_INTEGRATION_TEST_MATCHER — discovery and registration
# ==============================================================================

@test "INTEGRATION_TEST_MATCHER: default -itest registers cpp_alpha-itest with CTest" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_ctest_test_registered "$test_dir" "cpp_alpha-itest"
}

@test "INTEGRATION_TEST_MATCHER: default -itest registers cpp_beta-itest with CTest" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_ctest_test_registered "$test_dir" "cpp_beta-itest"
}

@test "INTEGRATION_TEST_MATCHER: default -itest registers py_alpha-itest with CTest" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_ctest_test_registered "$test_dir" "py_alpha-itest"
}

@test "INTEGRATION_TEST_MATCHER: default -itest registers sh_alpha-itest with CTest" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_ctest_test_registered "$test_dir" "sh_alpha-itest"
}

@test "INTEGRATION_TEST_MATCHER: custom -myitest discovers cpp_alpha-myitest and registers it" {
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        -DLIBRA_INTEGRATION_TEST_MATCHER="-myitest")

    assert_ctest_test_registered "$test_dir" "cpp_alpha-myitest"
}

@test "INTEGRATION_TEST_MATCHER: custom -myitest does not register default-matcher files" {
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        -DLIBRA_INTEGRATION_TEST_MATCHER="-myitest")

    assert_ctest_test_absent "$test_dir" "cpp_alpha-itest"
    assert_ctest_test_absent "$test_dir" "cpp_beta-itest"
}

# ==============================================================================
# LIBRA_INTEGRATION_TEST_MATCHER — CTest labels
# ==============================================================================

@test "INTEGRATION_TEST_MATCHER: cpp_alpha-itest receives label 'integration'" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_ctest_test_label "$test_dir" "cpp_alpha-itest" "integration"
}

@test "INTEGRATION_TEST_MATCHER: py_alpha-itest receives label 'integration'" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_ctest_test_label "$test_dir" "py_alpha-itest" "integration"
}

@test "INTEGRATION_TEST_MATCHER: sh_alpha-itest receives label 'integration'" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_ctest_test_label "$test_dir" "sh_alpha-itest" "integration"
}

# ==============================================================================
# LIBRA_REGRESSION_TEST_MATCHER — discovery and registration
# ==============================================================================

@test "REGRESSION_TEST_MATCHER: default -rtest registers cpp_alpha-rtest with CTest" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_ctest_test_registered "$test_dir" "cpp_alpha-rtest"
}

@test "REGRESSION_TEST_MATCHER: default -rtest registers cpp_beta-rtest with CTest" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_ctest_test_registered "$test_dir" "cpp_beta-rtest"
}

@test "REGRESSION_TEST_MATCHER: default -rtest registers py_alpha-rtest with CTest" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_ctest_test_registered "$test_dir" "py_alpha-rtest"
}

@test "REGRESSION_TEST_MATCHER: default -rtest registers sh_alpha-rtest with CTest" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_ctest_test_registered "$test_dir" "sh_alpha-rtest"
}

@test "REGRESSION_TEST_MATCHER: custom -myrtest discovers cpp_alpha-myrtest and registers it" {
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        -DLIBRA_REGRESSION_TEST_MATCHER="-myrtest")

    assert_ctest_test_registered "$test_dir" "cpp_alpha-myrtest"
}

@test "REGRESSION_TEST_MATCHER: custom -myrtest does not register default-matcher files" {
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        -DLIBRA_REGRESSION_TEST_MATCHER="-myrtest")

    assert_ctest_test_absent "$test_dir" "cpp_alpha-rtest"
    assert_ctest_test_absent "$test_dir" "cpp_beta-rtest"
}

# ==============================================================================
# LIBRA_REGRESSION_TEST_MATCHER — CTest labels
# ==============================================================================

@test "REGRESSION_TEST_MATCHER: cpp_alpha-rtest receives label 'regression'" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_ctest_test_label "$test_dir" "cpp_alpha-rtest" "regression"
}

@test "REGRESSION_TEST_MATCHER: py_alpha-rtest receives label 'regression'" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_ctest_test_label "$test_dir" "py_alpha-rtest" "regression"
}

@test "REGRESSION_TEST_MATCHER: sh_alpha-rtest receives label 'regression'" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_ctest_test_label "$test_dir" "sh_alpha-rtest" "regression"
}

# ==============================================================================
# LIBRA_TEST_HARNESS_MATCHER
# ==============================================================================

@test "TEST_HARNESS_MATCHER: default _test detects harness_test.cpp and creates harness target" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_target_exists "$test_dir" "sample_testing-cxx-harness"
}

@test "TEST_HARNESS_MATCHER: non-matching suffix finds no harness and creates no harness target" {
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        -DLIBRA_TEST_HARNESS_MATCHER="_no_such_harness")

    assert_target_absent "$test_dir" "sample_testing-cxx-harness"
}

# ==============================================================================
# LIBRA_CTEST_INCLUDE_UNIT_TESTS
# ==============================================================================

@test "CTEST_INCLUDE_UNIT_TESTS: default YES registers unit tests with CTest" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_ctest_test_registered "$test_dir" "cpp_alpha-utest"
    assert_ctest_test_registered "$test_dir" "cpp_beta-utest"
}

@test "CTEST_INCLUDE_UNIT_TESTS: NO removes cpp unit tests from CTest" {
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        -DLIBRA_CTEST_INCLUDE_UNIT_TESTS=NO)

    assert_ctest_test_absent "$test_dir" "cpp_alpha-utest"
    assert_ctest_test_absent "$test_dir" "cpp_beta-utest"
}

@test "CTEST_INCLUDE_UNIT_TESTS: NO removes interpreted unit tests from CTest" {
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        -DLIBRA_CTEST_INCLUDE_UNIT_TESTS=NO)

    assert_ctest_test_absent "$test_dir" "py_alpha-utest"
    assert_ctest_test_absent "$test_dir" "sh_alpha-utest"
}

@test "CTEST_INCLUDE_UNIT_TESTS: NO still keeps integration tests in CTest" {
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        -DLIBRA_CTEST_INCLUDE_UNIT_TESTS=NO)

    assert_ctest_test_registered "$test_dir" "cpp_alpha-itest"
    assert_ctest_test_registered "$test_dir" "py_alpha-itest"
}

@test "CTEST_INCLUDE_UNIT_TESTS: NO still keeps regression tests in CTest" {
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        -DLIBRA_CTEST_INCLUDE_UNIT_TESTS=NO)

    assert_ctest_test_registered "$test_dir" "cpp_alpha-rtest"
    assert_ctest_test_registered "$test_dir" "py_alpha-rtest"
}

@test "CTEST_INCLUDE_UNIT_TESTS: NO still creates unit-tests Makefile target" {
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        -DLIBRA_CTEST_INCLUDE_UNIT_TESTS=NO)

    assert_target_exists "$test_dir" "unit-tests"
}

# ==============================================================================
# LIBRA_CTEST_INCLUDE_INTEGRATION_TESTS
# ==============================================================================

@test "CTEST_INCLUDE_INTEGRATION_TESTS: default YES registers integration tests with CTest" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_ctest_test_registered "$test_dir" "cpp_alpha-itest"
    assert_ctest_test_registered "$test_dir" "cpp_beta-itest"
}

@test "CTEST_INCLUDE_INTEGRATION_TESTS: NO removes cpp integration tests from CTest" {
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        -DLIBRA_CTEST_INCLUDE_INTEGRATION_TESTS=NO)

    assert_ctest_test_absent "$test_dir" "cpp_alpha-itest"
    assert_ctest_test_absent "$test_dir" "cpp_beta-itest"
}

@test "CTEST_INCLUDE_INTEGRATION_TESTS: NO removes interpreted integration tests from CTest" {
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        -DLIBRA_CTEST_INCLUDE_INTEGRATION_TESTS=NO)

    assert_ctest_test_absent "$test_dir" "py_alpha-itest"
    assert_ctest_test_absent "$test_dir" "sh_alpha-itest"
}

@test "CTEST_INCLUDE_INTEGRATION_TESTS: NO still keeps unit tests in CTest" {
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        -DLIBRA_CTEST_INCLUDE_INTEGRATION_TESTS=NO)

    assert_ctest_test_registered "$test_dir" "cpp_alpha-utest"
    assert_ctest_test_registered "$test_dir" "py_alpha-utest"
}

@test "CTEST_INCLUDE_INTEGRATION_TESTS: NO still keeps regression tests in CTest" {
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        -DLIBRA_CTEST_INCLUDE_INTEGRATION_TESTS=NO)

    assert_ctest_test_registered "$test_dir" "cpp_alpha-rtest"
    assert_ctest_test_registered "$test_dir" "py_alpha-rtest"
}

@test "CTEST_INCLUDE_INTEGRATION_TESTS: NO still creates integration-tests Makefile target" {
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        -DLIBRA_CTEST_INCLUDE_INTEGRATION_TESTS=NO)

    assert_target_exists "$test_dir" "integration-tests"
}

# ==============================================================================
# LIBRA_CTEST_INCLUDE_REGRESSION_TESTS
# ==============================================================================

@test "CTEST_INCLUDE_REGRESSION_TESTS: default YES registers regression tests with CTest" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_ctest_test_registered "$test_dir" "cpp_alpha-rtest"
    assert_ctest_test_registered "$test_dir" "cpp_beta-rtest"
}

@test "CTEST_INCLUDE_REGRESSION_TESTS: NO removes cpp regression tests from CTest" {
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        -DLIBRA_CTEST_INCLUDE_REGRESSION_TESTS=NO)

    assert_ctest_test_absent "$test_dir" "cpp_alpha-rtest"
    assert_ctest_test_absent "$test_dir" "cpp_beta-rtest"
}

@test "CTEST_INCLUDE_REGRESSION_TESTS: NO removes interpreted regression tests from CTest" {
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        -DLIBRA_CTEST_INCLUDE_REGRESSION_TESTS=NO)

    assert_ctest_test_absent "$test_dir" "py_alpha-rtest"
    assert_ctest_test_absent "$test_dir" "sh_alpha-rtest"
}

@test "CTEST_INCLUDE_REGRESSION_TESTS: NO still keeps unit tests in CTest" {
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        -DLIBRA_CTEST_INCLUDE_REGRESSION_TESTS=NO)

    assert_ctest_test_registered "$test_dir" "cpp_alpha-utest"
    assert_ctest_test_registered "$test_dir" "py_alpha-utest"
}

@test "CTEST_INCLUDE_REGRESSION_TESTS: NO still keeps integration tests in CTest" {
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        -DLIBRA_CTEST_INCLUDE_REGRESSION_TESTS=NO)

    assert_ctest_test_registered "$test_dir" "cpp_alpha-itest"
    assert_ctest_test_registered "$test_dir" "py_alpha-itest"
}

@test "CTEST_INCLUDE_REGRESSION_TESTS: NO still creates regression-tests Makefile target" {
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        -DLIBRA_CTEST_INCLUDE_REGRESSION_TESTS=NO)

    assert_target_exists "$test_dir" "regression-tests"
}

# ==============================================================================
# Cross-variable interactions
# ==============================================================================

@test "INTERACTION: all three CTEST_INCLUDE_* NO leaves CTestTestfile empty of tests" {
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        -DLIBRA_CTEST_INCLUDE_UNIT_TESTS=NO \
        -DLIBRA_CTEST_INCLUDE_INTEGRATION_TESTS=NO \
        -DLIBRA_CTEST_INCLUDE_REGRESSION_TESTS=NO)

    [ -f "$test_dir/CTestTestfile.cmake" ]
    run grep -c "^add_test(" "$test_dir/CTestTestfile.cmake"
    [ "$output" -eq 0 ]
}

@test "INTERACTION: all three CTEST_INCLUDE_* NO still creates all umbrella Makefile targets" {
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        -DLIBRA_CTEST_INCLUDE_UNIT_TESTS=NO \
        -DLIBRA_CTEST_INCLUDE_INTEGRATION_TESTS=NO \
        -DLIBRA_CTEST_INCLUDE_REGRESSION_TESTS=NO)

    assert_target_exists "$test_dir" "unit-tests"
    assert_target_exists "$test_dir" "integration-tests"
    assert_target_exists "$test_dir" "regression-tests"
    assert_target_exists "$test_dir" "all-tests"
    assert_target_exists "$test_dir" "build-and-test"
}

@test "INTERACTION: custom matchers for all three types discover only the matching stubs" {
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        -DLIBRA_UNIT_TEST_MATCHER="-myutest" \
        -DLIBRA_INTEGRATION_TEST_MATCHER="-myitest" \
        -DLIBRA_REGRESSION_TEST_MATCHER="-myrtest")

    assert_ctest_test_registered "$test_dir" "cpp_alpha-myutest"
    assert_ctest_test_registered "$test_dir" "cpp_alpha-myitest"
    assert_ctest_test_registered "$test_dir" "cpp_alpha-myrtest"
    assert_ctest_test_absent     "$test_dir" "cpp_alpha-utest"
    assert_ctest_test_absent     "$test_dir" "cpp_alpha-itest"
    assert_ctest_test_absent     "$test_dir" "cpp_alpha-rtest"
}

@test "INTERACTION: custom matchers assign correct labels" {
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        -DLIBRA_UNIT_TEST_MATCHER="-myutest" \
        -DLIBRA_INTEGRATION_TEST_MATCHER="-myitest" \
        -DLIBRA_REGRESSION_TEST_MATCHER="-myrtest")

    assert_ctest_test_label "$test_dir" "cpp_alpha-myutest" "unit"
    assert_ctest_test_label "$test_dir" "cpp_alpha-myitest" "integration"
    assert_ctest_test_label "$test_dir" "cpp_alpha-myrtest" "regression"
}

# ==============================================================================
# LIBRA_CTEST_INCLUDE_* — cache persistence (these ARE cache variables)
# ==============================================================================

@test "CTEST_INCLUDE_UNIT_TESTS: default YES value stored in cache" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    run cache_value_equals "$test_dir" "LIBRA_CTEST_INCLUDE_UNIT_TESTS" "YES"
    [ "$status" -eq 0 ]
}

@test "CTEST_INCLUDE_UNIT_TESTS: NO value stored in cache" {
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        -DLIBRA_CTEST_INCLUDE_UNIT_TESTS=NO)

    run cache_value_equals "$test_dir" "LIBRA_CTEST_INCLUDE_UNIT_TESTS" "NO"
    [ "$status" -eq 0 ]
}

@test "CTEST_INCLUDE_UNIT_TESTS: NO persists across reconfiguration" {
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        -DLIBRA_CTEST_INCLUDE_UNIT_TESTS=NO)
    reconfigure_libra_testing_test "$test_dir"

    run cache_value_equals "$test_dir" "LIBRA_CTEST_INCLUDE_UNIT_TESTS" "NO"
    [ "$status" -eq 0 ]
}

@test "CTEST_INCLUDE_INTEGRATION_TESTS: default YES value stored in cache" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    run cache_value_equals "$test_dir" "LIBRA_CTEST_INCLUDE_INTEGRATION_TESTS" "YES"
    [ "$status" -eq 0 ]
}

@test "CTEST_INCLUDE_INTEGRATION_TESTS: NO value stored in cache" {
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        -DLIBRA_CTEST_INCLUDE_INTEGRATION_TESTS=NO)

    run cache_value_equals "$test_dir" "LIBRA_CTEST_INCLUDE_INTEGRATION_TESTS" "NO"
    [ "$status" -eq 0 ]
}

@test "CTEST_INCLUDE_INTEGRATION_TESTS: NO persists across reconfiguration" {
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        -DLIBRA_CTEST_INCLUDE_INTEGRATION_TESTS=NO)
    reconfigure_libra_testing_test "$test_dir"

    run cache_value_equals "$test_dir" "LIBRA_CTEST_INCLUDE_INTEGRATION_TESTS" "NO"
    [ "$status" -eq 0 ]
}

@test "CTEST_INCLUDE_REGRESSION_TESTS: default YES value stored in cache" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    run cache_value_equals "$test_dir" "LIBRA_CTEST_INCLUDE_REGRESSION_TESTS" "YES"
    [ "$status" -eq 0 ]
}

@test "CTEST_INCLUDE_REGRESSION_TESTS: NO value stored in cache" {
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        -DLIBRA_CTEST_INCLUDE_REGRESSION_TESTS=NO)

    run cache_value_equals "$test_dir" "LIBRA_CTEST_INCLUDE_REGRESSION_TESTS" "NO"
    [ "$status" -eq 0 ]
}

@test "CTEST_INCLUDE_REGRESSION_TESTS: NO persists across reconfiguration" {
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        -DLIBRA_CTEST_INCLUDE_REGRESSION_TESTS=NO)
    reconfigure_libra_testing_test "$test_dir"

    run cache_value_equals "$test_dir" "LIBRA_CTEST_INCLUDE_REGRESSION_TESTS" "NO"
    [ "$status" -eq 0 ]
}
