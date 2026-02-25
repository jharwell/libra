#
# Copyright 2026 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#
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

  **Available Variables for INFILE Template:**

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
    for building (excludes diagnostic flags like ``-W``).

  - ``LIBRA_TARGET_FLAGS_LINK`` - The configured linker flags relevant for
    building (excludes diagnostic flags like ``-W``). Note that IPO related
    flags for GCC/clang do *not* appear here, because CMake relies on the
    compiler driver to inject those into actual compiler commands during the
    final link if the compiler sees that IPO is active at compile time. This is
    not true for the Intel compilers.

  You can also use any standard CMake variables (e.g.,
  ``CMAKE_C_FLAGS_RELEASE``, ``PROJECT_VERSION``, ``CMAKE_BUILD_TYPE``, etc.).

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
