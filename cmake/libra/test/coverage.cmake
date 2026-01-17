#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#
include(libra/messaging)

set(COVERAGE_DIR ${PROJECT_BINARY_DIR}/coverage)
file(MAKE_DIRECTORY ${COVERAGE_DIR})

set(CMAKE_CXX_OUTPUT_EXTENSION_REPLACE ON)
set(CMAKE_C_OUTPUT_EXTENSION_REPLACE ON)

function(libra_coverage_register_lcov)
  find_program(lcov_EXECUTABLE NAMES lcov REQUIRED)
  libra_message(STATUS "Using lcov=${lcov_EXECUTABLE}")

  find_program(genhtml_EXECUTABLE NAMES genhtml REQUIRED)
  libra_message(STATUS "Using genhtml=${genhtml_EXECUTABLE}")

  set(QUIET --quiet) # for debugging

  # The default with lcov is to generate a relative coverage report of #
  # lines/functions executed out of the total # lines/functions from all files
  # which had at least 1 function run.
  #
  # Thus, if a file has no tests/is not run, it does not appear in the coverage
  # report, skewing the results higher than they would otherwise be. This may be
  # desired behavior, or may not, so the precoverage target is provided to
  # provide a switch.

  # Capture baseline empty coverage info for the project
  set(lcov_PRECMD
      ${lcov_EXECUTABLE}
      --capture
      --initial
      --directory
      ${PROJECT_SOURCE_DIR}
      --output-file
      ${COVERAGE_DIR}/pre.info
      ${QUIET})

  # Capture coverage info after running the project
  set(lcov_POSTCMD1
      ${lcov_EXECUTABLE}
      --capture
      --rc
      lcov_branch_coverage=1
      --directory
      ${PROJECT_SOURCE_DIR}
      --output-file
      ${COVERAGE_DIR}/post.info
      ${QUIET})

  # Combine pre- and post-info if pre.info exists (may not if precoverage target
  # was not run)
  set(lcov_POSTCMD2
      test
      -e
      ${COVERAGE_DIR}/pre.info
      &&
      ${lcov_EXECUTABLE}
      -a
      ${COVERAGE_DIR}/pre.info
      -a
      ${COVERAGE_DIR}/post.info
      --rc
      lcov_branch_coverage=1
      --directory
      ${PROJECT_SOURCE_DIR}
      --output-file
      ${COVERAGE_DIR}/coverage.info
      ${QUIET}
      ||
      cp
      ${COVERAGE_DIR}/post.info
      ${COVERAGE_DIR}/coverage.info)

  # Strip out coverage info for everything in:
  #
  # * /usr - STL/system libraries
  #
  # * ~/.conan2 - Other packages which have header files we are using in THIS
  #   project. Obviously conan-only.
  #
  set(STRIP_FROM_DIRS /usr/*)
  if("${LIBRA_DRIVER}" STREQUAL "CONAN")
    set(STRIP_FROM_DIRS ${STRIP_FROM_DIRS} */.conan2/*)
  endif()

  set(lcov_POSTCMD3
      ${lcov_EXECUTABLE}
      --rc
      lcov_branch_coverage=1
      -r
      ${COVERAGE_DIR}/coverage.info
      ${STRIP_FROM_DIRS}
      --ignore-errors=unused
      -o
      ${COVERAGE_DIR}/coverage-stripped.info
      ${QUIET})

  # Generate the html coverage report.
  set(genhtml_CMD
      ${genhtml_EXECUTABLE}
      ${COVERAGE_DIR}/coverage-stripped.info
      --output-directory
      coverage
      --branch-coverage
      --legend)

  # Generate coverage BEFORE any execution to enable post-run coverage which
  # will encompass the WHOLE library--not just files which had at least 1 line
  # execution.
  add_custom_target(
    lcov-preinfo
    COMMAND ${lcov_PRECMD}
    COMMENT "Generating ${PROJECT_NAME} pre-coverage info"
    VERBATIM)

  # Generate coverage from execution
  add_custom_target(
    lcov-postcoverage-info
    COMMAND ${lcov_POSTCMD1}
    COMMENT "Generating ${PROJECT_NAME} post-coverage info"
    VERBATIM)

  # If precoverage was run, combine the pre- and post- coverage files.
  # Otherwise, copy post -> combined.
  add_custom_target(
    lcov-postcoverage-combine
    DEPENDS lcov-postcoverage-info
    COMMAND ${lcov_POSTCMD2}
    COMMENT "Combining pre- and -post coverage info for ${PROJECT_NAME}"
    VERBATIM)

  # Strip out system files from coverage info
  add_custom_target(
    lcov-postcoverage-strip
    COMMAND ${lcov_POSTCMD3}
    DEPENDS lcov-postcoverage-combine
    COMMENT "Stripping /usr/* files from ${PROJECT_NAME} coverage info"
    VERBATIM)

  # Generate HTML
  add_custom_target(
    lcov-report
    COMMAND ${genhtml_CMD}
    DEPENDS lcov-postcoverage-strip
    COMMENT "Generating ${PROJECT_NAME} html coverage report in ${COVERAGE_DIR}"
    VERBATIM)
endfunction()

function(libra_coverage_register_gcovr)
  if(NOT DEFINED LIBRA_GCOV_EXECUTABLE)
    set(LIBRA_GCOV_EXECUTABLE gcov)
    string(FIND "${LIBRA_GCOV_EXECUTABLE}" "-" DASH_IDX)

    # The gcov version has to match the compiler version. If you are using the
    # default system C/C++ GCC compiler, then plain old gcov works. But if you
    # are using a different version then you need to be explicit.
    if(DASH_IDX GREATER -1)
      string(REPLACE "-" ";" SPLITTED "${CMAKE_CXX_COMPILER}")
      list(GET SPLITTED 1 COMPILER_VERSION)
      set(LIBRA_GCOV_EXECUTABLE gcov-${COMPILER_VERSION})
    endif()
  endif()

  libra_message(STATUS "Using gcov=${LIBRA_GCOV_EXECUTABLE}")

  find_program(gcovr_EXECUTABLE REQUIRED NAMES gcovr)
  libra_message(STATUS "Using gcovr=${gcovr_EXECUTABLE}")

  set(gcovr_BASE_CMD
      ${gcovr_EXECUTABLE}
      --gcov-executable=${LIBRA_GCOV_EXECUTABLE}
      --root=${PROJECT_SOURCE_DIR}
      --gcov-object-directory=${PROJECT_BINARY_DIR}
      --decisions
      --filter=src
      --filter=include
      --exclude=tests
      --print-summary)
  set(gcovr_REPORT_CMD ${gcovr_BASE_CMD} --html=${COVERAGE_DIR}/index.html
                       --html-details)

  set(THRESHOLDS LINES FUNCTIONS BRANCHES DECISIONS)
  foreach(THRESH ${THRESHOLDS})
    if(NOT DEFINED LIBRA_GCOVR_${THRESH}_THRESH)
      set(LIBRA_GCOVR_${THRESH}_THRESH ${LIBRA_GCOVR_${THRESH}_THRESH_DEFAULT})
    endif()
  endforeach()

  set(gcovr_CHECK_CMD
      ${gcovr_BASE_CMD}
      --fail-under-line=${LIBRA_GCOVR_LINES_THRESH}
      --fail-under-function=${LIBRA_GCOVR_FUNCTIONS_THRESH}
      --fail-under-branch=${LIBRA_GCOVR_BRANCHES_THRESH}
      --fail-under-decision=${LIBRA_GCOVR_DECISIONS_THRESH})

  add_custom_target(
    gcovr-check
    COMMAND ${gcovr_CHECK_CMD}
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
    VERBATIM)

  add_custom_target(
    gcovr-report
    COMMAND ${gcovr_REPORT_CMD}
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
    COMMENT "Generated html coverage report in ${COVERAGE_DIR}/index.html."
    VERBATIM)
endfunction()
