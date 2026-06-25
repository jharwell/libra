#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#

include(libra/defaults)
include(libra/utils)

# We want to be able to enable only SOME checks in clang-tidy in a single run,
# both to speed up pipelines, but also to fixing errors simpler when there are
# TONS. These seem to be a comprehensive set of errors in clang-20; may need to
# be updated in the future.
if(LIBRA_CLANG_TIDY_CATEGORY_TARGETS)
  if(NOT LIBRA_CLANG_TIDY_CATEGORIES)
    set(LIBRA_CLANG_TIDY_CATEGORIES ${LIBRA_CLANG_TIDY_CATEGORIES_DEFAULT})
  endif()
endif()

_libra_register_custom_target(analyze-clang-tidy LIBRA_ANALYSIS
                              clang_tidy_EXECUTABLE)
_libra_register_custom_target(fix-clang-tidy LIBRA_ANALYSIS
                              clang_tidy_EXECUTABLE)
foreach(c ${LIBRA_CLANG_TIDY_CATEGORIES})
  _libra_register_custom_target(analyze-clang-tidy-${c} LIBRA_ANALYSIS
                                clang_tidy_EXECUTABLE)
  _libra_register_custom_target(fix-clang-tidy-${c} LIBRA_ANALYSIS
                                clang_tidy_EXECUTABLE)
endforeach()

#[[.rst
.. cmake:command: _libra_clang_tidy_build_cmd

  Internal helper to build the clang-tidy command for a single file.
  Sets CLANG_TIDY_CMD in the caller's scope.

   :param FILE: The source/header file to analyze

   :param CHECKS_EXPR: The string passed to --checks=

   :param JOB_ARGS: Empty or "--fix --fix-errors"

   :param STD_ARGS: --extra-arg=-std=... or similar

   :param EXTRACTED_ARGS:  Include paths / defines extracted from the cmake
   target

   :param HEADER_FILTER: Value for --header-filter

   :param HEADER_EXCLUDES: Optional --exclude-header-filter=... flag(s)
]]
macro(
  _libra_clang_tidy_build_cmd
  FILE
  CHECKS_EXPR
  JOB_ARGS
  STD_ARGS
  EXTRACTED_ARGS
  HEADER_FILTER
  HEADER_EXCLUDES)

  # A nonexistent-but-syntactically-valid path tells clang-tidy to fall back to
  # flags supplied after '--' (fixed compilation database convention). We use a
  # well-known sentinel under /tmp so the intent is obvious.
  set(_LIBRA_FIXED_DB_SENTINEL "/tmp/libra-fixed-db-sentinel")

  if(LIBRA_USE_COMPDB)
    set(CLANG_TIDY_CMD
        ${clang_tidy_EXECUTABLE}
        --header-filter=${HEADER_FILTER}
        ${HEADER_EXCLUDES}
        --config-file=${LIBRA_CLANG_TIDY_FILEPATH}
        --checks=${CHECKS_EXPR}
        ${JOB_ARGS}
        ${STD_ARGS}
        --extra-arg=-Wno-unknown-warning-option
        --warnings-as-errors=*
        ${EXTRACTED_ARGS}
        ${LIBRA_CLANG_TIDY_EXTRA_ARGS}
        ${FILE})
  elseif(LIBRA_CLANG_TOOLS_USE_FIXED_DB)
    set(CLANG_TIDY_CMD
        ${clang_tidy_EXECUTABLE}
        --header-filter=${HEADER_FILTER}
        ${HEADER_EXCLUDES}
        --config-file=${LIBRA_CLANG_TIDY_FILEPATH}
        --checks=${CHECKS_EXPR}
        --warnings-as-errors=*
        -p
        ${_LIBRA_FIXED_DB_SENTINEL}
        --quiet
        ${LIBRA_CLANG_TIDY_EXTRA_ARGS}
        ${JOB_ARGS}
        ${FILE}
        --
        ${EXTRACTED_ARGS}
        ${STD_ARGS}
        -Wno-unknown-warning-option)
  else()
    set(CLANG_TIDY_CMD
        ${clang_tidy_EXECUTABLE}
        --header-filter=${HEADER_FILTER}
        ${HEADER_EXCLUDES}
        --config-file=${LIBRA_CLANG_TIDY_FILEPATH}
        --checks=${CHECKS_EXPR}
        --warnings-as-errors=*
        -p
        ${_LIBRA_FIXED_DB_SENTINEL}
        --quiet
        ${JOB_ARGS}
        ${EXTRACTED_ARGS}
        ${STD_ARGS}
        --extra-arg=-Wno-unknown-warning-option
        ${LIBRA_CLANG_TIDY_EXTRA_ARGS}
        ${FILE})
  endif()
