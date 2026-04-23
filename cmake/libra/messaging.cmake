#
# Copyright 2024 John Harwell, All rights reserved.
#
# SPDX-License Identifier: MIT
#
function(libra_message type msg)
  list(JOIN CMAKE_MESSAGE_INDENT "" indent)
  if(indent STREQUAL "")
    message(${type} "[LIBRA] ${msg}")
  else()
    message(${type} "${indent}${msg}")
  endif()
endfunction()

function(libra_error MSG)
  libra_message(
    FATAL_ERROR "${MSG}\n" "  Source dir: ${CMAKE_CURRENT_SOURCE_DIR}\n"
    "  Called from: ${CMAKE_CURRENT_LIST_DIR}")
endfunction()
