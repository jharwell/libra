#
# Copyright 2026 John Harwell, All rights reserved.
#
# SPDX-License-Identifier: MIT
#
file(WRITE ${CMAKE_BINARY_DIR}/net_a.cpp "int net_a(){return 0;}")
file(WRITE ${CMAKE_BINARY_DIR}/net_b.cpp "int net_b(){return 0;}")
file(WRITE ${CMAKE_BINARY_DIR}/serial_a.cpp "int serial_a(){return 0;}")
file(WRITE ${CMAKE_BINARY_DIR}/core.cpp "int core(){return 0;}")

file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/include)
file(WRITE ${CMAKE_BINARY_DIR}/include/mylib.hpp "#pragma once")

set(ALL_SRC ${CMAKE_BINARY_DIR}/net_a.cpp ${CMAKE_BINARY_DIR}/net_b.cpp
            ${CMAKE_BINARY_DIR}/serial_a.cpp ${CMAKE_BINARY_DIR}/core.cpp)

# Error injection: missing REGEX
if(LIBRA_TEST_COMPONENT_MISSING_REGEX)
  libra_add_component_library(
    TARGET
    sample_components
    COMPONENT
    networking
    SOURCES
    ${ALL_SRC})
  return()
endif()

if(LIBRA_TEST_USE_DEPRECATED_NAMES)
  libra_component_register_as_lib(sample_components "${ALL_SRC}" networking
                                  "net_.*\\.cpp")
  libra_add_library(
    NAME
    sample_components
    ${NET_SRC}
    ${SERIAL_SRC}
    ${CMAKE_BINARY_DIR}/core.cpp)
else()
  # Default: library strategy
  libra_add_component_library(
    TARGET
    sample_components
    COMPONENT
    networking
    SOURCES
    ${ALL_SRC}
    REGEX
    "net_.*\\.cpp")

  libra_add_component_library(
    TARGET
    sample_components
    COMPONENT
    serialization
    SOURCES
    ${ALL_SRC}
    REGEX
    "serial_.*\\.cpp")

  libra_add_library(NAME sample_components ${CMAKE_BINARY_DIR}/core.cpp)
endif()

libra_configure_exports(sample_components)
libra_install_target(sample_components INCLUDE_DIR ${CMAKE_BINARY_DIR}/include/)
libra_install_target(sample_components_networking INCLUDE_DIR
                     ${CMAKE_BINARY_DIR}/include/)
libra_install_copyright(
  sample_components ${CMAKE_CURRENT_SOURCE_DIR}/../sample_components/LICENSE)

assert_target_exists(sample_components)
assert_true(sample_components_networking_FOUND)

if(NOT LIBRA_TEST_USE_DEPRECATED_NAMES)
  assert_true(sample_components_serialization_FOUND)
endif()

assert_file_exists("${CMAKE_BINARY_DIR}/sample_components-config.cmake")
