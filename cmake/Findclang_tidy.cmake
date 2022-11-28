#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#
# Findclang_tidy results:
# clang_tidy_FOUND
# clang_tidy_EXECUTABLE

include(FindPackageHandleStandardArgs)

find_program(clang_tidy_EXECUTABLE
  NAMES
  clang-tidy-14
  clang-tidy-13
  clang-tidy-12
  clang-tidy-11
  clang-tidy-10
  clang-tidy
  PATHS
  "${clang_tidy_DIR}"
)

find_package_handle_standard_args(clang_tidy
    FOUND_VAR
        clang_tidy_FOUND
    REQUIRED_VARS
        clang_tidy_EXECUTABLE
)

mark_as_advanced(clang_tidy_EXECUTABLE)
