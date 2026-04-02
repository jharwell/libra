#
# Copyright 2026 John Harwell, All rights reserved.
#
# SPDX-License-Identifier: MIT
#
# ##############################################################################
# Script mode helper for the help-targets and build targets.
#
# Invoked by the custom targets created in summary.cmake via:
#
# cmake -D LIBRA_HELP_MODE=TARGETS|VARS -D
# LIBRA_SUMMARY_TARGETS="<semicolon-list>"   # TARGETS mode only -D
# _LIBRA_SUMMARY_COL_TARGET=<int>            # TARGETS mode only -D
# _LIBRA_SUMMARY_SEP_WIDTH=<int> -P summary_help.cmake
#
# ##############################################################################
# Load color definitions from the same directory as this script
get_filename_component(_this_dir "${CMAKE_CURRENT_LIST_FILE}" DIRECTORY)
include("${_this_dir}/colorize.cmake")

if(LIBRA_HELP_MODE STREQUAL "TARGETS")
  # Load _LIBRA_SUMMARY_TARGETS, _LIBRA_SUMMARY_COL_TARGET, and
  # _LIBRA_SUMMARY_SEP_WIDTH from the file written at configure time. Passing a
  # CMake list via -D on the command line is unsafe because the shell splits on
  # semicolons before CMake sees them.
  if(NOT LIBRA_TARGETS_FILE)
    message(FATAL_ERROR "summary_help.cmake: LIBRA_TARGETS_FILE is not set")
  endif()
  include("${LIBRA_TARGETS_FILE}")

  if(NOT _LIBRA_SUMMARY_TARGETS)
    message("No LIBRA targets registered.")
    return()
  endif()

  set(_sep "")
  foreach(_i RANGE ${_LIBRA_SUMMARY_SEP_WIDTH})
    string(APPEND _sep "-")
  endforeach()

  message("${BoldBlue}${_sep}")

  set(_th "Target")
  string(LENGTH "${_th}" _thl)
  math(EXPR _thpad "${_LIBRA_SUMMARY_COL_TARGET} - ${_thl}")
  foreach(_s RANGE ${_thpad})
    string(APPEND _th " ")
  endforeach()
  message("${BoldBlue}${_th}  Status  Reason")
  message("${BoldBlue}${_sep}${ColorReset}")

  # _LIBRA_SUMMARY_TARGETS is a flat list of (target, option, tool_var) triples
  # passed in as a semicolon-separated -D value Option values and tool paths
  # were written into the targets file at configure time -- no cache access
  # needed here.

  list(LENGTH _LIBRA_SUMMARY_TARGETS _total)
  set(_i 0)
  while(_i LESS _total)
    list(GET _LIBRA_SUMMARY_TARGETS ${_i} _tname)
    math(EXPR _oi "${_i} + 1")
    math(EXPR _ti "${_i} + 2")
    list(GET _LIBRA_SUMMARY_TARGETS ${_oi} _option)
    list(GET _LIBRA_SUMMARY_TARGETS ${_ti} _tool_var)

    # Pad to fixed column width
    set(_padded "${_tname}")
    string(LENGTH "${_tname}" _len)
    math(EXPR _nsp "${_LIBRA_SUMMARY_COL_TARGET} - ${_len}")
    if(_nsp GREATER 0)
      foreach(_s RANGE ${_nsp})
        string(APPEND _padded " ")
      endforeach()
    endif()

    if(NOT ${_option})
      set(_status "${Red}NO ${ColorReset}")
      set(_reason "${_option}=OFF")
    elseif(NOT _tool_var STREQUAL "NONE")
      # Derive human-readable tool name: clang_tidy_EXECUTABLE -> clang-tidy
      if(${_tool_var} STREQUAL LIBRA_SPHINXDOC_COMMAND)
        string(TOLOWER "${_tool_name}" ${_tool_var})
      else()
        string(REPLACE "_EXECUTABLE" "" _tool_name "${_tool_var}")
        string(REPLACE "_TOOL" "" _tool_name "${_tool_name}")
        string(REPLACE "_" "-" _tool_name "${_tool_name}")
        string(TOLOWER "${_tool_name}" _tool_name)
      endif()

      if(NOT ${_tool_var})
        set(_status "${Red}NO ${ColorReset}")
        set(_reason "${_tool_name} not found")
      else()
        set(_status "${Green}YES${ColorReset}")
        set(_reason "")
      endif()
    else()
      set(_status "${Green}YES${ColorReset}")
      set(_reason "")
    endif()

    message("${_padded}  ${_status}  ${_reason}")
    math(EXPR _i "${_i} + 3")
  endwhile()

  message("${BoldBlue}${_sep}${ColorReset}")

else()
  message(FATAL_ERROR "summary_help.cmake: LIBRA_HELP_MODE must be TARGETS"
                      "got '${LIBRA_HELP_MODE}'")
endif()
