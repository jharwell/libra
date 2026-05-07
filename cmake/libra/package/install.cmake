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

  configure_package_config_file(${CONFIG_TEMPLATE} "${OUTPUT_FILE}"
                                INSTALL_DESTINATION "lib/cmake/${TARGET}")

  write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}-configVersion.cmake"
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY ${COMPATIBILITY} # or AnyNewerVersion, ExactVersion, etc.
  )

  install(FILES "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}-configVersion.cmake"
          DESTINATION lib/cmake/${TARGET})

  # Install the configured exports file
  install(FILES "${OUTPUT_FILE}" DESTINATION "lib/cmake/${TARGET}")

  libra_message(STATUS
                "Configured cmake exports for ${TARGET} -> lib/cmake/${TARGET}")
endfunction()

#[[.rst:
.. cmake:command:: libra_install_cmake_modules

  Install ``.cmake`` files for a TARGET to ``lib/cmake/<TARGET>``.

  Useful if your project provides reusable CMake functionality that you want
  downstream projects to access. Supports both individual ``.cmake`` files and
  directories (searched recursively for ``.cmake`` files). Directory structure
  is preserved during installation.

  Non-``.cmake`` files are skipped with a warning.

  :param TARGET: The target name, used to derive the install destination
   ``lib/cmake/<TARGET>``. Must be a target for which
   :cmake:command:`libra_configure_exports` has already been called.

  :param FILES_OR_DIRS: One or more ``.cmake`` files or directories containing
   ``.cmake`` files.

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
    libra_error("libra_install_cmake_modules: TARGET is required")
  endif()
  if(NOT ARG_FILES_OR_DIRS)
    libra_error("libra_install_cmake_modules: FILES_OR_DIRS is required")
  endif()

  _libra_install_items(
    DESTINATION
    "lib/cmake/${ARG_TARGET}"
    ITEMS
    ${ARG_FILES_OR_DIRS}
    GLOB_PATTERN
    "*.cmake"
    CALLER
    "libra_install_cmake_modules"
    RESULT_COUNT
    _count)

  if(_count EQUAL 0)
    libra_error(
      "libra_install_cmake_modules: No .cmake files found to install\n"
      "  Check that your files/directories contain .cmake files")
  endif()

  libra_message(STATUS "Registered ${_count} .cmake file(s) for ${ARG_TARGET}")
endfunction()

#[[.rst:
.. cmake:command:: libra_install_files

  Install one or more files of any type to an explicit destination.

  Unlike :cmake:command:`libra_install_cmake_modules`, this function imposes
  no restriction on file type and takes an explicit ``DESTINATION`` rather than
  deriving one from a target name. Use it for scripts, data files, templates,
  or any other content that needs to reach the install tree.

  Passing a directory is an error; use :cmake:command:`libra_install_dir`
  for directory installation.

  :param DESTINATION: Install destination relative to
   :cmake:variable:`CMAKE_INSTALL_PREFIX`.

  :param FILES: One or more files to install.

  **Example:**

  .. code-block:: cmake

    libra_install_files(
      DESTINATION lib/cmake/mylib
      FILES       cmake/mylib/version.py cmake/mylib/utils.py)

]]
function(libra_install_files)
  cmake_parse_arguments(
    ARG
    ""
    "DESTINATION"
    "FILES"
    ${ARGN})

  if(NOT ARG_DESTINATION)
    libra_error("libra_install_files: DESTINATION is required")
  endif()
  if(NOT ARG_FILES)
    libra_error("libra_install_files: FILES is required")
  endif()

  _libra_install_items(
    DESTINATION
    "${ARG_DESTINATION}"
    ITEMS
    ${ARG_FILES}
    FILES_ONLY
    CALLER
    "libra_install_files"
    RESULT_COUNT
    _count)

  if(_count EQUAL 0)
    libra_error("libra_install_files: No files were installed")
  endif()

  libra_message(
    STATUS "Registered ${_count} file(s) for install -> ${ARG_DESTINATION}")
endfunction()

