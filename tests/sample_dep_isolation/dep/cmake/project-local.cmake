#
# Copyright 2026 John Harwell, All rights reserved.
#
# SPDX-License-Identifier: MIT
#

if(LIBRA_TEST_LANGUAGE STREQUAL "C")
  libra_add_library(${PROJECT_NAME} STATIC src/dep.c)
else()
  libra_add_library(${PROJECT_NAME} STATIC src/dep.cpp)
endif()
