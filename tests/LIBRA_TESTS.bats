#!/usr/bin/env bats
#
# BATS tests for LIBRA_TESTS and the LIBRA_ testing variables consumed by
# cmake/libra/test/testing.cmake.
#
# Variables under test
# --------------------
#   LIBRA_TESTS                           – master switch; enables test machinery (default: OFF)
#   LIBRA_UNIT_TEST_MATCHER               – glob suffix for unit-test sources     (default: -utest)
#   LIBRA_UNIT_TEST_MATCHER_DEFAULT       – read-only default value for above     (value: -utest)
#   LIBRA_INTEGRATION_TEST_MATCHER        – glob suffix for integration-test srcs (default: -itest)
#   LIBRA_INTEGRATION_TEST_MATCHER_DEFAULT– read-only default value for above     (value: -itest)
#   LIBRA_REGRESSION_TEST_MATCHER         – glob suffix for regression-test srcs  (default: -rtest)
#   LIBRA_REGRESSION_TEST_MATCHER_DEFAULT – read-only default value for above     (value: -rtest)
#   LIBRA_TEST_HARNESS_MATCHER            – glob suffix for test harness sources  (default: _test)
#   LIBRA_TEST_HARNESS_MATCHER_DEFAULT    – read-only default value for above     (value: _test)
#   LIBRA_CTEST_INCLUDE_UNIT_TESTS        – register unit tests with CTest        (default: YES)
#   LIBRA_CTEST_INCLUDE_INTEGRATION_TESTS – register integration tests w/ CTest  (default: YES)
#   LIBRA_CTEST_INCLUDE_REGRESSION_TESTS  – register regression tests w/ CTest   (default: YES)
#   LIBRA_NEGATIVE_TEST_INCLUDE_DIRS      – extra include dirs for neg-compile tests
#   LIBRA_NEGATIVE_TEST_COMPILE_FLAGS     – extra compile flags for neg-compile tests
#   LIBRA_TEST_HARNESS_LIBS               – libraries linked into the test harness
#   LIBRA_TEST_HARNESS_PACKAGES           – find_package() names for the harness
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

# ==============================================================================
# C extension (.c files)
# ==============================================================================

@test "COMPILED_EXTENSIONS: c_alpha-utest.c is registered as a unit test with CTest" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_ctest_test_registered "$test_dir" "c_alpha-utest"
}

@test "COMPILED_EXTENSIONS: c_alpha-itest.c is registered as an integration test with CTest" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_ctest_test_registered "$test_dir" "c_alpha-itest"
}

@test "COMPILED_EXTENSIONS: c_alpha-rtest.c is registered as a regression test with CTest" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_ctest_test_registered "$test_dir" "c_alpha-rtest"
}

@test "COMPILED_EXTENSIONS: c_alpha-utest receives label 'unit'" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_ctest_test_label "$test_dir" "c_alpha-utest" "unit"
}

@test "COMPILED_EXTENSIONS: c_alpha-itest receives label 'integration'" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_ctest_test_label "$test_dir" "c_alpha-itest" "integration"
}

@test "COMPILED_EXTENSIONS: c_alpha-rtest receives label 'regression'" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_ctest_test_label "$test_dir" "c_alpha-rtest" "regression"
}

@test "COMPILED_EXTENSIONS: LIBRA_CTEST_INCLUDE_UNIT_TESTS=NO removes c unit tests from CTest" {
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        -DLIBRA_CTEST_INCLUDE_UNIT_TESTS=NO)

    assert_ctest_test_absent "$test_dir" "c_alpha-utest"
}

# ==============================================================================
# Negative compile tests (.neg.cpp / .neg.c)
#
# Driven by public variables: LIBRA_NEGATIVE_TEST_INCLUDE_DIRS,
# LIBRA_NEGATIVE_TEST_COMPILE_FLAGS, and LIBRA_CTEST_INCLUDE_*.
# ==============================================================================

@test "NEGATIVE_COMPILE: neg.cpp unit test is registered with CTest" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_ctest_test_registered "$test_dir" "neg_cpp_alpha-utest"
}

@test "NEGATIVE_COMPILE: neg.c unit test is registered with CTest" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_ctest_test_registered "$test_dir" "neg_c_alpha-utest"
}

