#
# Copyright 2026 John Harwell, All rights reserved.
#
# SPDX-License-Identifier: MIT
#
# ##############################################################################
# Summary
# ##############################################################################
set(_LIBRA_SHOWED_SUMMARY NO)

# Column width constants
set(_LIBRA_SUMMARY_COL_FEATURE 37) # Feature description
set(_LIBRA_SUMMARY_COL_STATUS 26) # Status/value
set(_LIBRA_SUMMARY_COL_VARIABLE 33) # [VARIABLE_NAME]
set(_LIBRA_SUMMARY_COL_TARGET 22) # make target name
set(_LIBRA_SUMMARY_SEP_WIDTH 80) # inner separator width

#[[.rst:
.. cmake:command:: libra_config_summary_prepare_fields

  Prepare configuration fields for display by adding padding and colorization.

  Given a list of configurable fields in a project as strings, this function
  defines a set of new variables, one per field, with the prefix ``EMIT_``. The
  value of each new variable is right-padded with spaces so that any extra
  content on each line (when the variables are printed to the screen) can be
  left-aligned.  Additionally, common values like ON/OFF and YES/NO are
  colorized for easier visual parsing.

  This function is typically used in conjunction with
  :cmake:command:`libra_config_summary` to create nicely formatted configuration
  summaries.

  :param FIELDS: List of field names (variable names) to prepare for display.
   Each field will have a corresponding ``EMIT_<field>`` variable created in the
   parent scope that contains the padded and colorized value.

  **Colorization Rules:**

  - ``ON``, ``on``, ``YES``, ``yes`` - Displayed in green
  - ``OFF``, ``off``, ``NO``, ``no`` - Displayed in red
  - Special strings (``NONE``, ``ALL``, ``CONAN``) - No colorization
  - Version numbers (``x.y.z`` format) - No colorization

  **Example:**

  .. code-block:: cmake

    set(MY_FIELDS CMAKE_BUILD_TYPE LIBRA_TESTS LIBRA_CODE_COV)
    libra_config_summary_prepare_fields("${MY_FIELDS}")
    message(STATUS "Build type: ${EMIT_CMAKE_BUILD_TYPE}")
    message(STATUS "Tests:      ${EMIT_LIBRA_TESTS}")
]]
function(libra_config_summary_prepare_fields FIELDS)
  if(NOT FIELDS)
    libra_message(WARNING
                  "libra_config_summary_prepare_fields: No fields provided")
    return()
  endif()

  # Compute max value length for padding
  set(MAXLEN 0)
  foreach(field ${FIELDS})
    list(LENGTH ${field} LIST_LEN)
    if(LIST_LEN GREATER 1)
      string(REPLACE ";" " " OUT "${${field}}")
      set(EMIT_${field} "${OUT}")
    else()
      set(EMIT_${field} ${${field}})
    endif()

    if("${EMIT_${field}}" STREQUAL "")
      set(LEN 0)
    else()
      string(LENGTH "${EMIT_${field}}" LEN)
    endif()

    if(${LEN} GREATER ${MAXLEN})
      set(MAXLEN ${LEN})
    endif()
  endforeach()

  # Pad each value to MAXLEN, but cap at _LIBRA_SUMMARY_COL_STATUS to avoid long
  # paths blowing out the column
  if(MAXLEN GREATER ${_LIBRA_SUMMARY_COL_STATUS})
    set(MAXLEN ${_LIBRA_SUMMARY_COL_STATUS})
  endif()

  foreach(field ${FIELDS})
    if("${EMIT_${field}}" STREQUAL "")
      set(LEN 0)
    else()
      string(LENGTH "${EMIT_${field}}" LEN)
    endif()

    # Truncate if longer than column width
    if(LEN GREATER MAXLEN)
      math(EXPR _trunc "${MAXLEN} - 3")
      string(SUBSTRING "${EMIT_${field}}" 0 ${_trunc} _tmp)
      set(EMIT_${field} "${_tmp}...")
      set(LEN ${MAXLEN})
    endif()

    math(EXPR N_SPACES "${MAXLEN} - ${LEN}")
    foreach(n RANGE ${N_SPACES})
      string(APPEND EMIT_${field} " ")
    endforeach()
  endforeach()

  # Colorize
  foreach(field ${FIELDS})
    if("${${field}}" MATCHES "((NONE)|(ALL)|(CONAN))")
      set(EMIT_${field}
          ${EMIT_${field}}
          PARENT_SCOPE)
      continue()
    endif()
    if("${${field}}" MATCHES "[0-9]+.[0-9]+.[0-9]+")
      set(EMIT_${field}
          ${EMIT_${field}}
          PARENT_SCOPE)
      continue()
    endif()

    string(REGEX REPLACE "((ON)|(on)|(YES)|(yes))" "${Green}\\1${ColorReset}"
                         EMIT_${field} "${EMIT_${field}}")
    string(REGEX REPLACE "((OFF)|(off)|(NO)|no)" "${Red}\\1${ColorReset}"
                         EMIT_${field} "${EMIT_${field}}")

    set(EMIT_${field}
        ${EMIT_${field}}
        PARENT_SCOPE)
  endforeach()
