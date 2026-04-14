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

# ##############################################################################
# Register a target for clang-tidy checking
# ##############################################################################
function(
  do_register_clang_tidy
  CHECK_TARGET
  TARGET
  JOB
  SRCS
  HEADERS
  STUBS)
  analyze_clang_extract_args_from_target(${TARGET} EXTRACTED_ARGS)

  if(JOB STREQUAL "FIX")
    set(JOB_ARGS --fix --fix-errors)
  endif()

  add_custom_target(${CHECK_TARGET})
  set_target_properties(${CHECK_TARGET} PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1)

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

  foreach(CATEGORY ${CLANG_TIDY_CATEGORIES})

    add_custom_target(${CHECK_TARGET}-${CATEGORY})
    add_dependencies(${CHECK_TARGET} ${CHECK_TARGET}-${CATEGORY})
    set_target_properties(${CHECK_TARGET}-${CATEGORY}
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
          ${CHECK_TARGET}-${CATEGORY}-${file_target}
          COMMAND
            ${clang_tidy_EXECUTABLE}
            --header-filter=${CMAKE_SOURCE_DIR}/include/.* ${HEADER_EXCLUDES}
            --config-file=${LIBRA_CLANG_TIDY_FILEPATH}
            --checks=-*,${CATEGORY}*${LIBRA_CLANG_TIDY_CHECKS_CONFIG}
            ${JOB_ARGS} --extra-arg=-std=gnu++${LIBRA_CXX_STANDARD}
            --extra-arg=-Wno-unknown-warning-option --warnings-as-errors='*'
            ${EXTRACTED_ARGS} ${LIBRA_CLANG_TIDY_EXTRA_ARGS} ${file}
          WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
          COMMENT
            "Running ${clang_tidy_NAME} with compdb on ${file}, category=${CATEGORY},JOB=${JOB}"
        )
      else()
        if(LIBRA_CLANG_TOOLS_USE_FIXED_DB)
          add_custom_target(
            ${CHECK_TARGET}-${CATEGORY}-${file_target}
            COMMAND
              ${clang_tidy_EXECUTABLE}
              --header-filter=${CMAKE_CURRENT_SOURCE_DIR}/include/.*
              ${HEADER_EXCLUDES} --config-file=${LIBRA_CLANG_TIDY_FILEPATH}
              --checks=-*,${CATEGORY}*${LIBRA_CLANG_TIDY_CHECKS_CONFIG}
              --warnings-as-errors='*' -p /tmp/libra-nonexistent --quiet
              ${LIBRA_CLANG_TIDY_EXTRA_ARGS} ${JOB_ARGS} ${file} --
              ${EXTRACTED_ARGS} -std=gnu++${LIBRA_CXX_STANDARD}
              -Wno-unknown-warning-option
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            COMMENT
              "Running ${clang_tidy_NAME} without compdb on ${file} (fixed compdb)"
          )
        else()
          add_custom_target(
            ${CHECK_TARGET}-${CATEGORY}-${file_target}
            COMMAND
              ${clang_tidy_EXECUTABLE}
              --header-filter=${CMAKE_CURRENT_SOURCE_DIR}/include/.*
              ${HEADER_EXCLUDES} --config-file=${LIBRA_CLANG_TIDY_FILEPATH}
              --checks=-*,${CATEGORY}*${LIBRA_CLANG_TIDY_CHECKS_CONFIG}
              --warnings-as-errors='*' -p /tmp/libra-nonexistent --quiet
              ${JOB_ARGS} ${EXTRACTED_ARGS}
              --extra-arg=-std=gnu++${LIBRA_CXX_STANDARD}
              --extra-arg=-Wno-unknown-warning-option
              ${LIBRA_CLANG_TIDY_EXTRA_ARGS} ${file}
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            COMMENT
              "Running ${clang_tidy_NAME} without compdb on ${file} (--extra-arg)"
          )
        endif()

      endif()
      add_dependencies(${CHECK_TARGET}-${CATEGORY}
                       ${CHECK_TARGET}-${CATEGORY}-${file_target})
    endforeach()
  endforeach()

  set_target_properties(${CHECK_TARGET} PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1)
endfunction()

# ##############################################################################
# Register all target sources with the clang_tidy checker
# ##############################################################################
function(
  _libra_register_checker_clang_tidy
  TARGET
  SRCS
  HEADERS
  STUBS)
  if(NOT clang_tidy_EXECUTABLE)
    return()
  endif()

  do_register_clang_tidy(
    analyze-clang-tidy
    ${TARGET}
    "CHECK"
    "${SRCS}"
    "${HEADERS}"
    "${STUBS}")
  add_dependencies(analyze analyze-clang-tidy)
  get_filename_component(clang_tidy_NAME ${clang_tidy_EXECUTABLE} NAME)

  list(LENGTH ARGN LEN)
  libra_message(
    STATUS
    "Registered
    ${LEN}
    files
    with
    ${clang_tidy_NAME}
    checker")
endfunction()

# ##############################################################################
# Register all target sources with the clang_tidy fixer
# ##############################################################################
function(_libra_register_fixer_clang_tidy TARGET)
  if(NOT clang_tidy_EXECUTABLE)
    return()
  endif()

  do_register_clang_tidy(fix-clang-tidy ${TARGET} "FIX" ${ARGN})
  add_dependencies(fix fix-clang-tidy)

  get_filename_component(clang_tidy_NAME ${clang_tidy_EXECUTABLE} NAME)

  list(LENGTH ARGN LEN)
  libra_message(
    STATUS
    "Registered
    ${LEN}
    files
    with
    ${clang_tidy_NAME}
    fixer")
endfunction()

# ##############################################################################
# Enable or disable clang-tidy checking for the project
# ##############################################################################
function(_libra_toggle_clang_tidy request)
  if(NOT request)
    libra_message(
      STATUS
      "Disabling
    clang-tidy
    by
    request")
    set(clang_tidy_EXECUTABLE)
    return()
  endif()

  find_program(
    clang_tidy_EXECUTABLE
    NAMES clang-tidy-21
          clang-tidy-20
          clang-tidy-19
          clang-tidy-18
          clang-tidy-17
          clang-tidy-16
          clang-tidy-15
          clang-tidy-14
          clang-tidy-13
          clang-tidy-12
          clang-tidy-11
          clang-tidy-10
          clang-tidy
    PATHS "${clang_tidy_DIR}")

  if(NOT clang_tidy_EXECUTABLE)
    libra_message(
      STATUS
      "clang-tidy
    [disabled=not
    found]
    ")
    return()
  endif()
endfunction()
