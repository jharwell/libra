#
# Copyright 2026 John Harwell, All rights reserved.
#
# SPDX-License-Identifier: MIT
#
# Dependency project: a static library that also uses LIBRA, consumed via
# add_subdirectory() from sample_dep_isolation/root.
#
# LIBRA special targets (analyze, format, fix, coverage, etc.) must NOT be
# re-created here -- they are already owned by the root project and cmake
# target names must be globally unique.  LIBRA's NOT TARGET guards prevent
# duplicate creation; this project verifies those guards fire correctly.
#
cmake_minimum_required(VERSION 3.31 FATAL_ERROR)

if(NOT LIBRA_TEST_LANGUAGE)
  set(LIBRA_TEST_LANGUAGE "CXX")
endif()

if(LIBRA_TEST_LANGUAGE STREQUAL "C")
  project(sample_dep_lib C)
else()
  project(sample_dep_lib CXX)
endif()

# CMAKE_MODULE_PATH is inherited from the root project via add_subdirectory
include(libra/project)
