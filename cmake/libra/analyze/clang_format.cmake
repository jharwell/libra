#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#
include(libra/messaging)

# ##############################################################################
# Register a target for clang-format formatting
# ##############################################################################
function(do_register_clang_format FMT_TARGET JOB)
  if(JOB STREQUAL "FORMAT")
    set(JOB_ARGS -i)
  else()
    set(JOB_ARGS --Werror --dry-run -i)
  endif()

  # A clever way to bake in .clang-format and use with cmake. Tested with both
  # SELF and CONAN drivers, and will point to the baked-in .clang-format in this
  # repo.
  if(NOT DEFINED LIBRA_CLANG_FORMAT_FILEPATH)
    set(LIBRA_CLANG_FORMAT_FILEPATH_DEFAULT
        "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../../dots/.clang-format")
    set(LIBRA_CLANG_FORMAT_FILEPATH "${LIBRA_CLANG_FORMAT_FILEPATH_DEFAULT}")
  endif()
  get_filename_component(clang_format_NAME ${clang_format_EXECUTABLE} NAME)

  add_custom_target(
    ${FMT_TARGET}
    COMMAND ${clang_format_EXECUTABLE}
            -style=file:${LIBRA_CLANG_FORMAT_FILEPATH} ${JOB_ARGS} ${ARGN}
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    COMMENT "Running ${clang_format_NAME} JOB=${JOB}")

  set_target_properties(${FMT_TARGET} PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1)
endfunction()

# ##############################################################################
# Register all target sources with the clang-format formatter
# ##############################################################################
function(libra_register_formatter_clang_format)
  if(NOT clang_format_EXECUTABLE)
    return()
  endif()

  do_register_clang_format(format-clang-format "FORMAT" ${ARGN})
  add_dependencies(format format-clang-format)

  get_filename_component(clang_format_NAME ${clang_format_EXECUTABLE} NAME)
  list(LENGTH ARGN LEN)
  libra_message(STATUS
                "Registered ${LEN} files with ${clang_format_NAME} formatter")
endfunction()

# ##############################################################################
# Register all target sources with the clang-format checker
# ##############################################################################
function(libra_register_checker_clang_format)
  if(NOT clang_format_EXECUTABLE)
    return()
  endif()

  do_register_clang_format(analyze-clang-format "CHECK" ${ARGN})
  add_dependencies(analyze analyze-clang-format)

  get_filename_component(clang_format_NAME ${clang_format_EXECUTABLE} NAME)
  list(LENGTH ARGN LEN)
  libra_message(STATUS
                "Registered ${LEN} files with ${clang_format_NAME} checker")

endfunction()

# ##############################################################################
# Enable or disable clang-format for auto-formatting/checking for the project
# ##############################################################################
function(libra_toggle_clang_format request)
  if(NOT request)
    libra_message(STATUS "Disabling clang-format formatter by request")
    set(clang_format_EXECUTABLE)
    return()
  endif()

  find_program(
    clang_format_EXECUTABLE
    NAMES clang-format-21
          clang-format-20
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
    libra_message(STATUS "clang-format [disabled=not found]")
    return()
  endif()
endfunction()
