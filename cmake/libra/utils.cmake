#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#
# Set policy if policy is available
include(libra/test/negative)

function(set_policy POL VAL)

  if(POLICY ${POL})
    cmake_policy(SET ${POL} ${VAL})
  endif()

endfunction(set_policy)

# Function that extract entries matching a given regex from a list. ${OUTPUT}
# will store the list of matching filenames.
function(list_extract OUTPUT REGEX)
  foreach(FILENAME ${ARGN})
    if(${FILENAME} MATCHES "${REGEX}")
      list(APPEND ${OUTPUT} ${FILENAME})
    endif()
  endforeach()

  set(${OUTPUT}
      ${${OUTPUT}}
      PARENT_SCOPE)

endfunction(list_extract)

macro(dual_scope_set name value)
  # Set a variable in parent scope and make it visible in current scope
  set(${name}
      "${value}"
      PARENT_SCOPE)
  set(${name} "${value}")
endmacro()

macro(_libra_get_project_language OUT)
  # Prefer C++ over C if a project enables both languages.
  if(CMAKE_CXX_COMPILER_LOADED)
    set(${OUT} CXX)
  elseif(CMAKE_C_COMPILER_LOADED)
    set(${OUT} C)
  endif()

endmacro()

macro(_libra_calculate_srcs SOURCE SRCS_RET HEADERS_RET)
  libra_message(STATUS "Calculating sources for ${SOURCE}")
  _libra_get_project_language(_LANGUAGE)
  list(APPEND CMAKE_MESSAGE_INDENT " ")

  if("${_LANGUAGE}" MATCHES "CXX")
    libra_message(STATUS "Detected language C++ for project")
  elseif("${_LANGUAGE}" MATCHES "C")
    libra_message(STATUS "Detected language C project")
  endif()

  if(NOT _LANGUAGE)
    libra_message(WARNING "Unable to autodetect language--assuming CXX.")
    set(_LANGUAGE CXX)
  endif()

  if("${_LANGUAGE}" STREQUAL "C")
    if("${SOURCE}" STREQUAL "APIDOC")
      set(CANDIDATE_SRCS ${${PROJECT_NAME}_C_SRC})
      set(CANDIDATE_HEADERS ${${PROJECT_NAME}_C_HEADERS})
    else()
      set(CANDIDATE_SRCS ${${PROJECT_NAME}_C_SRC}
                         ${${PROJECT_NAME}_C_TESTS_SRC})
      set(CANDIDATE_HEADERS ${${PROJECT_NAME}_C_HEADERS})
    endif()
  elseif("${_LANGUAGE}" STREQUAL "CXX")
    if("${SOURCE}" STREQUAL "APIDOC")
      set(CANDIDATE_SRCS ${${PROJECT_NAME}_CXX_SRC})
      set(CANDIDATE_HEADERS ${${PROJECT_NAME}_CXX_HEADERS})
    else()
      set(CANDIDATE_SRCS ${${PROJECT_NAME}_CXX_SRC}
                         ${${PROJECT_NAME}_CXX_TESTS_SRC})
      set(CANDIDATE_HEADERS ${${PROJECT_NAME}_CXX_HEADERS})
    endif()
  else()
    libra_error("Bad language '${_LANGUAGE}' for project: must be {C,CXX}")
  endif()

  set(SELECTED_HEADERS ${CANDIDATE_HEADERS})
  set(SELECTED_SRCS)
  foreach(file ${CANDIDATE_SRCS})
    get_filename_component(_fname ${file} NAME)

    set(_SKIP_NEG_TEST)
    foreach(neg_ext ${_LIBRA_NEGATIVE_EXTENSIONS})
      if(_fname MATCHES "\\.${neg_ext}$")
        libra_message(STATUS "Skipping negative compilation test ${file}")
        set(_SKIP_NEG_TEST YES)
        continue()
      endif()
    endforeach()
    if(_SKIP_NEG_TEST)
      continue()
    endif()
    list(APPEND SELECTED_SRCS ${file})
  endforeach()

  set(${SRCS_RET} ${SELECTED_SRCS})
  set(${HEADERS_RET} ${SELECTED_HEADERS})
  list(POP_BACK CMAKE_MESSAGE_INDENT)
endmacro()

function(_libra_register_custom_target NAME OPTION TOOL)
  if(NOT NAME)
    libra_error("_libra_register_custom_target: NAME is required")
  endif()
  if(NOT OPTION)
    libra_error("_libra_register_custom_target: OPTION is required")
  endif()
  if(NOT TOOL)
    libra_error(
      "_libra_register_custom_target: TOOL is required (pass NONE if tool-agnostic)"
    )
  endif()

  set(_targets_file "${CMAKE_BINARY_DIR}/libra_targets.cmake")

  if(${OPTION})
    set(_opt_val "ON")
  else()
    set(_opt_val "OFF")
  endif()

  if(NOT TOOL STREQUAL "NONE")
    set(_tool_val "${${TOOL}}")
  else()
    set(_tool_val "")
  endif()

  file(
    APPEND "${_targets_file}"
    "list(APPEND _LIBRA_SUMMARY_TARGETS [[${NAME}]] [[${OPTION}]] [[${TOOL}]])\n"
  )
  file(APPEND "${_targets_file}" "set([[${OPTION}]] ${_opt_val})\n")
  if(NOT TOOL STREQUAL "NONE")
    file(APPEND "${_targets_file}" "set([[${TOOL}]] [[${_tool_val}]])\n")
  endif()
endfunction()
