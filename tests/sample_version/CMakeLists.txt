#
# Copyright 2026 John Harwell, All rights reserved.
#
# SPDX-License-Identifier: MIT
#
# Fixture for LIBRA_VERSION.bats. The test harness copies this directory into a
# per-test temp dir and builds whatever git history the test needs around it,
# so version resolution is fully controlled by the test (never LIBRA's own
# repository).
#
# Knobs (all injected as -D by the tests):
#
# LIBRA_TEST_VERSION_AUTO: When ON, don't call project() ourselves; let
# include(libra/project) call libra_extract_version() and project() for us.
#
# LIBRA_TEST_VERSION_SUBDIR: Path to a nested project to add_subdirectory()
# after the top-level project is configured, to check version scoping.
#
cmake_minimum_required(VERSION 3.31 FATAL_ERROR)

# Wire up LIBRA according to the consumption mode selected by the test harness.
# This has to come first: the explicit pattern below needs libra/version on the
# module path before project().
include(${LIBRA_TESTS_DIR}/consume/libra_consume.cmake)

if(LIBRA_TEST_VERSION_AUTO)
  include(libra/project)
else()
  include(libra/version)
  libra_extract_version()
  project(
    sample_version
    VERSION ${LIBRA_PROJECT_VERSION_NUMERIC}
    LANGUAGES C)
  include(libra/project)
endif()

# Machine-readable markers for the tests to grep. Printed after LIBRA has fully
# configured, so these reflect what the rest of the build would see.
message(STATUS "[VERSION-TEST] PROJECT_VERSION=${PROJECT_VERSION}")
message(STATUS "[VERSION-TEST] LIBRA_PROJECT_VERSION=${LIBRA_PROJECT_VERSION}")
message(STATUS "[VERSION-TEST] LIBRA_VERSION=${LIBRA_VERSION}")

if(LIBRA_TEST_VERSION_SUBDIR)
  add_subdirectory(${LIBRA_TEST_VERSION_SUBDIR} ${CMAKE_BINARY_DIR}/nested)
  # Must be unchanged by the nested project's libra_extract_version().
  message(
    STATUS "[VERSION-TEST] AFTER_NESTED LIBRA_PROJECT_VERSION=${LIBRA_PROJECT_VERSION}")
endif()
