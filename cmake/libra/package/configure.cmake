#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License-Identifier:  MIT
#
# ##############################################################################
# Custom messaging
# ##############################################################################
include(libra/messaging)

function(libra_configure_source_file INFILE OUTFILE SRC)
  execute_process(
    COMMAND git log --pretty=format:%H -n 1
    OUTPUT_VARIABLE LIBRA_GIT_REV
    ERROR_QUIET)

  # Check whether we got any revision (which isn't always the case, e.g. when
  # someone downloaded a zip file from Github instead of a checkout)
  if("${LIBRA_GIT_REV}" STREQUAL "")
    libra_message(WARNING "Stubbing version information--no git revision")
    set(LIBRA_GIT_REV "N/A")
    set(LIBRA_GIT_DIFF "")
    set(LIBRA_GIT_TAG "N/A")
    set(LIBRA_GIT_BRANCH "N/A")
  else()
    execute_process(COMMAND bash -c "git diff --quiet --exit-code || echo +"
                    OUTPUT_VARIABLE LIBRA_GIT_DIFF)
    execute_process(
      COMMAND git describe --exact-match --tags
      OUTPUT_VARIABLE LIBRA_GIT_TAG
      ERROR_QUIET)
    execute_process(COMMAND git rev-parse --abbrev-ref HEAD
                    OUTPUT_VARIABLE LIBRA_GIT_BRANCH)

    string(STRIP "${LIBRA_GIT_REV}" LIBRA_GIT_REV)
    string(STRIP "${LIBRA_GIT_DIFF}" LIBRA_GIT_DIFF)
    string(STRIP "${LIBRA_GIT_TAG}" LIBRA_GIT_TAG)
    string(STRIP "${LIBRA_GIT_BRANCH}" LIBRA_GIT_BRANCH)
  endif()

  string(TOUPPER "${CMAKE_BUILD_TYPE}" BUILD_TYPE_UPPER)

  # Filter out flags which don't affect the build at all
  set(LIBRA_C_FLAGS_BUILD ${CMAKE_C_FLAGS_${BUILD_TYPE_UPPER}})
  separate_arguments(LIBRA_C_FLAGS_BUILD NATIVE_COMMAND
                     "${LIBRA_C_FLAGS_BUILD}")
  list(
    FILTER
    LIBRA_C_FLAGS_BUILD
    INCLUDE
    REGEX
    "${LIBRA_BUILD_FLAGS_FILTER_REGEX}")

  set(LIBRA_CXX_FLAGS_BUILD ${CMAKE_CXX_FLAGS_${BUILD_TYPE_UPPER}})
  separate_arguments(LIBRA_CXX_FLAGS_BUILD NATIVE_COMMAND
                     "${LIBRA_CXX_FLAGS_BUILD}")
  list(
    FILTER
    LIBRA_CXX_FLAGS_BUILD
    INCLUDE
    REGEX
    "${LIBRA_BUILD_FLAGS_FILTER_REGEX}")

  # Write the file
  configure_file(${INFILE} ${OUTFILE})

  # Make sure we compile the file by adding to whatever list of source files was
  # provided.
  list(APPEND ${SRC} ${OUTFILE})
  set(${SRC}
      ${${SRC}}
      PARENT_SCOPE)
endfunction()
