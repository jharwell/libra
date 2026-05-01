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
  :cmake:variable:`CMAKE_INSTALL_PREFIX`.

  Enables the installed project to be used with ``find_package()`` by downstream
  projects. This function requires a ``cmake/config.cmake.in`` template file in
  your project root.

  :param TARGET: The target name for which to configure exports. This will be
   used to generate ``<TARGET>-config.cmake`` and must match the name used in
   ``find_package()``. You may need to call this on header-only dependencies to
   get them into the export set for your project. If you do, make sure you do
   *not* add said dependencies to your ``config.cmake.in`` file via
   ``find_dependency()``, as that will cause an infinite loop.

  :param COMPATIBILITY: The name of the CMake compatibility strategy for this
  exported target. If not specified, defaults to ``ExactVersion`` for safety.

  **Requirements:**

  The function expects a template file at
  ``${PROJECT_SOURCE_DIR}/cmake/config.cmake.in``. This template is processed by
  ``configure_package_config_file()`` to generate the final config file that
  defines everything necessary to use the project with ``find_package()``.

  The function expects :cmake:variable:`PROJECT_VERSION` to be defined.

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
    "TARGET;COMPATIBILITY"
    ""
    ${ARGN})

  if(NOT ARG_TARGET AND ARG_UNPARSED_ARGUMENTS)
    list(GET ARG_UNPARSED_ARGUMENTS 0 ARG_TARGET)
  endif()
  if(NOT ARG_COMPATIBILITY AND ARG_UNPARSED_ARGUMENTS)
    list(LENGTH ARG_UNPARSED_ARGUMENTS _len)
    if(_len GREATER 1)
      list(GET ARG_UNPARSED_ARGUMENTS 1 ARG_COMPATIBILITY)
    endif()
  endif()

  if(NOT ARG_TARGET)
    libra_error("libra_configure_exports: TARGET missing")
  endif()

  set(TARGET ${ARG_TARGET})
  if(NOT ARG_COMPATIBILITY)
    set(ARG_COMPATIBILITY "ExactVersion")
    libra_message(
      WARNING
      "COMPATABILITY not specified for ${ARG_TARGET}--defaulting to ExactVersion. Pass COMPATIBILITY <mode> to suppress this warning."
    )
  endif()
  set(COMPATIBILITY ${ARG_COMPATIBILITY})

  set(TARGET ${ARG_TARGET})
  set(COMPATIBILITY ${ARG_COMPATIBILITY})

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

  write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}-configVersion.cmake"
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY ${COMPATIBILITY} # or AnyNewerVersion, ExactVersion, etc.
  )

  install(FILES "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}-configVersion.cmake"
          DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${TARGET})

  # Install the configured exports file
  install(FILES "${OUTPUT_FILE}"
          DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/${TARGET}")

  libra_message(
    STATUS
    "Configured cmake exports for ${TARGET} -> ${CMAKE_INSTALL_LIBDIR}/cmake/${TARGET}"
  )
endfunction()

#[[.rst:
.. cmake:command:: libra_install_cmake_modules

  Install .cmake files for a TARGET to be installed at
  ``${CMAKE_INSTALL_PREFIX}``.

  Useful if your project provides reusable CMake functionality that you want
  downstream projects to access. Supports both individual files and directories
  (processed recursively).

  :param TARGET: The target name (used for install destination). Must be a
   target for which :cmake:command:`libra_configure_exports` has already been
   called.

  :param FILES_OR_DIRS: One or more .cmake files or directories containing
   .cmake files. Directories are searched recursively, and the directory
   structure is preserved during installation (not flattened).

  **Examples:**

  .. code-block:: cmake

    # Install individual files
    libra_install_cmake_modules(mylib
      cmake/MyLibHelpers.cmake
      cmake/MyLibUtils.cmake)

    # Install entire directory (recursive, structure preserved)
    libra_install_cmake_modules(mylib
      cmake/modules)

    # Mix files and directories
    libra_install_cmake_modules(mylib
      cmake/special.cmake
      cmake/modules)

  .. versionchanged:: 0.9.26
     Can now handle files OR directories of extra configs.
]]
function(libra_install_cmake_modules)
  # Track total number of files
  set(TOTAL_FILES 0)

  # Support both:
  #
  # * libra_install_cmake_modules(TARGET mylib FILES_OR_DIRS dir1)
  #
  # * libra_install_cmake_modules(mylib dir1 dir2)
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
    libra_error("libra_install_cmake_modules: TARGET argument is required")
  endif()

  if(NOT ARG_FILES_OR_DIRS)
    libra_error(
      "libra_install_cmake_modules: No files or directories specified.")
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
          "libra_install_cmake_modules: '${ITEM}' is not a .cmake file\n"
          "  Only .cmake files can be installed. This file will be skipped.")
      endif()
    else()
      libra_error("libra_install_cmake_modules: '${ITEM}' does not exist\n"
                  "  Verify the path is correct and the file/directory exists")
    endif()
  endforeach()

  if(TOTAL_FILES EQUAL 0)
    libra_error(
      "libra_install_cmake_modules: No .cmake files found to install\n"
      "  Check that your files/directories contain .cmake files")
  endif()

  # Print what was registered
  libra_message(
    STATUS "Registered ${TOTAL_FILES} extra .cmake file(s) for ${ARG_TARGET}")
