#
# Copyright 2025 John Harwell, All rights reserved.
#
# SPDX-License-Identifier: MIT
#
# sample_testing — minimal LIBRA project used by LIBRA_TESTS.bats.
#
# Purpose: provide a project with real test source files so that
# testing.cmake can discover them via GLOB_RECURSE, register them with
# CTest, and create the umbrella Makefile targets.  All test stubs are
# trivial (int main(){return 0;}) so they compile cleanly but never need
# to be run; the BATS tests only inspect the CMake configuration output.
#
cmake_minimum_required(VERSION 3.16 FATAL_ERROR)
project(sample_testing LANGUAGES CXX)

# Wire up LIBRA via the same mechanism all other sample projects use.
include(${CMAKE_CURRENT_SOURCE_DIR}/../consume/libra_consume.cmake)

include(libra/project)
