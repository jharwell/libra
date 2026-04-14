#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#
include(libra/messaging)

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

  set_target_properties(${FMT_TARGET} PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1)
endfunction()

#[[.rst
.. cmake:command: _libra_register_formatter_clang_format

  Calls :cmake:command:`_libra_register_clang_format` in FORMAT mode: apply
  formatting.
]]
function(_libra_register_formatter_clang_format)
  if(NOT clang_format_EXECUTABLE)
    return()
  endif()

  _libra_register_clang_format(format-clang-format "FORMAT" ${ARGN})
  add_dependencies(format format-clang-format)

  get_filename_component(clang_format_NAME ${clang_format_EXECUTABLE} NAME)
  list(LENGTH ARGN LEN)
  libra_message(STATUS
                "Registered ${LEN} files with ${clang_format_NAME} formatter")
endfunction()

#[[.rst
.. cmake:command: _libra_register_check_clang_format

  Calls :cmake:command:`_libra_register_clang_format` in CHECK mode: check if
  files are conformant to the applied schema.
]]
function(_libra_register_checker_clang_format)
  if(NOT clang_format_EXECUTABLE)
    return()
  endif()

  _libra_register_clang_format(analyze-clang-format "CHECK" ${ARGN})
  add_dependencies(analyze analyze-clang-format)

  get_filename_component(clang_format_NAME ${clang_format_EXECUTABLE} NAME)
  list(LENGTH ARGN LEN)
  libra_message(STATUS
                "Registered ${LEN} files with ${clang_format_NAME} checker")

endfunction()
