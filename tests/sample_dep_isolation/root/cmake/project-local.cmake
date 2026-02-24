#
# Copyright 2026 John Harwell, All rights reserved.
#
# SPDX-License-Identifier: MIT
#

if(LIBRA_TEST_LANGUAGE STREQUAL "C")
  libra_add_executable(${PROJECT_NAME} src/main.c)
  libra_configure_source_file(
    ${PROJECT_NAME}
    ${PROJECT_SOURCE_DIR}/src/build_info.c.in
    ${CMAKE_BINARY_DIR}/build_info.c)
else()
  libra_add_executable(${PROJECT_NAME} src/main.cpp)
  libra_configure_source_file(
    ${PROJECT_NAME}
    ${PROJECT_SOURCE_DIR}/src/build_info.cpp.in
    ${CMAKE_BINARY_DIR}/build_info.cpp)
endif()

target_link_libraries(${PROJECT_NAME} PRIVATE sample_dep_lib)
