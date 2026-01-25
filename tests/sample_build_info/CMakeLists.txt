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

# Point to libra cmake modules
set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/../../cmake)

include(libra/project)
