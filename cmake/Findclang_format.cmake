#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  LGPL-2.0-or-later
#

# Findclang_format results:
# clang_format_FOUND
# clang_format_EXECUTABLE

include(FindPackageHandleStandardArgs)

find_program(clang_format_EXECUTABLE
  NAMES
  clang-format-14
  clang-format-13
  clang-format-12
  clang-format-11
  clang-format-10
  clang-format
  PATHS
  "${CLANG_FORMAT_DIR}"
)

find_package_handle_standard_args(clang_format
    FOUND_VAR
        clang_format_FOUND
    REQUIRED_VARS
        clang_format_EXECUTABLE
)

mark_as_advanced(clang_format_EXECUTABLE)
