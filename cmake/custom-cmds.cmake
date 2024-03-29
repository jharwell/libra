#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#
# Set policy if policy is available
function(set_policy POL VAL)

  if(POLICY ${POL})
    cmake_policy(SET ${POL} ${VAL})
  endif()

endfunction(set_policy)

# Define function "source_group_by_path with three mandatory arguments (PARENT_PATH, REGEX, GROUP, ...)
# to group source files in folders (e.g. for MSVC solutions).
#
# Example:
# source_group_by_path("${CMAKE_CURRENT_SOURCE_DIR}/src" "\\\\.h$|\\\\.inl$|\\\\.cpp$|\\\\.c$|\\\\.ui$|\\\\.qrc$" "Source Files" ${sources})
function(source_group_by_path PARENT_PATH REGEX GROUP)

  foreach (FILENAME ${ARGN})

    get_filename_component(FILEPATH "${FILENAME}" REALPATH)
    file(RELATIVE_PATH FILEPATH ${PARENT_PATH} ${FILEPATH})
    get_filename_component(FILEPATH "${FILEPATH}" DIRECTORY)

    string(REPLACE "/" "\\" FILEPATH "${FILEPATH}")

    source_group("${GROUP}\\${FILEPATH}" REGULAR_EXPRESSION "${REGEX}" FILES ${FILENAME})

  endforeach()

endfunction(source_group_by_path)

# Function that extract entries matching a given regex from a list.
# ${OUTPUT} will store the list of matching filenames.
function(list_extract OUTPUT REGEX)
  foreach(FILENAME ${ARGN})
    if(${FILENAME} MATCHES "${REGEX}")
      list(APPEND ${OUTPUT} ${FILENAME})
    endif()
  endforeach()

  set(${OUTPUT} ${${OUTPUT}} PARENT_SCOPE)

endfunction(list_extract)

