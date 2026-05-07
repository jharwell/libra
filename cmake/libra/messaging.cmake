#
# Copyright 2024 John Harwell, All rights reserved.
#
# SPDX-License Identifier: MIT
#
function(libra_message _type)
  list(JOIN CMAKE_MESSAGE_INDENT "" indent)
  list(JOIN ARGN " " _msg)
  if(indent STREQUAL "")
    message(${_type} "[LIBRA] ${_msg}")
  else()
    message(${_type} "${indent}${_msg}")
  endif()
endfunction()

function(libra_error)
  list(JOIN ARGN " " _msg)
  libra_message(
    FATAL_ERROR "${_msg}\n" "  Source dir: ${CMAKE_CURRENT_SOURCE_DIR}\n"
    "  Called from: ${CMAKE_CURRENT_LIST_DIR}")
endfunction()
