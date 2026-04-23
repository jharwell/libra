#
# Copyright 2026 John Harwell, All rights reserved.
#
# SPDX-License Identifier: MIT
#
function(assert_true VAR)
  if(NOT ${VAR})
    message(FATAL_ERROR "Assertion failed: ${VAR} is false")
  endif()
endfunction()

function(assert_equal A B)
  if(NOT "${A}" STREQUAL "${B}")
    message(FATAL_ERROR "Assertion failed: '${A}' != '${B}'")
  endif()
endfunction()

function(assert_target_exists NAME)
  if(NOT TARGET ${NAME})
    message(FATAL_ERROR "Expected target '${NAME}' to exist")
  endif()
endfunction()

function(assert_file_exists PATH)
  if(NOT EXISTS "${PATH}")
    message(FATAL_ERROR "Expected file '${PATH}' to exist")
  endif()
endfunction()
