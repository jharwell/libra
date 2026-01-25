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

# Create a simple executable
# Use libra_add_executable() to ensure the target gets registered with LIBRA
libra_add_executable(${PROJECT_NAME} ${TEST_SOURCES})

# Use libra_configure_source_file to generate a file with build flags
# The generated build_info file will contain LIBRA_TARGET_FLAGS_BUILD as a string constant
if(LIBRA_TEST_LANGUAGE STREQUAL "C")
    libra_configure_source_file(
        ${PROJECT_SOURCE_DIR}/src/build_info.c.in
        ${CMAKE_BINARY_DIR}/build_info.c
    )
else()
    libra_configure_source_file(
        ${PROJECT_SOURCE_DIR}/src/build_info.cpp.in
        ${CMAKE_BINARY_DIR}/build_info.cpp
    )
endif()
