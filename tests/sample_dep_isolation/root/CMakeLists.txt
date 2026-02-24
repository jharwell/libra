#
# Copyright 2026 John Harwell, All rights reserved.
#
# SPDX-License-Identifier: MIT
#
# Root project: uses LIBRA and pulls in 'dep' as a subdirectory which also uses
# LIBRA.  Used to verify:
#
# (a) All LIBRA special targets (analyze, format, fix, coverage, etc.) are
# created for the root project.
#
# (b) No duplicate LIBRA special targets are created for the dep project (LIBRA
# guards against this with NOT TARGET checks).
#
# (c) LIBRA build settings set on the root do not bleed into the dep.
#
cmake_minimum_required(VERSION 3.31 FATAL_ERROR)

if(NOT LIBRA_TEST_LANGUAGE)
  set(LIBRA_TEST_LANGUAGE "CXX")
endif()

if(LIBRA_TEST_LANGUAGE STREQUAL "C")
  project(sample_dep_root C)
else()
  project(sample_dep_root CXX)
endif()

# Set CMAKE_MODULE_PATH from LIBRA_SOURCE_ROOT (set by test infrastructure) or
# fall back to relative path for direct invocation
if(LIBRA_SOURCE_ROOT)
  list(APPEND CMAKE_MODULE_PATH "${LIBRA_SOURCE_ROOT}/cmake")
else()
  list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../../../cmake")
endif()

include(libra/project)

add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/../dep
                 ${CMAKE_CURRENT_BINARY_DIR}/dep)
