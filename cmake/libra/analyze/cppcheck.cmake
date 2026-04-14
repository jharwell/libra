#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#
include(libra/messaging)

#[[.rst
.. cmake:command: _libra_register_cppcheck

  Register cppcheck on a target in a specific mode for all configured source
  files.

  :param ANALYSIS_TARGET: The name of the umbrella analysis target to create.

  :param TARGET: The name of the target which "owns" the source files to
   analyze.
]]
function(_libra_register_cppcheck ANALYSIS_TARGET TARGET)
  if(NOT DEFINED LIBRA_CPPCHECK_SUPPRESSIONS)
    set(LIBRA_CPPCHECK_SUPPRESSIONS "${LIBRA_CPPCHECK_SUPPRESSIONS_DEFAULT}")
  endif()

  if(NOT DEFINED LIBRA_CPPCHECK_EXTRA_ARGS)
    set(LIBRA_CPPCHECK_EXTRA_ARGS "${LIBRA_CPPCHECK_EXTRA_ARGS_DEFAULT}")
  endif()

  # This may be required
  if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    list(APPEND LIBRA_CPPCHECK_EXTRA_ARGS -D__linux__)
  endif()

  _libra_get_project_language(_LANG)
  if("${_LANG}" STREQUAL "CXX")
    set(STD_ARGS --std=c++${LIBRA_CXX_STANDARD})
  else()
    set(STD_ARGS --std=c++${LIBRA_C_STANDARD})
  endif()

  # If a compilation database is used, cppcheck doesn't let you check a specific
  # file.
  if(LIBRA_USE_COMPDB)
    add_custom_target(
      ${ANALYSIS_TARGET}
      COMMAND
        ${cppcheck_EXECUTABLE}
        --project=${PROJECT_BINARY_DIR}/compile_commands.json
        --enable=warning,style,performance,portability --verbose
        --check-level=exhaustive ${STD_ARGS} --inline-suppr
        "$<$<BOOL:${LIBRA_CPPCHECK_SUPPRESSIONS}>:--suppress=$<JOIN:${LIBRA_CPPCHECK_SUPPRESSIONS},\t--suppress=>>"
        "$<$<BOOL:${LIBRA_CPPCHECK_IGNORES}>:-i$<JOIN:${LIBRA_CPPCHECK_IGNORES},\t-i>>"
        ${LIBRA_CPPCHECK_EXTRA_ARGS} --error-exitcode=1
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/src
      COMMENT "Running ${cppcheck_NAME} with compdb")
  else()
    add_custom_target(${ANALYSIS_TARGET})
    foreach(file ${ARGN})
      # We create one target per file we want to analyze so that we can do
      # analysis in parallel if desired. Targets can't have '/' on '.' in their
      # names, hence the replacements.
      string(REPLACE "/" "_" file_target "${file}")
      string(REPLACE "." "_" file_target "${file_target}")

      analyze_build_fixeddb_for_target(${TARGET} EXTRACTED_ARGS)

      add_custom_target(
        ${ANALYSIS_TARGET}-${file_target}
        COMMAND
          ${cppcheck_EXECUTABLE} ${EXTRACTED_ARGS}
          --enable=warning,style,performance,portability --verbose ${STD_ARGS}
          --inline-suppr
          "$<$<BOOL:${LIBRA_CPPCHECK_SUPPRESSIONS}>:--suppress=$<JOIN:${LIBRA_CPPCHECK_SUPPRESSIONS},\t--suppress=>>"
          "$<$<BOOL:${LIBRA_CPPCHECK_IGNORES}>:-i$<JOIN:${LIBRA_CPPCHECK_IGNORES},\t-i>>"
          ${LIBRA_CPPCHECK_EXTRA_ARGS} --error-exitcode=1 ${file}
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        COMMENT "Running ${cppcheck_NAME} without compdb on ${file}")
      add_dependencies(${ANALYSIS_TARGET} ${ANALYSIS_TARGET}-${file_target})
    endforeach()
  endif()

  set_target_properties(${ANALYSIS_TARGET} PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD
                                                      1)
endfunction()

#[[.rst
.. cmake:command: _libra_register_checker_cppcheck

  Calls :cmake:command:`_libra_register_cppcheck` in CHECK mode: analyze
  only.

  :param TARGET: The name of the target which "owns" the source files to
   analyze.
]]
function(_libra_register_checker_cppcheck TARGET)
  if(NOT cppcheck_EXECUTABLE)
    return()
  endif()
  _libra_register_cppcheck(analyze-cppcheck ${TARGET} ${ARGN})

  add_dependencies(analyze analyze-cppcheck)

  get_filename_component(cppcheck_NAME ${cppcheck_EXECUTABLE} NAME)

  list(LENGTH ARGN LEN)
  libra_message(STATUS "Registered ${LEN} files with ${cppcheck_NAME}")
endfunction()
