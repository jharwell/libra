#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#
# Findgenhtml results:
# genhtml_FOUND
# genhtml_EXECUTABLE

include(FindPackageHandleStandardArgs)

find_program(genhtml_EXECUTABLE
    NAMES
        genhtml
    PATHS
        "${genhtml_DIR}"
        "$ENV{GENHTML_DIR}"
)

find_package_handle_standard_args(genhtml
	FOUND_VAR
        genhtml_FOUND
    REQUIRED_VARS
        genhtml_EXECUTABLE
)

mark_as_advanced(genhtml_EXECUTABLE)
