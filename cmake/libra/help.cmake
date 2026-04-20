#
# Copyright 2026 John Harwell, All rights reserved.
#
# SPDX-License-Identifier: MIT
#
# ##############################################################################
# Script mode helper for the help-targets target.
#
# Reads libra_targets.json (written at configure time by summary.cmake) and
# formats it as a terminal table. The JSON is the single source of truth; no
# availability logic is re-run here.
#
# Invoked by the custom target created in summary.cmake via:
#
# cmake -D LIBRA_JSON_FILE=<path> -D _LIBRA_SUMMARY_COL_TARGET=<int> -D
# _LIBRA_SUMMARY_SEP_WIDTH=<int> -P summary_help.cmake
#
# Requires CMake >= 3.19 (string(JSON ...))
# ##############################################################################

# Clear file to avaid stale accumulation
file(WRITE "${CMAKE_BINARY_DIR}/libra_targets.cmake" "")

#[[.rst
.. cmake:command:: _libra_help_resolve_status

  Used at configure time to resolve availability and derive JSON fields.

  Given an option name and tool variable name (both as strings), set _out_avail
  (ON/OFF) and _out_reason in the caller's scope.

  :param _option_name: The variable name, e.g. "LIBRA_TESTS" -- used in reason
   string.

  :param _option_val: The already-dereferenced boolean value of that variable .

  :param _tool_var: Tool variable name, or "NONE".
]]
function(
  _libra_help_resolve_status
  _option_name
  _option_val
  _tool_var
  _out_avail
  _out_reason)
  if(NOT _option_val)
    set(${_out_avail}
        OFF
        PARENT_SCOPE)
    set(${_out_reason}
        "${_option_name}=OFF"
        PARENT_SCOPE)
  elseif(NOT _tool_var STREQUAL "NONE")
    if(_tool_var STREQUAL "LIBRA_SPHINXDOC_COMMAND")
      set(_rstat_tool "${${_tool_var}}")
      string(TOLOWER "${_tool_var}" _rstat_tool_name)
    else()
      set(_rstat_tool "${${_tool_var}}")
      string(REPLACE "_EXECUTABLE" "" _rstat_tool_name "${_tool_var}")
      string(REPLACE "_TOOL" "" _rstat_tool_name "${_rstat_tool_name}")
      string(REPLACE "_" "-" _rstat_tool_name "${_rstat_tool_name}")
      string(TOLOWER "${_rstat_tool_name}" _rstat_tool_name)
    endif()
    if(NOT _rstat_tool)
      set(${_out_avail}
          OFF
          PARENT_SCOPE)
      set(${_out_reason}
          "${_rstat_tool_name} not found"
          PARENT_SCOPE)
    else()
      set(${_out_avail}
          ON
          PARENT_SCOPE)
      set(${_out_reason}
          ""
          PARENT_SCOPE)
    endif()
  else()
    set(${_out_avail}
        ON
        PARENT_SCOPE)
    set(${_out_reason}
        ""
        PARENT_SCOPE)
  endif()
endfunction()

# Map a LIBRA_XXX option name to a JSON category string.
function(_libra_help_option_to_category _option _out_var)
  if(_option STREQUAL "LIBRA_TESTS")
    set(${_out_var}
        "tests"
        PARENT_SCOPE)
  elseif(_option STREQUAL "LIBRA_DOCS")
    set(${_out_var}
        "docs"
        PARENT_SCOPE)
  elseif(_option STREQUAL "LIBRA_CODE_COV")
    set(${_out_var}
        "coverage"
        PARENT_SCOPE)
  elseif(_option STREQUAL "LIBRA_ANALYSIS")
    set(${_out_var}
        "analysis"
        PARENT_SCOPE)
  elseif(_option STREQUAL "LIBRA_FORMAT")
    set(${_out_var}
        "format"
        PARENT_SCOPE)
  else()
    set(${_out_var}
        "other"
        PARENT_SCOPE)
  endif()
endfunction()

