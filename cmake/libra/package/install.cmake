#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#
# ##############################################################################
# Custom messaging
# ##############################################################################
include(libra/messaging)
cmake_policy(SET CMP0177 NEW) # Normalize paths

# ##############################################################################
# Exports Configuration
# ##############################################################################
include(GNUInstallDirs)

#[[.rst:
.. cmake:command:: libra_configure_exports

  Configure the exports for a TARGET to be installed at
  ``${CMAKE_INSTALL_PREFIX}``.

  Enables the installed project to be used with ``find_package()`` by downstream
  projects. This function requires a ``cmake/config.cmake.in`` template file in
  your project root.

  To use, ``include(libra/package/install.cmake)``.

  :param TARGET: The target name for which to configure exports. This will be
   used to generate ``<TARGET>-config.cmake`` and must match the name used in
   ``find_package()``. You may need to call this on header-only dependencies to
   get them into the export set for your project. If you do, make sure you do
   *not* add said dependencies to your ``config.cmake.in`` file via
   ``find_dependency()``, as that will cause an infinite loop.

  **Requirements:**

  The function expects a template file at
  ``${PROJECT_SOURCE_DIR}/cmake/config.cmake.in``. This template is processed by
  ``configure_package_config_file()`` to generate the final config file that
  defines everything necessary to use the project with ``find_package()``.

  **Example:**

  .. code-block:: cmake

    libra_configure_exports(mylib)
]]
function(libra_configure_exports)
  # Support both: 1. libra_configure_exports(TARGET mylib) 2.
  # libra_configure_exports(mylib)
  cmake_parse_arguments(
    ARG
    ""
    "TARGET"
    ""
    ${ARGN})

  if(NOT ARG_TARGET AND ARGN)
    list(GET ARGN 0 ARG_TARGET)
  endif()

  if(NOT ARG_TARGET)
    libra_error("libra_configure_exports: TARGET missing")
  endif()

  set(TARGET ${ARG_TARGET})

  include(CMakePackageConfigHelpers)

  # Project exports file (i.e., the file which defines everything necessary to
  # use the project with find_package())
  set(CONFIG_TEMPLATE "${PROJECT_SOURCE_DIR}/cmake/config.cmake.in")

  if(NOT EXISTS "${CONFIG_TEMPLATE}")
    libra_error(
      "libra_configure_exports: Template file not found: ${CONFIG_TEMPLATE}\n"
      "  Create this file to define how your package should be found.\n"
      "  See CMakePackageConfigHelpers documentation for details.")
  endif()

  set(OUTPUT_FILE "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}-config.cmake")

  configure_package_config_file(
    ${CONFIG_TEMPLATE} "${OUTPUT_FILE}"
    INSTALL_DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/${TARGET}")

  # Install the configured exports file
  install(FILES "${OUTPUT_FILE}"
          DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/${TARGET}")

  libra_message(
    STATUS
    "Configured cmake exports for ${TARGET} -> ${CMAKE_INSTALL_LIBDIR}/cmake/${TARGET}"
  )
endfunction()

#[[.rst:
.. cmake:command:: libra_register_extra_configs_for_install

  Register extra .cmake files for a TARGET to be installed at
  ``${CMAKE_INSTALL_PREFIX}``.

  Configure additional ``.cmake`` files/directories for export. Useful if your
  project provides reusable CMake functionality that you want downstream
  projects to access. Supports both individual files and directories (processed
  recursively).

  To use, ``include(libra/package/install.cmake)``.

  :param TARGET: The target name (used for install destination). Must be a
   target for which :cmake:command:`libra_configure_exports` has already been
   called.

  :param FILES_OR_DIRS: One or more .cmake files or directories containing
   .cmake files. Directories are searched recursively, and the directory
   structure is preserved during installation (not flattened).

  **Examples:**

  .. code-block:: cmake

    # Install individual files
    libra_register_extra_configs_for_install(mylib
      cmake/MyLibHelpers.cmake
      cmake/MyLibUtils.cmake)

    # Install entire directory (recursive, structure preserved)
    libra_register_extra_configs_for_install(mylib
      cmake/modules)

    # Mix files and directories
    libra_register_extra_configs_for_install(mylib
      cmake/special.cmake
      cmake/modules)

  .. versionchanged:: 0.9.26
     Can now handle files OR directories of extra configs.
]]
function(libra_register_extra_configs_for_install)
  # Track total number of files
  set(TOTAL_FILES 0)

  # Support both: 1. libra_register_extra_configs_for_install(TARGET mylib
  # FILES_OR_DIRS dir1) 2. libra_register_extra_configs_for_install(mylib dir1
  # dir2)
  cmake_parse_arguments(
    ARG
    ""
    "TARGET"
    "FILES_OR_DIRS"
    ${ARGN})

  if(NOT ARG_TARGET AND ARG_UNPARSED_ARGUMENTS)
    list(GET ARG_UNPARSED_ARGUMENTS 0 ARG_TARGET)
    list(REMOVE_AT ARG_UNPARSED_ARGUMENTS 0)
  endif()

  if(NOT ARG_FILES_OR_DIRS AND ARG_UNPARSED_ARGUMENTS)
    set(ARG_FILES_OR_DIRS ${ARG_UNPARSED_ARGUMENTS})
  endif()

  if(NOT ARG_TARGET)
    libra_error(
      "libra_register_extra_configs_for_install: TARGET argument is required")
  endif()

  if(NOT ARG_FILES_OR_DIRS)
    libra_error(
      "libra_register_extra_configs_for_install: No files or directories specified."
    )
  endif()

  foreach(ITEM ${ARG_FILES_OR_DIRS})
    # Make the path absolute if it's relative
    if(NOT IS_ABSOLUTE "${ITEM}")
      set(ITEM "${CMAKE_CURRENT_SOURCE_DIR}/${ITEM}")
    endif()

    if(IS_DIRECTORY "${ITEM}")
      # It's a directory - find all .cmake files recursively
      file(
        GLOB_RECURSE DIR_CMAKE_FILES
        RELATIVE "${ITEM}"
        "${ITEM}/*.cmake")

      if(DIR_CMAKE_FILES)
        # Install each file maintaining directory structure
        foreach(REL_FILE ${DIR_CMAKE_FILES})
          get_filename_component(REL_DIR "${REL_FILE}" DIRECTORY)
          if(REL_DIR)
            install(
              FILES "${ITEM}/${REL_FILE}"
              DESTINATION
                "${CMAKE_INSTALL_LIBDIR}/cmake/${ARG_TARGET}/${REL_DIR}")
          else()
            install(FILES "${ITEM}/${REL_FILE}"
                    DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/${ARG_TARGET}")
          endif()
          math(EXPR TOTAL_FILES "${TOTAL_FILES} + 1")
        endforeach()
        libra_message(STATUS "Found .cmake file(s) in directory: ${ITEM}")
      endif()

    elseif(EXISTS "${ITEM}")
      # It's a file - validate and add it
      if(ITEM MATCHES "\\.cmake$")
        install(FILES "${ITEM}"
                DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/${ARG_TARGET}")
        math(EXPR TOTAL_FILES "${TOTAL_FILES} + 1")
      else()
        libra_message(
          WARNING
          "libra_register_extra_configs_for_install: '${ITEM}' is not a .cmake file\n"
          "  Only .cmake files can be registered. This file will be skipped.")
      endif()
    else()
      libra_error(
        "libra_register_extra_configs_for_install: '${ITEM}' does not exist\n"
        "  Verify the path is correct and the file/directory exists")
    endif()
  endforeach()

  if(TOTAL_FILES EQUAL 0)
    libra_error(
      "libra_register_extra_configs_for_install: No .cmake files found to install\n"
      "  Check that your files/directories contain .cmake files")
  endif()

  # Print what was registered
  libra_message(
    STATUS "Registered ${TOTAL_FILES} extra .cmake file(s) for ${ARG_TARGET}")
endfunction()

#[[.rst:
.. cmake:command:: libra_register_copyright_for_install

  Register a copyright notice file to be installed at CMAKE_INSTALL_DOCDIR.

  The file is automatically renamed to ``copyright`` during installation, which
  is the standard name expected by Debian package tools (``lintian``). This
  function is useful when configuring CPack to generate .deb/.rpm packages.

  To use, ``include(libra/package/install.cmake)``.

  :param TARGET: The target name (used for the installation directory path).

  :param FILE: Path to the copyright file (typically LICENSE, COPYING,
   etc.). Can be any filename; it will be renamed to ``copyright`` during
   installation.

  **Installation Path:**

  The file is installed to: ``${CMAKE_INSTALL_DATAROOTDIR}/doc/${TARGET}/copyright``

  **Example:**

  .. code-block:: cmake

    libra_register_copyright_for_install(mylib ${PROJECT_SOURCE_DIR}/LICENSE)
]]
function(libra_register_copyright_for_install)
  # Support both: 1. libra_register_copyright_for_install(TARGET mylib FILE
  # LICENSE) 2. libra_register_copyright_for_install(mylib LICENSE)
  cmake_parse_arguments(
    ARG
    ""
    "TARGET;FILE"
    ""
    ${ARGN})

  if(NOT ARG_TARGET AND ARG_UNPARSED_ARGUMENTS)
    list(GET ARG_UNPARSED_ARGUMENTS 0 ARG_TARGET)
    list(REMOVE_AT ARG_UNPARSED_ARGUMENTS 0)
  endif()

  if(NOT ARG_FILE AND ARG_UNPARSED_ARGUMENTS)
    list(GET ARG_UNPARSED_ARGUMENTS 0 ARG_FILE)
  endif()

  if(NOT ARG_TARGET OR NOT ARG_FILE)
    libra_error(
      "libra_register_copyright_for_install: TARGET and FILE are required")
  endif()

  if(NOT IS_ABSOLUTE "${ARG_FILE}")
    set(ARG_FILE "${CMAKE_CURRENT_SOURCE_DIR}/${ARG_FILE}")
  endif()

  set(INSTALL_PATH "${CMAKE_INSTALL_DATAROOTDIR}/doc/${ARG_TARGET}")
  install(
    FILES ${ARG_FILE}
    DESTINATION ${INSTALL_PATH}
    RENAME copyright)

  libra_message(STATUS
                "Registered copyright file for ${ARG_TARGET}: ${ARG_FILE}")
