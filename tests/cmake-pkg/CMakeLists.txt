#
# Copyright 2025 John Harwell, All rights reserved.
#
# SPDX-License Identifier: MIT
#
cmake_minimum_required(VERSION 3.31 FATAL_ERROR)
project(cmake-pkg-project C CXX)

find_package(libra REQUIRED)
include(libra/project)