endfunction()

#[[.rst:
.. cmake:command:: libra_install_copyright

  Install a copyright notice file at :cmake:variable:`CMAKE_INSTALL_DOCDIR`.

  The file is automatically renamed to ``copyright`` during installation, which
  is the standard name expected by Debian package tools (``lintian``). This
  function is useful when configuring CPack to generate .deb/.rpm packages.

  :param TARGET: The target name (used for the installation directory path).

  :param FILE: Path to the copyright file (typically LICENSE, COPYING,
   etc.). Can be any filename; it will be renamed to ``copyright`` during
   installation.

  **Installation Path:**

  The file is installed to: ``${CMAKE_INSTALL_DATAROOTDIR}/doc/${TARGET}/copyright``

  **Example:**

  .. code-block:: cmake

    libra_install_copyright(mylib ${PROJECT_SOURCE_DIR}/LICENSE)
]]
function(libra_install_copyright)
  # Support both: 1. libra_install_copyright(TARGET mylib FILE LICENSE) 2.
  # libra_install_copyright(mylib LICENSE)
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
    libra_error("libra_install_copyright: TARGET and FILE are required")
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
.. cmake:command:: libra_install_headers

  Install header files from a DIRECTORY at ``${CMAKE_INSTALL_PREFIX}``.

  Recursively finds and installs all ``.hpp`` and ``.h`` files from the
  specified directory, preserving the directory structure. These can be from
  your project, a header-only dependency, etc.

  Useful if you need to selectively install only SOME headers from a project,
  add some third party headers from another dir, etc.

  :param DIRECTORY: The directory containing header files to install. Searched
   recursively for ``.hpp`` and ``.h`` files.

  **Example:**

  .. code-block:: cmake

    # Install headers from include/ to ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_INCLUDEDIR}
    libra_install_headers(${PROJECT_SOURCE_DIR}/include)

    # This installs: include/mylib/foo.hpp -> ${CMAKE_INSTALL_PREFIX}/include/mylib/foo.hpp
]]
function(libra_install_headers)
  # Support both: 1. libra_install_headers(DIRECTORY include/) 2.
  # libra_install_headers(include/)
  cmake_parse_arguments(
    ARG
    ""
    "DIRECTORY"
    ""
    ${ARGN})

  if(NOT ARG_DIRECTORY AND ARG_UNPARSED_ARGUMENTS)
    list(GET ARG_UNPARSED_ARGUMENTS 0 ARG_DIRECTORY)
  endif()

  if(NOT ARG_DIRECTORY)
    libra_error("libra_install_headers: DIRECTORY is required")
  endif()

  # Make the path absolute if it's relative
  if(NOT IS_ABSOLUTE "${ARG_DIRECTORY}")
    set(ARG_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/${ARG_DIRECTORY}")
  endif()

  if(NOT IS_DIRECTORY "${ARG_DIRECTORY}")
    libra_error("libra_install_headers: Not a directory: ${ARG_DIRECTORY}\n"
                "  Verify the path is correct and points to a directory")
  endif()

  # Check if directory contains any headers
  file(GLOB_RECURSE HEADER_CHECK "${ARG_DIRECTORY}/*.hpp"
       "${ARG_DIRECTORY}/*.h")

  if(NOT HEADER_CHECK)
    libra_message(
      WARNING
      "libra_install_headers: No .hpp or .h files found in ${ARG_DIRECTORY}\n"
      "  This directory will be installed but appears to be empty")
  else()
    list(LENGTH HEADER_CHECK NUM_HEADERS)
  endif()

  set(INSTALL_PATH "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_INCLUDEDIR}")

  install(
    DIRECTORY ${ARG_DIRECTORY}
    DESTINATION ${INSTALL_PATH}
    FILES_MATCHING
    PATTERN "*.hpp"
    PATTERN "*.h")

  libra_message(
    STATUS
    "Registered ${NUM_HEADERS} headers for install from ${ARG_DIRECTORY}")
endfunction()

#[[.rst:
.. cmake:command:: libra_install_target

  Install a TARGET with proper export configuration.

  Installs the target's library or executable files and creates an export file
  (``<TARGET>-exports.cmake``) that allows downstream projects to use the target
  with ``find_package()``.

  :param TARGET: The CMake target to install. Must be a valid target created
   with :cmake:command:`add_library` or :cmake:command:`add_executable`. Must be
   a target for which :cmake:command:`libra_configure_exports` has already been
   called.

  :param INCLUDE_DIR: (Optional) Path to directory containing header files to
   install. If omitted, no headers are installed. Use for libraries; omit for
   executables.

  The target is installed with:

  - Libraries: ``${CMAKE_INSTALL_LIBDIR}``
  - Executables: ``${CMAKE_INSTALL_BINDIR}``
  - Headers: ``${CMAKE_INSTALL_INCLUDEDIR}`` (if ``INCLUDE_DIR`` provided)
  - Export file: ``${CMAKE_INSTALL_LIBDIR}/cmake/${TARGET}/${TARGET}-exports.cmake``

  **What Gets Installed:**

  - Shared libraries (.so, .dylib, .dll)
  - Static libraries (.a, .lib)
  - Executables (if applicable)
  - Headers (if ``INCLUDE_DIR`` provided)
  - CMake export file for use with ``find_package()``

  **Example:**

  .. code-block:: cmake

    # Library with headers
    add_library(mylib src/mylib.cpp)
    libra_install_target(mylib INCLUDE_DIR include/)

    # Executable, no headers
    add_executable(mytool src/main.cpp)
    libra_install_target(mytool)

    # Downstream projects can now use:
    # find_package(mylib REQUIRED)
    # target_link_libraries(their_target mylib::mylib)

]]
function(libra_install_target)
  # Support: 1. libra_install_target(TARGET mylib) 2.
  # libra_install_target(mylib) 3. libra_install_target(mylib INCLUDE_DIR
  # include/) 4. libra_install_target(TARGET mylib INCLUDE_DIR include/)
  cmake_parse_arguments(
    ARG
    ""
    "TARGET;INCLUDE_DIR"
    ""
    ${ARGN})

  if(NOT ARG_TARGET AND ARG_UNPARSED_ARGUMENTS)
    list(GET ARG_UNPARSED_ARGUMENTS 0 ARG_TARGET)
    list(REMOVE_AT ARG_UNPARSED_ARGUMENTS 0)
  endif()

  if(NOT ARG_INCLUDE_DIR AND ARG_UNPARSED_ARGUMENTS)
    list(GET ARG_UNPARSED_ARGUMENTS 0 ARG_INCLUDE_DIR)
  endif()

  if(NOT ARG_TARGET)
    libra_error("libra_install_target: TARGET is required")
  endif()

  if(NOT TARGET ${ARG_TARGET})
    libra_error("libra_install_target: Target '${ARG_TARGET}' does not exist.")
  endif()

  get_target_property(_type ${ARG_TARGET} TYPE)

  if(NOT _type STREQUAL "STATIC_LIBRARY"
     AND NOT _type STREQUAL "SHARED_LIBRARY"
     AND NOT _type STREQUAL "MODULE_LIBRARY"
     AND NOT _type STREQUAL "EXECUTABLE")
    libra_error(
      "libra_install_target: Target '${ARG_TARGET}' has unsupported type '${_type}'."
    )
  endif()

  if(ARG_INCLUDE_DIR)
    libra_install_headers(${ARG_INCLUDE_DIR})
  endif()

  # Install .so and .a libraries
  install(
    TARGETS ${ARG_TARGET}
    EXPORT ${ARG_TARGET}-exports
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})

  install(
    EXPORT ${ARG_TARGET}-exports
    FILE ${ARG_TARGET}-exports.cmake
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${ARG_TARGET}
    NAMESPACE ${ARG_TARGET}::)

  libra_message(STATUS "Registered target ${ARG_TARGET} for install")
  list(APPEND CMAKE_MESSAGE_INDENT " ")

  libra_message(STATUS
                "Libraries -> ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}")
  if(ARG_INCLUDE_DIR)
    libra_message(
      STATUS "Headers -> ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_INCLUDEDIR}")
  endif()
  libra_message(
    STATUS
    "Exports -> ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}/cmake/${ARG_TARGET}/${ARG_TARGET}-exports.cmake"
  )
  list(POP_BACK CMAKE_MESSAGE_INDENT)
endfunction()

# ##############################################################################
# Deprecated function wrappers
#
# These are the old function names, kept for backwards compatibility. They will
# be removed in a future version of libra. Use the new names instead.
# ##############################################################################

macro(libra_register_extra_configs_for_install)
  libra_message(
    DEPRECATION
    "libra_register_extra_configs_for_install() is deprecated. Use libra_install_cmake_modules() instead."
  )
  libra_install_cmake_modules(${ARGN})
endmacro()

macro(libra_register_copyright_for_install)
  libra_message(
    DEPRECATION
    "libra_register_copyright_for_install() is deprecated. Use libra_install_copyright() instead."
  )
  libra_install_copyright(${ARGN})
endmacro()

macro(libra_register_headers_for_install)
  libra_message(
    DEPRECATION
    "libra_register_headers_for_install() is deprecated. Use libra_install_headers() instead."
  )
  libra_install_headers(${ARGN})
endmacro()

macro(libra_register_target_for_install)
  libra_message(
    DEPRECATION
    "libra_register_target_for_install() is deprecated. Use libra_install_target() instead."
  )
  libra_install_target(${ARGN})
endmacro()