endfunction()

#[[.rst:
.. cmake:command:: libra_config_summary_row

  Add a custom row to the LIBRA configuration summary feature table.

  Intended for use in ``project-local.cmake`` to extend the LIBRA summary with
  project-specific configuration options, displayed in the same style and
  column alignment as built-in LIBRA rows.

  Must be called **after** :cmake:command:`libra_config_summary` has been
  called (or from within a ``project-local.cmake`` that is included before
  LIBRA emits the summary), so that
  :cmake:command:`libra_config_summary_prepare_fields` has already run and the
  ``EMIT_`` variable for the status field is populated.

  **Signature:**

  .. code-block:: cmake

     libra_config_summary_row(
         LABEL    <string>
         STATUS   <variable-name>
         VARIABLE <string>
     )

  :param LABEL: Feature description shown in column 1. Will be truncated/padded
   to determined column width.

  :param STATUS: Name of an EMIT_<X> variable (prepared via
   :cmake:command:`libra_config_summary_prepare_fields()`) whose value is shown
   in column 2.

  :param VARIABLE: Variable name shown in column 3, e.g. "[MY_OPTION]". Pass ""
   to leave blank.

  **Example:**

  .. code-block:: cmake

    # In project-local.cmake, after calling libra_config_summary_prepare_fields
    # on your own fields:
    set(my_fields MY_BACKEND MY_FEATURE_X)
    libra_config_summary_prepare_fields("${my_fields}")

    libra_config_summary()  # emits LIBRA rows first

    libra_config_summary_row(
        LABEL    "Backend type........................."
        STATUS   EMIT_MY_BACKEND
        VARIABLE "[MY_BACKEND]")

    libra_config_summary_row(
        LABEL    "Enable feature X....................."
        STATUS   EMIT_MY_FEATURE_X
        VARIABLE "[MY_FEATURE_X]")

  **Notes:**

  - The ``LABEL`` string should use trailing ``.`` characters to reach the
    column width (``_LIBRA_SUMMARY_COL_FEATURE`` = 40), matching the style of
    built-in rows. If shorter, it will be right-padded with spaces
    automatically. If longer, it will be silently truncated to fit.
  - The ``STATUS`` argument is the **name** of a variable (not its value), so
    pass ``EMIT_MY_VAR`` not ``${EMIT_MY_VAR}``. This matches the calling
    convention of the internal ``_libra_summary_row`` helper.
  - Call :cmake:command:`libra_config_summary_prepare_fields` on your custom
    fields before calling this function so the ``EMIT_`` variables exist and
    are colorized.

  **See Also:**

  - :cmake:command:`libra_config_summary`
  - :cmake:command:`libra_config_summary_prepare_fields`
  - :cmake:command:`libra_config_summary_target_block`

]]
function(libra_config_summary_row)
  cmake_parse_arguments(
    ARG
    ""
    "LABEL;STATUS;VARIABLE"
    ""
    ${ARGN})

  if(NOT ARG_LABEL)
    libra_error("libra_config_summary_row: LABEL is required")
  endif()
  if(NOT ARG_STATUS)
    libra_error("libra_config_summary_row: STATUS is required")
  endif()

  # VARIABLE is optional -- default to empty string
  if(NOT DEFINED ARG_VARIABLE)
    set(ARG_VARIABLE "")
  endif()

  _libra_summary_row("${ARG_LABEL}" ${ARG_STATUS} "${ARG_VARIABLE}")
