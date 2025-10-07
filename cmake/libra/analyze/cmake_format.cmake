#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#

include(libra/messaging)
# ##############################################################################
# Register a target for cmake-format formatting/checking
# ##############################################################################
function(do_register_cmake_format FMT_TARGET JOB)
  if(JOB STREQUAL "FORMAT")
    set(JOB_ARGS -i)
  else()
    set(JOB_ARGS --check)
  endif()

  # A clever way to bake in .cmake-format and use with cmake. Tested with both
  # SELF and CONAN drivers, and will point to the baked-in .cmake-format in this
  # repo.
  if(NOT DEFINED LIBRA_CMAKE_FORMAT_FILEPATH)
    set(LIBRA_CMAKE_FORMAT_FILEPATH_DEFAULT
        "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../../dots/.cmake-format")

    set(LIBRA_CMAKE_FORMAT_FILEPATH "${LIBRA_CMAKE_FORMAT_FILEPATH_DEFAULT}")
  endif()

  get_filename_component(cmake_format_NAME ${cmake_format_EXECUTABLE} NAME)
  add_custom_target(
    ${FMT_TARGET}
    COMMAND ${cmake_format_EXECUTABLE} -c${LIBRA_CMAKE_FORMAT_FILEPATH}
            ${JOB_ARGS} ${ARGN}
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    COMMENT "Running ${cmake_format_NAME}: JOB=${JOB}")

  set_target_properties(${FMT_TARGET} PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1)
endfunction()

# ##############################################################################
# Register all target sources with the cmake-format formatter
# ##############################################################################
function(libra_register_formatter_cmake_format)
  if(NOT cmake_format_EXECUTABLE)
    return()
  endif()

  do_register_cmake_format(format-cmake-format "FORMAT" ${ARGN})
  add_dependencies(format format-cmake-format)

  get_filename_component(cmake_format_NAME ${cmake_format_EXECUTABLE} NAME)
  list(LENGTH ARGN LEN)
  libra_message(STATUS
                "Registered ${LEN} files with ${cmake_format_NAME} formatter")
endfunction()

# ##############################################################################
# Register all target sources with the cmake-format checker
# ##############################################################################
function(libra_register_checker_cmake_format)
  if(NOT cmake_format_EXECUTABLE)
    return()
  endif()

  do_register_cmake_format(analyze-cmake-format "CHECK" ${ARGN})
  add_dependencies(analyze analyze-cmake-format)

  get_filename_component(cmake_format_NAME ${cmake_format_EXECUTABLE} NAME)
  list(LENGTH ARGN LEN)
  libra_message(STATUS
                "Registered ${LEN} files with ${cmake_format_NAME} checker")
endfunction()

# ##############################################################################
# Enable or disable cmake_format for auto-formatting/checking for the project
# ##############################################################################
function(libra_toggle_cmake_format request)
  if(NOT request)
    libra_message(STATUS "Disabling cmake-format by request")
    set(cmake_format_EXECUTABLE)
    return()
  endif()

  find_program(
    cmake_format_EXECUTABLE
    NAMES cmake-format
    PATHS "${cmake_format_DIR}")

  if(NOT cmake_format_EXECUTABLE)
    libra_message(STATUS "cmake-format [disabled=not found]")
    return()
  endif()
endfunction()
