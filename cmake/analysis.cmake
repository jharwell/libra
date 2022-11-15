#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#
include(${CMAKE_CURRENT_LIST_DIR}/cppcheck.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/clang_tidy.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/clang_format.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/clang_check.cmake)

# Function to register a target for enabled code checkers
function(register_checkers TARGET)
  add_custom_target(${TARGET}-check)

  set_target_properties(${TARGET}-check
    PROPERTIES
    EXCLUDE_FROM_DEFAULT_BUILD 1
    )
  register_cppcheck_checker(${TARGET} ${ARGN})
  register_clang_tidy_checker(${TARGET} ${ARGN})
  register_clang_check_checker(${TARGET} ${ARGN})
endfunction()

# Function to register a target for enabled automated formatters
function(register_auto_formatters TARGET)
  if (NOT CLANG_FORMAT_ENABLED)
    return()
  endif()

  add_custom_target(${TARGET}-format)

  set_target_properties(${TARGET}-format
    PROPERTIES
    EXCLUDE_FROM_DEFAULT_BUILD 1
    )

  register_clang_format(${TARGET} ${ARGN})
endfunction()

# Function to register a target for enabled automated fixers
function(register_auto_fixers TARGET)
  if (NOT CLANG_TIDY_FIX_ENABLED)
    return()
  endif()

  add_custom_target(${TARGET}-fix)

  set_target_properties(${TARGET}-fix
    PROPERTIES
    EXCLUDE_FROM_DEFAULT_BUILD 1
    )

  register_clang_tidy_fix(${TARGET} ${ARGN})
endfunction()
