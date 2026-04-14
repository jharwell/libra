#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#

#[[.rst
.. cmake:command: _libra_register_clang_check

  Register clang-check on a target in a specific mode for all configured source
  files.

  :param ANALYSIS_TARGET: The name of the umbrella analysis target to create.

  :param TARGET: The name of the target which "owns" the source files to
   analyze.

  :param JOB: Either "FIX" or "CHECK", depending on what you want clang-check to
   do.
]]
function(_libra_register_clang_check ANALYSIS_TARGET TARGET JOB)
  analyze_clang_extract_args_from_target(${TARGET} EXTRACTED_ARGS)

  if(JOB STREQUAL "FIX")
    set(JOB_ARGS --fixit)
  endif()

  add_custom_target(${ANALYSIS_TARGET})
  set_target_properties(${ANALYSIS_TARGET} PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD
                                                      1)

  _libra_get_project_language(_LANG)
  if("${_LANG}" STREQUAL "CXX")
    set(STD_ARGS --extra-arg=-std=gnu++${LIBRA_CXX_STANDARD})
  else()
    set(STD_ARGS --extra-arg=-std=gnu${LIBRA_C_STANDARD})
  endif()

  foreach(file ${ARGN})
    # We create one target per file we want to analyze so that we can do
    # analysis in parallel if desired. Targets can't have '/' on '.' in their
    # names, hence the replacements.
    string(REPLACE "/" "_" file_target "${file}")
    string(REPLACE "." "_" file_target "${file_target}")
    if(LIBRA_USE_COMPDB)
      add_custom_target(
        ${ANALYSIS_TARGET}-${file_target}
        COMMAND
          ${clang_check_EXECUTABLE} -analyze ${STD_ARGS}
          --extra-arg=-Wno-unknown-warning-option --extra-arg=-Werror
          --extra-arg="-Xanalyzer" --extra-arg="-analyzer-output=text"
          ${EXTRACTED_ARGS} ${file}
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        COMMENT "Running ${clang_check_NAME} with compdb on ${file}, JOB=${JOB}"
      )
    else()
      if(LIBRA_CLANG_TOOLS_USE_FIXED_DB)
        add_custom_target(
          ${ANALYSIS_TARGET}-${file_target}
          COMMAND
            ${clang_check_EXECUTABLE} -analyze ${file} -- ${EXTRACTED_ARGS}
            ${STD_ARGS} -Wno-unknown-warning-option -Werror -Xanalyzer
            -analyzer-output=text
          WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
          COMMENT
            "Running ${clang_check_NAME} without compdb on ${file}, JOB=${JOB} (fixed compdb)"
        )
      else()
        add_custom_target(
          ${ANALYSIS_TARGET}-${file_target}
          COMMAND
            ${clang_check_EXECUTABLE} -analyze --extra-arg="-Xanalyzer"
            --extra-arg="-analyzer-output=text" ${EXTRACTED_ARGS} ${STD_ARGS}
            --extra-arg=-Wno-unknown-warning-option --extra-arg=-Werror ${file}
          WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
          COMMENT
            "Running ${clang_check_NAME} without compdb on ${file}, JOB=${JOB} (--extra-arg)"
        )
      endif()
    endif()
    add_dependencies(${ANALYSIS_TARGET} ${ANALYSIS_TARGET}-${file_target})
  endforeach()

endfunction()

#[[.rst
.. cmake:command: _libra_register_checker_clang_check

  Calls :cmake:command:`_libra_register_clang_check` in CHECK mode: analyze
  only.

  :param TARGET: The name of the target which "owns" the source files to
   analyze.
]]
function(_libra_register_checker_clang_check TARGET)
  if(NOT clang_check_EXECUTABLE)
    return()
  endif()

  _libra_register_clang_check(analyze-clang-check ${TARGET} "CHECK" ${ARGN})
  add_dependencies(analyze analyze-clang-check)

  get_filename_component(clang_check_NAME ${clang_check_EXECUTABLE} NAME)

  list(LENGTH ARGN LEN)
  libra_message(STATUS
                "Registered ${LEN} files with ${clang_check_NAME} checker")

endfunction()

#[[.rst
.. cmake:command: _libra_register_fixer_clang_check

  Calls :cmake:command:`_libra_register_clang_check` in FIX mode: analyze
  and fix everything.

  :param TARGET: The name of the target which "owns" the source files to
   analyze.
]]
function(_libra_register_fixer_clang_check TARGET)
  if(NOT clang_check_EXECUTABLE)
    return()
  endif()

  _libra_register_clang_check(fix-clang-check ${TARGET} "FIX" ${ARGN})
  add_dependencies(fix fix-clang-check)

  get_filename_component(clang_check_NAME ${clang_check_EXECUTABLE} NAME)
  list(LENGTH ARGN LEN)
  libra_message(STATUS "Registered ${LEN} files with ${clang_check_NAME} fixer")

endfunction()
