#
# Copyright 2026 John Harwell, All rights reserved.
#
# SPDX-License Identifier: MIT
#
include(${CMAKE_SOURCE_DIR}/../common.cmake)

file(WRITE ${CMAKE_BINARY_DIR}/a.cpp "int f(){return 0;}")
file(WRITE ${CMAKE_BINARY_DIR}/b.cpp "int g(){return 0;}")

libra_add_library(mylib ${CMAKE_BINARY_DIR}/a.cpp)
libra_add_executable(myexe ${CMAKE_BINARY_DIR}/b.cpp)

libra_register_target_for_install(mylib)

assert_target_exists(mylib)
assert_target_exists(myexe)

libra_target_count(COUNT)
assert_equal(${COUNT} 2)
