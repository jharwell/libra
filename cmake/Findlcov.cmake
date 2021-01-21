# Findlcov results:
# LCOV_FOUND
# LCOV_EXECUTABLE

include(FindPackageHandleStandardArgs)

find_program(LCOV_EXECUTABLE
    NAMES
        lcov
    PATHS
        "${LCOV_DIR}"
        "$ENV{LCOV_DIR}"
)

find_package_handle_standard_args(LCOV
	FOUND_VAR
        LCOV_FOUND
    REQUIRED_VARS
        LCOV_EXECUTABLE
)

mark_as_advanced(LCOV_EXECUTABLE)