@test "NEGATIVE_COMPILE: neg.cpp integration test is registered with CTest" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_ctest_test_registered "$test_dir" "neg_cpp_alpha-itest"
}

@test "NEGATIVE_COMPILE: neg.cpp regression test is registered with CTest" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_ctest_test_registered "$test_dir" "neg_cpp_alpha-rtest"
}

@test "NEGATIVE_COMPILE: neg unit test receives label 'unit'" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_ctest_test_label "$test_dir" "neg_cpp_alpha-utest" "unit"
}



@test "NEGATIVE_COMPILE: neg integration test receives label 'integration'" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_ctest_test_label "$test_dir" "neg_cpp_alpha-itest" "integration"
}


@test "NEGATIVE_COMPILE: neg regression test receives label 'regression'" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_ctest_test_label "$test_dir" "neg_cpp_alpha-rtest" "regression"
}


@test "NEGATIVE_COMPILE: LIBRA_CTEST_INCLUDE_UNIT_TESTS=NO excludes neg unit tests from CTest" {
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        -DLIBRA_CTEST_INCLUDE_UNIT_TESTS=NO)

    assert_ctest_test_absent "$test_dir" "neg_cpp_alpha-utest"
    assert_ctest_test_absent "$test_dir" "neg_c_alpha-utest"
}

@test "NEGATIVE_COMPILE: LIBRA_CTEST_INCLUDE_INTEGRATION_TESTS=NO excludes neg integration tests from CTest" {
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        -DLIBRA_CTEST_INCLUDE_INTEGRATION_TESTS=NO)

    assert_ctest_test_absent "$test_dir" "neg_cpp_alpha-itest"
}

@test "NEGATIVE_COMPILE: LIBRA_CTEST_INCLUDE_REGRESSION_TESTS=NO excludes neg regression tests from CTest" {
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        -DLIBRA_CTEST_INCLUDE_REGRESSION_TESTS=NO)

    assert_ctest_test_absent "$test_dir" "neg_cpp_alpha-rtest"
}

@test "NEGATIVE_COMPILE: LIBRA_NEGATIVE_TEST_INCLUDE_DIRS adds extra include path without breaking configure" {
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        -DLIBRA_NEGATIVE_TEST_INCLUDE_DIRS="/tmp")

    [ -f "$test_dir/CTestTestfile.cmake" ]
    assert_ctest_test_registered "$test_dir" "neg_cpp_alpha-utest"
}

@test "NEGATIVE_COMPILE: LIBRA_NEGATIVE_TEST_COMPILE_FLAGS adds extra flags without breaking configure" {
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        -DLIBRA_NEGATIVE_TEST_COMPILE_FLAGS="-DLIBRA_NEG_TEST_EXTRA=1")

    [ -f "$test_dir/CTestTestfile.cmake" ]
    assert_ctest_test_registered "$test_dir" "neg_cpp_alpha-utest"
}

# ==============================================================================
# LIBRA_TEST_HARNESS_LIBS
# ==============================================================================

@test "TEST_HARNESS_LIBS: setting LIBRA_TEST_HARNESS_LIBS does not break configure" {
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        -DLIBRA_TEST_HARNESS_LIBS="m")

    assert_target_exists "$test_dir" "sample_testing-cxx-harness"
}

# ==============================================================================
# LIBRA_TEST_HARNESS_PACKAGES
# ==============================================================================

@test "TEST_HARNESS_PACKAGES: empty LIBRA_TEST_HARNESS_PACKAGES configures without error" {
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        -DLIBRA_TEST_HARNESS_PACKAGES="")

    assert_target_exists "$test_dir" "sample_testing-cxx-harness"
}

# ==============================================================================
# LIBRA_UNIT_TEST_MATCHER_DEFAULT — default value contract
#
# The DEFAULT variable is set by libra/defaults and consumed by testing.cmake
# when no project-local override is present. Tests here verify that the
# default wire-up produces the expected discovery behaviour without needing to
# pass LIBRA_UNIT_TEST_MATCHER explicitly.
# ==============================================================================

@test "UNIT_TEST_MATCHER_DEFAULT: omitting LIBRA_UNIT_TEST_MATCHER still registers cpp_alpha-utest" {
    # If the default wiring is broken the glob produces nothing and no test is
    # registered, making this a meaningful canary for the DEFAULT variable.
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_ctest_test_registered "$test_dir" "cpp_alpha-utest"
}

