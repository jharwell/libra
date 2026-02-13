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

# Build and export producer first
file(WRITE ${CMAKE_BINARY_DIR}/lib.cpp "int f(){return 0;}")

libra_add_library(NAME producer ${CMAKE_BINARY_DIR}/lib.cpp)

libra_configure_exports(TARGET producer EXPORT ProducerTargets)

set(CMAKE_PREFIX_PATH ${CMAKE_BINARY_DIR})

find_package(ProducerTargets REQUIRED)

assert_target_exists(producer)
