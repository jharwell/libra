#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#
# Findlcov results:
# lcov_FOUND
# lcov_EXECUTABLE

include(FindPackageHandleStandardArgs)

find_program(lcov_EXECUTABLE
    NAMES
        lcov
    PATHS
        "${lcov_DIR}"
        "$ENV{LCOV_DIR}"
)

find_package_handle_standard_args(lcov
	FOUND_VAR
        lcov_FOUND
    REQUIRED_VARS
        lcov_EXECUTABLE
)

mark_as_advanced(lcov_EXECUTABLE)
