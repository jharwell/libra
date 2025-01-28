#
# Copyright 2025 John Harwell, All rights reserved.
#
# SPDX-License Identifier: MIT
#
# This file contains all of the baked-in defaults in LIBRA so to make it easy to
# tweak/extend LIBRA to suite a given use case.

set(LIBRA_SAN_DEFAULT "NONE")
set(LIBRA_FORTIFY_DEFAULT "NONE")

set(LIBRA_UNIT_TEST_MATCHER_DEFAULT -utest)
set(LIBRA_INTEGRATION_TEST_MATCHER_DEFAULT -itest)
set(LIBRA_TEST_HARNTESS_MATCHER_DEFAULT _test)

set(LIBRA_CLANG_TIDY_FILEPATH_DEFAULT
    "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../../dots/.clang-tidy")
set(LIBRA_CLANG_FORMAT_FILEPATH_DEFAULT
    "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../../dots/.clang-format")
set(LIBRA_CMAKE_FORMAT_FILEPATH_DEFAULT
    "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../../dots/.cmake-format")

set(LIBRA_CLANG_TIDY_CHECKS_CONFIG_DEFAULT ,-clang-diagnostic-*)
