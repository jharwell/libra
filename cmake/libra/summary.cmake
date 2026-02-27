#
# Copyright 2026 John Harwell, All rights reserved.
#
# SPDX-License-Identifier: MIT
#
# ##############################################################################
# Public API
# ##############################################################################
set(_LIBRA_SHOWED_SUMMARY NO)

# Column width constants
set(_LIBRA_SUMMARY_COL_FEATURE 37) # Feature description
set(_LIBRA_SUMMARY_COL_STATUS 46) # Status/value
set(_LIBRA_SUMMARY_COL_VARIABLE 33) # [VARIABLE_NAME]
set(_LIBRA_SUMMARY_COL_TARGET 22) # make target name
set(_LIBRA_SUMMARY_SEP_WIDTH 80) # inner separator width

# ##############################################################################
# Public API
# ##############################################################################

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
   to the column width.

  :param STATUS: Name of an ``EMIT_<X>`` variable (prepared via
   :cmake:command:`libra_config_summary_prepare_fields`) whose value is shown
   in column 2.

  :param VARIABLE: Variable name shown in column 3, e.g. ``[MY_OPTION]``. Pass
   ``""`` to leave blank.

  **Example:**

  .. code-block:: cmake

    set(my_fields MY_BACKEND MY_FEATURE_X)
    libra_config_summary_prepare_fields("${my_fields}")

    libra_config_summary()

    libra_config_summary_row(
        LABEL    "Backend type........................."
        STATUS   EMIT_MY_BACKEND
        VARIABLE "[MY_BACKEND]")

    libra_config_summary_row(
        LABEL    "Enable feature X....................."
        STATUS   EMIT_MY_FEATURE_X
        VARIABLE "[MY_FEATURE_X]")

  **Notes:**

  - ``LABEL`` should use trailing ``.`` characters to reach the column width
    (``_LIBRA_SUMMARY_COL_FEATURE`` = 37), matching the style of built-in rows.
    Shorter labels are right-padded with spaces automatically; longer labels are
    truncated to fit.
  - ``STATUS`` is the **name** of a variable, not its value — pass
    ``EMIT_MY_VAR``, not ``${EMIT_MY_VAR}``.
  - Call :cmake:command:`libra_config_summary_prepare_fields` on your custom
    fields before calling this function so the ``EMIT_`` variables exist and
    are colorized.

  **See Also:**

  - :cmake:command:`libra_config_summary`
  - :cmake:command:`libra_config_summary_prepare_fields`
  - :cmake:command:`libra_help_targets_block`
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

  if(NOT DEFINED ARG_VARIABLE)
    set(ARG_VARIABLE "")
  endif()

  _libra_summary_row("${ARG_LABEL}" ${ARG_STATUS} "${ARG_VARIABLE}")
endfunction()

