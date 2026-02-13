#
# Copyright (c) 2026 Boon Logic, Inc.
#
# The software provided is the sole and exclusive property of EpiSys Science,
# Inc. The user shall use the software only in support of the agreed upon
# experimental purpose only and shall preserve and protect the software from
# disclosure to any person or persons, other than employees, consultants, and
# contracted staff of the corporation with a need to know, through an exercise
# of care equivalent to the degree of care it uses to preserve and protect its
# own intellectual property. Unauthorized use of the software is prohibited
# without written consent.
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
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
