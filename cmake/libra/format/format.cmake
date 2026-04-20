#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#
include(libra/format/clang_format)
include(libra/format/cmake_format)
include(libra/messaging)
include(libra/utils)

_libra_register_custom_target(format LIBRA_FORMAT NONE)
_libra_register_custom_target(format-check LIBRA_FORMAT NONE)

#[[.rst:
.. cmake:command:: _libra_find_formatting_tools

  Finds acceptable versions of all formatting tools LIBRA uses.

  Currently this is:

  - clang-format
  - cmake-format
]]
function(_libra_find_formatting_tools)
  list(APPEND CMAKE_MESSAGE_INDENT " ")

  # clang-format
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
          clang-format
    PATHS "${clang_format_DIR}")

  if(NOT clang_format_EXECUTABLE)
    libra_message(STATUS "clang-format [disabled=notfound]")
  endif()

  # cmake-format
  find_program(
    cmake_format_EXECUTABLE
    NAMES cmake-format
    PATHS "${cmake_format_DIR}")

  if(NOT cmake_format_EXECUTABLE)
    libra_message(STATUS "cmake-format [disabled=notfound]")
  endif()

  list(POP_BACK CMAKE_MESSAGE_INDENT)
endfunction()

if(LIBRA_FORMAT AND CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
  _libra_calculate_srcs("FORMATTING" ${PROJECT_NAME}_ANALYSIS_SRC
                        ${PROJECT_NAME}_ANALYSIS_HEADERS)

  # Should not be needed, but just for safety
  if("${LIBRA_DRIVER}" MATCHES "CONAN")
    list(
      FILTER
      ${PROJECT_NAME}_ANALYSIS_SRC
      EXCLUDE
      REGEX
      "\.conan2")
    list(
      FILTER
      ${PROJECT_NAME}_ANALYSIS_HEADERS
      EXCLUDE
      REGEX
      "\.conan2")
  endif()

  # Find tools
  _libra_find_formatting_tools()

  libra_message(STATUS "Enabling formatting tools: checkers")
  add_custom_target(format-check)
  set_target_properties(format-check PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1
                                                EXCLUDE_FROM_ALL 1)
  _libra_register_checker_cmake_format(format-check
                                       ${${PROJECT_NAME}_CMAKE_SRC})
  _libra_register_checker_clang_format(
    format-check "${${PROJECT_NAME}_ANALYSIS_SRC}"
    "${${PROJECT_NAME}_ANALYSIS_HEADERS}")

  # Configure formatting tools
  add_custom_target(format)
  set_target_properties(format PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1
                                          EXCLUDE_FROM_ALL 1)
  libra_message(STATUS "Enabling formatting tools: formatters")
  _libra_register_formatter_clang_format(
    format "${${PROJECT_NAME}_ANALYSIS_SRC}"
    "${${PROJECT_NAME}_ANALYSIS_HEADERS}")
  _libra_register_formatter_cmake_format(format ${${PROJECT_NAME}_CMAKE_SRC})
endif()
