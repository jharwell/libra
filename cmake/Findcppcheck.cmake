#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#
# Findcppcheck results:
# cppcheck_FOUND
# cppcheck_EXECUTABLE

include(FindPackageHandleStandardArgs)

find_program(cppcheck_EXECUTABLE
    NAMES
        cppcheck
    PATHS
        "${cppcheck_DIR}"
        "$ENV{CPPCHECK_DIR}"
)

find_package_handle_standard_args(cppcheck
	FOUND_VAR
        cppcheck_FOUND
    REQUIRED_VARS
        cppcheck_EXECUTABLE
)

mark_as_advanced(cppcheck_EXECUTABLE)