#[[.rst:
.. cmake:command:: libra_config_summary

  Print a summary of the current LIBRA configuration to the terminal during
  ``cmake`` configure. Displays the feature table (table 1) only: all LIBRA
  options with their current values and controlling variable names.

  For additional information available after configure:

  - ``make help-targets`` — shows all LIBRA make targets with YES/NO
    availability status and the reason each unavailable target is disabled.
  - ``make help-vars``    — shows all enumerated LIBRA option variables with
    their valid values.

  .. note::
     This function only displays the summary once per configure run.

  **See Also:**

  - :cmake:command:`libra_config_summary_prepare_fields`
  - :cmake:command:`libra_config_summary_row`
  - :cmake:command:`libra_help_targets_block`
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
      LIBRA_FORTIFY
      LIBRA_USE_COMPDB
      LIBRA_CPPCHECK_IGNORES
      LIBRA_CPPCHECK_SUPPRESSIONS
      LIBRA_CPPCHECK_EXTRA_ARGS
      LIBRA_CLANG_FORMAT_FILEPATH
      LIBRA_CLANG_TIDY_FILEPATH
      LIBRA_CLANG_TIDY_CHECKS_CONFIG
      LIBRA_C_DIAG_CANDIDATES
      LIBRA_CXX_DIAG_CANDIDATES
      LIBRA_TEST_HARNESS_LIBS
      LIBRA_TEST_HARNESS_PACKAGES
      LIBRA_TEST_HARNESS_MATCHER
      LIBRA_UNIT_TEST_MATCHER
      LIBRA_INTEGRATION_TEST_MATCHER
      LIBRA_REGRESSION_TEST_MATCHER
      LIBRA_CTEST_INCLUDE_UNIT_TESTS
      LIBRA_CTEST_INCLUDE_INTEGRATION_TESTS
      LIBRA_CTEST_INCLUDE_REGRESSION_TESTS
      LIBRA_GCOVR_LINES_THRESH
      LIBRA_GCOVR_FUNCTIONS_THRESH
      LIBRA_GCOVR_DECISIONS_THRESH
      LIBRA_GCOVR_BRANCHES_THRESH)

  libra_config_summary_prepare_fields("${fields}")

  # Header
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
  _libra_summary_row("Use compilation database.............."
                     EMIT_LIBRA_USE_COMPDB "[LIBRA_USE_COMPDB]")

  message("")
  if(LIBRA_ANALYSIS)
    _libra_summary_row("cppcheck ignores......................"
                       EMIT_LIBRA_CPPCHECK_IGNORES "[LIBRA_CPPCHECK_IGNORES]")
    _libra_summary_row(
      "cppcheck suppressions................." EMIT_LIBRA_CPPCHECK_SUPPRESSIONS
      "[LIBRA_CPPCHECK_SUPPRESSIONS]")
    _libra_summary_row(
      "cppcheck extra args..................." EMIT_LIBRA_CPPCHECK_EXTRA_ARGS
      "[LIBRA_CPPCHECK_EXTRA_ARGS]")
    _libra_summary_row(
      "clang-format filepath................." EMIT_LIBRA_CLANG_FORMAT_FILEPATH
      "[LIBRA_CLANG_FORMAT_FILEPATH]")
    _libra_summary_row(
      "clang-tidy filepath..................." EMIT_LIBRA_CLANG_TIDY_FILEPATH
      "[LIBRA_CLANG_TIDY_FILEPATH]")
    _libra_summary_row(
      "clang-tidy checks....................."
      EMIT_LIBRA_CLANG_TIDY_CHECKS_CONFIG "[LIBRA_CLANG_TIDY_CHECKS_CONFIG]")

  endif()
  if(LIBRA_TESTS)
    _libra_summary_row("Test harness libs....................."
                       EMIT_LIBRA_TEST_HARNESS_LIBS "[LIBRA_TEST_HARNESS_LIBS]")
    _libra_summary_row(
      "Test harness packages................." EMIT_LIBRA_TEST_HARNESS_PACKAGES
      "[LIBRA_TEST_HARNESS_PACKAGES]")
    _libra_summary_row(
      "Test harness matchere................." EMIT_LIBRA_TEST_HARNESS_MATCHER
      "[LIBRA_TEST_HARNESS_MATCHER]")
    _libra_summary_row("Unit test matcher....................."
                       EMIT_LIBRA_UNIT_TEST_MATCHER "[LIBRA_UNIT_TEST_MATCHER]")
    _libra_summary_row(
      "Integration test matcher.............."
      EMIT_LIBRA_INTEGRATION_TEST_MATCHER "[LIBRA_INTEGRATION_TEST_MATCHER]")
    _libra_summary_row(
      "Regression test matcher..............."
      EMIT_LIBRA_REGRESSION_TEST_MATCHER "[LIBRA_REGRESSION_TEST_MATCHER]")
    _libra_summary_row(
      "CTest include unit tests.............."
      EMIT_LIBRA_CTEST_INCLUDE_UNIT_TESTS "[LIBRA_CTEST_INCLUDE_UNIT_TESTS]")
    _libra_summary_row(
      "CTest include integration tests......."
      EMIT_LIBRA_CTEST_INCLUDE_INTEGRATION_TESTS
      "[LIBRA_CTEST_INCLUDE_INTEGRATION_TESTS]")
    _libra_summary_row(
      "CTest include regression tests........"
      EMIT_LIBRA_CTEST_INCLUDE_REGRESSION_TESTS
      "[LIBRA_CTEST_INCLUDE_REGRESSION_TESTS]")
  endif()

  if(LIBRA_CODE_COV)
    _libra_summary_row(
      "gcovr lines threshold................." EMIT_LIBRA_GCOVR_LINES_THRESH
      "[LIBRA_GCOVR_LINES_THRESH]")
    _libra_summary_row(
      "gcovr functions threshold............."
      EMIT_LIBRA_GCOVR_FUNCTIONS_THRESH "[LIBRA_GCOVR_FUNCTIONS_THRESH]")
    _libra_summary_row(
      "gcovr branches threshold.............." EMIT_LIBRA_GCOVR_BRANCHES_THRESH
      "[LIBRA_GCOVR_BRANCHES_THRESH]")
    _libra_summary_row(
      "gcovr decisions threshold............."
      EMIT_LIBRA_GCOVR_DECISIONS_THRESH "[LIBRA_GCOVR_DECISIONS_THRESH]")
  endif()
  message("${BoldBlue}${_outer_sep}${ColorReset}")

  set(_LIBRA_SHOWED_SUMMARY
      YES
      PARENT_SCOPE)
endfunction()

# ##############################################################################
# Private API
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

