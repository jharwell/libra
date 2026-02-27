#
# Copyright 2025 John Harwell, All rights reserved.
#
# SPDX-License-Identifier: MIT
#
# project-local.cmake for sample_testing.
#
# Declares a minimal static library so that testing.cmake can wire test
# executables against ${PROJECT_NAME} via target_link_libraries.  No real
# symbols are required; the library source is a single stub file.
#

libra_add_library(${PROJECT_NAME} STATIC ${CMAKE_CURRENT_SOURCE_DIR}/src/lib.cpp)
