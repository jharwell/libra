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

  Passing a directory is an error; use :cmake:command:`libra_install_dir()`
  for directory installation.

  :param DESTINATION: Install destination relative to
   :cmake:variable:`CMAKE_INSTALL_PREFIX`.

  :param FILES: One or more files to install.

  :param RENAME: (Optional) Rename the file at the destination. May only be
   used when exactly one file is given in ``FILES``. An error is raised if
   ``RENAME`` is specified alongside multiple files.

  **Examples:**

  .. code-block:: cmake

    # Install multiple files
    libra_install_files(
      DESTINATION lib/cmake/mylib
      FILES       cmake/mylib/version.py cmake/mylib/utils.py)

    # Install and rename a single file
    libra_install_files(
      DESTINATION bin
      FILES       scripts/start.sh.in
      RENAME      start.sh)

]]
function(libra_install_files)
  cmake_parse_arguments(
    ARG
    ""
    "DESTINATION;RENAME"
    "FILES"
    ${ARGN})

  if(NOT ARG_DESTINATION)
    libra_error("libra_install_files: DESTINATION is required")
  endif()
  if(NOT ARG_FILES)
    libra_error("libra_install_files: FILES is required")
  endif()
  if(ARG_RENAME)
    list(LENGTH ARG_FILES _nfiles)
    if(NOT _nfiles EQUAL 1)
      libra_error(
        "libra_install_files: RENAME requires exactly one file, got ${_nfiles}\n"
        "  Remove RENAME or reduce FILES to a single file")
    endif()
    install(
      FILES ${ARG_FILES}
      DESTINATION "${ARG_DESTINATION}"
      RENAME "${ARG_RENAME}")
    libra_message(
      STATUS
      "Registered 1 file for install -> ${ARG_DESTINATION}/${ARG_RENAME}")
    return()
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
  # 2026-09-24 [JRH]: Included here, not at module scope, so it's available for
  # consumers using this function but does not cause spurious "no architecture
  # defined" warnings when LIBRA itself is installed.
  include(GNUInstallDirs)

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
  specified directory, preserving the directory structure below it. These can
  be from your project, a header-only dependency, etc.

  ``DIRECTORY`` follows :cmake:command:`install(DIRECTORY)`: with a trailing
  ``/`` its contents are installed; without one, the directory itself is.

  Useful if you need to selectively install only SOME headers from a project,
  add some third party headers from another dir, etc.

  :param DIRECTORY: The directory containing header files to install. Searched
   recursively for ``.hpp`` and ``.h`` files.

  **Example:**

  .. code-block:: cmake

    # Install the contents of include/ (note the trailing /) to
    # ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_INCLUDEDIR}
    libra_install_headers(${PROJECT_SOURCE_DIR}/include/)

    # This installs: include/mylib/foo.hpp -> ${CMAKE_INSTALL_PREFIX}/include/mylib/foo.hpp
]]
function(libra_install_headers)
  # 2026-09-24 [JRH]: Included here, not at module scope, so it's available for
  # consumers using this function but does not cause spurious "no architecture
  # defined" warnings when LIBRA itself is installed.
  include(GNUInstallDirs)

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

  # Relative, so `cmake --install --prefix` and CPack can relocate headers along
  # with everything else.
  install(
    DIRECTORY ${ARG_DIRECTORY}
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
    FILES_MATCHING
    PATTERN "*.hpp"
    PATTERN "*.h")

  libra_message(
    STATUS
    "Registered ${NUM_HEADERS} headers for install from ${ARG_DIRECTORY}")
endfunction()