@test "UNIT_TEST_MATCHER_DEFAULT: omitting LIBRA_UNIT_TEST_MATCHER still registers cpp_beta-utest" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_ctest_test_registered "$test_dir" "cpp_beta-utest"
}

@test "UNIT_TEST_MATCHER_DEFAULT: default does not accidentally pick up itest files as unit tests" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    run ctest_test_has_label "$test_dir" "cpp_alpha-itest" "unit"
    [ "$status" -ne 0 ]
}

# ==============================================================================
# LIBRA_INTEGRATION_TEST_MATCHER_DEFAULT — default value contract
# ==============================================================================

@test "INTEGRATION_TEST_MATCHER_DEFAULT: omitting LIBRA_INTEGRATION_TEST_MATCHER registers cpp_alpha-itest" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_ctest_test_registered "$test_dir" "cpp_alpha-itest"
}

@test "INTEGRATION_TEST_MATCHER_DEFAULT: default does not accidentally pick up rtest files as integration tests" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    run ctest_test_has_label "$test_dir" "cpp_alpha-rtest" "integration"
    [ "$status" -ne 0 ]
}

# ==============================================================================
# LIBRA_REGRESSION_TEST_MATCHER_DEFAULT — default value contract
# ==============================================================================

@test "REGRESSION_TEST_MATCHER_DEFAULT: omitting LIBRA_REGRESSION_TEST_MATCHER registers cpp_alpha-rtest" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_ctest_test_registered "$test_dir" "cpp_alpha-rtest"
}

@test "REGRESSION_TEST_MATCHER_DEFAULT: default does not accidentally pick up utest files as regression tests" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    run ctest_test_has_label "$test_dir" "cpp_alpha-utest" "regression"
    [ "$status" -ne 0 ]
}

# ==============================================================================
# LIBRA_TEST_HARNESS_MATCHER_DEFAULT — default value contract
# ==============================================================================

@test "TEST_HARNESS_MATCHER_DEFAULT: omitting LIBRA_TEST_HARNESS_MATCHER creates cxx-harness target" {
    # harness_test.cpp matches the default suffix (_test), so the target must
    # be created when the caller does not supply LIBRA_TEST_HARNESS_MATCHER.
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_target_exists "$test_dir" "sample_testing-cxx-harness"
}

@test "TEST_HARNESS_MATCHER_DEFAULT: default suffix does not create harness when no file matches" {
    # Pass a suffix that matches nothing in sample_testing/tests — the harness
    # target must then be absent.
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        -DLIBRA_TEST_HARNESS_MATCHER="_no_such_suffix_xyzzy")

    assert_target_absent "$test_dir" "sample_testing-cxx-harness"
}

# ==============================================================================
# Non-compiled tests
# ==============================================================================

@test "INTERPRETED_TESTS: bats_alpha-utest.bats is registered as a unit test with CTest when bats is available" {
    # BATS test files fall in the interpreted path.  If bats is not on PATH,
    # enable_single_interpreted_test emits a warning and skips registration,
    # which is the correct behaviour — we skip the assertion accordingly.
    if ! command -v bats &>/dev/null; then
        skip "bats not found on PATH — bats-test registration cannot be verified"
    fi

    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_ctest_test_registered "$test_dir" "bats_alpha-utest"
}

@test "INTERPRETED_TESTS: bats_alpha-utest.bats receives label 'unit' when bats is available" {
    if ! command -v bats &>/dev/null; then
        skip "bats not found on PATH — bats-test label cannot be verified"
    fi

    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_ctest_test_label "$test_dir" "bats_alpha-utest" "unit"
}

@test "INTERPRETED_TESTS: bats_alpha-itest.bats is registered as an integration test when bats is available" {
    if ! command -v bats &>/dev/null; then
        skip "bats not found on PATH — bats-test registration cannot be verified"
    fi

    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_ctest_test_registered "$test_dir" "bats_alpha-itest"
}

@test "INTERPRETED_TESTS: bats_alpha-rtest.bats is registered as a regression test when bats is available" {
    if ! command -v bats &>/dev/null; then
        skip "bats not found on PATH — bats-test registration cannot be verified"
    fi

    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_ctest_test_registered "$test_dir" "bats_alpha-rtest"
}

