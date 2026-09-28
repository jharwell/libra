#
# Copyright 2026 John Harwell, All rights reserved.
#
# SPDX-License-Identifier: MIT
#
include(libra/messaging)
include(libra/version-impl)

# Captured when version.cmake is include()'d -- at this point
# CMAKE_CURRENT_LIST_DIR correctly points at cmake/libra/. Inside
# libra_extract_version() it would point at the caller's directory.
set(_LIBRA_VERSION_CMAKE_DIR "${CMAKE_CURRENT_LIST_DIR}")

#[[.rst:
.. cmake:command:: libra_extract_version

  Derive the project version from the current git state and expose it as
  CMake variables in the calling scope.

  This function MUST be called before ``project()`` so that
  :cmake:variable:`LIBRA_PROJECT_VERSION_NUMERIC` is available for
  ``project(VERSION ...)``. Because it runs before ``libra/messaging`` is loaded
  it uses plain ``message()`` internally rather than ``libra_message()``.

  Version is resolved through a four-tier priority chain (exact tag ->
  untagged commit annotated via ``git describe`` -> baked ``self.cmake``
  fallback -> ``0.0.0``). See :ref:`concepts/versioning/source-of-truth` for
  the authoritative description of each tier and the resulting version
  strings; this docstring intentionally does not restate it to avoid drift.

  Git is run in the calling project's source directory
  (``CMAKE_CURRENT_SOURCE_DIR``), never in LIBRA's. The baked ``self.cmake``
  tier applies only when the calling project *is* LIBRA; any other project
  without git gets ``0.0.0`` rather than LIBRA's version.

  **Cache variables set:**

  - :cmake:variable:`LIBRA_PROJECT_VERSION`
  - :cmake:variable:`LIBRA_PROJECT_VERSION_NUMERIC`
  - :cmake:variable:`LIBRA_PROJECT_VERSION_PRERELEASE`

  **Typical usage in a consuming project:**

  .. code-block:: cmake

    # CMakeLists.txt -- before including libra/project
    include(libra/version)
    libra_extract_version()

    # libra/project then calls:
    #   project(... VERSION ${LIBRA_PROJECT_VERSION_NUMERIC} ...)
    include(libra/project)

    message(STATUS "${PROJECT_NAME} ${LIBRA_PROJECT_VERSION}")

  **CPM dependency consumption:**

  .. code-block:: cmake

    # GIT_TAG takes the full semver tag (prerelease suffix included).
    # VERSION takes the numeric component only (CMake deduplication key).
    CPMAddPackage(
      NAME    mydep
      GIT_TAG v${LIBRA_PROJECT_VERSION}
      VERSION   ${LIBRA_PROJECT_VERSION_NUMERIC}
    )

  .. NOTE::
     :cmake:variable:`LIBRA_PROJECT_VERSION_NUMERIC` maps to CMake's
     :cmake:variable:`PROJECT_VERSION` after the ``project()`` call, which also
     sets the standard :cmake:variable:`PROJECT_VERSION_MAJOR`,
     :cmake:variable:`PROJECT_VERSION_MINOR`, and
     :cmake:variable:`PROJECT_VERSION_PATCH` components.
     :cmake:variable:`LIBRA_PROJECT_VERSION` and
     :cmake:variable:`LIBRA_PROJECT_VERSION_PRERELEASE` carry the information
     that CMake's own version machinery cannot represent.

  .. NOTE::
     This variable family is distinct from :cmake:variable:`LIBRA_VERSION`, which
     is the version of the LIBRA build framework itself.
]]
function(libra_extract_version)
  file(REAL_PATH "${CMAKE_CURRENT_SOURCE_DIR}" _dir)
  file(REAL_PATH "${_LIBRA_VERSION_CMAKE_DIR}/../.." _libra_root)

  # Tiers 1-2: git, in the PROJECT's directory. No toplevel requirement: a
  # project's CMakeLists.txt may live in a subdirectory of its repo.
  _libra_resolve_from_git("${_dir}" FALSE TRUE _v)

  # Tier 3: baked self.cmake -- LIBRA only.
  if(NOT _v_full AND _dir STREQUAL _libra_root)
    _libra_resolve_from_baked(_v)
  endif()

  # Tier 4: nothing available.
  if(NOT _v_full)
    libra_message(WARNING "Failed to extract version from git or self.cmake. "
                  "Falling back to 0.0.0.")
    set(_v_numeric "0.0.0")
    set(_v_full "0.0.0")
    set(_v_prerelease "")
  else()
    libra_message(STATUS "Extracted project version ${_v_full}")
  endif()

  # Setting the normal variables too means nested projects each see their own
  # version inside CMake, while the cache holds only the top-level one for
  # clibra.
  if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    set(LIBRA_PROJECT_VERSION
        "${_v_full}"
        CACHE INTERNAL "")
    set(LIBRA_PROJECT_VERSION_NUMERIC
        "${_v_numeric}"
        CACHE INTERNAL "")
    set(LIBRA_PROJECT_VERSION_PRERELEASE
        "${_v_prerelease}"
        CACHE INTERNAL "")
  else()
    set(LIBRA_PROJECT_VERSION
        "${_v_full}"
        PARENT_SCOPE)
    set(LIBRA_PROJECT_VERSION_NUMERIC
        "${_v_numeric}"
        PARENT_SCOPE)
    set(LIBRA_PROJECT_VERSION_PRERELEASE
        "${_v_prerelease}"
        PARENT_SCOPE)
  endif()
endfunction()
