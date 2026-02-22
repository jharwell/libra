#
# Copyright 2025 John Harwell, All rights reserved.
#
# SPDX-License Identifier: MIT
#
cmake_minimum_required(VERSION 3.31 FATAL_ERROR)

# Determine which language to test based on CMake variable
if(NOT LIBRA_TEST_LANGUAGE)
  set(LIBRA_TEST_LANGUAGE "CXX") # Default to C++
endif()

if(LIBRA_TEST_LANGUAGE STREQUAL "C")
  project(sample_build_info C)
else()
  project(sample_build_info CXX)
endif()

# Wire up LIBRA according to the consumption mode selected by the test harness.
# LIBRA_CONSUME_MODE and companion variables are injected as -D arguments by
# run_libra_cmake_test() in test_helpers.bash.  When not set the module falls
# back to the in_situ relative path so samples still work when invoked directly.
include(${CMAKE_CURRENT_SOURCE_DIR}/../consume/libra_consume.cmake)

include(libra/project)
