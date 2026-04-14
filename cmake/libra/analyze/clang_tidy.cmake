#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#

include(libra/defaults)

# We want to be able to enable only SOME checks in clang-tidy in a single run,
# both to speed up pipelines, but also to fixing errors simpler when there are
# TONS. These seem to be a comprehensive set of errors in clang-20; may need to
# be updated in the future.
set(CLANG_TIDY_CATEGORIES
    clang-analyzer-core
    abseil
    cppcoreguidelines
    readability
    hicpp
    bugprone
    cert
    performance
    portability
    concurrency
    modernize
    misc
    google)

#[[.rst
.. cmake:command: _libra_register_clang_tidy

  Register clang-tidy on a target in a specific mode for all configured source
  files.

  :param ANALYSIS_TARGET: The name of the umbrella analysis target to create.

  :param TARGET: The name of the target which "owns" the source files to
   analyze.

  :param JOB: Either "FIX" or "CHECK", depending on what you want clang-tidy to
   do.
]]
function(
  _libra_register_clang_tidy
  ANALYSIS_TARGET
  TARGET
  JOB
  SRCS
  HEADERS
  STUBS)
  analyze_clang_extract_args_from_target(${TARGET} EXTRACTED_ARGS)

  if(JOB STREQUAL "FIX")
    set(JOB_ARGS --fix --fix-errors)
  endif()

  add_custom_target(${ANALYSIS_TARGET})
  set_target_properties(${ANALYSIS_TARGET} PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD
                                                      1)

  set(LIBRA_CLANG_TIDY_FILEPATH_DEFAULT
      "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../../dots/.clang-tidy")

  # A clever way to bake in .clang-tidy and use with cmake. Tested with both
  # SELF and CONAN drivers, and will point to the baked-in .clang-tidy in this
  # repo.
  if(NOT DEFINED LIBRA_CLANG_TIDY_FILEPATH)
    set(LIBRA_CLANG_TIDY_FILEPATH "${LIBRA_CLANG_TIDY_FILEPATH_DEFAULT}")
  endif()

  if("${LIBRA_DRIVER}" STREQUAL "CONAN")
    set(HEADER_EXCLUDES --exclude-header-filter=*/.conan2/*)
  endif()

  if(NOT DEFINED LIBRA_CLANG_TIDY_CHECKS_CONFIG)
    set(LIBRA_CLANG_TIDY_CHECKS_CONFIG
        "${LIBRA_CLANG_TIDY_CHECKS_CONFIG_DEFAULT}")
  endif()

  get_filename_component(clang_tidy_NAME ${clang_tidy_EXECUTABLE} NAME)

  _libra_get_project_language(_LANG)
  if("${_LANG}" STREQUAL "CXX")
    set(STD_ARGS --extra-arg=-std=gnu++${LIBRA_CXX_STANDARD})
  else()
    set(STD_ARGS --extra-arg=-std=gnu${LIBRA_C_STANDARD})
  endif()

  foreach(CATEGORY ${CLANG_TIDY_CATEGORIES})

    add_custom_target(${ANALYSIS_TARGET}-${CATEGORY})
    add_dependencies(${ANALYSIS_TARGET} ${ANALYSIS_TARGET}-${CATEGORY})
    set_target_properties(${ANALYSIS_TARGET}-${CATEGORY}
                          PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1)

    # We generate per-file commands so that we (a) get more fine-grained
    # feedback from clang-tidy, and (b) don't have to wait until clang-tidy
    # finishes running against ALL files to get feedback for a given file.
    foreach(file ${SRCS} ${HEADERS} ${STUBS})

      # We create one target per file we want to analyze so that we can do
      # analysis in parallel if desired. Targets can't have '/' on '.' in their
      # names, hence the replacements.
      string(REPLACE "/" "_" file_target "${file}")
      string(REPLACE "." "_" file_target "${file_target}")

      # Only run the -misc-include-cleaner on header files. It's just noise in
      # source files.
      if("${CATEGORY}" STREQUAL "misc" AND NOT "${file}" IN_LIST HEADERS)
        continue()
      elseif(NOT "${CATEGORY}" STREQUAL "misc" AND "${file}" IN_LIST HEADERS)
        continue()
      endif()
      if(LIBRA_USE_COMPDB)
        add_custom_target(
          ${ANALYSIS_TARGET}-${CATEGORY}-${file_target}
          COMMAND
            ${clang_tidy_EXECUTABLE}
            --header-filter=${CMAKE_SOURCE_DIR}/include/.* ${HEADER_EXCLUDES}
            --config-file=${LIBRA_CLANG_TIDY_FILEPATH}
            --checks=-*,${CATEGORY}*${LIBRA_CLANG_TIDY_CHECKS_CONFIG}
            ${JOB_ARGS} ${STD_ARGS} --extra-arg=-Wno-unknown-warning-option
            --warnings-as-errors='*' ${EXTRACTED_ARGS}
            ${LIBRA_CLANG_TIDY_EXTRA_ARGS} ${file}
          WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
          COMMENT
            "Running ${clang_tidy_NAME} with compdb on ${file}, category=${CATEGORY},JOB=${JOB}"
        )
      else()
        if(LIBRA_CLANG_TOOLS_USE_FIXED_DB)
          add_custom_target(
            ${ANALYSIS_TARGET}-${CATEGORY}-${file_target}
            COMMAND
              ${clang_tidy_EXECUTABLE}
              --header-filter=${CMAKE_CURRENT_SOURCE_DIR}/include/.*
              ${HEADER_EXCLUDES} --config-file=${LIBRA_CLANG_TIDY_FILEPATH}
              --checks=-*,${CATEGORY}*${LIBRA_CLANG_TIDY_CHECKS_CONFIG}
              --warnings-as-errors='*' -p /tmp/libra-nonexistent --quiet
              ${LIBRA_CLANG_TIDY_EXTRA_ARGS} ${JOB_ARGS} ${file} --
              ${EXTRACTED_ARGS} ${STD_ARGS} -Wno-unknown-warning-option
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            COMMENT
              "Running ${clang_tidy_NAME} without compdb on ${file} (fixed compdb)"
          )
        else()
          add_custom_target(
            ${ANALYSIS_TARGET}-${CATEGORY}-${file_target}
            COMMAND
              ${clang_tidy_EXECUTABLE}
              --header-filter=${CMAKE_CURRENT_SOURCE_DIR}/include/.*
              ${HEADER_EXCLUDES} --config-file=${LIBRA_CLANG_TIDY_FILEPATH}
              --checks=-*,${CATEGORY}*${LIBRA_CLANG_TIDY_CHECKS_CONFIG}
              --warnings-as-errors='*' -p /tmp/libra-nonexistent --quiet
              ${JOB_ARGS} ${EXTRACTED_ARGS} ${STD_ARGS}
              --extra-arg=-Wno-unknown-warning-option
              ${LIBRA_CLANG_TIDY_EXTRA_ARGS} ${file}
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            COMMENT
              "Running ${clang_tidy_NAME} without compdb on ${file} (--extra-arg)"
          )
        endif()

      endif()
      add_dependencies(${ANALYSIS_TARGET}-${CATEGORY}
                       ${ANALYSIS_TARGET}-${CATEGORY}-${file_target})
    endforeach()
  endforeach()

endfunction()

#[[.rst
.. cmake:command: _libra_register_checker_clang_tidy

  Calls :cmake:command:`_libra_register_clang_tidy` in CHECK mode: analyze
  only.

  This function is different than the other analysis checkers, because the
  misc-include-cleaner category needs the raw headers (no stubs).

  :param TARGET: The name of the target which "owns" the source files to
   analyze.

  :param SRCS: The list of source files to analyze.

  :param HEADERS: The list of raw header files to analyze.

  :param STUBS: The list of stub files to analyze.
]]
function(
  _libra_register_checker_clang_tidy
  TARGET
  SRCS
  HEADERS
  STUBS)
  if(NOT clang_tidy_EXECUTABLE)
    return()
  endif()

  _libra_register_clang_tidy(
    analyze-clang-tidy
    ${TARGET}
    "CHECK"
    "${SRCS}"
    "${HEADERS}"
    "${STUBS}")
  add_dependencies(analyze analyze-clang-tidy)
  get_filename_component(clang_tidy_NAME ${clang_tidy_EXECUTABLE} NAME)

  list(LENGTH SRCS LEN1)
  list(LENGTH HEADERS LEN2)
  list(LENGTH STUBS LEN3)
  math(EXPR LEN "${LEN1} + ${LEN2} + ${LEN3}")
  libra_message(STATUS
                "Registered ${LEN} files with ${clang_tidy_NAME} checker")
endfunction()

#[[.rst
.. cmake:command: _libra_register_fixer_clang_tidy

  Calls :cmake:command:`_libra_register_clang_tidy` in FIX mode: analyze
  and fix.

  :param TARGET: The name of the target which "owns" the source files to
   analyze.

  :param SRCS: The list of source files to analyze.
]]
function(_libra_register_fixer_clang_tidy TARGET SRCS)
  if(NOT clang_tidy_EXECUTABLE)
    return()
  endif()

  # Fixers operate on source files only -- no headers or stubs needed. Pass
  # empty lists for HEADERS and STUBS to satisfy the positional signature of
  # _libra_register_clang_tidy.
  _libra_register_clang_tidy(
    fix-clang-tidy
    ${TARGET}
    "FIX"
    "${SRCS}"
    ""
    "")
  add_dependencies(fix fix-clang-tidy)

  get_filename_component(clang_tidy_NAME ${clang_tidy_EXECUTABLE} NAME)

  list(LENGTH SRCS LEN)
  libra_message(STATUS "Registered ${LEN} files with ${clang_tidy_NAME} fixer")
endfunction()