endfunction()

#[[.rst:
.. cmake:command:: libra_config_summary_target_block

  Register a block of targets for display in table 2 of
  :cmake:command:`libra_config_summary`. The purpose is to make it clear which
  targets will/will not be available at build time and *why*.

  Appends target/tool pairs to the global ``_LIBRA_SUMMARY_TARGETS`` list which
  is emitted as a unified table after the main feature table, so all target
  names are padded to a consistent width across all feature groups

  :param OPTION: ``LIBRA_XX`` option that gates all targets.

  :param TARGETS: Flat list of (target, tool_var) pairs. Pass NONE as tool_var
   if target is gated only by OPTION.

  .. code-block:: cmake

     libra_config_summary_target_block(
         OPTION  <variable-name>
         TARGETS <target> <tool-var> ...
     )

  **Example:**

  .. code-block:: cmake

     libra_config_summary_target_block(
         OPTION LIBRA_ANALYSIS
         TARGETS
             analyze              NONE
             analyze-clang-tidy   clang_tidy_EXECUTABLE
             analyze-cppcheck     cppcheck_EXECUTABLE
     )
]]
function(libra_config_summary_target_block)
  cmake_parse_arguments(
    ARG
    ""
    "OPTION"
    "TARGETS"
    ${ARGN})

  if(NOT ARG_OPTION)
    libra_error("libra_config_summary_target_block: OPTION is required")
  endif()
  if(NOT ARG_TARGETS)
    libra_error("libra_config_summary_target_block: TARGETS is required")
  endif()

  # Parse flat (target, tool_var) pairs and append to global accumulator
  set(_toggle ON)
  set(_cur_target "")
  foreach(_item ${ARG_TARGETS})
    if(_toggle)
      set(_cur_target "${_item}")
      set(_toggle OFF)
    else()
      # Append: target;option;tool_var
      list(
        APPEND
        _LIBRA_SUMMARY_TARGETS
        "${_cur_target}"
        "${ARG_OPTION}"
        "${_item}")
      set(_toggle ON)
    endif()
  endforeach()

  set(_LIBRA_SUMMARY_TARGETS
      "${_LIBRA_SUMMARY_TARGETS}"
      CACHE INTERNAL "")
endfunction()