# ==============================================================================
# LIBRA_NEGATIVE_TEST_INCLUDE_DIRS — extra include paths for negative tests
# ==============================================================================

@test "NEGATIVE_TEST_INCLUDE_DIRS: multiple dirs can be passed without breaking configure" {
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        -DLIBRA_NEGATIVE_TEST_INCLUDE_DIRS="/tmp;/usr/include")

    [ -f "$test_dir/CTestTestfile.cmake" ]
    assert_ctest_test_registered "$test_dir" "neg_cpp_alpha-utest"
}

@test "NEGATIVE_TEST_INCLUDE_DIRS: empty value does not break configure" {
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        -DLIBRA_NEGATIVE_TEST_INCLUDE_DIRS="")

    [ -f "$test_dir/CTestTestfile.cmake" ]
    assert_ctest_test_registered "$test_dir" "neg_cpp_alpha-utest"
}

# ==============================================================================
# LIBRA_NEGATIVE_TEST_COMPILE_FLAGS — extra compile flags for negative tests
# ==============================================================================

@test "NEGATIVE_TEST_COMPILE_FLAGS: multiple flags can be passed without breaking configure" {
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        "-DLIBRA_NEGATIVE_TEST_COMPILE_FLAGS=-DLIBRA_NEG_A=1;-DLIBRA_NEG_B=2")

    [ -f "$test_dir/CTestTestfile.cmake" ]
    assert_ctest_test_registered "$test_dir" "neg_cpp_alpha-utest"
}

@test "NEGATIVE_TEST_COMPILE_FLAGS: empty value does not break configure" {
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        -DLIBRA_NEGATIVE_TEST_COMPILE_FLAGS="")

    [ -f "$test_dir/CTestTestfile.cmake" ]
    assert_ctest_test_registered "$test_dir" "neg_cpp_alpha-utest"
}

# ==============================================================================
# LIBRA_TEST_HARNESS_LIBS — libraries linked into the harness and test executables
# ==============================================================================

@test "TEST_HARNESS_LIBS: passing a system library does not break configure" {
    # 'm' (libm) is present on all POSIX systems and is a safe canary.
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        -DLIBRA_TEST_HARNESS_LIBS="m")

    assert_target_exists "$test_dir" "sample_testing-cxx-harness"
    assert_ctest_test_registered "$test_dir" "cpp_alpha-utest"
}

@test "TEST_HARNESS_LIBS: multiple libraries can be specified without breaking configure" {
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        "-DLIBRA_TEST_HARNESS_LIBS=m;dl")

    assert_target_exists "$test_dir" "sample_testing-cxx-harness"
}

@test "TEST_HARNESS_LIBS: empty value leaves harness target intact" {
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        -DLIBRA_TEST_HARNESS_LIBS="")

    assert_target_exists "$test_dir" "sample_testing-cxx-harness"
}

# ==============================================================================
# LIBRA_TEST_HARNESS_PACKAGES — find_package() calls inside configure_test_harness
# ==============================================================================

@test "TEST_HARNESS_PACKAGES: non-empty unknown package causes configure to fail" {
    # configure_test_harness() calls find_package(... REQUIRED) for each entry.
    # A package name that cannot be found must make cmake exit non-zero.
    # We verify the failure mode so callers know the variable is honoured.
    local test_dir="$TEST_BUILD_DIR/testing_${RANDOM}"
    mkdir -p "$test_dir"

    local compiler
    compiler=$(get_compiler "${COMPILER_TYPE:-gnu}" "cxx")

    local cmake_args=(
        "$LIBRA_TESTS_DIR/sample_testing"
        -DCMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE:-Debug}"
        -DCMAKE_CXX_COMPILER="$compiler"
        -DLIBRA_TESTS=ON
        "-DLIBRA_TEST_HARNESS_PACKAGES=NonExistentPackageXyzzy"
        --log-level="$LOGLEVEL"
    )

    while IFS= read -r _flag; do
        [[ -n "$_flag" ]] && cmake_args+=("$_flag")
    done < <(_consume_mode_cmake_args)

    cd "$test_dir"
    run cmake "${cmake_args[@]}"
    cd - > /dev/null

    [ "$status" -ne 0 ]
}