# Derive the parent umbrella target name from a target name. Sets _out_var to ""
# for top-level targets.
function(_libra_help_derive_parent _tname _out_var)
  if(_tname MATCHES "^analyze-clang-tidy-.+")
    set(${_out_var}
        "analyze-clang-tidy"
        PARENT_SCOPE)
  elseif(_tname MATCHES "^format-.+")
    set(${_out_var}
        "format"
        PARENT_SCOPE)
  elseif(_tname MATCHES "^fix-.+")
    set(${_out_var}
        "fix"
        PARENT_SCOPE)
  elseif(_tname MATCHES "^analyze-.+")
    set(${_out_var}
        "analyze"
        PARENT_SCOPE)
  else()
    set(${_out_var}
        ""
        PARENT_SCOPE)
  endif()
endfunction()

#[[.rst:
.. cmake:command:: _libra_create_targets_json

  Write libra_targets.json to the build directory at the end of configure phase,
  with info about what special LIBRA targets are available or not, and
  why. Conforms to the "help" JSON schema.

  File read by:

  - ``clibra info`` command

  - ``help-targets`` CMake target at build time which formats the output for the
    terminal.
]]
function(_libra_create_targets_json JSON_OUTPUT_FILE)
  include("${CMAKE_BINARY_DIR}/libra_targets.cmake")

  # ------------------------------------------------------------------
  # Write libra_targets.json at configure time. All option and tool values are
  # fully resolved here, so there is no reason to defer this work to a
  # build-time target.
  # ------------------------------------------------------------------

  # Escape a string for embedding in a JSON value.
  macro(_json_esc _in _out)
    string(REPLACE "\\" "\\\\" ${_out} "${_in}")
    string(REPLACE "\"" "\\\"" ${_out} "${${_out}}")
  endmacro()

  set(_json "{\n")
  string(APPEND _json "  \"schema_version\": 1,\n")
  string(APPEND _json "  \"project\": \"${CMAKE_PROJECT_NAME}\",\n")
  string(APPEND _json "  \"targets\": [\n")

  list(LENGTH _LIBRA_SUMMARY_TARGETS _tw_len)
  set(_tw_i 0)
  set(_first_entry YES)

  while(_tw_i LESS _tw_len)
    math(EXPR _tw_i1 "${_tw_i} + 1")
    math(EXPR _tw_i2 "${_tw_i} + 2")
    list(GET _LIBRA_SUMMARY_TARGETS ${_tw_i} _tw_name)
    list(GET _LIBRA_SUMMARY_TARGETS ${_tw_i1} _tw_opt)
    list(GET _LIBRA_SUMMARY_TARGETS ${_tw_i2} _tw_tool)

    _libra_help_resolve_status(
      "${_tw_opt}"
      "${${_tw_opt}}"
      "${_tw_tool}"
      _tw_avail
      _tw_reason)
    _libra_help_option_to_category("${_tw_opt}" _tw_category)
    _libra_help_derive_parent("${_tw_name}" _tw_parent)

    if(_tw_avail)
      set(_tw_avail_json "true")
    else()
      set(_tw_avail_json "false")
    endif()

    _json_esc("${_tw_reason}" _tw_reason_esc)
    if(_tw_reason_esc STREQUAL "")
      set(_tw_reason_json "null")
    else()
      set(_tw_reason_json "\"${_tw_reason_esc}\"")
    endif()

    if(_tw_parent STREQUAL "")
      set(_tw_parent_json "null")
    else()
      set(_tw_parent_json "\"${_tw_parent}\"")
    endif()

    if(NOT _first_entry)
      string(APPEND _json ",\n")
    endif()
    set(_first_entry NO)

    string(APPEND _json "    {\n")
    string(APPEND _json "      \"name\": \"${_tw_name}\",\n")
    string(APPEND _json "      \"available\": ${_tw_avail_json},\n")
    string(APPEND _json "      \"unavailable_reason\": ${_tw_reason_json},\n")
    string(APPEND _json "      \"category\": \"${_tw_category}\",\n")
    string(APPEND _json "      \"parent\": ${_tw_parent_json}\n")
    string(APPEND _json "    }")

    math(EXPR _tw_i "${_tw_i} + 3")
  endwhile()

  string(APPEND _json "\n  ]\n}\n")
  file(WRITE "${JSON_OUTPUT_FILE}" "${_json}")
  libra_message(STATUS
                "Wrote target availability information to ${JSON_OUTPUT_FILE}")
endfunction()