#[[.rst:
.. cmake:command:: libra_config_summary

  Print a comprehensive summary of LIBRA configuration variables to the
  terminal in three sections:

  #. **Feature table** — all LIBRA options with their current values and
     controlling variable names.
  #. **Targets table** — all LIBRA make targets with YES/NO status and reason
     if not available.
  #. **Variable reference** — valid values for all enumerated LIBRA options.

  .. note::
     This function only displays the summary once per configure run.

  **See Also:**

  - :cmake:command:`libra_config_summary_prepare_fields`
  - :cmake:command:`libra_config_summary_target_block`
]]
function(libra_config_summary)
  if(_LIBRA_SHOWED_SUMMARY)
    return()
  endif()

  # Reset target accumulator for this configure run
  set(_LIBRA_SUMMARY_TARGETS
      ""
      CACHE INTERNAL "")

  # Build separator strings
  set(_outer_sep "")
  foreach(_i RANGE 79)
    string(APPEND _outer_sep "-")
  endforeach()
  set(_inner_sep "")
  foreach(_i RANGE ${_LIBRA_SUMMARY_SEP_WIDTH})
    string(APPEND _inner_sep "-")
  endforeach()

  message("${BoldBlue}${_outer_sep}")
  message("${BoldBlue}                           LIBRA Configuration Summary")
  message("${BoldBlue}${_outer_sep}${ColorReset}")
  message("")

  get_filename_component(MAKE_NAME ${CMAKE_MAKE_PROGRAM} NAME)

  set(fields
      LIBRA_VERSION
      LIBRA_DRIVER
      CMAKE_INSTALL_PREFIX
      CMAKE_GENERATOR
      LIBRA_DEPS_PREFIX
      CMAKE_BUILD_TYPE
      CMAKE_SYSTEM_PROCESSOR
      CMAKE_HOST_SYSTEM_PROCESSOR
      CMAKE_C_COMPILER_ID
      CMAKE_CXX_COMPILER_ID
      CMAKE_C_COMPILER_VERSION
      CMAKE_CXX_COMPILER_VERSION
      CMAKE_C_COMPILER
      CMAKE_CXX_COMPILER
      LIBRA_C_STANDARD
      LIBRA_CXX_STANDARD
      LIBRA_GLOBAL_C_FLAGS
      LIBRA_GLOBAL_CXX_FLAGS
      LIBRA_NO_CCACHE
      LIBRA_BUILD_PROF
      LIBRA_NATIVE_OPT
      LIBRA_TESTS
      LIBRA_PGO
      LIBRA_CODE_COV
      LIBRA_DOCS
      LIBRA_FPC
      LIBRA_FPC_EXPORT
      LIBRA_ERL
      LIBRA_ERL_EXPORT
      LIBRA_SAN
      LIBRA_VALGRIND_COMPAT
      LIBRA_ANALYSIS
      LIBRA_LTO
      LIBRA_OPT_REPORT
      LIBRA_STDLIB
      LIBRA_FORTIFY)

  libra_config_summary_prepare_fields("${fields}")

  # Table 1 header
  set(_fh "Feature")
  string(LENGTH "${_fh}" _fhl)
  math(EXPR _fhpad "${_LIBRA_SUMMARY_COL_FEATURE} - ${_fhl}")
  foreach(_s RANGE ${_fhpad})
    string(APPEND _fh " ")
  endforeach()
  set(_sh "Status")
  string(LENGTH "${_sh}" _shl)
  math(EXPR _shpad "${_LIBRA_SUMMARY_COL_STATUS} - ${_shl}")
  foreach(_s RANGE ${_shpad})
    string(APPEND _sh " ")
  endforeach()
  message("${_fh} ${_sh} Variable")
  message("${_inner_sep}")

  # version / generator
  _libra_summary_row("LIBRA version........................."
                     EMIT_LIBRA_VERSION "[LIBRA_VERSION]")
  _libra_summary_row("LIBRA driver.........................." EMIT_LIBRA_DRIVER
                     "[LIBRA_DRIVER]")
  _libra_summary_row("Generator............................."
                     EMIT_CMAKE_GENERATOR "[CMAKE_GENERATOR]")

  message("")

  # paths
  _libra_summary_row("Install prefix........................"
                     EMIT_CMAKE_INSTALL_PREFIX "[CMAKE_INSTALL_PREFIX]")
  if("${LIBRA_DRIVER}" MATCHES "SELF")
    _libra_summary_row("Project dependencies prefix..........."
                       EMIT_LIBRA_DEPS_PREFIX "[LIBRA_DEPS_PREFIX]")
  endif()

  message("")

  # build info
  _libra_summary_row("Build type............................"
                     EMIT_CMAKE_BUILD_TYPE "[CMAKE_BUILD_TYPE]")
  _libra_summary_row(
    "Host architecture....................." EMIT_CMAKE_HOST_SYSTEM_PROCESSOR
    "[CMAKE_HOST_SYSTEM_PROCESSOR]")
  _libra_summary_row("Build target architecture............."
                     EMIT_CMAKE_SYSTEM_PROCESSOR "[CMAKE_SYSTEM_PROCESSOR]")

  message("")

  # compiler
  _libra_summary_row("C Compiler ID........................."
                     EMIT_CMAKE_C_COMPILER_ID "[CMAKE_C_COMPILER_ID]")
  _libra_summary_row("C++ Compiler ID......................."
                     EMIT_CMAKE_CXX_COMPILER_ID "[CMAKE_CXX_COMPILER_ID]")
  _libra_summary_row("C Compiler version...................."
                     EMIT_CMAKE_C_COMPILER_VERSION "[CMAKE_C_COMPILER_VERSION]")
  _libra_summary_row(
    "C++ Compiler version.................." EMIT_CMAKE_CXX_COMPILER_VERSION
    "[CMAKE_CXX_COMPILER_VERSION]")
  _libra_summary_row("C Compiler path......................."
                     EMIT_CMAKE_C_COMPILER "[CMAKE_C_COMPILER]")
  _libra_summary_row("C++ Compiler path....................."
                     EMIT_CMAKE_CXX_COMPILER "[CMAKE_CXX_COMPILER]")
  _libra_summary_row("C std................................."
                     EMIT_LIBRA_C_STANDARD "[CMAKE_C_STANDARD]")
  _libra_summary_row("C++ std..............................."
                     EMIT_LIBRA_CXX_STANDARD "[CMAKE_CXX_STANDARD]")
  _libra_summary_row("Global C flags........................"
                     EMIT_LIBRA_GLOBAL_C_FLAGS "[LIBRA_GLOBAL_C_FLAGS]")
  _libra_summary_row("Global C++ flags......................"
                     EMIT_LIBRA_GLOBAL_CXX_FLAGS "[LIBRA_GLOBAL_CXX_FLAGS]")

  message("")

  # LIBRA features
  _libra_summary_row("Build tests..........................." EMIT_LIBRA_TESTS
                     "[LIBRA_TESTS]")
  _libra_summary_row("PGO..................................." EMIT_LIBRA_PGO
                     "[LIBRA_PGO]")
  _libra_summary_row("Code coverage instrumentation........."
                     EMIT_LIBRA_CODE_COV "[LIBRA_CODE_COV]")
  _libra_summary_row("Native optimization options..........."
                     EMIT_LIBRA_NATIVE_OPT "[LIBRA_NATIVE_OPT]")
  _libra_summary_row("Disable ccache........................"
                     EMIT_LIBRA_NO_CCACHE "[LIBRA_NO_CCACHE]")
  _libra_summary_row("Enable build profiling................"
                     EMIT_LIBRA_BUILD_PROF "[LIBRA_BUILD_PROF]")
  _libra_summary_row("Enable LTO............................" EMIT_LIBRA_LTO
                     "[LIBRA_LTO]")
  _libra_summary_row("Function Precondition Checking (FPC).." EMIT_LIBRA_FPC
                     "[LIBRA_FPC]")
  _libra_summary_row("FPC Export............................"
                     EMIT_LIBRA_FPC_EXPORT "[LIBRA_FPC_EXPORT]")
  _libra_summary_row("Event reporting level (ERL)..........." EMIT_LIBRA_ERL
                     "[LIBRA_ERL]")
  _libra_summary_row("ERL Export............................"
                     EMIT_LIBRA_ERL_EXPORT "[LIBRA_ERL_EXPORT]")
  _libra_summary_row("Sanitizers............................" EMIT_LIBRA_SAN
                     "[LIBRA_SAN]")
  _libra_summary_row("Enable Valgrind compatibility........."
                     EMIT_LIBRA_VALGRIND_COMPAT "[LIBRA_VALGRIND_COMPAT]")
  _libra_summary_row("Stdlib options........................" EMIT_LIBRA_STDLIB
                     "[LIBRA_STDLIB]")
  _libra_summary_row("Fortify build........................."
                     EMIT_LIBRA_FORTIFY "[LIBRA_FORTIFY]")
  _libra_summary_row("Enable API doc tools.................." EMIT_LIBRA_DOCS
                     "[LIBRA_DOCS]")
  _libra_summary_row("Enable code analysis/format/fix......."
                     EMIT_LIBRA_ANALYSIS "[LIBRA_ANALYSIS]")
  _libra_summary_row("Enable optimization reports..........."
                     EMIT_LIBRA_OPT_REPORT "[LIBRA_OPT_REPORT]")

  message("${_inner_sep}")

  # Register all target blocks
  libra_config_summary_target_block(
    OPTION
    LIBRA_TESTS
    TARGETS
    all-tests
    NONE
    unit-tests
    NONE
    integration-tests
    NONE
    build-and-test
    NONE)

  libra_config_summary_target_block(
    OPTION
    LIBRA_DOCS
    TARGETS
    apidoc
    DOXYGEN_EXECUTABLE
    apidoc-check-clang
    clang_EXECUTABLE)

  libra_config_summary_target_block(
    OPTION
    LIBRA_CODE_COV
    TARGETS
    lcov-preinfo
    LCOV_EXECUTABLE
    lcov-report
    LCOV_EXECUTABLE
    gcovr-report
    gcovr_EXECUTABLE
    gcovr-check
    gcovr_EXECUTABLE
    llvm-summary
    LLVM_COV_TOOL
    llvm-show
    LLVM_COV_TOOL
    llvm-report-coverage
    LLVM_COV_TOOL
    llvm-export-lcov
    LLVM_COV_TOOL)

  libra_config_summary_target_block(
    OPTION
    LIBRA_ANALYSIS
    TARGETS
    analyze
    NONE
    analyze-clang-tidy
    clang_tidy_EXECUTABLE
    analyze-clang-check
    clang_check_EXECUTABLE
    analyze-cppcheck
    cppcheck_EXECUTABLE
    analyze-cmake-format
    cmake_format_EXECUTABLE)

  libra_config_summary_target_block(
    OPTION
    LIBRA_ANALYSIS
    TARGETS
    format
    NONE
    format-clang-format
    clang_format_EXECUTABLE
    format-cmake-format
    cmake_format_EXECUTABLE)

  libra_config_summary_target_block(
    OPTION
    LIBRA_ANALYSIS
    TARGETS
    fix
    NONE
    fix-clang-tidy
    clang_tidy_EXECUTABLE
    fix-clang-check
    clang_check_EXECUTABLE)

  # Emit table 2 (targets) and table 3 (variable reference)
  _libra_summary_emit_targets()
  _libra_summary_emit_variable_ref()

  message("")
  message("${BoldBlue}${_outer_sep}${ColorReset}")

  set(_LIBRA_SHOWED_SUMMARY
      YES
      PARENT_SCOPE)
