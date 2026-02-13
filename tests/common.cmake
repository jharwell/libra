#
# Copyright (c) 2026 Boon Logic, Inc.
#
# The software provided is the sole and exclusive property of EpiSys Science,
# Inc. The user shall use the software only in support of the agreed upon
# experimental purpose only and shall preserve and protect the software from
# disclosure to any person or persons, other than employees, consultants, and
# contracted staff of the corporation with a need to know, through an exercise
# of care equivalent to the degree of care it uses to preserve and protect its
# own intellectual property. Unauthorized use of the software is prohibited
# without written consent.
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
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
