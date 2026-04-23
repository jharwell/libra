#
# Copyright 2025 John Harwell, All rights reserved.
#
# SPDX-License-Identifier: MIT
#
# libra_consume.cmake
#
# Included by every sample project CMakeLists.txt to wire up LIBRA according to
# the consumption mode requested by the test harness.  The mode is selected by
# the LIBRA_CONSUME_MODE cache variable, which is injected as a -D argument by
# run_libra_cmake_test() in test_helpers.bash.
#
# Supported modes (value of LIBRA_CONSUME_MODE):
#
# in_situ (default) The original behaviour: CMAKE_MODULE_PATH is pointed at the
# cmake/ directory two levels above the tests/ tree.  Requires LIBRA_SOURCE_ROOT
# to be set (injected by the test helper) or falls back to the relative path
# that the original samples used.
#
# add_subdirectory LIBRA is pulled in via add_subdirectory().  LIBRA_SOURCE_ROOT
# must point to the LIBRA repository root.  LIBRA's own root CMakeLists.txt is
# expected to append cmake/ to CMAKE_MODULE_PATH; if it does not (i.e. LIBRA has
# no root CMakeLists.txt) we append it ourselves.
#
# installed_package LIBRA has been installed to a prefix and is located via
# find_package(). CMAKE_PREFIX_PATH must already include the install prefix; the
# test helper sets this via -DCMAKE_PREFIX_PATH=<prefix>. After find_package()
# conan-style builddirs semantics don't apply here, so we manually append the
# installed cmake/ dir to CMAKE_MODULE_PATH using the libra_DIR hint that
# find_package() populates.
#
# cpm LIBRA is pulled in via CPM.cmake using a local SOURCE_DIR (no network
# required).  LIBRA_CPM_CMAKE must point to CPM.cmake and LIBRA_SOURCE_ROOT must
# point to the LIBRA repo root.  After CPMAddPackage() we append the cmake/
# subdir of the fetched source to CMAKE_MODULE_PATH.
#
# conan LIBRA has been installed into the Conan local cache via `conan create`
# and a conan_toolchain.cmake has been generated in the build directory by
# `conan install`.  We include that toolchain here; Conan's toolchain sets
# CMAKE_MODULE_PATH to include the package's builddirs (cmake/), so
# include(libra/project) works directly afterwards.
#

if(NOT DEFINED LIBRA_CONSUME_MODE OR LIBRA_CONSUME_MODE STREQUAL "in_situ")
  # ── in_situ ──────────────────────────────────────────────────────────────
  # Prefer the injected LIBRA_SOURCE_ROOT so the helper controls the path; fall
  # back to the historical relative path so samples still work when run directly
  # without going through the test harness.
  if(DEFINED LIBRA_SOURCE_ROOT)
    set(CMAKE_MODULE_PATH "${LIBRA_SOURCE_ROOT}/cmake")
  else()
    set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../../cmake")
  endif()

elseif(LIBRA_CONSUME_MODE STREQUAL "add_subdirectory")
  # ── add_subdirectory ──────────────────────────────────────────────────────
  if(NOT DEFINED LIBRA_SOURCE_ROOT)
    message(
      FATAL_ERROR
        "libra_consume: LIBRA_SOURCE_ROOT must be set for add_subdirectory mode"
    )
  endif()

  # Guard against double-inclusion if multiple sample sub-projects exist
  if(NOT TARGET libra_module_path_set)
    # LIBRA may or may not have a root CMakeLists.txt that handles this itself.
    # We use add_subdirectory only when a CMakeLists.txt is present; otherwise
    # we fall back to manually setting the module path.
    if(EXISTS "${LIBRA_SOURCE_ROOT}/CMakeLists.txt")
      add_subdirectory("${LIBRA_SOURCE_ROOT}" "${CMAKE_BINARY_DIR}/_libra_src"
                       EXCLUDE_FROM_ALL)
    endif()
    # Whether or not add_subdirectory() ran, ensure cmake/ is on the path.
    # Prepend so it takes priority over any system-installed version.
    list(PREPEND CMAKE_MODULE_PATH "${LIBRA_SOURCE_ROOT}/cmake")
    # Sentinel so nested directories (e.g. consumer/) don't repeat this
    add_custom_target(libra_module_path_set)
  endif()

elseif(LIBRA_CONSUME_MODE STREQUAL "installed_package")
  # ── installed_package ────────────────────────────────────────────────────
  # CMAKE_PREFIX_PATH is set by the test helper via
  # -DCMAKE_PREFIX_PATH=<prefix>. LIBRA is a cmake-module-only package so there
  # is no compiled library to link; find_package locates the config file and we
  # use the resolved prefix to set CMAKE_MODULE_PATH.
  find_package(libra REQUIRED CONFIG)
  # libra_DIR is set by find_package to the directory containing
  # libra-config.cmake. That file lives at <prefix>/cmake/libra-config.cmake, so
  # one level up is <prefix>/cmake — exactly what we need on CMAKE_MODULE_PATH.
  get_filename_component(_libra_cmake_dir "${libra_DIR}" DIRECTORY)
  list(PREPEND CMAKE_MODULE_PATH "${_libra_cmake_dir}")

elseif(LIBRA_CONSUME_MODE STREQUAL "cpm")
  # ── CPM ───────────────────────────────────────────────────────────────────
  if(NOT DEFINED LIBRA_CPM_CMAKE)
    message(
      FATAL_ERROR
        "libra_consume: LIBRA_CPM_CMAKE must point to CPM.cmake for cpm mode")
  endif()
  if(NOT DEFINED LIBRA_SOURCE_ROOT)
    message(
      FATAL_ERROR "libra_consume: LIBRA_SOURCE_ROOT must be set for cpm mode")
  endif()

  include("${LIBRA_CPM_CMAKE}")

  # SOURCE_DIR tells CPM to use a local directory instead of downloading.
  # DOWNLOAD_ONLY YES avoids CPM trying to call add_subdirectory() on a
  # cmake-module-only project that may not have a suitable CMakeLists.txt.
  cpmaddpackage(
    NAME
    libra
    SOURCE_DIR
    "${LIBRA_SOURCE_ROOT}"
    DOWNLOAD_ONLY
    YES)

  # CPM sets libra_SOURCE_DIR after CPMAddPackage()
  list(PREPEND CMAKE_MODULE_PATH "${libra_SOURCE_DIR}/cmake")

elseif(LIBRA_CONSUME_MODE STREQUAL "conan")
  # ── conan ─────────────────────────────────────────────────────────────────
  # The test helper has already run `conan install` in the build directory,
  # which produces conan_toolchain.cmake.  Including it populates
  # CMAKE_MODULE_PATH with the package's builddirs (cmake/), after which
  # include(libra/project) works without any further setup.
  set(_conan_toolchain "${CMAKE_BINARY_DIR}/conan/conan_toolchain.cmake")
  if(NOT EXISTS "${_conan_toolchain}")
    message(
      FATAL_ERROR
        "libra_consume: conan_toolchain.cmake not found at '${_conan_toolchain}'.\n"
        "The test helper must run 'conan install' before cmake is invoked.")
  endif()
  include("${_conan_toolchain}")

else()
  message(
    FATAL_ERROR
      "libra_consume: unknown LIBRA_CONSUME_MODE '${LIBRA_CONSUME_MODE}'.\n"
      "Valid values: in_situ, add_subdirectory, installed_package, cpm, conan")
endif()