endfunction()

# ##############################################################################
# Internal helper: emit one row of table 1 (feature + status + variable)
# ##############################################################################
function(_libra_summary_row FEATURE_LABEL STATUS_VAR VARIABLE_NAME)
  # Pad feature label to _LIBRA_SUMMARY_COL_FEATURE
  set(_feat "${FEATURE_LABEL}")
  string(LENGTH "${_feat}" _len)
  math(EXPR _pad "${_LIBRA_SUMMARY_COL_FEATURE} - ${_len}")
  if(_pad GREATER 0)
    foreach(_s RANGE ${_pad})
      string(APPEND _feat " ")
    endforeach()
  endif()

  # Status is already padded/colorized via EMIT_ variable
  set(_stat "${${STATUS_VAR}}")

  # Pad variable name to _LIBRA_SUMMARY_COL_VARIABLE
  set(_var "${VARIABLE_NAME}")
  string(LENGTH "${_var}" _vlen)
  math(EXPR _vpad "${_LIBRA_SUMMARY_COL_VARIABLE} - ${_vlen}")
  if(_vpad GREATER 0)
    foreach(_s RANGE ${_vpad})
      string(APPEND _var " ")
    endforeach()
  endif()

  message("${_feat} ${_stat} ${_var}")
endfunction()

