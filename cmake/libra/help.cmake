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
# ##############################################################################

# Clear file to avoid stale accumulation across configure runs
file(WRITE "${CMAKE_BINARY_DIR}/libra_targets.cmake" "")

#[[.rst:
.. cmake:command:: _libra_help_resolve_status

  Resolve the availability of a custom target and produce a human-readable
  reason string for display in the help table and ``libra_targets.json``.

  Availability is determined by two independent gates applied in order:

  1. **Option gate** -- every option in ``_option_names`` must be ``ON``.  If
     any are ``OFF`` the target is unavailable regardless of the tool state.

  2. **Tool gate** -- when all options are ``ON``, the resolved value of
     ``_tool_var`` must be non-empty (i.e. the tool was found by
     ``find_program`` / ``find_package``).

  The ``unavailable_reason`` string always lists **all** gating options with
  their current values (e.g. ``LIBRA_ANALYSIS=OFF,
  LIBRA_CLANG_TIDY_CATEGORY_TARGETS=ON``) so the user sees the complete
  picture in one glance rather than having to fix options one at a time.  When
  the target is available the reason is set to the empty string (serialised as
  JSON ``null`` by the caller).

  :param _option_names: Semicolon-separated list of LIBRA option variable
   names, e.g. ``"LIBRA_ANALYSIS;LIBRA_CLANG_TIDY_CATEGORY_TARGETS"``.  All
   must be ``ON`` for the target to be considered available.

  :param _tool_var: Name of the CMake variable that holds the resolved tool
   path (e.g. ``clang_tidy_EXECUTABLE``), or the literal string ``NONE`` when
   no tool check is required.

  :param _out_avail: Name of the variable in the caller's scope that receives
   ``ON`` or ``OFF``.

  :param _out_reason: Name of the variable in the caller's scope that receives
   the reason string (empty when available).
]]
function(
  _libra_help_resolve_status
  _option_names
  _tool_var
  _out_avail
  _out_reason)

  # Build a reason string showing ALL options with their values (option A). This
  # gives the user the complete picture even when multiple gates exist.
  set(_reason "")
  foreach(_opt IN LISTS _option_names)
    if(_reason)
      string(APPEND _reason ", ")
    endif()
    if(${_opt})
      string(APPEND _reason "${_opt}=ON")
    else()
      string(APPEND _reason "${_opt}=OFF")
    endif()
  endforeach()

  # Check whether all options are ON
  set(_all_on YES)
  foreach(_opt IN LISTS _option_names)
    if(NOT ${_opt})
      set(_all_on NO)
      break()
    endif()
  endforeach()

  if(NOT _all_on)
    set(${_out_avail}
        OFF
        PARENT_SCOPE)
    set(${_out_reason}
        "${_reason}"
        PARENT_SCOPE)
    return()
  endif()

  # All options ON -- check the tool
  if(NOT _tool_var STREQUAL "NONE")
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

#[[.rst:
.. cmake:command:: _libra_help_option_to_category

  Map a LIBRA option variable name to the JSON category string used in
  ``libra_targets.json``.  When a target has multiple gating options, pass the
  **primary** (first) option; all options for a given target map to the same
  category by construction.

  Known mappings:

  ================================  ===========
  Option                            Category
  ================================  ===========
  ``LIBRA_TESTS``                   ``tests``
  ``LIBRA_DOCS``                    ``docs``
  ``LIBRA_COVERAGE``                ``coverage``
  ``LIBRA_ANALYSIS``                ``analysis``
  ``LIBRA_FORMAT``                  ``format``
  *(anything else)*                 ``other``
  ================================  ===========

  :param _option: The primary LIBRA option name.

  :param _out_var: Name of the variable in the caller's scope that receives
   the category string.
]]
function(_libra_help_option_to_category _option _out_var)
  if(_option STREQUAL "LIBRA_TESTS")
    set(${_out_var}
        "tests"
        PARENT_SCOPE)
  elseif(_option STREQUAL "LIBRA_DOCS")
    set(${_out_var}
        "docs"
        PARENT_SCOPE)
  elseif(_option STREQUAL "LIBRA_COVERAGE")
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

#[[.rst:
.. cmake:command:: _libra_help_derive_parent

  Derive the umbrella (parent) target name from a leaf target name using
  naming conventions.  The result is stored in ``_out_var`` and is set to the
  empty string for top-level targets that have no parent.

  Naming rules applied (first match wins):

  - ``analyze-clang-tidy-*``  →  ``analyze-clang-tidy``
  - ``format-*``              →  ``format``
  - ``fix-*``                 →  ``fix``
  - ``analyze-*``             →  ``analyze``
  - *(anything else)*         →  ``""`` (no parent)

  :param _tname: The full target name to inspect.
  :param _out_var: Name of the variable in the caller's scope that receives
   the parent target name, or the empty string if there is no parent.
]]
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

  Serialise the registered LIBRA target metadata to ``libra_targets.json`` at
  configure time.  The file is the single source of truth consumed by:

  - ``clibra info`` -- the companion CLI tool reads it to display target state.
  - The ``help-targets`` CMake build target -- formats it as a terminal table
    at build time via :cmake:command:`help_targets.cmake`.

  The function reads ``${CMAKE_BINARY_DIR}/libra_targets.cmake`` (written
  incrementally by :cmake:command:`_libra_register_custom_target()` during
  configure) and iterates over the ``_LIBRA_SUMMARY_TARGETS`` list it defines.
  That list is a flat sequence of 3-element records::

    [NAME, OPTIONS_SERIALIZED, TOOL, NAME, OPTIONS_SERIALIZED, TOOL, ...]

  For each record :cmake:command:`_libra_help_resolve_status()` is called to
  determine availability, then the result is emitted as a JSON object
  conforming to the ``help`` schema (``schema_version: 1``).

  All option and tool values are fully resolved at configure time; no
  availability logic is deferred to build time.

  :param JSON_OUTPUT_FILE: Absolute path to the JSON file to write.  Typically
   ``${CMAKE_BINARY_DIR}/libra_targets.json``.
]]
function(_libra_create_targets_json JSON_OUTPUT_FILE)
  include("${CMAKE_BINARY_DIR}/libra_targets.cmake")

  # Escape a string for safe embedding as a JSON string value.
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
    list(GET _LIBRA_SUMMARY_TARGETS ${_tw_i1} _tw_opts_str)
    list(GET _LIBRA_SUMMARY_TARGETS ${_tw_i2} _tw_tool)

    # Re-expand the serialized option list (\\; -> ;)
    string(REPLACE "\\;" ";" _tw_opts "${_tw_opts_str}")

    _libra_help_resolve_status("${_tw_opts}" "${_tw_tool}" _tw_avail _tw_reason)

    # Use the first (primary) option for category derivation; all options on a
    # given target map to the same category by construction.
    list(GET _tw_opts 0 _tw_primary_opt)
    _libra_help_option_to_category("${_tw_primary_opt}" _tw_category)
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
