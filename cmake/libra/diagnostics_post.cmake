#
# Copyright 2026 John Harwell, All rights reserved.
#
# SPDX-License Identifier: MIT
#

# This is separate from the the API function so that the API version can be
# available in project-local.cmake. Target compile flags/options/etc aren't set
# until AFTER project-local.cmake is included, so if we try to filter out build
# flags at that point, we will get nothing. This is not pretty, but it does
# work.
function(_libra_configure_source_file_post INFILE OUTFILE)
  # Extract git information
  execute_process(
    COMMAND git log --pretty=format:%H -n 1
    OUTPUT_VARIABLE LIBRA_GIT_REV
    ERROR_QUIET)

  # Check whether we got any revision (which isn't always the case, e.g. when
  # someone downloaded a zip file from Github instead of a checkout)
  if("${LIBRA_GIT_REV}" STREQUAL "")
    libra_message(
      WARNING
      "libra_configure_source_file: Not in a git repository - stubbing version information\n"
      "  Git-related variables will be set to 'N/A'")
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

  get_target_property(COMPILE_OPTIONS ${PROJECT_NAME} COMPILE_OPTIONS)
  get_target_property(COMPILE_DEFINITIONS ${PROJECT_NAME} COMPILE_DEFINITIONS)
  get_target_property(COMPILE_FLAGS ${PROJECT_NAME} COMPILE_FLAGS)
  get_target_property(INTERFACE_COMPILE_OPTIONS ${PROJECT_NAME}
                      INTERFACE_COMPILE_OPTIONS)

  set(LIBRA_TARGET_FLAGS_BUILD)
  if(COMPILE_OPTIONS)
    list(APPEND LIBRA_TARGET_FLAGS_BUILD ${COMPILE_OPTIONS})
  endif()
  if(COMPILE_DEFINITIONS)
    list(APPEND LIBRA_TARGET_FLAGS_BUILD ${COMPILE_DEFINITIONS})
  endif()

  # Filter: skip generator expressions, remove warning flags
  set(FILTERED_FLAGS)
  foreach(flag IN LISTS LIBRA_TARGET_FLAGS_BUILD)
    # Skip generator expressions entirely
    if(flag MATCHES "[$<>]")
      continue()
    endif()

    if(NOT flag MATCHES "${LIBRA_TARGET_FLAGS_FILTER_REGEX}")
      list(APPEND FILTERED_FLAGS ${flag})
    endif()
  endforeach()

  list(REMOVE_DUPLICATES FILTERED_FLAGS)
  set(LIBRA_TARGET_FLAGS_BUILD ${FILTERED_FLAGS})

  # Have to join with ' '; a list joined with ';' is (apparently) not valid in a
  # configured source file.
  list(JOIN FILTERED_FLAGS " " LIBRA_TARGET_FLAGS_BUILD)

  # Write the file
  configure_file(${INFILE} ${OUTFILE})

  # Make sure we compile the file by adding to main target
  target_sources(${PROJECT_NAME} PRIVATE ${OUTFILE})

  libra_message(STATUS "Configured source file: ${INFILE} -> ${OUTFILE}")
endfunction()

list(LENGTH LIBRA_CONFIGURED_SOURCE_FILES_SRC N_SRC)
list(LENGTH LIBRA_CONFIGURED_SOURCE_FILES_DEST N_DEST)

if(NOT N_SRC EQUAL N_DEST)
  libra_message(
    FATAL_ERROR
    "Configured file list length mismatch! SRC=${N_SRC}, DEST=${N_DEST}")
endif()

math(EXPR N_SRC "${N_SRC} - 1")

foreach(i RANGE ${N_SRC})
  list(GET LIBRA_CONFIGURED_SOURCE_FILES_SRC ${i} INFILE)
  list(GET LIBRA_CONFIGURED_SOURCE_FILES_DEST ${i} OUTFILE)
  _libra_configure_source_file_post("${INFILE}" "${OUTFILE}")
endforeach()