# ##############################################################################
# Internal: emit table 2 (targets)
# ##############################################################################
function(_libra_summary_emit_targets)
  if(NOT _LIBRA_SUMMARY_TARGETS)
    return()
  endif()

  # Build separator string
  set(_sep "")
  foreach(_i RANGE ${_LIBRA_SUMMARY_SEP_WIDTH})
    string(APPEND _sep "-")
  endforeach()

  message("")
  message("Targets")
  message("${_sep}")

  # Header
  set(_th "Target")
  string(LENGTH "${_th}" _thl)
  math(EXPR _thpad "${_LIBRA_SUMMARY_COL_TARGET} - ${_thl}")
  foreach(_s RANGE ${_thpad})
    string(APPEND _th " ")
  endforeach()
  message("${_th}  Status  Reason")
  message("${_sep}")

  list(LENGTH _LIBRA_SUMMARY_TARGETS _total)

  # Emit rows - pad to fixed column width so status column is always aligned
  # regardless of color escape sequences in the status value
  set(_i 0)
  while(_i LESS _total)
    list(GET _LIBRA_SUMMARY_TARGETS ${_i} _tname)
    math(EXPR _oi "${_i} + 1")
    math(EXPR _ti "${_i} + 2")
    list(GET _LIBRA_SUMMARY_TARGETS ${_oi} _option)
    list(GET _LIBRA_SUMMARY_TARGETS ${_ti} _tool_var)

    set(_padded "${_tname}")
    string(LENGTH "${_tname}" _len)
    math(EXPR _nsp "${_LIBRA_SUMMARY_COL_TARGET} - ${_len}")
    if(_nsp GREATER 0)
      foreach(_s RANGE ${_nsp})
        string(APPEND _padded " ")
      endforeach()
    endif()

    # Determine status and reason
    if(NOT ${_option})
      set(_status "${Red}NO ${ColorReset}")
      set(_reason "${_option}=OFF")
    elseif(NOT "${_tool_var}" STREQUAL "NONE" AND NOT ${_tool_var})
      string(REPLACE "_EXECUTABLE" "" _tool_name "${_tool_var}")
      string(REPLACE "_TOOL" "" _tool_name "${_tool_name}")
      string(REPLACE "_" "-" _tool_name "${_tool_name}")
      string(TOLOWER "${_tool_name}" _tool_name)
      set(_status "${Red}NO ${ColorReset}")
      set(_reason "${_tool_name} not found")
    else()
      set(_status "${Green}YES${ColorReset}")
      set(_reason "")
    endif()

    message("${_padded}  ${_status}     ${_reason}")
    math(EXPR _i "${_i} + 3")
  endwhile()

  message("${_sep}")
