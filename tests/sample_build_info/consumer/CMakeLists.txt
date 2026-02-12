#
# Copyright 2025 John Harwell, All rights reserved.
#
# SPDX-License Identifier: MIT
#
# Consumer subdirectory: a plain (non-LIBRA) executable that links against
# sample_build_info as a static library.  Used to test whether the LIBRA_ERL
# define propagates downstream (i.e. whether LIBRA_ERL_EXPORT is working).
#
# We query INTERFACE_COMPILE_DEFINITIONS off the library target.  That property
# contains exactly the PUBLIC definitions set via target_compile_definitions().
# PRIVATE definitions do NOT appear there.  We write it into a configured source
# file so the shell test can grep it.
#
project(consumer C CXX)
if(LIBRA_TEST_LANGUAGE STREQUAL "C")
  set(CONSUMER_SOURCES main.c)
  set(BUILD_INFO_IN ${CMAKE_CURRENT_SOURCE_DIR}/consumer_build_info.c.in)
  set(BUILD_INFO_OUT ${CMAKE_CURRENT_BINARY_DIR}/consumer_build_info.c)
else()
  set(CONSUMER_SOURCES main.cpp)
  set(BUILD_INFO_IN ${CMAKE_CURRENT_SOURCE_DIR}/consumer_build_info.cpp.in)
  set(BUILD_INFO_OUT ${CMAKE_CURRENT_BINARY_DIR}/consumer_build_info.cpp)
endif()

libra_add_executable(${PROJECT_NAME} ${CONSUMER_SOURCES})
target_link_libraries(${PROJECT_NAME} PUBLIC sample_build_info)

libra_configure_source_file(${PROJECT_NAME} ${BUILD_INFO_IN} ${BUILD_INFO_OUT})