# Get all the subdirectories in a directory.
macro(subdirlist result curdir)
  file(GLOB children RELATIVE ${curdir} ${curdir}/*)
  set(dirlist "")
  foreach(child ${children})
    if(IS_DIRECTORY ${curdir}/${child})
      list(APPEND dirlist ${child})
    endif()
  endforeach()
  set(${result} ${dirlist})
endmacro()

function(add_mpi_executable EXECUTABLE)
  add_executable(${EXECUTABLE})
  target_link_libraries(${EXECUTABLE} ${MPI_C_LIBRARIES})
endfunction(add_mpi_executable)

macro(dual_scope_set name value)
  # Set a variable in parent scope and make it visible in current scope
  set(${name} "${value}" PARENT_SCOPE)
  set(${name} "${value}")
endmacro()

################################################################################
# Summary                                                                      #
################################################################################
# Only want to show the summary once
set(LIBRA_SHOWED_SUMMARY NO)
function(emit)

endfunction(emit)

function(libra_config_summary_prepare_fields FIELDS_LIST)
  # Get maxlength of summary field value for padding so everything
  # lines up nicely.
  set(MAXLEN 0)
  foreach(field ${FIELDS_LIST})
    set(EMIT_${field} ${${field}})
    if("${EMIT_${field}}" STREQUAL "")
      set(LEN 0)
    else()
      string(LENGTH "${EMIT_${field}}" LEN)
    endif()

    if(${LEN} GREATER ${MAXLEN})
      set(MAXLEN ${LEN})
    endif()
  endforeach()

  # Append the necessary amount of spaces to each summary field value.
  foreach(field ${FIELDS_LIST})
    if("${EMIT_${field}}" STREQUAL "")
      set(LEN 0)
    else()
      string(LENGTH ${EMIT_${field}} LEN)
    endif()
    math(EXPR N_SPACES "${MAXLEN} - ${LEN}")

    foreach(n RANGE ${N_SPACES})
      string(APPEND EMIT_${field} " ")
    endforeach()
  endforeach()

  # Iterate over fields, colorizing as needed
  foreach(field ${FIELDS_LIST})
    # something with a special string field--nothing to do
    if("${${field}}" MATCHES "((NONE)|(ALL))" )
      set(EMIT_${field} ${EMIT_${field}} PARENT_SCOPE)
      continue()
    endif()

    # Version #--nothing to do
    if("${${field}}" MATCHES "[0-9]+.[0-9]+.[0-9]+" )
      set(EMIT_${field} ${EMIT_${field}} PARENT_SCOPE)
      continue()
    endif()

    string(REGEX
      REPLACE
      "((ON)|(on)|(YES)|(yes))"
      "${Green}\\1${ColorReset}"
      EMIT_${field}
      "${EMIT_${field}}")

    string(REGEX
      REPLACE
      "((OFF)|(off)|(NO)|no)"
      "${Red}\\1${ColorReset}"
      EMIT_${field}
      "${EMIT_${field}}")

    set(EMIT_${field} ${EMIT_${field}} PARENT_SCOPE)
  endforeach()
endfunction(libra_config_summary_prepare_fields)

function(libra_config_summary)

  message("${BoldBlue}--------------------------------------------------------------------------------")
  message("${BoldBlue}                           LIBRA Configuration Summary")
  message("${BoldBlue}--------------------------------------------------------------------------------")
  message("")

  set(fields
    LIBRA_VERSION
    CMAKE_INSTALL_PREFIX
    LIBRA_DEPS_PREFIX

    CMAKE_BUILD_TYPE
    CMAKE_SYSTEM_PROCESSOR
    CMAKE_HOST_SYSTEM_PROCESSOR

    CMAKE_C_COMPILER
    CMAKE_CXX_COMPILER
    LIBRA_C_STANDARD
    LIBRA_CXX_STANDARD

    LIBRA_TESTS
    LIBRA_MT
    LIBRA_MP
    LIBRA_PGO
    LIBRA_RTD_BUILD
    LIBRA_CODE_COV
    LIBRA_DOCS
    LIBRA_FPC
    LIBRA_ERL
    LIBRA_SAN
    LIBRA_VALGRIND_COMPAT
    LIBRA_ANALYSIS
    LIBRA_LTO
    LIBRA_OPT_REPORT
    LIBRA_STDLIB
  )

  libra_config_summary_prepare_fields("${fields}")

  message(STATUS "LIBRA version.........................: ${ColorBold}${EMIT_LIBRA_VERSION}${ColorReset} [LIBRA_VERSION]")

  # paths
  message(STATUS "Install prefix........................: ${ColorBold}${EMIT_CMAKE_INSTALL_PREFIX}${ColorReset} [CMAKE_INSTALL_PREFIX]")
  message(STATUS "Project dependencies prefix...........: ${ColorBold}${EMIT_LIBRA_DEPS_PREFIX}${ColorReset} [LIBRA_DEPS_PREFIX]")

  # build info
  message(STATUS "Build type............................: ${ColorBold}${EMIT_CMAKE_BUILD_TYPE}${ColorReset} [CMAKE_BUILD_TYPE]")
  message(STATUS "Host architecture.....................: ${ColorBold}${EMIT_CMAKE_HOST_SYSTEM_PROCESSOR}${ColorReset} [CMAKE_HOST_SYSTEM_PROCESSOR]")
  message(STATUS "Build target architecture.............: ${ColorBold}${EMIT_CMAKE_SYSTEM_PROCESSOR}${ColorReset} [CMAKE_SYSTEM_PROCESSOR]")

  # compiler info
  message(STATUS "C Compiler............................: ${ColorBold}${EMIT_CMAKE_C_COMPILER}${ColorReset} [CMAKE_C_COMPILER]")
  message(STATUS "C++ Compiler..........................: ${ColorBold}${EMIT_CMAKE_CXX_COMPILER}${ColorReset} [CMAKE_CXX_COMPILER]")
  message(STATUS "C std.................................: ${ColorBold}${EMIT_LIBRA_C_STANDARD}${ColorReset} [CMAKE_C_STANDARD]")
  message(STATUS "C++ std...............................: ${ColorBold}${EMIT_LIBRA_CXX_STANDARD}${ColorReset} [CMAKE_CXX_STANDARD]")

  # LIBRA options
  message(STATUS "Build tests...........................: ${ColorBold}${EMIT_LIBRA_TESTS}${ColorReset} [LIBRA_TESTS] (make unit-tests) ")
  message(STATUS "Enable multithread+openmp.............: ${ColorBold}${EMIT_LIBRA_MT}${ColorReset} [LIBRA_MT]")
  message(STATUS "Enable multiprocess+MPI...............: ${ColorBold}${EMIT_LIBRA_MP}${ColorReset} [LIBRA_MP]")
  message(STATUS "PGO...................................: ${ColorBold}${EMIT_LIBRA_PGO}${ColorReset} [LIBRA_PGO={NONE,GEN,USE}]")
  message(STATUS "ReadTheDocs build.....................: ${ColorBold}${EMIT_LIBRA_RTD_BUILD}${ColorReset} [LIBRA_RTD_BUILD]")
  message(STATUS "Enable code coverage instrumentation..: ${ColorBold}${EMIT_LIBRA_CODE_COV}${ColorReset} [LIBRA_CODE_COV] (make {precoverage,coverage}-report)")
  message(STATUS "Enable API doc building...............: ${ColorBold}${EMIT_LIBRA_DOCS}${ColorReset} [LIBRA_DOCS] (make apidoc) ")
  message(STATUS "Function Precondition Checking (FPC)..: ${ColorBold}${EMIT_LIBRA_FPC}${ColorReset} [LIBRA_FPC={RETURN,ABORT,NONE,INHERIT}]")
  message(STATUS "Event reporting level (ERL)...........: ${ColorBold}${EMIT_LIBRA_ERL}${ColorReset} [LIBRA_ERL={FATAL,ERROR,WARN,INFO,DEBUG,TRACE,ALL,NONE,INHERIT}]")
  message(STATUS "Sanitizers............................: ${ColorBold}${EMIT_LIBRA_SAN}${ColorReset} [LIBRA_SAN={MSAN,ASAN,SSAN,TSAN}]")
  message(STATUS "Enable Valgrind compatibility.........: ${ColorBold}${EMIT_LIBRA_VALGRIND_COMPAT}${ColorReset} [LIBRA_VALGRIND_COMPAT]")
  message(STATUS "Enable static analysis................: ${ColorBold}${EMIT_LIBRA_ANALYSIS}${ColorReset} [LIBRA_ANALYSIS] (make ${PROJECT_NAME}-{check,clang-check,cppcheck,tidy-check,tidy-fix,clang-format})")
  message(STATUS "Enable Link-Time Optimization (LTO)...: ${ColorBold}${EMIT_LIBRA_LTO}${ColorReset} [LIBRA_LTO]")
  message(STATUS "Enable optimization reports...........: ${ColorBold}${EMIT_LIBRA_OPT_REPORT}${ColorReset} [LIBRA_OPT_REPORT]")  
  message(STATUS "Enable stdlib.........................: ${ColorBold}${EMIT_LIBRA_STDLIB}${ColorReset} [LIBRA_STDLIB]")  

  message("")
  message("${BoldBlue}--------------------------------------------------------------------------------${ColorReset}")

  set(LIBRA_SHOWED_SUMMARY YES PARENT_SCOPE)
endfunction()
