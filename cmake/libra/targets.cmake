#
# Copyright 2026 John Harwell, All rights reserved.
#
# SPDX-License Identifier: MIT
#
# ##############################################################################
# Target Configuration
# ##############################################################################
include(libra/compile/standard)

#[[.rst:
.. cmake:command:: libra_add_library

   Register a library target.

   Thin wrapper around :cmake:command:`add_library()` which forwards all
   arguments to the built in function, and adds the target name to
   the list of targets to apply the LIBRA magic to.
]]
function(libra_add_library)
  # Keyword form: NAME <name> ...
  if(ARGV0 STREQUAL "NAME")
    cmake_parse_arguments(
      ARG
      ""
      "NAME"
      ""
      ${ARGV})

    if(NOT DEFINED ARG_NAME)
      libra_error("libra_add_library: NAME missing")
    endif()

    set(NAME ${ARG_NAME})
    set(_rest ${ARG_UNPARSED_ARGUMENTS})
    # Positional form: <name> ...
  else()
    set(NAME ${ARGV0})
    set(_rest ${ARGV})
    list(REMOVE_AT _rest 0)
  endif()

  if(NOT ${NAME} IN_LIST _LIBRA_TARGETS)
    list(APPEND _LIBRA_TARGETS ${NAME})

    set(_LIBRA_TARGETS
        "${_LIBRA_TARGETS}"
        CACHE INTERNAL "")
    libra_message(STATUS "Added library target ${NAME}")

  endif()
  add_library(${NAME} ${_rest})
  set(_LIBRA_TARGET_OWNER_${NAME}
      "${PROJECT_NAME}"
      CACHE INTERNAL "")
  _libra_configure_standard(${NAME})
endfunction()

#[[.rst:
.. cmake:command:: libra_add_executable

   Register an executable target.

   Thin wrapper around :cmake:command:`add_executable()` which forwards all
   arguments to the built in function, and adds the target name to
   the list of targets to apply the LIBRA magic to.

]]
function(libra_add_executable)
  # Keyword form: NAME <name> ...
  if(ARGV0 STREQUAL "NAME")
    cmake_parse_arguments(
      ARG
      ""
      "NAME"
      ""
      ${ARGV})

    if(NOT DEFINED ARG_NAME)
      libra_error("libra_add_executable: NAME missing")
    endif()

    set(NAME ${ARG_NAME})
    set(_rest ${ARG_UNPARSED_ARGUMENTS})

    # Positional form: <name> ...
  else()
    set(NAME ${ARGV0})
    set(_rest ${ARGV})
    list(REMOVE_AT _rest 0)
  endif()

  if(NOT ${NAME} IN_LIST _LIBRA_TARGETS)
    list(APPEND _LIBRA_TARGETS ${NAME})
    set(_LIBRA_TARGETS
        "${_LIBRA_TARGETS}"
        CACHE INTERNAL "")
    libra_message(STATUS "Added executable target ${NAME}")
  endif()
  add_executable(${NAME} ${_rest})
  set(_LIBRA_TARGET_OWNER_${NAME}
      "${PROJECT_NAME}"
      CACHE INTERNAL "")
  _libra_configure_standard(${NAME})
endfunction()

function(libra_get_targets OUT_VAR)
  set(${OUT_VAR}
      "${_LIBRA_TARGETS}"
      PARENT_SCOPE)
endfunction()

function(libra_target_registered TARGET OUT_VAR)
  list(FIND _LIBRA_TARGETS ${TARGET} _idx)

  if(_idx EQUAL -1)
    set(${OUT_VAR}
        FALSE
        PARENT_SCOPE)
  else()
    set(${OUT_VAR}
        TRUE
        PARENT_SCOPE)
  endif()
endfunction()

function(libra_target_count OUT_VAR)
  list(LENGTH _LIBRA_TARGETS _len)
  set(${OUT_VAR}
      ${_len}
      PARENT_SCOPE)
endfunction()
