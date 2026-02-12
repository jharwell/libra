#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#
# ##############################################################################
# Target Configuration
# ##############################################################################
macro(libra_add_library NAME)
  # Save the target name for later use
  set(LIBRA_TARGETS
      "${LIBRA_TARGETS};${NAME}"
      CACHE INTERNAL "")

  libra_message(STATUS "Added library target ${NAME}")
  # Forward all arguments to add_library
  add_library(${NAME} ${ARGN})
endmacro()

macro(libra_add_executable NAME)
  # Save the target name for later use list(APPEND LIBRA_TARGETS ${NAME})
  set(LIBRA_TARGETS
      "${LIBRA_TARGETS};${NAME}"
      CACHE INTERNAL "")

  libra_message(STATUS "Added executable target ${NAME}")
  # Forward all arguments to add_executable
  add_executable(${NAME} ${ARGN})
endmacro()

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
