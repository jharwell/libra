#
# Copyright 2026 John Harwell, All rights reserved.
#
# SPDX-License Identifier: MIT
#
function(evaluate_genex input_string target output_var)
  set(result "")

  foreach(item IN LISTS input_string)
    if(item MATCHES "^\\$<")
      evaluate_single_genex("${item}" "${target}" evaluated_item)
      if(evaluated_item)
        # evaluated_item might be a list (semicolon-separated)
        foreach(subitem IN LISTS evaluated_item)
          if(subitem)
            list(APPEND result "${subitem}")
          endif()
        endforeach()
      endif()
    else()
      if(item)
        list(APPEND result "${item}")
      endif()
    endif()
  endforeach()

  set(${output_var}
      ${result}
      PARENT_SCOPE)
endfunction()

function(evaluate_single_genex genex target output_var)
  set(result "")

  # Match $<$<CONDITION>:value> The value part can contain anything except the
  # final > We match from the end backwards to get the right closing >

  if(genex MATCHES "^\\$<\\$<([^>]+)>:(.*)>[ \t]*$")
    # Properly closed: $<$<CONFIG:Debug>:-O3>
    set(condition "${CMAKE_MATCH_1}")
    set(value "${CMAKE_MATCH_2}")

  elseif(genex MATCHES "^\\$<\\$<([^>]+)>:(.*)$")
    # Missing final >: $<$<CONFIG:Debug>:-O3
    set(condition "${CMAKE_MATCH_1}")
    set(value "${CMAKE_MATCH_2}")
    # libra_message(WARNING "Fixed malformed genex: ${genex}")

  else()
    # Not a conditional genex, try simple queries
    if(genex MATCHES "^\\$<CONFIG:([^>]+)>$")
      set(config "${CMAKE_MATCH_1}")
      if(CMAKE_CONFIGURATION_TYPES)
        if("${config}" IN_LIST CMAKE_CONFIGURATION_TYPES)
          set(result "${config}")
        endif()
      else()
        if(CMAKE_BUILD_TYPE STREQUAL "${config}")
          set(result "${config}")
        endif()
      endif()

    elseif(genex MATCHES "^\\$<LINK_LANGUAGE:([^>]+)>$")
      set(lang "${CMAKE_MATCH_1}")
      evaluate_link_language("${target}" link_lang)
      if(link_lang STREQUAL "${lang}")
        set(result "${lang}")
      endif()

    elseif(genex MATCHES "^\\$<COMPILE_LANGUAGE:([^>]+)>$")
      set(lang "${CMAKE_MATCH_1}")
      evaluate_compile_language("${target}" "${lang}" has_lang)
      if(has_lang)
        set(result "${lang}")
      endif()

    else()
      libra_message(WARNING "Cannot parse genex: ${genex}")
    endif()

    set(${output_var}
        ${result}
        PARENT_SCOPE)
    return()
  endif()

  # We have condition and value - evaluate condition
  evaluate_condition("${condition}" "${target}" condition_result)

  if(condition_result)
    # Value might be semicolon-separated flags But we need to be careful not to
    # split on semicolons that are part of the value
    set(result "${value}")
  endif()

  set(${output_var}
      ${result}
      PARENT_SCOPE)
endfunction()