# Register a block of targets for display via the ``help-targets`` make target.
# The purpose is to make it clear which targets will/will not be available at
# build time and *why*.
#
# :param OPTION: ``LIBRA_XX`` option that gates all targets in this block.
#
# :param TARGETS: Flat list of ``(target, tool_var)`` pairs. Pass ``NONE`` as
# ``tool_var`` if a target is gated only by ``OPTION`` with no additional tool
# dependency.
#
# .. code-block:: cmake
#
# libra_help_targets_block( OPTION  <variable-name> TARGETS <target> <tool-var>
# ... )
#
# **Example:**
#
# .. code-block:: cmake
#
# libra_help_targets_block( OPTION LIBRA_ANALYSIS TARGETS analyze NONE
# analyze-clang-tidy   clang_tidy_EXECUTABLE analyze-cppcheck
# cppcheck_EXECUTABLE )
#
function(_libra_help_targets_block)
  cmake_parse_arguments(
    ARG
    ""
    "OPTION"
    "TARGETS"
    ${ARGN})

  if(NOT ARG_OPTION)
    libra_error("libra_help_targets_block: OPTION is required")
  endif()
  if(NOT ARG_TARGETS)
    libra_error("libra_help_targets_block: TARGETS is required")
  endif()

  # Parse flat (target, tool_var) pairs and append to global accumulator
  set(_toggle ON)
  set(_cur_target "")
  foreach(_item ${ARG_TARGETS})
    if(_toggle)
      set(_cur_target "${_item}")
      set(_toggle OFF)
    else()
      list(
        APPEND
        _LIBRA_SUMMARY_TARGETS
        "${_cur_target}"
        "${ARG_OPTION}"
        "${_item}")
      set(_toggle ON)
    endif()
  endforeach()

endfunction()

# Create help-targets build target

function(_libra_create_help_targets)
  # Register all target blocks for help-targets
  _libra_help_targets_block(
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

  _libra_help_targets_block(
    OPTION
    LIBRA_DOCS
    TARGETS
    apidoc
    DOXYGEN_EXECUTABLE
    apidoc-check-clang
    clang_EXECUTABLE)

  _libra_help_targets_block(
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

  _libra_help_targets_block(
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

  _libra_help_targets_block(
    OPTION
    LIBRA_ANALYSIS
    TARGETS
    format
    NONE
    format-clang-format
    clang_format_EXECUTABLE
    format-cmake-format
    cmake_format_EXECUTABLE)

  _libra_help_targets_block(
    OPTION
    LIBRA_ANALYSIS
    TARGETS
    fix
    NONE
    fix-clang-tidy
    clang_tidy_EXECUTABLE
    fix-clang-check
    clang_check_EXECUTABLE)

  # _LIBRA_SUMMARY_TARGETS is a CMake list (semicolons) and cannot be passed
  # safely as a -D argument on the command line -- the shell splits on
  # semicolons before CMake sees them. Instead, write the list to a small CMake
  # file at configure time and have the script include() it.
  set(_this_script "${CMAKE_CURRENT_LIST_DIR}/summary_help.cmake")
  set(_targets_file "${CMAKE_BINARY_DIR}/libra_summary_targets.cmake")

  # Write the target list and all referenced option/tool values into a cmake
  # file at configure time when they are fully resolved. This avoids both the
  # semicolon-in-list -D problem and the load_cache() problem of needing
  # variable names known ahead of time in script mode.
  file(WRITE "${_targets_file}"
       "set(_LIBRA_SUMMARY_TARGETS ${_LIBRA_SUMMARY_TARGETS})\n")
  set(_tw_i 0)
  list(LENGTH _LIBRA_SUMMARY_TARGETS _tw_len)
  while(_tw_i LESS _tw_len)
    math(EXPR _tw_i1 "${_tw_i} + 1")
    math(EXPR _tw_i2 "${_tw_i} + 2")
    list(GET _LIBRA_SUMMARY_TARGETS ${_tw_i} _tw_name)
    list(GET _LIBRA_SUMMARY_TARGETS ${_tw_i1} _tw_opt)
    list(GET _LIBRA_SUMMARY_TARGETS ${_tw_i2} _tw_tool)
    # Write the triple
    file(
      APPEND "${_targets_file}"
      "list(APPEND _LIBRA_SUMMARY_TARGETS [[${_tw_name}]] [[${_tw_opt}]] [[${_tw_tool}]])\n"
    )
    # Write resolved option value
    if(${_tw_opt})
      file(APPEND "${_targets_file}" "set([[${_tw_opt}]] ON)\n")
    else()
      file(APPEND "${_targets_file}" "set([[${_tw_opt}]] OFF)\n")
    endif()
    # Write resolved tool path (empty string if not found)
    if(NOT _tw_tool STREQUAL "NONE")
      file(APPEND "${_targets_file}"
           "set([[${_tw_tool}]] [[${${_tw_tool}}]])\n")
    endif()
    math(EXPR _tw_i "${_tw_i} + 3")
  endwhile()

  if(NOT TARGET help-targets)
    add_custom_target(
      help-targets
      COMMAND
        ${CMAKE_COMMAND} -D LIBRA_HELP_MODE=TARGETS -D
        LIBRA_TARGETS_FILE=${_targets_file} -D
        _LIBRA_SUMMARY_COL_TARGET=${_LIBRA_SUMMARY_COL_TARGET} -D
        _LIBRA_SUMMARY_SEP_WIDTH=${_LIBRA_SUMMARY_SEP_WIDTH} -P
        "${_this_script}"
      VERBATIM
      COMMENT "LIBRA target availability"
      USES_TERMINAL)
  endif()
endfunction()

_libra_create_help_targets()
