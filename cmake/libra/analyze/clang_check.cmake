#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#

# ##############################################################################
# Register a target for clang-tidy checking
# ##############################################################################
function(do_register_clang_check CHECK_TARGET TARGET JOB)
  analyze_clang_extract_args_from_target(${TARGET} EXTRACTED_ARGS)

  if(JOB STREQUAL "FIX")
    set(JOB_ARGS --fixit)
  endif()

  add_custom_target(${CHECK_TARGET})

  # To get this to work with bleeding edge libraries, we have to tell clang to
  # use its own stdlib intsead of GCC's. Not doing this is fine for some
  # libraries, but for >= C++20 libs, it can cause problems.
  #
  # We also use --extra-arg=... instead of '-- ...' because the former is
  # documented and works, and the latter is undocumented and SORT OF works.
  foreach(file ${ARGN})
    # We create one target per file we want to analyze so that we can do
    # analysis in parallel if desired. Targets can't have '/' on '.' in their
    # names, hence the replacements.
    string(REPLACE "/" "_" file_target "${file}")
    string(REPLACE "." "_" file_target "${file_target}")

    add_custom_target(
      ${CHECK_TARGET}-${file_target}
      COMMAND
        ${clang_check_EXECUTABLE} ${file} -analyze ${EXTRACTED_ARGS}
        --extra-arg=-std=${LIBRA_CXX_STANDARD}
        --extra-arg=-Wno-unknown-warning-option --extra-arg=-Werror
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
      COMMENT "Running ${clang_check_NAME} with compdb on ${file}, JOB=${JOB}")
    add_dependencies(${CHECK_TARGET} ${CHECK_TARGET}-${file_target})
  endforeach()

  set_target_properties(${CHECK_TARGET} PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1)
endfunction()

# ##############################################################################
# Register all target sources with the clang_check checker
# ##############################################################################
function(libra_register_checker_clang_check TARGET)
  if(NOT clang_check_EXECUTABLE)
    return()
  endif()

  do_register_clang_check(analyze-clang-check ${TARGET} "CHECK" ${ARGN})
  add_dependencies(analyze analyze-clang-check)

  get_filename_component(clang_check_NAME ${clang_check_EXECUTABLE} NAME)
  list(LENGTH ARGN LEN)
  libra_message(STATUS
                "Registered ${LEN} files with ${clang_check_NAME} checker")

endfunction()

# ##############################################################################
# Register all target sources with the clang_check fixer
# ##############################################################################
function(libra_register_fixer_clang_check TARGET)
  if(NOT clang_check_EXECUTABLE)
    return()
  endif()

  do_register_clang_check(fix-clang-check ${TARGET} "FIX" ${ARGN})
  add_dependencies(fix fix-clang-check)

  get_filename_component(clang_check_NAME ${clang_check_EXECUTABLE} NAME)
  list(LENGTH ARGN LEN)
  libra_message(STATUS "Registered ${LEN} files with ${clang_check_NAME} fixer")

endfunction()

# ##############################################################################
# Enable or disable clang-check fixing for the project
# ##############################################################################
function(libra_toggle_clang_check request)
  if(NOT request)
    libra_message(STATUS "Disabling clang-check by request")
    set(clang_check_EXECUTABLE)
    return()
  endif()

  find_program(
    clang_check_EXECUTABLE
    NAMES clang-tidy-21
          clang-check-20
          clang-check-19
          clang-check-18
          clang-check-17
          clang-check-16
          clang-check-15
          clang-check-14
          clang-check-13
          clang-check-12
          clang-check-11
          clang-check-10
          clang-check
    PATHS "${clang_check_DIR}")

  if(NOT clang_check_EXECUTABLE)
    libra_message(STATUS "clang-check [disabled=not found]")
    return()
  endif()
endfunction()