# ==============================================================================
# LIBRA_NEGATIVE_COMPILE — .expected companion file
#
# enable_single_negative_compile_test() looks for a <stem>.expected file
# alongside the .neg.cpp source.  When present the shell command asserts both
# that compilation fails AND that the expected string appears in stderr.
# We verify that configure succeeds with the companion in place and that the
# negative test is still registered with CTest.
# ==============================================================================

@test "NEGATIVE_COMPILE: configure succeeds when a .expected companion file is present" {
    # sample_testing is expected to ship at least one .expected companion.
    # If none are present this test is a no-op (the configure still succeeds).
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    [ -f "$test_dir/CTestTestfile.cmake" ]
}

@test "NEGATIVE_COMPILE: neg.c unit test receives label 'unit'" {
    test_dir=$(run_libra_testing_cmake_test -DLIBRA_TESTS=ON)

    assert_ctest_test_label "$test_dir" "neg_c_alpha-utest" "unit"
}

@test "NEGATIVE_COMPILE: LIBRA_CTEST_INCLUDE_REGRESSION_TESTS=NO excludes neg.c regression tests from CTest" {
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        -DLIBRA_CTEST_INCLUDE_REGRESSION_TESTS=NO)

    # c_alpha-rtest must be absent alongside cpp_alpha-rtest.neg
    assert_ctest_test_absent "$test_dir" "neg_c_alpha-rtest"
}

# ==============================================================================
# Cross-variable interactions (extended)
# ==============================================================================

@test "INTERACTION: LIBRA_UNIT_TEST_MATCHER and LIBRA_CTEST_INCLUDE_UNIT_TESTS=NO — custom stubs absent from CTest" {
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        -DLIBRA_UNIT_TEST_MATCHER="-myutest" \
        -DLIBRA_CTEST_INCLUDE_UNIT_TESTS=NO)

    assert_ctest_test_absent "$test_dir" "cpp_alpha-myutest"
}

@test "INTERACTION: LIBRA_INTEGRATION_TEST_MATCHER and LIBRA_CTEST_INCLUDE_INTEGRATION_TESTS=NO — custom stubs absent from CTest" {
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        -DLIBRA_INTEGRATION_TEST_MATCHER="-myitest" \
        -DLIBRA_CTEST_INCLUDE_INTEGRATION_TESTS=NO)

    assert_ctest_test_absent "$test_dir" "cpp_alpha-myitest"
}

@test "INTERACTION: LIBRA_REGRESSION_TEST_MATCHER and LIBRA_CTEST_INCLUDE_REGRESSION_TESTS=NO — custom stubs absent from CTest" {
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        -DLIBRA_REGRESSION_TEST_MATCHER="-myrtest" \
        -DLIBRA_CTEST_INCLUDE_REGRESSION_TESTS=NO)

    assert_ctest_test_absent "$test_dir" "cpp_alpha-myrtest"
}

@test "INTERACTION: LIBRA_TEST_HARNESS_MATCHER non-match and LIBRA_TEST_HARNESS_LIBS coexist without error" {
    # When no harness sources are found the harness target is absent, but
    # LIBRA_TEST_HARNESS_LIBS must not cause a configure error in that case.
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        -DLIBRA_TEST_HARNESS_MATCHER="_no_such_harness" \
        -DLIBRA_TEST_HARNESS_LIBS="m")

    assert_target_absent "$test_dir" "sample_testing-cxx-harness"
    # The umbrella targets must still exist — no harness does not mean no tests.
    assert_target_exists "$test_dir" "unit-tests"
}

@test "INTERACTION: neg tests respect LIBRA_UNIT_TEST_MATCHER when a custom matcher is set" {
    # Negative unit tests follow the same matcher suffix as positive unit tests.
    # With a custom matcher, only the custom-named .neg files should appear.
    test_dir=$(run_libra_testing_cmake_test \
        -DLIBRA_TESTS=ON \
        -DLIBRA_UNIT_TEST_MATCHER="-myutest")

    # Default-matcher neg files must be absent
    assert_ctest_test_absent "$test_dir" "neg_cpp_alpha-utest"
    assert_ctest_test_absent "$test_dir" "neg_c_alpha-utest"
}
