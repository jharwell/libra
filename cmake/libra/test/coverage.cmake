#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License-Identifier: MIT
#

include(libra/messaging)

set(COVERAGE_DIR ${PROJECT_BINARY_DIR}/coverage)
file(MAKE_DIRECTORY ${COVERAGE_DIR})

set(CMAKE_CXX_OUTPUT_EXTENSION_REPLACE ON)
set(CMAKE_C_OUTPUT_EXTENSION_REPLACE ON)

# ##############################################################################
# Helper Functions
# ##############################################################################
# Detect coverage tool based on compiler
#
function(_libra_detect_gcov_tool OUTPUT_VAR)
  if(CMAKE_CXX_COMPILER_ID MATCHES "Clang" OR CMAKE_C_COMPILER_ID MATCHES
                                              "Clang")
    # Extract Clang version
    if(CMAKE_CXX_COMPILER)
      execute_process(COMMAND ${CMAKE_CXX_COMPILER} --version
                      OUTPUT_VARIABLE CLANG_VERSION_OUTPUT)
    else()
      execute_process(COMMAND ${CMAKE_C_COMPILER} --version
                      OUTPUT_VARIABLE CLANG_VERSION_OUTPUT)
    endif()
    string(REGEX MATCH "clang version ([0-9]+)" _ "${CLANG_VERSION_OUTPUT}")
    set(CLANG_MAJOR ${CMAKE_MATCH_1})

    # Try versioned llvm-cov first, fall back to unversioned
    find_program(LLVM_COV NAMES llvm-cov-${CLANG_MAJOR} llvm-cov REQUIRED)
    set(${OUTPUT_VAR}
        "${LLVM_COV} gcov"
        PARENT_SCOPE)
    libra_message(STATUS "Using clang coverage for GNU format: ${LLVM_COV}")

  elseif(CMAKE_CXX_COMPILER_ID MATCHES "GNU" OR CMAKE_C_COMPILER_ID MATCHES
                                                "GNU")
    if(CMAKE_CXX_COMPILER)
      get_filename_component(COMPILER_NAME ${CMAKE_CXX_COMPILER} NAME)
    else()
      get_filename_component(COMPILER_NAME ${CMAKE_C_COMPILER} NAME)
    endif()
    # Extract GCC version from compiler name (e.g., gcc-13 -> gcov-13)
    string(REPLACE "g++" "gcov" GCOV_NAME ${COMPILER_NAME})
    string(REPLACE "gcc" "gcov" GCOV_NAME ${GCOV_NAME})

    find_program(GCOV_TOOL NAMES ${GCOV_NAME} gcov REQUIRED)
    set(${OUTPUT_VAR}
        ${GCOV_TOOL}
        PARENT_SCOPE)
    libra_message(STATUS "Using GCC coverage for GNU format: ${GCOV_TOOL}")

  else()
    libra_message(FATAL_ERROR
                  "Unsupported compiler for coverage: ${CMAKE_CXX_COMPILER_ID}")
  endif()
endfunction()

# Detect llvm-cov and llvm-profdata for native Clang coverage
function(_libra_detect_llvm_tools LLVM_COV_VAR LLVM_PROFDATA_VAR)
  # Extract Clang version
  if(CMAKE_CXX_COMPILER)
    execute_process(COMMAND ${CMAKE_CXX_COMPILER} --version
                    OUTPUT_VARIABLE CLANG_VERSION_OUTPUT)
  else()
    execute_process(COMMAND ${CMAKE_C_COMPILER} --version
                    OUTPUT_VARIABLE CLANG_VERSION_OUTPUT)
  endif()

  string(REGEX MATCH "clang version ([0-9]+)" _ "${CLANG_VERSION_OUTPUT}")
  set(CLANG_MAJOR ${CMAKE_MATCH_1})

  # Find llvm-cov
  find_program(LLVM_COV_TOOL NAMES llvm-cov-${CLANG_MAJOR} llvm-cov REQUIRED)

  # Find llvm-profdata
  find_program(LLVM_PROFDATA_TOOL NAMES llvm-profdata-${CLANG_MAJOR}
                                        llvm-profdata REQUIRED)

  set(${LLVM_COV_VAR}
      ${LLVM_COV_TOOL}
      PARENT_SCOPE)
  set(${LLVM_PROFDATA_VAR}
      ${LLVM_PROFDATA_TOOL}
      PARENT_SCOPE)

  libra_message(STATUS "Using llvm-cov=${LLVM_COV_TOOL}")
  libra_message(STATUS "Using llvm-profdata=${LLVM_PROFDATA_TOOL}")
