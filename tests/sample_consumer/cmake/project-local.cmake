#
# Copyright 2026 John Harwell, All rights reserved.
#
# SPDX-License Identifier: MIT
#
include(${CMAKE_SOURCE_DIR}/../common.cmake)

# Build and export producer first
file(WRITE ${CMAKE_BINARY_DIR}/lib.cpp "int f(){return 0;}")

libra_add_library(NAME producer ${CMAKE_BINARY_DIR}/lib.cpp)

libra_configure_exports(TARGET producer EXPORT ProducerTargets)

set(CMAKE_PREFIX_PATH ${CMAKE_BINARY_DIR})

find_package(ProducerTargets REQUIRED)

assert_target_exists(producer)
