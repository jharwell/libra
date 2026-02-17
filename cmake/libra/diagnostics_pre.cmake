#
# Copyright 2026 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#
# ##############################################################################
# Summary                                                                      #
# ##############################################################################
# Only want to show the summary once
set(_LIBRA_SHOWED_SUMMARY NO)

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


  :param FIELDS: List of field names (variable names) to prepare for
   display. Each field will have a corresponding ``EMIT_<field>`` variable
   created in the parent scope that contains the padded and colorized value.

  **Colorization Rules:**

  - ``ON``, ``on``, ``YES``, ``yes`` - Displayed in green
  - ``OFF``, ``off``, ``NO``, ``no`` - Displayed in red
  - Special strings (``NONE``, ``ALL``, ``CONAN``) - No colorization
  - Version numbers (``x.y.z`` format) - No colorization

  **Example:**

  .. code-block:: cmake

    set(MY_FIELDS
      CMAKE_BUILD_TYPE
      LIBRA_TESTS
      LIBRA_CODE_COV)

    libra_config_summary_prepare_fields("${MY_FIELDS}")

    # Now you can use EMIT_CMAKE_BUILD_TYPE, EMIT_LIBRA_TESTS, etc.
    message(STATUS "Build type: ${EMIT_CMAKE_BUILD_TYPE}")
    message(STATUS "Tests: ${EMIT_LIBRA_TESTS}")
]]
function(libra_config_summary_prepare_fields FIELDS)
  # Validate input
  if(NOT FIELDS)
    libra_message(
      WARNING "libra_config_summary_prepare_fields: No fields provided\n"
      "  Pass a list of variable names to prepare for display")
    return()
  endif()

  # Get maxlength of summary field value for padding so everything lines up
  # nicely.
  set(MAXLEN 0)
  foreach(field ${FIELDS})
    list(LENGTH ${field} LIST_LEN)
    if(LIST_LEN GREATER 1)
      string(REPLACE ";" " " OUT "${${field}}") # Joins list elements with a
                                                # space
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

  # Append the necessary amount of spaces to each summary field value.
  foreach(field ${FIELDS})
    if("${EMIT_${field}}" STREQUAL "")
      set(LEN 0)
    else()
      string(LENGTH ${EMIT_${field}} LEN)
    endif()
    math(EXPR N_SPACES "${MAXLEN} - ${LEN}")

    foreach(n RANGE ${N_SPACES})
      string(APPEND EMIT_${field} " ")
    endforeach()
  endforeach()

  # Iterate over fields, colorizing as needed
  foreach(field ${FIELDS})
    # something with a special string field--nothing to do
    if("${${field}}" MATCHES "((NONE)|(ALL)|(CONAN))")
      set(EMIT_${field}
          ${EMIT_${field}}
          PARENT_SCOPE)
      continue()
    endif()

    # Version #--nothing to do
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
.. cmake:command:: libra_config_summary

  Print a comprehensive summary of LIBRA configuration variables to the
  terminal.

  Displays a nicely formatted, colorized summary of all LIBRA configuration
  variables and their current values. This helps debug the inevitable "Did I
  actually set the variable I thought I did?" questions. Using this function,
  you can see EXACTLY what variable values will be when you invoke your chosen
  build engine.

  The summary includes:

  - LIBRA version and driver mode
  - Generator and build system information
  - Installation paths
  - Build type and architecture
  - Compiler information and standards
  - All LIBRA feature flags (tests, sanitizers, optimizations, etc.)
  - Available make targets for each enabled feature

  **Usage Patterns:**

  You can put this at the end of ``project-local.cmake`` if you want to control
  when LIBRA's configuration summary vs. your project's configuration summary is
  emitted. Otherwise, LIBRA will run it automatically at the end of the
  configure step, as determined by :cmake:variable:`LIBRA_SUMMARY`.

  **Example:**

  .. code-block:: cmake

    # In your CMakeLists.txt or project-local.cmake
    libra_config_summary()

    # Output will show something like:
    # --------------------------------------------------------------------------------
    #                            LIBRA Configuration Summary
    # --------------------------------------------------------------------------------
    # LIBRA version.........................: 0.9.25
    # Build type............................: Release
    # Build tests...........................: ON
    # ...

  .. note::
     This function only displays the summary once per configure run. Subsequent
     calls in the same configure will be ignored.

  **See Also:**

  - :cmake:command:`libra_config_summary_prepare_fields` - Prepare fields for display

]]
function(libra_config_summary)
  # Only show summary once per configure
  if(_LIBRA_SHOWED_SUMMARY)
    return()
  endif()

  message(
    "${BoldBlue}--------------------------------------------------------------------------------"
  )
  message("${BoldBlue}                           LIBRA Configuration Summary")
  message(
    "${BoldBlue}--------------------------------------------------------------------------------"
  )
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
      CMAKE_C_COMPILER
      CMAKE_CXX_COMPILER
      LIBRA_C_STANDARD
      LIBRA_CXX_STANDARD
      LIBRA_GLOBAL_C_FLAGS
      LIBRA_GLOBAL_CXX_FLAGS
      LIBRA_NO_CCACHE
      LIBRA_BUILD_PROF
      LIBRA_NATIVE_OPT
      LIBRA_OPT_LEVEL
      LIBRA_OPT_OPTIONS
      LIBRA_DEBUG_INFO
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

  message(
    STATUS
      "LIBRA version.........................: ${ColorBold}${EMIT_LIBRA_VERSION}${ColorReset} [LIBRA_VERSION]"
  )
  message(
    STATUS
      "LIBRA driver..........................: ${ColorBold}${EMIT_LIBRA_DRIVER}${ColorReset} [LIBRA_DRIVER={SELF,CONAN}]"
  )
  message(
    STATUS
      "Generator.............................: ${ColorBold}${EMIT_CMAKE_GENERATOR}${ColorReset} [CMAKE_GENERATOR]"
  )

  # paths
  message("")
  message(
    STATUS
      "Install prefix........................: ${ColorBold}${EMIT_CMAKE_INSTALL_PREFIX}${ColorReset} [CMAKE_INSTALL_PREFIX]"
  )
  if("${LIBRA_DRIVER}" MATCHES "SELF")
    message(
      STATUS
        "Project dependencies prefix...........: ${ColorBold}${EMIT_LIBRA_DEPS_PREFIX}${ColorReset} [LIBRA_DEPS_PREFIX]"
    )
  endif()

  # build info
  message("")
  message(
    STATUS
      "Build type............................: ${ColorBold}${EMIT_CMAKE_BUILD_TYPE}${ColorReset} [CMAKE_BUILD_TYPE]"
  )
  message(
    STATUS
      "Host architecture.....................: ${ColorBold}${EMIT_CMAKE_HOST_SYSTEM_PROCESSOR}${ColorReset} [CMAKE_HOST_SYSTEM_PROCESSOR]"
  )
  message(
    STATUS
      "Build target architecture.............: ${ColorBold}${EMIT_CMAKE_SYSTEM_PROCESSOR}${ColorReset} [CMAKE_SYSTEM_PROCESSOR]"
  )

  # compiler info
  message(
    STATUS
      "C Compiler............................: ${ColorBold}${EMIT_CMAKE_C_COMPILER}${ColorReset} [CMAKE_C_COMPILER]"
  )
  message(
    STATUS
      "C++ Compiler..........................: ${ColorBold}${EMIT_CMAKE_CXX_COMPILER}${ColorReset} [CMAKE_CXX_COMPILER]"
  )
  message(
    STATUS
      "C std.................................: ${ColorBold}${EMIT_LIBRA_C_STANDARD}${ColorReset} [CMAKE_C_STANDARD]"
  )
  message(
    STATUS
      "C++ std...............................: ${ColorBold}${EMIT_LIBRA_CXX_STANDARD}${ColorReset} [CMAKE_CXX_STANDARD]"
  )
  message(
    STATUS
      "Global C flags........................: ${ColorBold}${EMIT_LIBRA_GLOBAL_C_FLAGS}${ColorReset} [LIBRA_GLOBAL_C_FLAGS]"
  )
  message(
    STATUS
      "Global C++ flags......................: ${ColorBold}${EMIT_LIBRA_GLOBAL_CXX_FLAGS}${ColorReset} [LIBRA_GLOBAL_CXX_FLAGS]"
  )

  message("")
  # LIBRA options
  message(
    STATUS
      "Build tests...........................: ${ColorBold}${EMIT_LIBRA_TESTS}${ColorReset} [LIBRA_TESTS] (${MAKE_NAME} {all-tests,unit-tests,integration-tests,build-and-test) "
  )

  message(
    STATUS
      "PGO...................................: ${ColorBold}${EMIT_LIBRA_PGO}${ColorReset} [LIBRA_PGO={NONE,GEN,USE}]"
  )
  message(
    STATUS
      "Code coverage instrumentation.........: ${ColorBold}${EMIT_LIBRA_CODE_COV}${ColorReset} [LIBRA_CODE_COV] (${MAKE_NAME} {lcov-{preinfo,report}, gcovr-{report,check}, llvm-{summary,show,report-coverage,export-lcov}})"
  )
  message(
    STATUS
      "Optimization level override...........: ${ColorBold}${EMIT_LIBRA_OPT_LEVEL}${ColorReset} [LIBRA_OPT_LEVEL]"
  )

  message(
    STATUS
      "Native optimization options...........: ${ColorBold}${EMIT_LIBRA_NATIVE_OPT}${ColorReset} [LIBRA_NATIVE_OPT]"
  )
  message(
    STATUS
      "Active optimization options...........: ${ColorBold}${EMIT_LIBRA_OPT_OPTIONS}${ColorReset} [LIBRA_OPT_OPTIONS]"
  )
  message(
    STATUS
      "Debug info.............................: ${ColorBold}${EMIT_LIBRA_DEBUG_INFO}${ColorReset} [LIBRA_DEBUG_INFO]"
  )
  message(
    STATUS
      "Disable ccache........................: ${ColorBold}${EMIT_LIBRA_NO_CCACHE}${ColorReset} [LIBRA_NO_CCACHE]"
  )
  message(
    STATUS
      "Enable build profiling................: ${ColorBold}${EMIT_LIBRA_BUILD_PROF}${ColorReset} [LIBRA_BUILD_PROF]"
  )
  message(
    STATUS
      "Enable Link-Time Optimization (LTO)...: ${ColorBold}${EMIT_LIBRA_LTO}${ColorReset} [LIBRA_LTO]"
  )
  message(
    STATUS
      "Function Precondition Checking (FPC)..: ${ColorBold}${EMIT_LIBRA_FPC}${ColorReset} [LIBRA_FPC={RETURN,ABORT,NONE,INHERIT}]"
  )
  message(
    STATUS
      "FPC Export............................: ${ColorBold}${EMIT_LIBRA_FPC_EXPORT}${ColorReset} [LIBRA_FPC_EXPORT]"
  )
  message(
    STATUS
      "Event reporting level (ERL)...........: ${ColorBold}${EMIT_LIBRA_ERL}${ColorReset} [LIBRA_ERL={FATAL,ERROR,WARN,INFO,DEBUG,TRACE,ALL,NONE,INHERIT}]"
  )
  message(
    STATUS
      "ERL Export............................: ${ColorBold}${EMIT_LIBRA_ERL_EXPORT}${ColorReset} [LIBRA_ERL_EXPORT]"
  )
  message(
    STATUS
      "Sanitizers............................: ${ColorBold}${EMIT_LIBRA_SAN}${ColorReset} [LIBRA_SAN={MSAN,ASAN,SSAN,TSAN}]"
  )
  message(
    STATUS
      "Enable Valgrind compatibility.........: ${ColorBold}${EMIT_LIBRA_VALGRIND_COMPAT}${ColorReset} [LIBRA_VALGRIND_COMPAT]"
  )
  message(
    STATUS
      "Stdlib options........................: ${ColorBold}${EMIT_LIBRA_STDLIB}${ColorReset} [LIBRA_STDLIB={NONE,STDCXX,CXX}]"
  )
  message(
    STATUS
      "Fortify build.........................: ${ColorBold}${EMIT_LIBRA_FORTIFY}${ColorReset} [LIBRA_FORTIFY={NONE,STACK,SOURCE,ALL}]"
  )
  message(
    STATUS
      "Enable API doc tools..................: ${ColorBold}${EMIT_LIBRA_DOCS}${ColorReset} [LIBRA_DOCS] (${MAKE_NAME} {apidoc,apidoc-check-{doxygen,clang}})"
  )
  message(
    STATUS
      "Enable code checkers..................: ${ColorBold}${EMIT_LIBRA_ANALYSIS}${ColorReset} [LIBRA_ANALYSIS] (${MAKE_NAME} {analyze,analyze-{clang-{check,tidy,format},cppcheck,cmake-format}})"
  )
  message(
    STATUS
      "Enable code formatters................: ${ColorBold}${EMIT_LIBRA_ANALYSIS}${ColorReset} [LIBRA_ANALYSIS] (${MAKE_NAME} {format,format-{clang-format,cmake-format}})"
  )
  message(
    STATUS
      "Enable code fixers....................: ${ColorBold}${EMIT_LIBRA_ANALYSIS}${ColorReset} [LIBRA_ANALYSIS] (${MAKE_NAME} {fix,fix-{clang-tidy,clang-check}})"
  )
  message(
    STATUS
      "Enable optimization reports...........: ${ColorBold}${EMIT_LIBRA_OPT_REPORT}${ColorReset} [LIBRA_OPT_REPORT]"
  )

  message("")
  message(
    "${BoldBlue}--------------------------------------------------------------------------------${ColorReset}"
  )

  set(_LIBRA_SHOWED_SUMMARY
      YES
      PARENT_SCOPE)