endfunction()

# ##############################################################################
# Internal: emit table 3 (variable reference)
# ##############################################################################
function(_libra_summary_emit_variable_ref)
  set(_sep "")
  foreach(_i RANGE ${_LIBRA_SUMMARY_SEP_WIDTH})
    string(APPEND _sep "-")
  endforeach()

  message("")
  message("Variable Reference")
  message("${_sep}")

  set(_refs
      "LIBRA_DRIVER"
      "SELF|CONAN"
      "LIBRA_PGO"
      "NONE|GEN|USE"
      "LIBRA_FPC"
      "RETURN|ABORT|NONE|INHERIT"
      "LIBRA_ERL"
      "FATAL|ERROR|WARN|INFO|DEBUG|TRACE|ALL|NONE|INHERIT"
      "LIBRA_SAN"
      "MSAN|ASAN|SSAN|TSAN"
      "LIBRA_STDLIB"
      "NONE|STDCXX|CXX"
      "LIBRA_FORTIFY"
      "NONE|STACK|SOURCE|ALL")

  # Compute max key width
  set(_maxkey 0)
  set(_i 0)
  list(LENGTH _refs _total)
  while(_i LESS _total)
    list(GET _refs ${_i} _key)
    string(LENGTH "${_key}" _klen)
    if(_klen GREATER _maxkey)
      set(_maxkey ${_klen})
    endif()
    math(EXPR _i "${_i} + 2")
  endwhile()

  # Emit header after _maxkey is known
  set(_vh "Variable")
  string(LENGTH "${_vh}" _vhl)
  math(EXPR _vhpad "${_maxkey} - ${_vhl}")
  foreach(_s RANGE ${_vhpad})
    string(APPEND _vh " ")
  endforeach()
  message("${_vh}  Valid Values")
  message("${_sep}")

  set(_i 0)
  while(_i LESS _total)
    list(GET _refs ${_i} _key)
    math(EXPR _vi "${_i} + 1")
    list(GET _refs ${_vi} _val)

    set(_kpadded "${_key}")
    string(LENGTH "${_key}" _klen)
    math(EXPR _kpad "${_maxkey} - ${_klen}")
    foreach(_s RANGE ${_kpad})
      string(APPEND _kpadded " ")
    endforeach()

    message("${_kpadded}  ${_val}")
    math(EXPR _i "${_i} + 2")
  endwhile()

  message("${_sep}")
endfunction()