endfunction()

#[[.rst:
.. cmake:command:: libra_register_headers_for_install

  Register header files from a DIRECTORY to be installed at
  ``${CMAKE_INSTALL_PREFIX}``.

  Recursively finds and installs all ``.hpp`` and ``.h`` files from the
  specified directory, preserving the directory structure. These can be from
  your project, a header-only dependency, etc.

  To use, ``include(libra/package/install.cmake)``.

  :param DIRECTORY: The directory containing header files to install. Searched
   recursively for ``.hpp`` and ``.h`` files.

  **Example:**

  .. code-block:: cmake

    # Install headers from include/ to ${CMAKE_INSTALL_PREFIX}/include
    libra_register_headers_for_install(
      ${PROJECT_SOURCE_DIR}/include
      )

    # This installs: include/mylib/foo.hpp -> ${CMAKE_INSTALL_PREFIX}/include/mylib/foo.hpp
]]
function(libra_register_headers_for_install DIRECTORY)
  # Validate arguments
  if(NOT DIRECTORY)
    libra_error("libra_register_headers_for_install: DIRECTORY is required")
  endif()

  # Make the path absolute if it's relative
  if(NOT IS_ABSOLUTE "${DIRECTORY}")
    set(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/${DIRECTORY}")
  endif()

  if(NOT IS_DIRECTORY "${DIRECTORY}")
    libra_error(
      "libra_register_headers_for_install: Not a directory: ${DIRECTORY}\n"
      "  Verify the path is correct and points to a directory")
  endif()

  # Check if directory contains any headers
  file(GLOB_RECURSE HEADER_CHECK "${DIRECTORY}/*.hpp" "${DIRECTORY}/*.h")

  if(NOT HEADER_CHECK)
    libra_message(
      WARNING
      "libra_register_headers_for_install: No .hpp or .h files found in ${DIRECTORY}\n"
      "  This directory will be installed but appears to be empty")
  else()
    list(LENGTH HEADER_CHECK NUM_HEADERS)
    libra_message(STATUS "Found ${NUM_HEADERS} header file(s) in ${DIRECTORY}")
  endif()

  set(INSTALL_PATH "${CMAKE_INSTALL_PREFIX}/include")

  install(
    DIRECTORY ${DIRECTORY}
    DESTINATION ${INSTALL_PATH}
    FILES_MATCHING
    PATTERN "*.hpp"
    PATTERN "*.h")
  libra_message(STATUS "Registered headers for install from ${DIRECTORY}")
endfunction()

#[[.rst:
.. cmake:command:: libra_register_target_for_install

  Register a TARGET for installation with proper export configuration.

  Installs the target's library files (.so, .a) and public headers, and creates
  an export file (``<TARGET>-exports.cmake``) that allows downstream projects to
  use the target with ``find_package()``. The target is associated with the
  necessary exports file so child projects can find it.

  To use, ``include(libra/package/install.cmake)``.

  :param TARGET: The CMake target to install. Must be a valid library target
   created with :cmake:command:`add_library` or :cmake:command:`add_executable`.
   Must be a target for which :cmake:command:`libra_configure_exports` has
   already been called.

  The target is installed with:

    - Libraries: ``${CMAKE_INSTALL_LIBDIR}``
    - Public headers: ``${CMAKE_INSTALL_PREFIX}/include``
    - Export file: ``${CMAKE_INSTALL_LIBDIR}/cmake/${TARGET}/${TARGET}-exports.cmake``

  **What Gets Installed:**

  - Shared libraries (.so, .dylib, .dll)
  - Static libraries (.a, .lib)
  - Executables (if applicable)
  - Public headers (as specified by target properties)
  - CMake export file for use with ``find_package()``

  **Example:**

  .. code-block:: cmake

    add_library(mylib src/mylib.cpp)
    set_target_properties(mylib PROPERTIES PUBLIC_HEADER "include/mylib.hpp")

    libra_register_target_for_install(mylib)

    # Downstream projects can now use:
    # find_package(mylib REQUIRED)
    # target_link_libraries(their_target mylib::mylib)

]]
function(libra_register_target_for_install TARGET)
  if(NOT TARGET)
    libra_error("libra_register_target_for_install: Valid TARGET is required")
  endif()

  if(NOT TARGET ${TARGET})
    libra_error(
      "libra_register_target_for_install: Target '${TARGET}' does not exist.\n")
  endif()

  get_target_property(_type ${TARGET} TYPE)

  if(NOT _type STREQUAL "STATIC_LIBRARY"
     AND NOT _type STREQUAL "SHARED_LIBRARY"
     AND NOT _type STREQUAL "MODULE_LIBRARY"
     AND NOT _type STREQUAL "EXECUTABLE")
    libra_error(
      "libra_register_target_for_install: Target '${TARGET}' has unsupported type '${_type}'."
    )
  endif() # Verify target exists

  # Install .so and .a libraries
  install(
    # Install the target
    TARGETS ${TARGET}
    # Associate target with <target>-exports.cmake
    EXPORT ${TARGET}-exports
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    PUBLIC_HEADER DESTINATION ${CMAKE_INSTALL_PREFIX}/include)

  install(
    EXPORT ${TARGET}-exports
    FILE ${TARGET}-exports.cmake
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${TARGET}
    NAMESPACE ${TARGET}::)

  libra_message(STATUS "Registered target for install: ${TARGET}")
  libra_message(
    STATUS "  Libraries -> ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}")
  libra_message(STATUS "  Headers -> ${CMAKE_INSTALL_PREFIX}/include")
  libra_message(
    STATUS
    "  Exports -> ${CMAKE_INSTALL_LIBDIR}/cmake/${TARGET}/${TARGET}-exports.cmake"
  )
endfunction()