endfunction()

#[[.rst:
.. cmake:command:: libra_configure_source_file

  Populate a source file template with build and git information.

  Use build information from LIBRA and your project to populate a source file
  template. LIBRA automatically adds the generated file to the list of files for
  the main :cmake:variable:`PROJECT_NAME` target. This is useful for printing
  information when your library loads or application starts as a sanity check
  during debugging to help ensure that you are running what you think you
  are. Must be called *after* the :cmake:variable:`PROJECT_NAME` target is
  defined.

  :param TARGET: The target the the configured source file should be added to.

  :param INFILE: The input template file. Should contain CMake variable
   references like ``@LIBRA_GIT_REV@`` that will be replaced with actual values.

  :param OUTFILE: The output file path where the configured file will be
   written.

  **Available Variables for Template:**

  The following variables are available for use in your ``INFILE`` template:

  - ``LIBRA_GIT_REV`` - Git SHA of the current tip. Result of
    ``git log --pretty=format:%H -n 1``.

  - ``LIBRA_GIT_DIFF`` - Indicates if the build is "dirty" (contains local
    changes not in git). Result of ``git diff --quiet --exit-code || echo
    +``. Will be ``+`` if dirty, empty otherwise.

  - ``LIBRA_GIT_TAG`` - The current git tag for the git rev, if any. Result of
    ``git describe --exact-match --tags``.

  - ``LIBRA_GIT_BRANCH`` - The current git branch, if any. Result of
    ``git rev-parse --abbrev-ref HEAD``.

  - ``LIBRA_TARGET_FLAGS_COMPILE`` - The configured compiler flags relevant
    for building (excludes diagnostic flags like ``-W*``).

  - ``LIBRA_TARGET_FLAGS_LINK`` - The configured linker flags relevant for
    building (excludes diagnostic flags like ``-W*``).

  You can also use any standard CMake variables (e.g., ``CMAKE_C_FLAGS_RELEASE``,
  ``PROJECT_VERSION``, ``CMAKE_BUILD_TYPE``, etc.).

  **Example:**

  .. code-block:: cmake

    # In CMakeLists.txt
    set(MY_SOURCES src/main.cpp src/foo.cpp)

    libra_add_executable(${PROJECT_NAME} ${MY_SOURCES})

    libra_configure_source_file(
      ${PROJECT_NAME}
      ${PROJECT_SOURCE_DIR}/src/version.cpp.in
      ${CMAKE_BINARY_DIR}/version.cpp)

  .. code-block:: cpp

    // In src/version.cpp.in
    #include <iostream>

    void print_version() {
      std::cout << "Git Rev: @LIBRA_GIT_REV@@LIBRA_GIT_DIFF@" << std::endl;
      std::cout << "Branch: @LIBRA_GIT_BRANCH@" << std::endl;
      std::cout << "Tag: @LIBRA_GIT_TAG@" << std::endl;
      std::cout << "Build Type: @CMAKE_BUILD_TYPE@" << std::endl;
    }

  .. NOTE::
     If your code is not in a git repository, all git-related fields will be
     stubbed out with ``N/A`` and will not be very useful. A warning will be
     emitted during configuration.

]]
function(libra_configure_source_file TARGET INFILE OUTFILE)
  # Validate arguments
  if(NOT INFILE)
    libra_error("libra_configure_source_file: INFILE is required")
  endif()

  if(NOT OUTFILE)
    libra_error("libra_configure_source_file: OUTFILE is required")
  endif()

  # Check input file exists
  if(NOT EXISTS "${INFILE}")
    libra_error(
      "libra_configure_source_file: Input file does not exist: ${INFILE}")
  endif()

  if(NOT "${INFILE}" IN_LIST _LIBRA_${TARGET}_CONFIGURED_SOURCE_FILES_SRC)
    list(APPEND _LIBRA_${TARGET}_CONFIGURED_SOURCE_FILES_SRC "${INFILE}")
    set(_LIBRA_${TARGET}_CONFIGURED_SOURCE_FILES_SRC
        "${_LIBRA_${TARGET}_CONFIGURED_SOURCE_FILES_SRC}"
        CACHE INTERNAL "")
  endif()

  if(NOT "${OUTFILE}" IN_LIST _LIBRA_${TARGET}_CONFIGURED_SOURCE_FILES_DEST)
    list(APPEND _LIBRA_${TARGET}_CONFIGURED_SOURCE_FILES_DEST "${OUTFILE}")
    set(_LIBRA_${TARGET}_CONFIGURED_SOURCE_FILES_DEST
        "${_LIBRA_${TARGET}_CONFIGURED_SOURCE_FILES_DEST}"
        CACHE INTERNAL "")
  endif()
endfunction()
