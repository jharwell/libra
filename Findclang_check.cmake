# Findclang_format results:
# clang_check_FOUND
# clang_check_EXECUTABLE

include(FindPackageHandleStandardArgs)

find_program(clang_check_EXECUTABLE
    NAMES
        clang-check-4.0
        clang-check-3.8
        clang-check
    PATHS
        "${CLANG_CHECK_DIR}"
)

find_package_handle_standard_args(clang_check
    FOUND_VAR
        clang_check_FOUND
    REQUIRED_VARS
        clang_check_EXECUTABLE
)

mark_as_advanced(clang_check_EXECUTABLE)
