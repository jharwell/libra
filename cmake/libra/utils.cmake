#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#
# ##############################################################################
# Target Configuration
# ##############################################################################
#[[.rst:
.. cmake:command:: libra_add_library

   Register a library target.

   Thin wrapper around :cmake:command:`add_library()` which forwards all
   arguments to the built in function, and adds the target name to
   :cmake:variable:`LIBRA_TARGETS`. You don't *have* to use this function, but
   if you don't then much of the LIBRA magic w.r.t. compilers/compilation can
   only be applied to the :cmake:variable:`PROJECT_NAME` target.
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

  if(NOT ${NAME} IN_LIST LIBRA_TARGETS)
    list(APPEND LIBRA_TARGETS ${NAME})
    set(LIBRA_TARGETS
        "${LIBRA_TARGETS}"
        CACHE INTERNAL "")
    libra_message(STATUS "Added library target ${NAME}")

    add_library(${NAME} ${_rest})
  endif()
endfunction()

#[[.rst:
.. cmake:command:: libra_add_executable

   Register an executable target.

   Thin wrapper around :cmake:command:`add_executable()` which forwards all
   arguments to the built in function, and adds the target name to
   :cmake:variable:`LIBRA_TARGETS`. You don't *have* to use this function, but
   if you don't then much of the LIBRA magic w.r.t. compilers/compilation can
   only be applied to the :cmake:variable:`PROJECT_NAME` target.

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

  if(NOT ${NAME} IN_LIST LIBRA_TARGETS)
    list(APPEND LIBRA_TARGETS ${NAME})
    set(LIBRA_TARGETS
        "${LIBRA_TARGETS}"
        CACHE INTERNAL "")
    libra_message(STATUS "Added executable target ${NAME}")

    add_executable(${NAME} ${_rest})
  endif()
endfunction()

function(libra_get_targets OUT_VAR)
  set(${OUT_VAR}
      "${LIBRA_TARGETS}"
      PARENT_SCOPE)
endfunction()

function(libra_target_registered TARGET OUT_VAR)
  list(FIND LIBRA_TARGETS ${TARGET} _idx)

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
  list(LENGTH LIBRA_TARGETS _len)
  set(${OUT_VAR}
      ${_len}
      PARENT_SCOPE)
endfunction()

# Set policy if policy is available
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
