#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#
include(libra/messaging)

find_program(
  lcov_EXECUTABLE
  NAMES lcov
  PATHS "${lcov_DIR}" "$ENV{LCOV_DIR}")

find_program(
  genhtml_EXECUTABLE
  NAMES genhtml
  PATHS "${genhtml_DIR}" "$ENV{GENHTML_DIR}")

set(CMAKE_CXX_OUTPUT_EXTENSION_REPLACE ON)
set(CMAKE_C_OUTPUT_EXTENSION_REPLACE ON)

if(NOT lcov_FOUND)
  libra_message(FATAL_ERROR
                "lcov needs to be installed to generate code coverage reports!")
endif()

if(NOT genhtml_FOUND)
  libra_message(
    FATAL_ERROR
    "genthml needs to be installed to generate code coverage reports!")
endif()

set(COVERAGE_DIR ${CMAKE_BINARY_DIR}/coverage)
file(MAKE_DIRECTORY ${COVERAGE_DIR})

# The default with lcov is to generate a relative coverage report of #
# lines/functions executed out of the total # lines/functions from all files
# which had at least 1 function run.
#
# Thus, if a file has no tests/is not run, it does not appear in the coverage
# report, skewing the results higher than they would otherwise be. This may be
# desired behavior, or may not, so the precoverage target is provided to provide
# a switch.

# Capture baseline empty coverage info for the project
set(lcov_PRECMD
    ${lcov_EXECUTABLE}
    --include
    \*/${PROJECT_NAME}/\*
    --exclude
    \*/ext/\*
    --capture
    --initial
    --directory
    .
    --output-file
    ${COVERAGE_DIR}/pre.info
    --quiet)

# Capture coverage info after running the project
set(lcov_POSTCMD1
    ${lcov_EXECUTABLE}
    --include
    \*/${PROJECT_NAME}/\*
    --exclude
    \*/ext/\*
    --capture
    --rc
    lcov_branch_coverage=1
    --directory
    .
    --output-file
    ${COVERAGE_DIR}/post.info
    --quiet)

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
    .
    --output-file
    ${COVERAGE_DIR}/coverage.info
    --quiet
    ||
    cp
    ${COVERAGE_DIR}/post.info
    ${COVERAGE_DIR}/coverage.info)

# Strip out coverage info for everything in /usr, which is system libraries.
set(lcov_POSTCMD3
    ${lcov_EXECUTABLE}
    -r
    --rc
    lcov_branch_coverage=1
    ${COVERAGE_DIR}/coverage.info
    "/usr/*"
    -o
    ${COVERAGE_DIR}/coverage-stripped.info
    --quiet)

# Generate the html coverage report.
set(genhtml_CMD
    ${genhtml_EXECUTABLE}
    ${COVERAGE_DIR}/coverage-stripped.info
    --output-directory
    coverage
    --branch-coverage
    --legend
    --quiet)

# Generate coverage BEFORE any execution to enable post-run coverage which will
# encompass the WHOLE library--not just files which had at least 1 line
# execution.
add_custom_target(
  precoverage-info
  COMMAND ${lcov_PRECMD}
  COMMENT "Generating ${PROJECT_NAME} pre-coverage info"
  VERBATIM)

# Generate coverage from execution
add_custom_target(
  postcoverage-info
  COMMAND ${lcov_POSTCMD1}
  COMMENT "Generating ${PROJECT_NAME} post-coverage info"
  VERBATIM)

# If precoverage was run, combine the pre- and post- coverage files. Otherwise,
# copy post -> combined.
add_custom_target(
  postcoverage-combine
  DEPENDS postcoverage-info
  COMMAND ${lcov_POSTCMD2}
  COMMENT "Combining pre- and -post coverage info for ${PROJECT_NAME}"
  VERBATIM)

# Strip out system files from coverage info
add_custom_target(
  postcoverage-strip
  COMMAND ${lcov_POSTCMD3}
  DEPENDS postcoverage-combine
  COMMENT "Stripping /usr/* files from ${PROJECT_NAME} coverage info"
  VERBATIM)

# Generate HTML
add_custom_target(
  coverage-html
  COMMAND ${genhtml_CMD}
  DEPENDS postcoverage-strip
  COMMENT "Generating ${PROJECT_NAME} html coverage report in ${COVERAGE_DIR}"
  VERBATIM)

add_custom_target(
  coverage-report
  COMMAND ${genhtml_CMD}
  DEPENDS coverage-html)
