#
# Copyright 2025 John Harwell, All rights reserved.
#
# SPDX-License-Identifier: MIT
#

# Determine which language sources to use
if(LIBRA_TEST_LANGUAGE STREQUAL "C")
  set(TEST_SOURCES ${${PROJECT_NAME}_C_SRC})
else()
  set(TEST_SOURCES ${${PROJECT_NAME}_CXX_SRC})
endif()

# ---------------------------------------------------------------------------
# STUBS test path: build a STATIC library with a public header so that
# _libra_generate_header_stubs and _libra_prune_stale_stubs are exercised during
# LIBRA_ANALYSIS=ON configure.
# ---------------------------------------------------------------------------
if(LIBRA_TEST_STUBS)
  # include/sample_build_info/stub.hpp is a static source-tree file that
  # project.cmake's GLOB_RECURSE picks up into ${PROJECT_NAME}_CXX_HEADERS
  # before project-local.cmake is included.  Exposing it via
  # INTERFACE_INCLUDE_DIRECTORIES on the library target gives
  # _libra_generate_header_stubs something to produce a stub for.
  libra_add_library(${PROJECT_NAME} STATIC lib_stub.cpp)
  target_include_directories(
    ${PROJECT_NAME}
    INTERFACE $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>)

elseif(LIBRA_TEST_ERL_EXPORT OR LIBRA_TEST_FPC_EXPORT)
  if(LIBRA_TEST_LANGUAGE STREQUAL "C")
    set(LIB_SOURCES lib_stub.c)
  else()
    set(LIB_SOURCES lib_stub.cpp)
  endif()

  libra_add_library(${PROJECT_NAME} STATIC ${LIB_SOURCES})
  add_subdirectory(consumer)

  # ---------------------------------------------------------------------------
  # Default path: simple executable (used by all other tests).
  # ---------------------------------------------------------------------------
else()
  libra_add_executable(${PROJECT_NAME} ${TEST_SOURCES})

  # Use libra_configure_source_file to generate a file with build flags. The
  # generated build_info file will contain LIBRA_TARGET_FLAGS_COMPILE as a
  # string constant.
  if(LIBRA_TEST_LANGUAGE STREQUAL "C")
    libra_configure_source_file(
      ${PROJECT_NAME} ${PROJECT_SOURCE_DIR}/src/build_info.c.in
      ${CMAKE_BINARY_DIR}/build_info.c)
  else()
    libra_configure_source_file(
      ${PROJECT_NAME} ${PROJECT_SOURCE_DIR}/src/build_info.cpp.in
      ${CMAKE_BINARY_DIR}/build_info.cpp)
  endif()
endif()

# ---------------------------------------------------------------------------
# Compiler version requirement testing. Exercises all argument combinations so
# the missing-ID, missing-VERSION, and version-too-low error paths are all
# reachable from the bats test suite.
# ---------------------------------------------------------------------------
if(LIBRA_TEST_REQUIRE_COMPILER_MISSING_ID)
  libra_require_compiler(VERSION 1.1.1)
elseif(LIBRA_TEST_REQUIRE_COMPILER_MISSING_VERSION)
  libra_require_compiler(ID GNU)
elseif(LIBRA_TEST_REQUIRE_COMPILER_VERSION AND NOT
                                               LIBRA_TEST_REQUIRE_COMPILER_ID)
  # Exercise the missing-ID error path
  libra_require_compiler(VERSION ${LIBRA_TEST_REQUIRE_COMPILER_VERSION})
elseif(LIBRA_TEST_REQUIRE_COMPILER_ID AND NOT
                                          LIBRA_TEST_REQUIRE_COMPILER_VERSION)
  # Exercise the missing-VERSION error path
  libra_require_compiler(ID ${LIBRA_TEST_REQUIRE_COMPILER_ID})
elseif(LIBRA_TEST_REQUIRE_COMPILER_ID AND LIBRA_TEST_REQUIRE_COMPILER_VERSION)
  if(LIBRA_TEST_REQUIRE_COMPILER_LANG)
    libra_require_compiler(
      LANG
      ${LIBRA_TEST_REQUIRE_COMPILER_LANG}
      ID
      ${LIBRA_TEST_REQUIRE_COMPILER_ID}
      VERSION
      ${LIBRA_TEST_REQUIRE_COMPILER_VERSION})
  else()
    libra_require_compiler(ID ${LIBRA_TEST_REQUIRE_COMPILER_ID} VERSION
                           ${LIBRA_TEST_REQUIRE_COMPILER_VERSION})
  endif()
endif()
