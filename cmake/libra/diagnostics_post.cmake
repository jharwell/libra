#
# Copyright 2026 John Harwell, All rights reserved.
#
# SPDX-License Identifier: MIT
#

# Function to extract and filter flags from a string containing generator
# expressions
#
# Usage: extract_and_filter_flags(<input_string> <filter_regex>
# <output_variable>)
function(extract_and_filter_flags input_string filter_regex output_var)
  set(filtered_result)

  # Work with the string representation
  set(flags_string "${input_string}")

  # Match nested generator expressions: $<$<...>:...> Use a greedy match to get
  # the full generator expression
  while(flags_string MATCHES "\\$<\\$<[^>]+>:([^>]+)>")
    set(genex_content "${CMAKE_MATCH_1}")

    # Split the content by semicolons
    string(REPLACE ";" "%%SEP%%" temp_content "${genex_content}")
    string(REPLACE "%%SEP%%" ";" flag_list "${temp_content}")

    foreach(flag IN LISTS flag_list)
      if(NOT flag MATCHES "${filter_regex}")
        list(APPEND filtered_result ${flag})
      endif()
    endforeach()

    # Remove this generator expression from the string and continue
    string(REGEX REPLACE "\\$<\\$<[^>]+>:[^>]+>" "" flags_string
                         "${flags_string}")
  endwhile()

  # Handle any remaining non-generator-expression flags
  if(flags_string)
    string(REPLACE ";" "%%SEP%%" temp "${flags_string}")
    string(REPLACE "%%SEP%%" ";" remaining_flags "${temp}")

    foreach(flag IN LISTS remaining_flags)
      if(flag AND NOT flag MATCHES "[$<>]")
        if(NOT flag MATCHES "${filter_regex}")
          list(APPEND filtered_result ${flag})
        endif()
      endif()
    endforeach()
  endif()

  # Return the result
  set(${output_var}
      ${filtered_result}
      PARENT_SCOPE)
endfunction()

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
  get_target_property(LINK_OPTIONS ${PROJECT_NAME} LINK_OPTIONS)

  if(COMPILE_OPTIONS)
    list(APPEND RAW_FLAGS_COMPILE ${COMPILE_OPTIONS})
  endif()
  if(COMPILE_DEFINITIONS)
    list(APPEND RAW_FLAGS_COMPILE ${COMPILE_DEFINITIONS})
  endif()
  if(LINK_OPTIONS)
    list(APPEND RAW_FLAGS_LINK ${LINK_OPTIONS})
  endif()

  set(FILTERED_FLAGS_COMPILE)
  extract_and_filter_flags(
    "${RAW_FLAGS_COMPILE}" "${LIBRA_TARGET_FLAGS_COMPILE_FILTER_REGEX}"
    FILTERED_FLAGS_COMPILE)

  set(FILTERED_FLAGS_LINK)
  extract_and_filter_flags(
    "${RAW_FLAGS_LINK}" "${LIBRA_TARGET_FLAGS_LINK_FILTER_REGEX}"
    FILTERED_FLAGS_LINK)

  # Have to join with ' '; a list joined with ';' is (apparently) not valid in a
  # configured source file.
  list(REMOVE_DUPLICATES FILTERED_FLAGS_COMPILE)
  list(REMOVE_DUPLICATES FILTERED_FLAGS_LINK)
  list(JOIN FILTERED_FLAGS_COMPILE " " LIBRA_TARGET_FLAGS_COMPILE)
  list(JOIN FILTERED_FLAGS_LINK " " LIBRA_TARGET_FLAGS_LINK)

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
