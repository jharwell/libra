#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#
include(libra/messaging)
# ##############################################################################
# Register a target for clang_format
# ##############################################################################

function(do_register_clang_format FMT_TARGET TARGET)

  get_filename_component(clang_format_NAME ${clang_format_EXECUTABLE} NAME)

  # A clever way to bake in .clang-format and use with cmake. Tested with both
  # SELF and CONAN drivers, and will point to the baked-in .clang-format in this
  # repo.
  if(NOT DEFINED LIBRA_CLANG_FORMAT_FILEPATH)
    set(LIBRA_CLANG_FORMAT_FILEPATH
        "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../../clang-tools/.clang-format")
  endif()

  add_custom_target(
    ${FMT_TARGET}
    COMMAND
      ${clang_format_EXECUTABLE} -style=file:${LIBRA_CLANG_FORMAT_FILEPATH}
      "$<$<NOT:$<BOOL:${LIBRA_CLANG_FORMAT_BAKED_IN_CONFIG}>>:-style=file>" -i
      ${ARGN}
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    COMMENT "Running ${clang_format_NAME}")

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
