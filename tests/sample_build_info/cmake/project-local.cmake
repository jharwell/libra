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
# ERL_EXPORT test path: build a STATIC library + a plain consumer executable.
# The consumer links the library and we inspect what definitions propagated. We
# do NOT use libra_configure_source_file here — that macro appends sources to
# ${PROJECT_NAME} assuming it is an executable, and we don't need the library's
# own build_info for this test.
# ---------------------------------------------------------------------------
if(LIBRA_TEST_ERL_EXPORT OR LIBRA_TEST_FPC_EXPORT)
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