function(evaluate_condition condition target output_var)
  set(result 0)

  if(condition MATCHES "^COMPILE_LANGUAGE:(.+)$")
    set(lang "${CMAKE_MATCH_1}")
    evaluate_compile_language("${target}" "${lang}" result)

  elseif(condition MATCHES "^LINK_LANGUAGE:(.+)$")
    set(lang "${CMAKE_MATCH_1}")
    evaluate_link_language("${target}" link_lang)
    if(link_lang STREQUAL "${lang}")
      set(result 1)
    endif()

  elseif(condition MATCHES "^CONFIG:(.+)$")
    set(config "${CMAKE_MATCH_1}")
    if(CMAKE_CONFIGURATION_TYPES)
      if("${config}" IN_LIST CMAKE_CONFIGURATION_TYPES)
        set(result 1)
      endif()
    else()
      if(CMAKE_BUILD_TYPE STREQUAL "${config}")
        set(result 1)
      endif()
    endif()

  elseif(condition MATCHES "^CXX_COMPILER_ID:(.+)$")
    set(compiler_id "${CMAKE_MATCH_1}")
    if(CMAKE_CXX_COMPILER_ID STREQUAL "${compiler_id}")
      set(result 1)
    endif()

  elseif(condition MATCHES "^C_COMPILER_ID:(.+)$")
    set(compiler_id "${CMAKE_MATCH_1}")
    if(CMAKE_C_COMPILER_ID STREQUAL "${compiler_id}")
      set(result 1)
    endif()

  elseif(condition MATCHES "^PLATFORM_ID:(.+)$")
    set(platform "${CMAKE_MATCH_1}")
    if(CMAKE_SYSTEM_NAME STREQUAL "${platform}")
      set(result 1)
    endif()

  elseif(condition MATCHES "^BOOL:(.+)$")
    if(CMAKE_MATCH_1)
      set(result 1)
    endif()

  else()
    libra_message(WARNING "Unknown condition: ${condition}")
  endif()

  set(${output_var}
      ${result}
      PARENT_SCOPE)
endfunction()

function(evaluate_compile_language target lang output_var)
  set(result 0)

  get_target_property(sources ${target} SOURCES)
  if(NOT sources)
    set(${output_var}
        0
        PARENT_SCOPE)
    return()
  endif()

  foreach(src IN LISTS sources)
    if(src MATCHES "^\\$<")
      continue()
    endif()

    get_source_file_property(src_lang "${src}" LANGUAGE)

    if(NOT src_lang OR src_lang STREQUAL "NOTFOUND")
      if(src MATCHES "\\.(cpp|cxx|cc|C|CPP)$")
        set(src_lang "CXX")
      elseif(src MATCHES "\\.(c)$")
        set(src_lang "C")
      elseif(src MATCHES "\\.(cu)$")
        set(src_lang "CUDA")
      endif()
    endif()

    if(src_lang STREQUAL "${lang}")
      set(result 1)
      break()
    endif()
  endforeach()

  set(${output_var}
      ${result}
      PARENT_SCOPE)
endfunction()

function(evaluate_link_language target output_var)
  get_target_property(link_lang ${target} LINKER_LANGUAGE)

  if(NOT link_lang OR link_lang STREQUAL "NOTFOUND")
    get_target_property(sources ${target} SOURCES)

    if(sources)
      set(has_cxx FALSE)
      set(has_c FALSE)

      foreach(src IN LISTS sources)
        if(src MATCHES "^\\$<")
          continue()
        endif()

        if(src MATCHES "\\.(cpp|cxx|cc|C|CPP)$")
          set(has_cxx TRUE)
        elseif(src MATCHES "\\.(c)$")
          set(has_c TRUE)
        endif()
      endforeach()

      if(has_cxx)
        set(link_lang "CXX")
      elseif(has_c)
        set(link_lang "C")
      endif()
    endif()
  endif()

  set(${output_var}
      ${link_lang}
      PARENT_SCOPE)
endfunction()

function(
  extract_and_filter_flags
  input_string
  filter_regex
  target
  output_var)
  # Evaluate generator expressions
  evaluate_genex("${input_string}" "${target}" evaluated_flags)

  set(filtered_result "")

  foreach(flag IN LISTS evaluated_flags)
    if(NOT flag)
      continue()
    endif()

    # Remove any stray > characters that might have leaked through
    string(REGEX REPLACE "[<>]" "" flag "${flag}")

    # Skip empty after cleaning
    string(STRIP "${flag}" flag)
    if(NOT flag)
      continue()
    endif()

    # Apply filter
    if(NOT flag MATCHES "${filter_regex}")
      list(APPEND filtered_result "${flag}")
    endif()
  endforeach()

  set(${output_var}
      ${filtered_result}
      PARENT_SCOPE)
endfunction()

