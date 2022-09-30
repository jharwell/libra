# Findgenhtml results:
# genhtml_FOUND
# genhtml_EXECUTABLE

include(FindPackageHandleStandardArgs)

find_program(genhtml_EXECUTABLE
    NAMES
        genhtml
    PATHS
        "${GENHTML_DIR}"
        "$ENV{GENHTML_DIR}"
)

find_package_handle_standard_args(genhtml
	FOUND_VAR
        genhtml_FOUND
    REQUIRED_VARS
        genhtml_EXECUTABLE
)

mark_as_advanced(genhtml_EXECUTABLE)