#[[.rst:
.. cmake:command:: libra_install_dir

  Install one or more directories to an explicit destination.

  Directories are searched recursively and their structure is preserved.
  Passing a plain file is an error; use :cmake:command:`libra_install_files`
  for individual file installation.

  :param DESTINATION: Install destination relative to
   :cmake:variable:`CMAKE_INSTALL_PREFIX`.

  :param DIRS: One or more directories to install.

  **Example:**

  .. code-block:: cmake

    libra_install_dir(
      DESTINATION share/mylib
      DIRS        data/templates data/schemas)

]]
function(libra_install_dir)
  cmake_parse_arguments(
    ARG
    ""
    "DESTINATION"
    "DIRS"
    ${ARGN})

  if(NOT ARG_DESTINATION)
    libra_error("libra_install_dir: DESTINATION is required")
  endif()
  if(NOT ARG_DIRS)
    libra_error("libra_install_dir: DIRS is required")
  endif()

  _libra_install_items(
    DESTINATION
    "${ARG_DESTINATION}"
    ITEMS
    ${ARG_DIRS}
    DIRS_ONLY
    CALLER
    "libra_install_dir"
    RESULT_COUNT
    _count)

  if(_count EQUAL 0)
    libra_error("libra_install_dir: No files were installed")
  endif()

  libra_message(
    STATUS "Registered ${_count} file(s) for install -> ${ARG_DESTINATION}")
endfunction()

#[[.rst:
.. cmake:command:: libra_install_files

  Install arbitrary files or directories at ``${CMAKE_INSTALL_PREFIX}``.

  Unlike :cmake:command:`libra_install_cmake_modules`, this function imposes
  no restriction on file type. Use it to install scripts, data files,
  templates, or any other content that needs to be present in the install
  tree.

  Supports both individual files and directories (processed recursively).
  Directory structure is preserved during installation.

  :param DESTINATION: Install destination relative to
   :cmake:variable:`CMAKE_INSTALL_PREFIX`.

  :param FILES_OR_DIRS: One or more files or directories to install.
   Directories are searched recursively and their structure is preserved.

  **Examples:**

  .. code-block:: cmake

    # Install a single script
    libra_install_files(
      DESTINATION lib/cmake/libra
      FILES_OR_DIRS cmake/libra/version.py)

    # Install an entire directory (structure preserved)
    libra_install_files(
      DESTINATION share/mylib/data
      FILES_OR_DIRS data/templates)

    # Mix files and directories
    libra_install_files(
      DESTINATION share/mylib
      FILES_OR_DIRS data/config.json data/templates)

]]
function(libra_install_files)
  cmake_parse_arguments(
    ARG
    ""
    "DESTINATION"
    "FILES_OR_DIRS"
    ${ARGN})

  if(NOT ARG_DESTINATION)
    libra_error("libra_install_files: DESTINATION is required")
  endif()

  if(NOT ARG_FILES_OR_DIRS)
    libra_error("libra_install_files: FILES_OR_DIRS is required")
  endif()

  set(_total 0)

  foreach(ITEM ${ARG_FILES_OR_DIRS})
    if(NOT IS_ABSOLUTE "${ITEM}")
      set(ITEM "${CMAKE_CURRENT_SOURCE_DIR}/${ITEM}")
    endif()

    if(IS_DIRECTORY "${ITEM}")
      file(
        GLOB_RECURSE _dir_files
        RELATIVE "${ITEM}"
        "${ITEM}/*")

      foreach(_rel_file ${_dir_files})
        get_filename_component(_rel_dir "${_rel_file}" DIRECTORY)
        if(_rel_dir)
          install(FILES "${ITEM}/${_rel_file}"
                  DESTINATION "${ARG_DESTINATION}/${_rel_dir}")
        else()
          install(FILES "${ITEM}/${_rel_file}" DESTINATION "${ARG_DESTINATION}")
        endif()
        math(EXPR _total "${_total} + 1")
      endforeach()

    elseif(EXISTS "${ITEM}")
      install(FILES "${ITEM}" DESTINATION "${ARG_DESTINATION}")
      math(EXPR _total "${_total} + 1")

    else()
      libra_error("libra_install_files: '${ITEM}' does not exist\n"
                  "  Verify the path is correct")
    endif()
  endforeach()

  if(_total EQUAL 0)
    libra_error("libra_install_files: No files found to install")
  endif()

  libra_message(
    STATUS "Registered ${_total} file(s) for install -> ${ARG_DESTINATION}")
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
  - Export file: ``lib/cmake/${TARGET}/${TARGET}-exports.cmake``

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
    DESTINATION lib/cmake/${ARG_TARGET}
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
    "Exports -> ${CMAKE_INSTALL_PREFIX}/lib/cmake/${ARG_TARGET}/${ARG_TARGET}-exports.cmake"
  )
  list(POP_BACK CMAKE_MESSAGE_INDENT)