# This is separate from the the API function so that the API version can be
# available in project-local.cmake. Target compile flags/options/etc aren't set
# until AFTER project-local.cmake is included, so if we try to filter out build
# flags at that point, we will get nothing. This is not pretty, but it does
# work.
function(_libra_configure_source_file_post TARGET INFILE OUTFILE)
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

  get_target_property(COMPILE_OPTIONS ${TARGET} COMPILE_OPTIONS)
  get_target_property(COMPILE_DEFINITIONS ${TARGET} COMPILE_DEFINITIONS)
  get_target_property(COMPILE_FLAGS ${TARGET} COMPILE_FLAGS)
  get_target_property(INTERFACE_COMPILE_OPTIONS ${TARGET}
                      INTERFACE_COMPILE_OPTIONS)
  get_target_property(LINK_OPTIONS ${TARGET} LINK_OPTIONS)

  if(COMPILE_OPTIONS)
    list(APPEND RAW_FLAGS_COMPILE ${COMPILE_OPTIONS})
  endif()
  if(COMPILE_DEFINITIONS)
    list(APPEND RAW_FLAGS_COMPILE ${COMPILE_DEFINITIONS})
  endif()
  if(LINK_OPTIONS)
    list(APPEND RAW_FLAGS_LINK ${LINK_OPTIONS})
  endif()

  string(TOUPPER "${CMAKE_BUILD_TYPE}" build_type_upper)

  # Include the build flags you get with the selected cmake build type
  list(APPEND RAW_FLAGS_COMPILE ${CMAKE_CXX_FLAGS_${build_type_upper}})
  list(APPEND RAW_FLAGS_COMPILE ${CMAKE_C_FLAGS_${build_type_upper}})

  # Include the build flags you get when using cmake's builtin IPO capability If
  # a target has both C/C++ code, any duplicates will be removed below. You
  # can't include these unconditionally, because (I've learned) these variables
  # are non-empty even with IPO is not enabled.
  if(LIBRA_LTO)
    list(APPEND RAW_FLAGS_COMPILE ${CMAKE_CXX_COMPILE_OPTIONS_IPO})
    list(APPEND RAW_FLAGS_LINK ${CMAKE_CXX_LINK_OPTIONS_IPO})
    list(APPEND RAW_FLAGS_COMPILE ${CMAKE_C_COMPILE_OPTIONS_IPO})
    list(APPEND RAW_FLAGS_LINK ${CMAKE_C_LINK_OPTIONS_IPO})
  endif()

  extract_and_filter_flags(
    "${RAW_FLAGS_COMPILE}" "${_LIBRA_TARGET_FLAGS_COMPILE_FILTER_REGEX}"
    ${TARGET} FILTERED_FLAGS_COMPILE)

  set(FILTERED_FLAGS_LINK)
  extract_and_filter_flags(
    "${RAW_FLAGS_LINK}" "${_LIBRA_TARGET_FLAGS_LINK_FILTER_REGEX}" ${TARGET}
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
  target_sources(${TARGET} PRIVATE ${OUTFILE})

  libra_message(STATUS "Configured source file: ${INFILE} -> ${OUTFILE}")
endfunction()

foreach(TARGET ${_LIBRA_TARGETS})
  list(LENGTH _LIBRA_${TARGET}_CONFIGURED_SOURCE_FILES_SRC N_SRC)
  list(LENGTH _LIBRA_${TARGET}_CONFIGURED_SOURCE_FILES_DEST N_DEST)

  if(NOT N_SRC EQUAL N_DEST)
    libra_error(
      "Configured file list length mismatch! SRC=${N_SRC}, DEST=${N_DEST}")
  endif()

  if(N_SRC GREATER 0)
    math(EXPR N_SRC "${N_SRC} - 1")

    foreach(i RANGE ${N_SRC})
      list(GET _LIBRA_${TARGET}_CONFIGURED_SOURCE_FILES_SRC ${i} INFILE)
      list(GET _LIBRA_${TARGET}_CONFIGURED_SOURCE_FILES_DEST ${i} OUTFILE)
      _libra_configure_source_file_post("${TARGET}" "${INFILE}" "${OUTFILE}")
    endforeach()
  endif()
endforeach()
