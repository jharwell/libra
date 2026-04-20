#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License-Identifier: MIT
#

include(libra/messaging)
include(libra/defaults)
include(libra/utils)

_libra_register_custom_target(lcov-preinfo LIBRA_CODE_COV lcov_EXECUTABLE)
_libra_register_custom_target(lcov-report LIBRA_CODE_COV lcov_EXECUTABLE)
_libra_register_custom_target(gcovr-check LIBRA_CODE_COV gcovr_EXECUTABLE)
_libra_register_custom_target(gcovr-report LIBRA_CODE_COV gcovr_EXECUTABLE)
_libra_register_custom_target(llvm-profdata LIBRA_CODE_COV LLVM_PROFDATA)
_libra_register_custom_target(llvm-summary LIBRA_CODE_COV LLVM_COV)
_libra_register_custom_target(llvm-show LIBRA_CODE_COV LLVM_COV)
_libra_register_custom_target(llvm-report LIBRA_CODE_COV LLVM_COV)
_libra_register_custom_target(llvm-export-lcov LIBRA_CODE_COV LLVM_COV)
_libra_register_custom_target(llvm-coverage LIBRA_CODE_COV NONE)

set(COVERAGE_DIR ${PROJECT_BINARY_DIR}/coverage)
file(MAKE_DIRECTORY ${COVERAGE_DIR})

set(CMAKE_CXX_OUTPUT_EXTENSION_REPLACE ON)
set(CMAKE_C_OUTPUT_EXTENSION_REPLACE ON)

#[[.rst
.. cmake:command:: _libra_detect_gcov_tool

  Try to find a suitable gcov tool for coverage calculations. For GNU compilers,
  this looks for gcov-XX, where XX is the compiler version. For clang compilers,
  this looks for llvm-cov-XX, where XX is the compiler version.

  :param OUTPUT_VAR: The output variable to set if a suitable tool is found.
]]
function(_libra_detect_gcov_tool OUTPUT_VAR)
  if(CMAKE_CXX_COMPILER_ID MATCHES "Clang" OR CMAKE_C_COMPILER_ID MATCHES
                                              "Clang")

    # Use whichever compiler IS actually clang for version detection
    if(CMAKE_C_COMPILER_ID MATCHES "Clang")
      set(_detect_compiler ${CMAKE_C_COMPILER})
    else()
      set(_detect_compiler ${CMAKE_CXX_COMPILER})
    endif()

    execute_process(
      COMMAND ${_detect_compiler} --version
      OUTPUT_VARIABLE _clang_stdout
      ERROR_VARIABLE _clang_stderr)
    set(CLANG_VERSION_OUTPUT "${_clang_stdout}${_clang_stderr}")
    string(REGEX MATCH "version ([0-9]+)" _ "${CLANG_VERSION_OUTPUT}")
    set(CLANG_MAJOR ${CMAKE_MATCH_1})

    find_program(LLVM_COV NAMES llvm-cov-${CLANG_MAJOR} llvm-cov REQUIRED)
    set(${OUTPUT_VAR}
        "${LLVM_COV} gcov"
        PARENT_SCOPE)
    libra_message(STATUS "Using clang coverage for GNU format: ${LLVM_COV}")

  elseif(CMAKE_CXX_COMPILER_ID MATCHES "GNU" OR CMAKE_C_COMPILER_ID MATCHES
                                                "GNU")
    # Use whichever compiler IS actually GNU
    if(CMAKE_C_COMPILER_ID MATCHES "GNU")
      get_filename_component(COMPILER_NAME ${CMAKE_C_COMPILER} NAME)
    else()
      get_filename_component(COMPILER_NAME ${CMAKE_CXX_COMPILER} NAME)
    endif()

    string(REPLACE "g++" "gcov" GCOV_NAME ${COMPILER_NAME})
    string(REPLACE "gcc" "gcov" GCOV_NAME ${GCOV_NAME})

    find_program(GCOV_TOOL NAMES ${GCOV_NAME} gcov REQUIRED)
    set(${OUTPUT_VAR}
        ${GCOV_TOOL}
        PARENT_SCOPE)
    libra_message(STATUS "Using GCC coverage for GNU format: ${GCOV_TOOL}")

  else()
    libra_error("Unsupported compiler for coverage: ${CMAKE_CXX_COMPILER_ID}")
  endif()
endfunction()