endfunction()

# cmake-format: off
# ##############################################################################
# Internal implementation shared by libra_install_cmake_modules,
# libra_install_files, and libra_install_dir.
#
# Parameters:
#   DESTINATION    - install destination relative to CMAKE_INSTALL_PREFIX
#   ITEMS          - list of files and/or directories to install
#   GLOB_PATTERN   - (optional) glob pattern applied when scanning directories
#                    and used to validate individual files (e.g. "*.cmake").
#                    If omitted, all files are accepted.
#   FILES_ONLY     - (flag) error if any item is a directory
#   DIRS_ONLY      - (flag) error if any item is a plain file
#   CALLER         - calling function name, used in error/warning messages
#   RESULT_COUNT   - output variable receiving the number of files installed
# ##############################################################################
# cmake-format: on
function(_libra_install_items)
  cmake_parse_arguments(
    ARG
    "FILES_ONLY;DIRS_ONLY"
    "DESTINATION;GLOB_PATTERN;CALLER;RESULT_COUNT"
    "ITEMS"
    ${ARGN})

  set(_count 0)

  foreach(_item ${ARG_ITEMS})
    if(NOT IS_ABSOLUTE "${_item}")
      set(_item "${CMAKE_CURRENT_SOURCE_DIR}/${_item}")
    endif()

    if(NOT EXISTS "${_item}")
      libra_error("${ARG_CALLER}: '${_item}' does not exist\n"
                  "  Verify the path is correct and the file/directory exists")
    endif()

    if(IS_DIRECTORY "${_item}")
      if(ARG_FILES_ONLY)
        libra_error(
          "${ARG_CALLER}: '${_item}' is a directory -- only files are accepted\n"
          "  Use libra_install_dir() to install directories")
      endif()

      if(ARG_GLOB_PATTERN)
        file(
          GLOB_RECURSE _dir_files
          RELATIVE "${_item}"
          "${_item}/${ARG_GLOB_PATTERN}")
      else()
        file(
          GLOB_RECURSE _dir_files
          RELATIVE "${_item}"
          "${_item}/*")
      endif()

      foreach(_rel_file ${_dir_files})
        get_filename_component(_rel_dir "${_rel_file}" DIRECTORY)
        if(_rel_dir)
          install(FILES "${_item}/${_rel_file}"
                  DESTINATION "${ARG_DESTINATION}/${_rel_dir}")
        else()
          install(FILES "${_item}/${_rel_file}"
                  DESTINATION "${ARG_DESTINATION}")
        endif()
        math(EXPR _count "${_count} + 1")
      endforeach()

    else()
      if(ARG_DIRS_ONLY)
        libra_error(
          "${ARG_CALLER}: '${_item}' is a file -- only directories are accepted\n"
          "  Use libra_install_files() to install individual files")
      endif()

      if(ARG_GLOB_PATTERN)
        # Convert the glob pattern to a regex suffix check.
        string(REPLACE "." "\\." _pat_re "${ARG_GLOB_PATTERN}")
        string(REPLACE "*" ".*" _pat_re "${_pat_re}")
        if(NOT _item MATCHES "${_pat_re}$")
          libra_message(
            WARNING
            "${ARG_CALLER}: '${_item}' does not match '${ARG_GLOB_PATTERN}' -- skipping"
          )
          continue()
        endif()
      endif()

      install(FILES "${_item}" DESTINATION "${ARG_DESTINATION}")
      math(EXPR _count "${_count} + 1")
    endif()
  endforeach()

  set(${ARG_RESULT_COUNT}
      ${_count}
      PARENT_SCOPE)
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
