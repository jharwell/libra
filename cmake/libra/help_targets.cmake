#
# Copyright 2026 John Harwell, All rights reserved.
#
# SPDX-License-Identifier: MIT
#
get_filename_component(_this_dir "${CMAKE_CURRENT_LIST_FILE}" DIRECTORY)
include("${_this_dir}/colorize.cmake")

if(NOT LIBRA_JSON_FILE)
  message(FATAL_ERROR "summary_help.cmake: LIBRA_JSON_FILE is not set")
endif()

if(NOT EXISTS "${LIBRA_JSON_FILE}")
  message(
    FATAL_ERROR "summary_help.cmake: JSON file not found: ${LIBRA_JSON_FILE}\n"
                "Re-run cmake to regenerate it.")
endif()

file(READ "${LIBRA_JSON_FILE}" _json_text)
string(JSON _n_targets LENGTH "${_json_text}" "targets")

# --------------------------------------------------------------------------
# Print the table
# --------------------------------------------------------------------------
set(_sep "")
foreach(_i RANGE ${_LIBRA_SUMMARY_SEP_WIDTH})
  string(APPEND _sep "-")
endforeach()

set(_th "Target")
string(LENGTH "${_th}" _thl)
math(EXPR _thpad "${_LIBRA_SUMMARY_COL_TARGET} - ${_thl}")
foreach(_s RANGE ${_thpad})
  string(APPEND _th " ")
endforeach()

message("${BoldBlue}${_sep}")
message("${BoldBlue}${_th}  Status  Reason")
message("${BoldBlue}${_sep}${ColorReset}")

set(_idx 0)
while(_idx LESS _n_targets)
  string(
    JSON
    _tname
    GET
    "${_json_text}"
    "targets"
    ${_idx}
    "name")
  string(
    JSON
    _avail
    GET
    "${_json_text}"
    "targets"
    ${_idx}
    "available")
  string(
    JSON
    _rtype
    TYPE
    "${_json_text}"
    "targets"
    ${_idx}
    "unavailable_reason")

  # Pad target name to fixed column width
  set(_padded "${_tname}")
  string(LENGTH "${_tname}" _len)
  math(EXPR _nsp "${_LIBRA_SUMMARY_COL_TARGET} - ${_len}")
  if(_nsp GREATER 0)
    foreach(_s RANGE ${_nsp})
      string(APPEND _padded " ")
    endforeach()
  endif()

  # string(JSON GET ...) returns ON/OFF for JSON booleans (not true/false)
  if(_avail)
    set(_status "${Green}YES${ColorReset}")
    set(_reason "")
  else()
    set(_status "${Red}NO ${ColorReset}")
    # Only GET the reason string when it is not JSON null
    if(_rtype STREQUAL "NULL")
      set(_reason "")
    else()
      string(
        JSON
        _reason
        GET
        "${_json_text}"
        "targets"
        ${_idx}
        "unavailable_reason")
    endif()
  endif()

  message("${_padded}  ${_status}  ${_reason}")
  math(EXPR _idx "${_idx} + 1")
endwhile()

message("${BoldBlue}${_sep}${ColorReset}")
