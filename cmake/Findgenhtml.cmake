# Findgenhtml results:
# GENHTML_FOUND
# GENHTML_EXECUTABLE

include(FindPackageHandleStandardArgs)

find_program(GENHTML_EXECUTABLE
    NAMES
        genhtml
    PATHS
        "${GENHTML_DIR}"
        "$ENV{GENHTML_DIR}"
)

find_package_handle_standard_args(GENHTML
	FOUND_VAR
        GENHTML_FOUND
    REQUIRED_VARS
        GENHTML_EXECUTABLE
)

mark_as_advanced(GENHTML_EXECUTABLE)