#[[.rst
.. cmake:command:: _libra_detect_llvm_tools

  Detect llvm-cov and llvm-profdata for native Clang coverage.

  :param LLVM_COV_VAR: The output variable to set if a suitable llvm-cov tool is
   found.

  :param LLVM_PROFDATA_VAR: The output variable to set if a suitable
   llvm-profdata tool is found.
]]
function(_libra_detect_llvm_tools LLVM_COV_VAR LLVM_PROFDATA_VAR)
  list(APPEND CMAKE_MESSAGE_INDENT " ")

  # Use whichever compiler IS actually clang for version detection
  if(CMAKE_C_COMPILER_ID MATCHES "Clang")
    set(_detect_compiler ${CMAKE_C_COMPILER})
  else()
    set(_detect_compiler ${CMAKE_CXX_COMPILER})
  endif()

  execute_process(
    COMMAND ${_detect_compiler} --version
    OUTPUT_VARIABLE _clang_stdout
    ERROR_VARIABLE _clang_stderr)
  set(CLANG_VERSION_OUTPUT "${_clang_stdout}${_clang_stderr}")
  string(REGEX MATCH "version ([0-9]+)" _ "${CLANG_VERSION_OUTPUT}")
  set(CLANG_MAJOR ${CMAKE_MATCH_1})

  find_program(LLVM_COV_TOOL NAMES llvm-cov-${CLANG_MAJOR} llvm-cov REQUIRED)
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
  list(POP_BACK CMAKE_MESSAGE_INDENT)
endfunction()

#[[.rst
.. cmake:command:: _libra_get_test_executables

  Get all executables for coverage calculations by searching through the
  current directory.

  :param OUTPUT_VAR: The output variable to set with the result.
]]
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
  get_all_targets_recursive(all_targets ${CMAKE_CURRENT_SOURCE_DIR})

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

#[[.rst
.. cmake:command:: _libra_coverage_register_lcov

  Register lcov for covareg (GNU compatible format).
]]
function(_libra_coverage_register_lcov)
  list(APPEND CMAKE_MESSAGE_INDENT " ")

  find_program(lcov_EXECUTABLE NAMES lcov REQUIRED)
  find_program(GENHTML_EXECUTABLE NAMES genhtml REQUIRED)

  _libra_detect_gcov_tool(LLVM_COV_TOOL)
  set(LLVM_COV_TOOL
      ${LLVM_COV_TOOL}
      PARENT_SCOPE)

  libra_message(STATUS "Using lcov=${lcov_EXECUTABLE}")
  libra_message(STATUS "Using genhtml=${GENHTML_EXECUTABLE}")

  # 2026-02-23 [JRH]: The geninfo_intermediate=on is required to get things to
  # work with newer versions of lcov/gcov/gcovr.
  set(LCOV_COMMON_FLAGS
      --gcov-tool
      ${LLVM_COV_TOOL}
      --rc
      branch_coverage=1
      --rc
      geninfo_intermediate=1
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
      COMMAND ${lcov_EXECUTABLE} ${LCOV_COMMON_FLAGS} --capture --initial
              --output-file ${COVERAGE_DIR}/pre.info
      COMMENT "Capturing baseline coverage for ${PROJECT_NAME}"
      VERBATIM)
    set_target_properties(lcov-preinfo PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1
                                                  EXCLUDE_FROM_ALL 1)

    # Post-coverage: Capture after running tests, merge with baseline, strip,
    # generate HTML
    add_custom_target(
      lcov-report
      # Capture post-test coverage
      COMMAND ${lcov_EXECUTABLE} ${LCOV_COMMON_FLAGS} --capture --output-file
              ${COVERAGE_DIR}/post.info
      # Merge pre/post if pre.info exists, otherwise use post.info
      COMMAND
        test -e ${COVERAGE_DIR}/pre.info && ${lcov_EXECUTABLE}
        ${LCOV_COMMON_FLAGS} -a ${COVERAGE_DIR}/pre.info -a
        ${COVERAGE_DIR}/post.info --output-file ${COVERAGE_DIR}/coverage.info ||
        cp ${COVERAGE_DIR}/post.info ${COVERAGE_DIR}/coverage.info
      # Strip excluded directories
      COMMAND
        ${lcov_EXECUTABLE} ${LCOV_COMMON_FLAGS} --remove
        ${COVERAGE_DIR}/coverage.info ${EXCLUDE_PATTERNS} --ignore-errors unused
        --output-file ${COVERAGE_DIR}/coverage-stripped.info
      # Generate HTML report
      COMMAND ${GENHTML_EXECUTABLE} ${COVERAGE_DIR}/coverage-stripped.info
              --output-directory ${COVERAGE_DIR} --branch-coverage --legend
      COMMENT "Generating HTML coverage report in ${COVERAGE_DIR}"
      VERBATIM)
    set_target_properties(lcov-report PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1
                                                 EXCLUDE_FROM_ALL 1)
    libra_message(STATUS "Created lcov coverage targets")
  endif()
  list(POP_BACK CMAKE_MESSAGE_INDENT)