endfunction()

# Get all test executables for coverage
function(_libra_get_test_executables OUTPUT_VAR)
  # Get all targets in the project
  set(test_executables "")

  macro(get_all_targets_recursive targets dir)
    get_property(
      subdirectories
      DIRECTORY ${dir}
      PROPERTY SUBDIRECTORIES)
    foreach(subdir ${subdirectories})
      get_all_targets_recursive(${targets} ${subdir})
    endforeach()
    get_property(
      current_targets
      DIRECTORY ${dir}
      PROPERTY BUILDSYSTEM_TARGETS)
    list(APPEND ${targets} ${current_targets})
  endmacro()

  set(all_targets "")
  get_all_targets_recursive(all_targets ${CMAKE_SOURCE_DIR})

  # Filter for test executables
  foreach(target ${all_targets})
    get_target_property(target_type ${target} TYPE)
    if(target_type STREQUAL "EXECUTABLE")
      # Check if it's a test (has tests in name or is added via add_test)
      string(TOLOWER ${target} target_lower)
      list(APPEND test_executables $<TARGET_FILE:${target}>)
    endif()
  endforeach()

  set(${OUTPUT_VAR}
      ${test_executables}
      PARENT_SCOPE)
endfunction()

# ##############################################################################
# LCOV Coverage (GCC-compatible format)
# ##############################################################################
function(libra_coverage_register_lcov)
  find_program(LCOV_EXECUTABLE NAMES lcov REQUIRED)
  find_program(GENHTML_EXECUTABLE NAMES genhtml REQUIRED)

  _libra_detect_gcov_tool(GCOV_TOOL)

  libra_message(STATUS "Using lcov=${LCOV_EXECUTABLE}")
  libra_message(STATUS "Using genhtml=${GENHTML_EXECUTABLE}")

  # Common lcov flags
  set(LCOV_COMMON_FLAGS
      --gcov-tool
      ${GCOV_TOOL}
      --rc
      branch_coverage=1
      --directory
      ${PROJECT_BINARY_DIR}
      --quiet)

  # Directories to exclude from coverage
  set(EXCLUDE_PATTERNS /usr/* ${PROJECT_BINARY_DIR}/_deps/*)
  if("${LIBRA_DRIVER}" STREQUAL "CONAN")
    list(APPEND EXCLUDE_PATTERNS */.conan2/*)
  endif()

  if(NOT TARGET lcov-preinfo)
    # Pre-coverage: Capture baseline before running tests
    add_custom_target(
      lcov-preinfo
      COMMAND ${LCOV_EXECUTABLE} ${LCOV_COMMON_FLAGS} --capture --initial
              --output-file ${COVERAGE_DIR}/pre.info
      COMMENT "Capturing baseline coverage for ${PROJECT_NAME}"
      VERBATIM)

    # Post-coverage: Capture after running tests, merge with baseline, strip,
    # generate HTML
    add_custom_target(
      lcov-report
      # Capture post-test coverage
      COMMAND ${LCOV_EXECUTABLE} ${LCOV_COMMON_FLAGS} --capture --output-file
              ${COVERAGE_DIR}/post.info
      # Merge pre/post if pre.info exists, otherwise use post.info
      COMMAND
        test -e ${COVERAGE_DIR}/pre.info && ${LCOV_EXECUTABLE}
        ${LCOV_COMMON_FLAGS} -a ${COVERAGE_DIR}/pre.info -a
        ${COVERAGE_DIR}/post.info --output-file ${COVERAGE_DIR}/coverage.info ||
        cp ${COVERAGE_DIR}/post.info ${COVERAGE_DIR}/coverage.info
      # Strip excluded directories
      COMMAND
        ${LCOV_EXECUTABLE} ${LCOV_COMMON_FLAGS} --remove
        ${COVERAGE_DIR}/coverage.info ${EXCLUDE_PATTERNS} --ignore-errors unused
        --output-file ${COVERAGE_DIR}/coverage-stripped.info
      # Generate HTML report
      COMMAND ${GENHTML_EXECUTABLE} ${COVERAGE_DIR}/coverage-stripped.info
              --output-directory ${COVERAGE_DIR} --branch-coverage --legend
      COMMENT "Generating HTML coverage report in ${COVERAGE_DIR}"
      VERBATIM)
    libra_message(STATUS "Created lcov coverage targets")
  endif()
endfunction()

# ##############################################################################
# GCOVR Coverage (GCC-compatible format with gcovr)
# ##############################################################################
function(libra_coverage_register_gcovr)
  _libra_detect_gcov_tool(GCOV_TOOL)

  libra_message(STATUS "Using gcovr=${GCOV_TOOL}")

  # Base gcovr command
  set(GCOVR_BASE_CMD
      gcovr
      --gcov-executable=${GCOV_TOOL}
      --root=${PROJECT_SOURCE_DIR}
      --object-directory=${PROJECT_BINARY_DIR}
      --decisions
      --filter=src
      --filter=include
      --exclude=tests
      --print-summary)

  # Set default thresholds if not provided
  set(THRESHOLDS LINES FUNCTIONS BRANCHES DECISIONS)
  foreach(THRESH ${THRESHOLDS})
    if(NOT DEFINED LIBRA_GCOVR_${THRESH}_THRESH)
      set(LIBRA_GCOVR_${THRESH}_THRESH 0)
    endif()
  endforeach()

  # Coverage check target (fails if below thresholds)
  if(NOT TARGET gcovr-check)
    add_custom_target(
      gcovr-check
      COMMAND
        ${GCOVR_BASE_CMD} --fail-under-line=${LIBRA_GCOVR_LINES_THRESH}
        --fail-under-function=${LIBRA_GCOVR_FUNCTIONS_THRESH}
        --fail-under-branch=${LIBRA_GCOVR_BRANCHES_THRESH}
        --fail-under-decision=${LIBRA_GCOVR_DECISIONS_THRESH}
      WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
      COMMENT "Checking coverage thresholds"
      VERBATIM)
    # HTML report target
    add_custom_target(
      gcovr-report
      COMMAND ${GCOVR_BASE_CMD} --html=${COVERAGE_DIR}/index.html --html-details
      WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
      COMMENT "Generating HTML coverage report in ${COVERAGE_DIR}/index.html"
      VERBATIM)
    libra_message(STATUS "Created gcovr coverage targets")
  endif()
endfunction()

# ##############################################################################
# LLVM-COV Coverage (Native Clang source-based coverage)
# ##############################################################################
function(libra_coverage_register_llvm)
  if(NOT (CMAKE_C_COMPILER_ID MATCHES "Clang" OR CMAKE_CXX_COMPILER_ID MATCHES
                                                 "Clang"))
    libra_message(FATAL_ERROR "llvm-cov coverage requires clang compiler")
  endif()

  _libra_detect_llvm_tools(LLVM_COV LLVM_PROFDATA)

  # Get all test executables
  _libra_get_test_executables(TEST_EXECUTABLES)

  if(NOT TEST_EXECUTABLES)
    libra_message(
      WARNING
      "No test executables found for llvm-cov coverage. Targets will be created but may fail when run."
    )
  endif()

  # Build object list for llvm-cov show/report
  set(COVERAGE_OBJECTS "")
  foreach(exe ${TEST_EXECUTABLES})
    list(APPEND COVERAGE_OBJECTS -object ${exe})
  endforeach()

  # Source directories to include in coverage
  set(SOURCE_FILTERS "")
  foreach(dir src include)
    if(EXISTS ${PROJECT_SOURCE_DIR}/${dir})
      list(APPEND SOURCE_FILTERS ${PROJECT_SOURCE_DIR}/${dir})
    endif()
  endforeach()

  # Merge raw profile data
  add_custom_target(
    llvm-profdata
    COMMAND ${CMAKE_COMMAND} -E make_directory ${COVERAGE_DIR}
    COMMAND
      bash -c
      "find ${PROJECT_BINARY_DIR} -name '*.profraw' -exec ${LLVM_PROFDATA} merge -sparse -o ${COVERAGE_DIR}/coverage.profdata {} +"
    COMMENT "Merging LLVM profile data"
    WORKING_DIRECTORY ${PROJECT_BINARY_DIR})

  # Generate text coverage summary
  add_custom_target(
    llvm-summary
    DEPENDS llvm-profdata
    COMMAND
      ${LLVM_COV} report ${COVERAGE_OBJECTS}
      -instr-profile=${COVERAGE_DIR}/coverage.profdata
      -ignore-filename-regex='tests/.*' -use-color
    COMMENT "Generating coverage summary"
    VERBATIM)

  # Generate detailed text coverage report
  add_custom_target(
    llvm-show
    DEPENDS llvm-profdata
    COMMAND
      ${LLVM_COV} show ${COVERAGE_OBJECTS}
      -instr-profile=${COVERAGE_DIR}/coverage.profdata
      -ignore-filename-regex='tests/.*' -show-line-counts-or-regions
      -show-instantiations -use-color -Xdemangler c++filt -Xdemangler -n
    COMMENT "Generating detailed coverage report"
    VERBATIM)

  # Generate HTML coverage report
  add_custom_target(
    llvm-report
    DEPENDS llvm-profdata
    COMMAND
      ${LLVM_COV} show ${COVERAGE_OBJECTS}
      -instr-profile=${COVERAGE_DIR}/coverage.profdata -format=html
      -output-dir=${COVERAGE_DIR} -ignore-filename-regex='tests/.*'
      -show-line-counts-or-regions -show-instantiations -show-branches=count
      -Xdemangler c++filt -Xdemangler -n
    COMMENT "Generating HTML coverage report in ${COVERAGE_DIR}"
    VERBATIM)

  # Export coverage in lcov format (for compatibility with other tools)
  add_custom_target(
    llvm-export-lcov
    DEPENDS llvm-profdata
    COMMAND
      ${LLVM_COV} export ${COVERAGE_OBJECTS}
      -instr-profile=${COVERAGE_DIR}/coverage.profdata -format=lcov
      -ignore-filename-regex='tests/.*' > ${COVERAGE_DIR}/coverage.lcov
    COMMENT "Exporting coverage in lcov format"
    VERBATIM)

  # All-in-one target: merge + report + summary
  add_custom_target(
    llvm-coverage
    DEPENDS llvm-profdata llvm-report llvm-summary
    COMMENT "Generating complete LLVM coverage report")
  libra_message(STATUS "Created LLVM coverage targets")
endfunction()

if("${CMAKE_C_COMPILER_ID}" MATCHES "Clang" OR "${CMAKE_CXX_COMPILER_ID}"
                                               MATCHES "Clang")
  if(LIBRA_CODE_COV_NATIVE)
    libra_coverage_register_llvm()
  else()
    libra_coverage_register_lcov()
    libra_coverage_register_gcovr()
  endif()
elseif("${CMAKE_C_COMPILER_ID}" MATCHES "GNU" OR "${CMAKE_CXX_COMPILER_ID}"
                                                 MATCHES "GNU")
  libra_coverage_register_lcov()
  libra_coverage_register_gcovr()
else()
  libra_message(FATAL_ERROR "Unsupported compiler for coverage")
endif()
