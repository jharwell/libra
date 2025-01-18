#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#

# ##############################################################################
# Register a target for clang_format
# ##############################################################################

function(do_register_clang_format FMT_TARGET TARGET)
  add_custom_target(
    ${FMT_TARGET}
    COMMAND ${clang_format_EXECUTABLE} -style=file -i ${ARGN}
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    COMMENT "Running ${clang_format_EXECUTABLE}")

  set_target_properties(${FMT_TARGET} PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1)

  add_dependencies(${FMT_TARGET} ${TARGET})
endfunction()

# ##############################################################################
# Register all target sources with the clang_format formatter
# ##############################################################################
function(libra_register_formatter_clang_format TARGET)
  if(NOT clang_format_EXECUTABLE)
    return()
  endif()

  do_register_clang_format(format-clang-format ${TARGET} ${ARGN})
  add_dependencies(format format-clang-format)
endfunction()

# ##############################################################################
# Enable or disable clang_format for auto-formatting for the project
# ##############################################################################
function(libra_toggle_formatter_clang_format request)
  if(NOT request)
    libra_message(STATUS "Disabling clang-format formatter by request")
    set(clang_format_EXECUTABLE)
    return()
  endif()

  find_program(
    clang_format_EXECUTABLE
    NAMES clang-format-20
          clang-format-19
          clang-format-18
          clang-format-17
          clang-format-16
          clang-format-15
          clang-format-14
          clang-format-13
          clang-format-12
          clang-format-11
          clang-format-10
          clang-format
    PATHS "${clang_format_DIR}")

  if(NOT clang_format_EXECUTABLE)
    message(STATUS "clang-format [disabled=not found]")
    return()
  endif()
endfunction()