endmacro()

#[[.rst
.. cmake:command: _libra_clang_tidy_should_skip

  Returns TRUE in OUT_VAR if FILE should be skipped for the
  given CATEGORY.

  Rules:

  - misc category  -> headers only  (misc-include-cleaner is noise on .cpp)
  - other category -> sources only  (running checks on headers is
    unreliable; rely on source file stubs to get accurate compdb info).
]]
macro(
  _libra_clang_tidy_should_skip
  FILE
  HEADERS
  CATEGORY
  OUT_VAR)
  set(${OUT_VAR} FALSE)
  set(_is_header FALSE)
  if("${FILE}" IN_LIST ${HEADERS})
    set(_is_header TRUE)
  endif()

  if("${CATEGORY}" STREQUAL "misc" AND NOT _is_header)
    set(${OUT_VAR} TRUE)
  elseif(NOT "${CATEGORY}" STREQUAL "misc" AND _is_header)
    set(${OUT_VAR} TRUE)
  endif()
endmacro()

#[[.rst
.. cmake:command: _libra_register_clang_tidy

  Register clang-tidy on a target in a specific mode for all configured source
  files.

  :param UMBRELLA_TARGET: The name of the umbrella analysis target to create.
   Per-file targets are added as dependencies of this target, so running it
   will analyze all registered files.

  :param TARGET: The name of the cmake target which "owns" the source files to
   analyze. Used to extract include paths, defines, and other compiler flags.

  :param JOB: Either ``FIX`` or ``CHECK``, depending on what you want
   clang-tidy to do.

  :param SRCS: List of source files (``.c``/``.cpp``) to analyze.

  :param HEADERS: List of raw header files to analyze. The ``misc`` category
   (``misc-include-cleaner``) runs on these; all other categories skip them.

  :param STUBS: List of stub header files to analyze alongside HEADERS.
]]
function(
  _libra_register_clang_tidy
  UMBRELLA_TARGET
  TARGET
  JOB
  SRCS
  HEADERS
  STUBS)

  _libra_analyze_clang_extract_args_from_target(${TARGET} EXTRACTED_ARGS)

  if(JOB STREQUAL "FIX")
    set(JOB_ARGS --fix --fix-errors)
  else()
    set(JOB_ARGS "")
  endif()

  # Guard against duplicate umbrella target registration (e.g. multiple library
  # targets registered in the same project).
  if(NOT TARGET ${UMBRELLA_TARGET})
    add_custom_target(${UMBRELLA_TARGET})
    set_target_properties(
      ${UMBRELLA_TARGET} PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1
                                    EXCLUDE_FROM_ALL 1)
  endif()

  if(NOT DEFINED LIBRA_CLANG_TIDY_FILEPATH)
    set(LIBRA_CLANG_TIDY_FILEPATH
        "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../../dots/.clang-tidy")
  endif()

  # Exclude conan-managed headers from analysis — they are not our code.
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

  if(LIBRA_USE_COMPDB)
    set(HEADER_FILTER ${CMAKE_SOURCE_DIR}/include/.*)
  else()
    set(HEADER_FILTER ${CMAKE_CURRENT_SOURCE_DIR}/include/.*)
  endif()

  if(LIBRA_CLANG_TIDY_CATEGORY_TARGETS)
    foreach(CATEGORY ${LIBRA_CLANG_TIDY_CATEGORIES})
      if(NOT TARGET ${UMBRELLA_TARGET}-${CATEGORY})
        add_custom_target(${UMBRELLA_TARGET}-${CATEGORY})
        set_target_properties(
          ${UMBRELLA_TARGET}-${CATEGORY} PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1
                                                    EXCLUDE_FROM_ALL 1)
        add_dependencies(${UMBRELLA_TARGET} ${UMBRELLA_TARGET}-${CATEGORY})
      endif()

      # We generate per-file commands so that we (a) get more fine-grained
      # feedback from clang-tidy, and (b) don't have to wait until clang-tidy
      # finishes running against ALL files to get feedback for a given file.
      foreach(FILE ${SRCS} ${HEADERS} ${STUBS})
        _libra_clang_tidy_should_skip(${FILE} HEADERS ${CATEGORY} _SKIP)
        if(_SKIP)
          continue()
        endif()

        # Targets can't have '/' or '.' in their names.
        string(REPLACE "/" "_" file_target "${FILE}")
        string(REPLACE "." "_" file_target "${file_target}")

        set(_CHECKS_EXPR "-*,${CATEGORY}*${LIBRA_CLANG_TIDY_CHECKS_CONFIG}")
        _libra_clang_tidy_build_cmd(
          ${FILE}
          "${_CHECKS_EXPR}"
          "${JOB_ARGS}"
          "${STD_ARGS}"
          "${EXTRACTED_ARGS}"
          "${HEADER_FILTER}"
          "${HEADER_EXCLUDES}")

        add_custom_target(
          ${UMBRELLA_TARGET}-${CATEGORY}-${file_target}
          COMMAND ${CLANG_TIDY_CMD}
          WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
          COMMENT
            "Running ${clang_tidy_NAME} on ${FILE} [category=${CATEGORY}, JOB=${JOB}]"
        )
        add_dependencies(${UMBRELLA_TARGET}-${CATEGORY}
                         ${UMBRELLA_TARGET}-${CATEGORY}-${file_target})
      endforeach()
    endforeach()

  else()
    # Monolithic mode: all checks in a single analyze-clang-tidy target.
    foreach(FILE ${SRCS} ${HEADERS} ${STUBS})

      # misc-include-cleaner is only meaningful on headers.
      set(_is_header FALSE)
      if("${FILE}" IN_LIST HEADERS)
        set(_is_header TRUE)
      endif()

      if(_is_header)
        set(_NO_MISC "")
      else()
        set(_NO_MISC "-misc-include-cleaner")
      endif()

      string(REPLACE "/" "_" file_target "${FILE}")
      string(REPLACE "." "_" file_target "${file_target}")

      set(_CHECKS_EXPR "*,${_NO_MISC}${LIBRA_CLANG_TIDY_CHECKS_CONFIG}")
      _libra_clang_tidy_build_cmd(
        ${FILE}
        "${_CHECKS_EXPR}"
        "${JOB_ARGS}"
        "${STD_ARGS}"
        "${EXTRACTED_ARGS}"
        "${HEADER_FILTER}"
        "${HEADER_EXCLUDES}")

      add_custom_target(
        ${UMBRELLA_TARGET}-${file_target}
        COMMAND ${CLANG_TIDY_CMD}
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        COMMENT "Running ${clang_tidy_NAME} on ${FILE} [JOB=${JOB}]")
      add_dependencies(${UMBRELLA_TARGET} ${UMBRELLA_TARGET}-${file_target})
    endforeach()
  endif()
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
  libra_message(STATUS "Registered ${LEN} files with ${clang_tidy_NAME}")
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
  libra_message(STATUS "Registered ${LEN} files with ${clang_tidy_NAME}")
endfunction()
