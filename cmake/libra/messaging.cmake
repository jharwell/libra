#
# Copyright 2024 John Harwell, All rights reserved.
#
# SPDX-License Identifier: MIT
#
function(libra_message type msg)
  message(${type} "[LIBRA] ${msg}")
endfunction()

function(libra_error MSG)
  libra_message(
    FATAL_ERROR "${MSG}\n" "  Source dir: ${CMAKE_CURRENT_SOURCE_DIR}\n"
    "  Called from: ${CMAKE_CURRENT_LIST_DIR}")
endfunction()
