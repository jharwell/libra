#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#
include(libra/messaging)
include(libra/utils)

_libra_register_custom_target(format-check-clang LIBRA_FORMAT
                              clang_format_EXECUTABLE)
_libra_register_custom_target(format-clang LIBRA_FORMAT clang_format_EXECUTABLE)

#[[.rst
.. cmake:command: _libra_register_clang_format

  Register clang-format on a target in a specific mode for all configured source
  files.

  :param FMT_TARGET: The name of the umbrella format target to create.

  :param JOB: Either "FORMAT" or "CHECK", depending on what you want clang-format to
   do.
]]
function(_libra_register_clang_format FMT_TARGET JOB)
  if(JOB STREQUAL "FORMAT")
    set(JOB_ARGS -i)
  else()
    set(JOB_ARGS --Werror --dry-run)
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

  add_custom_target(${FMT_TARGET})
  set_target_properties(${FMT_TARGET} PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1
                                                 EXCLUDE_FROM_ALL 1)

  # We generate per-file commands so that we (a) get more fine-grained feedback
  # from clang-format, and (b) don't have to wait until clang-format finishes
  # running against ALL files to get feedback for a given file. Granted,
  # clang-format is pretty fast, but for slow machines or massive codbases, this
  # code be an issue.
  foreach(file ${ARGN})

    # We create one target per file we want to analyze so that we can do
    # analysis in parallel if desired. Targets can't have '/' on '.' in their
    # names, hence the replacements.
    string(REPLACE "/" "_" file_target "${file}")
    string(REPLACE "." "_" file_target "${file_target}")

    add_custom_target(
      ${FMT_TARGET}-${file_target}
      COMMAND ${clang_format_EXECUTABLE}
              -style=file:${LIBRA_CLANG_FORMAT_FILEPATH} ${JOB_ARGS} ${file}
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
      COMMENT "Running ${clang_format_NAME} JOB=${JOB}")

    add_dependencies(${FMT_TARGET} ${FMT_TARGET}-${file_target})
  endforeach()
endfunction()

#[[.rst
.. cmake:command: _libra_register_formatter_clang_format

  Calls :cmake:command:`_libra_register_clang_format` in FORMAT mode: apply
  formatting.
]]
function(_libra_register_formatter_clang_format PARENT_TARGET)
  if(NOT clang_format_EXECUTABLE)
    return()
  endif()
  list(APPEND CMAKE_MESSAGE_INDENT " ")

  _libra_register_clang_format(format-clang "FORMAT" ${ARGN})
  add_dependencies(${PARENT_TARGET} format-clang)

  get_filename_component(clang_format_NAME ${clang_format_EXECUTABLE} NAME)
  list(LENGTH ARGN LEN)
  libra_message(STATUS "Registered ${LEN} files with ${clang_format_NAME}")
  list(POP_BACK CMAKE_MESSAGE_INDENT)
endfunction()

#[[.rst
.. cmake:command: _libra_register_check_clang_format

  Calls :cmake:command:`_libra_register_clang_format` in CHECK mode: check if
  files are conformant to the applied schema.
]]
function(_libra_register_checker_clang_format PARENT_TARGET)
  if(NOT clang_format_EXECUTABLE)
    return()
  endif()
  list(APPEND CMAKE_MESSAGE_INDENT " ")

  _libra_register_clang_format(format-check-clang "CHECK" ${ARGN})
  add_dependencies(${PARENT_TARGET} format-check-clang)

  get_filename_component(clang_format_NAME ${clang_format_EXECUTABLE} NAME)
  list(LENGTH ARGN LEN)
  libra_message(STATUS "Registered ${LEN} files with ${clang_format_NAME}")
  list(POP_BACK CMAKE_MESSAGE_INDENT)
endfunction()
