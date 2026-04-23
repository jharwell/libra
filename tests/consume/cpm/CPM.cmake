# CPM.cmake - C++ Package Manager
# Vendored minimal implementation for LIBRA test suite.
#
# This is a purpose-built subset of CPM.cmake (https://github.com/cpm-cmake/CPM.cmake)
# that supports only the SOURCE_DIR workflow used by the LIBRA tests.  No
# network access is required or attempted.  For full CPM functionality in a
# real project, replace this file with the official release.
#
# Supported CPMAddPackage() keywords:
#   NAME        - package name (required)
#   SOURCE_DIR  - path to local source tree (required for our use)
#   DOWNLOAD_ONLY - if YES, skip add_subdirectory()
#
# After CPMAddPackage(NAME foo SOURCE_DIR /path) the following variables are set:
#   foo_SOURCE_DIR  - the resolved source directory
#   foo_ADDED       - TRUE if the package was added in this call
#
# Usage:
#   include(path/to/CPM.cmake)
#   CPMAddPackage(NAME libra SOURCE_DIR /path/to/libra DOWNLOAD_ONLY YES)
#   list(PREPEND CMAKE_MODULE_PATH "${libra_SOURCE_DIR}/cmake")
#
cmake_minimum_required(VERSION 3.14)

# Guard against double-inclusion
if(DEFINED CPM_INITIALIZED)
  return()
endif()
set(CPM_INITIALIZED TRUE)

# Package registry: tracks which packages have been added
set(CPM_PACKAGES "" CACHE INTERNAL "CPM registered packages")

# CPMAddPackage(NAME <name> SOURCE_DIR <dir> [DOWNLOAD_ONLY <YES|NO>] ...)
#
# Sets <name>_SOURCE_DIR and <name>_ADDED in the calling scope.
function(CPMAddPackage)
  set(_options)
  set(_one_value NAME SOURCE_DIR DOWNLOAD_ONLY VERSION GIT_TAG GIT_REPOSITORY)
  set(_multi_value OPTIONS)
  cmake_parse_arguments(CPM "${_options}" "${_one_value}" "${_multi_value}" ${ARGN})

  if(NOT CPM_NAME)
    message(FATAL_ERROR "CPMAddPackage: NAME is required")
  endif()

  # Check if already registered (idempotent)
  if("${CPM_NAME}" IN_LIST CPM_PACKAGES)
    # Already added - surface the cached source dir and return
    set(${CPM_NAME}_ADDED FALSE PARENT_SCOPE)
    # The source dir was set on first call; it persists as a cache entry
    if(DEFINED CPM_${CPM_NAME}_SOURCE_DIR)
      set(${CPM_NAME}_SOURCE_DIR "${CPM_${CPM_NAME}_SOURCE_DIR}" PARENT_SCOPE)
    endif()
    return()
  endif()

  # Register the package
  list(APPEND CPM_PACKAGES "${CPM_NAME}")
  set(CPM_PACKAGES "${CPM_PACKAGES}" CACHE INTERNAL "CPM registered packages")

  # Resolve source directory
  if(CPM_SOURCE_DIR)
    if(NOT IS_ABSOLUTE "${CPM_SOURCE_DIR}")
      get_filename_component(CPM_SOURCE_DIR
        "${CMAKE_CURRENT_SOURCE_DIR}/${CPM_SOURCE_DIR}" ABSOLUTE)
    endif()
    if(NOT EXISTS "${CPM_SOURCE_DIR}")
      message(FATAL_ERROR
        "CPMAddPackage: SOURCE_DIR '${CPM_SOURCE_DIR}' does not exist")
    endif()
    set(_source_dir "${CPM_SOURCE_DIR}")
  else()
    # This stub does not implement download/fetch.  For the LIBRA test suite
    # SOURCE_DIR is always provided.
    message(FATAL_ERROR
      "CPMAddPackage: this vendored CPM stub only supports SOURCE_DIR. "
      "Provide SOURCE_DIR pointing to a local checkout of '${CPM_NAME}'.")
  endif()

  # Cache for idempotency on subsequent calls
  set(CPM_${CPM_NAME}_SOURCE_DIR "${_source_dir}" CACHE INTERNAL
    "CPM source dir for ${CPM_NAME}")

  # Export to caller
  set(${CPM_NAME}_SOURCE_DIR "${_source_dir}" PARENT_SCOPE)
  set(${CPM_NAME}_ADDED TRUE PARENT_SCOPE)

  message(STATUS "CPM: adding '${CPM_NAME}' from local source '${_source_dir}'")

  # add_subdirectory() unless explicitly suppressed
  if(NOT CPM_DOWNLOAD_ONLY OR NOT "${CPM_DOWNLOAD_ONLY}" STREQUAL "YES")
    if(EXISTS "${_source_dir}/CMakeLists.txt")
      set(_binary_dir "${CMAKE_BINARY_DIR}/_cpm/${CPM_NAME}")
      add_subdirectory("${_source_dir}" "${_binary_dir}" EXCLUDE_FROM_ALL)
    else()
      message(STATUS
        "CPM: '${CPM_NAME}' has no CMakeLists.txt - skipping add_subdirectory()")
    endif()
  endif()
endfunction()

# Convenience alias matching the full CPM API
function(CPMFindPackage)
  CPMAddPackage(${ARGN})
endfunction()