endfunction()

#[[.rst
.. cmake:command:: _libra_coverage_register_gcovr

  Register gcovr for coverage (GNU compatible format).
]]
function(_libra_coverage_register_gcovr)
  list(APPEND CMAKE_MESSAGE_INDENT " ")

  _libra_detect_gcov_tool(gcovr_EXECUTABLE)

  libra_message(STATUS "Using gcovr=${gcovr_EXECUTABLE}")
  set(gcovr_EXECUTABLE
      ${gcovr_EXECUTABLE}
      PARENT_SCOPE)

  # Base gcovr command
  set(GCOVR_BASE_CMD
      gcovr
      --gcov-executable=${gcovr_EXECUTABLE}
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
      set(LIBRA_GCOVR_${THRESH}_THRESH
          ${LIBRA_GCOVR_${THRESH}_THRESH_DEFAULT}
          CACHE STRING "" FORCE)
    endif()

  endforeach()

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
    set_target_properties(gcovr-check PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1
                                                 EXCLUDE_FROM_ALL 1)
    # HTML report target
    add_custom_target(
      gcovr-report
      COMMAND ${GCOVR_BASE_CMD} --html=${COVERAGE_DIR}/index.html --html-details
      WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
      COMMENT "Generating HTML coverage report in ${COVERAGE_DIR}/index.html"
      VERBATIM)
    set_target_properties(gcovr-report PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1
                                                  EXCLUDE_FROM_ALL 1)
    libra_message(STATUS "Created gcovr coverage targets")
  endif()
  list(POP_BACK CMAKE_MESSAGE_INDENT)
endfunction()

#[[.rst
.. cmake:command:: _libra_coverage_register_llvm

  Register llvm-cov for coverage. Requires clang compiler.
]]
function(_libra_coverage_register_llvm)
  list(APPEND CMAKE_MESSAGE_INDENT " ")

  if(NOT (CMAKE_C_COMPILER_ID MATCHES "Clang" OR CMAKE_CXX_COMPILER_ID MATCHES
                                                 "Clang"))
    libra_error("llvm-cov coverage requires clang compiler")
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
  set_target_properties(llvm-summary PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1
                                                EXCLUDE_FROM_ALL 1)

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
  set_target_properties(llvm-show PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1
                                             EXCLUDE_FROM_ALL 1)

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
  set_target_properties(llvm-report PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1
                                               EXCLUDE_FROM_ALL 1)

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
  set_target_properties(llvm-export-lcov PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1
                                                    EXCLUDE_FROM_ALL 1)

  # All-in-one target: merge + report + summary
  add_custom_target(
    llvm-coverage
    DEPENDS llvm-profdata llvm-report llvm-summary
    COMMENT "Generating complete LLVM coverage report")
  set_target_properties(llvm-coverage PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1
                                                 EXCLUDE_FROM_ALL 1)
  list(POP_BACK CMAKE_MESSAGE_INDENT)
endfunction()

if(LIBRA_CODE_COV AND CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
  libra_message(STATUS "Configuring code coverage")

  if("${CMAKE_C_COMPILER_ID}" MATCHES "Clang" OR "${CMAKE_CXX_COMPILER_ID}"
                                                 MATCHES "Clang")
    if(LIBRA_CODE_COV_NATIVE)
      _libra_coverage_register_llvm()
    else()
      _libra_coverage_register_lcov()
      _libra_coverage_register_gcovr()
    endif()
  elseif("${CMAKE_C_COMPILER_ID}" MATCHES "GNU" OR "${CMAKE_CXX_COMPILER_ID}"
                                                   MATCHES "GNU")
    _libra_coverage_register_lcov()
    _libra_coverage_register_gcovr()
  else()
    libra_error("Unsupported compiler for coverage")
  endif()
endif()