# cmake-format: off
# ##############################################################################
# _libra_add_header_file_set
#
# Give TARGET a public HEADERS file set made of every header under its own
# public/interface include directories, if it doesn't already declare one.
#
# Only the target's own INTERFACE_INCLUDE_DIRECTORIES are used (not those of
# libraries it links), and only directories inside the project's source or
# binary tree: build-time paths from $<BUILD_INTERFACE:...> and plain absolute
# paths are globbed; $<INSTALL_INTERFACE:...> and other generator expressions
# are skipped, as are directories outside the project (system/third-party).
# ##############################################################################
# cmake-format: on
function(_libra_add_header_file_set TARGET)
  # Only libraries that are built here have headers to install.
  get_target_property(_imported ${TARGET} IMPORTED)
  get_target_property(_type ${TARGET} TYPE)
  if(_imported OR NOT _type MATCHES "^(STATIC|SHARED|MODULE)_LIBRARY$")
    return()
  endif()

  # A file set the project declared itself wins.
  get_target_property(_existing ${TARGET} INTERFACE_HEADER_SETS)
  if(_existing)
    return()
  endif()

  get_target_property(_dirs ${TARGET} INTERFACE_INCLUDE_DIRECTORIES)
  if(NOT _dirs)
    return()
  endif()

  set(_base_dirs)
  set(_headers)
  foreach(_dir IN LISTS _dirs)
    if(_dir MATCHES "^\\$<BUILD_INTERFACE:(.*)>$")
      set(_dir "${CMAKE_MATCH_1}")
    endif()
    if(_dir MATCHES "\\$<" OR NOT IS_ABSOLUTE "${_dir}")
      continue()
    endif()

    cmake_path(
      IS_PREFIX
      PROJECT_SOURCE_DIR
      "${_dir}"
      NORMALIZE
      _in_src)
    cmake_path(
      IS_PREFIX
      PROJECT_BINARY_DIR
      "${_dir}"
      NORMALIZE
      _in_bin)
    if(NOT (_in_src OR _in_bin) OR NOT IS_DIRECTORY "${_dir}")
      continue()
    endif()

    file(
      GLOB_RECURSE
      _found
      "${_dir}/*.h"
      "${_dir}/*.hh"
      "${_dir}/*.hpp"
      "${_dir}/*.hxx")
    if(_found)
      list(APPEND _base_dirs "${_dir}")
      list(APPEND _headers ${_found})
    endif()
  endforeach()

  if(NOT _headers)
    return()
  endif()

  list(REMOVE_DUPLICATES _base_dirs)
  list(REMOVE_DUPLICATES _headers)

  target_sources(
    ${TARGET}
    PUBLIC FILE_SET
           HEADERS
           BASE_DIRS
           ${_base_dirs}
           FILES
           ${_headers})

  list(LENGTH _headers _count)
  libra_message(STATUS "Collected ${_count} public headers for ${TARGET}")
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
  The target is installed with:

  - Libraries: ``${CMAKE_INSTALL_LIBDIR}``
  - Executables: ``${CMAKE_INSTALL_BINDIR}``
  - Headers: ``${CMAKE_INSTALL_INCLUDEDIR}``. Headers are installed from two
    disjoint sources:

    #. From the target's public ``HEADERS`` file sets (paths kept relative to
       each set's ``BASE_DIRS``, and the install location added to the exported
       target's include directories, if the target defines them. Otherwise,
       LIBRA computes the header list from the interface include dirs for the
       target.

    #. From the targets ``PUBLIC_HEADER`` property.

  - Export file: ``lib/cmake/${TARGET}/${TARGET}-exports.cmake``

  **What Gets Installed:**

  - Shared libraries (.so, .dylib, .dll)
  - Static libraries (.a, .lib)
  - Executables (if applicable)
  - CMake export file for use with ``find_package()``

  **Example:**

  .. code-block:: cmake

    # Headers found from the target's public include directories:
    # include/mylib/foo.hpp installs to ${CMAKE_INSTALL_INCLUDEDIR}/mylib/foo.hpp
    add_library(mylib src/mylib.cpp)
    target_include_directories(mylib PUBLIC
      $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>)
    libra_install_target(mylib)

    # Or choose the headers explicitly with a file set, which takes precedence
    target_sources(mylib PUBLIC FILE_SET HEADERS BASE_DIRS include
                   FILES include/mylib/foo.hpp)
    libra_install_target(mylib)

    # Executable, no headers
    add_executable(mytool src/main.cpp)
    libra_install_target(mytool)

    # Downstream projects can now use:
    # find_package(mylib REQUIRED)
    # target_link_libraries(their_target mylib::mylib)

]]
function(libra_install_target)
  # 2026-09-24 [JRH]: Included here, not at module scope, so it's available for
  # consumers using this function but does not cause spurious "no architecture
  # defined" warnings when LIBRA itself is installed.
  include(GNUInstallDirs)

  # Support: 1. libra_install_target(TARGET mylib) 2.
  # libra_install_target(mylib) 3. libra_install_target(mylib INCLUDE_DIR
  # include/) 4. libra_install_target(TARGET mylib INCLUDE_DIR include/)
  cmake_parse_arguments(
    ARG
    ""
    "TARGET"
    ""
    ${ARGN})

  if(NOT ARG_TARGET AND ARG_UNPARSED_ARGUMENTS)
    list(GET ARG_UNPARSED_ARGUMENTS 0 ARG_TARGET)
    list(REMOVE_AT ARG_UNPARSED_ARGUMENTS 0)
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

  _libra_add_header_file_set(${ARG_TARGET})

  # Install the target's public header file sets, if any. install() errors on a
  # FILE_SET the target doesn't have, so only name the ones it does.
  set(_file_set_args)
  get_target_property(_header_sets ${ARG_TARGET} INTERFACE_HEADER_SETS)
  if(_header_sets)
    foreach(_set IN LISTS _header_sets)
      list(
        APPEND
        _file_set_args
        FILE_SET
        ${_set}
        DESTINATION
        ${CMAKE_INSTALL_INCLUDEDIR})
    endforeach()
  endif()

  # Install .so and .a libraries
  install(
    TARGETS ${ARG_TARGET}
    EXPORT ${ARG_TARGET}-exports
    ${_file_set_args}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
            # If the target sets the PUBLIC_HEADER property, then this will
            # install the headers. But most targets don't set this property.
    PUBLIC_HEADER DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})

  install(
    EXPORT ${ARG_TARGET}-exports
    FILE ${ARG_TARGET}-exports.cmake
    DESTINATION lib/cmake/${ARG_TARGET}
    NAMESPACE ${ARG_TARGET}::)

  libra_message(STATUS "Registered target ${ARG_TARGET} for install")
  list(APPEND CMAKE_MESSAGE_INDENT " ")

  libra_message(STATUS
                "Libraries -> ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}")
  libra_message(
    STATUS "Headers -> ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_INCLUDEDIR}")
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
