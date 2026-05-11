#
# Copyright 2026 John Harwell, All rights reserved.
#
# SPDX-License-Identifier: MIT
#
include(libra/messaging)

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

  Version is resolved through the following priority chain:

  1. **Tagged commit** — HEAD carries an exact git tag whose format matches
     ``vMAJOR.MINOR.PATCH`` or ``vMAJOR.MINOR.PATCH-PRERELEASE``, per semantic
     versioning.  This is the normal state for every consumable build (stable
     release or a ``dev.N`` / ``rc.N`` prerelease produced by CI).

  2. **Untagged commit** — HEAD is not directly tagged.  The nearest
     ancestor tag is located via ``git describe --tags --long`` and the
     result is annotated with the commit distance so the version string is
     unique and clearly non-releasable.  A warning is emitted.

  3. **No git / no tags** — all version variables are set to ``0.0.0`` with
     an empty prerelease component and a warning is emitted.  This covers
     source tarballs and shallow clones that predate any tag.

  **Variables set in the calling scope:**

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
     :camke:variable`LIBRA_PROJECT_VERSION_NUMERIC` maps to CMake's
     :cmake:variable:`PROJECT_VERSION` after the ``project()`` call, which also
     sets the standard :cmake:variable:`PROJECT_VERSION_MAJOR`,
     :cmake:variable:`PROJECT_VERSION_MINOR`, and
     :cmake:variable:`PROJECT_VERSION_PATCH` components.
     :cmake:variable:`LIBRA_PROJECT_VERSION` and
     :cmake:variable:`LIBRA_PROJECT_VERSION_PRERELEASE` carry the information
     that CMake's own version machinery cannot represent.

  .. NOTE::
     This variable family is distinct from :cmake:variable`LIBRA_VERSION`, which
     is the version of the LIBRA build framework itself.
]]
function(libra_extract_version)
  set(_version_py "${_LIBRA_VERSION_CMAKE_DIR}/version.py")

  execute_process(
    COMMAND python3 "${_version_py}"
    OUTPUT_VARIABLE _full
    OUTPUT_STRIP_TRAILING_WHITESPACE)

  execute_process(
    COMMAND python3 "${_version_py}" --numeric
    OUTPUT_VARIABLE _numeric
    OUTPUT_STRIP_TRAILING_WHITESPACE)

  execute_process(
    COMMAND python3 "${_version_py}" --prerelease
    OUTPUT_VARIABLE _prerelease
    OUTPUT_STRIP_TRAILING_WHITESPACE)

  # fallback if python3/git unavailable
  if("${_full}" STREQUAL "")
    libra_message(
      WARNING "Failed to extract version: version.py returned nothing."
      "Falling back to 0.0.0.")
    set(_full "0.0.0")
    set(_numeric "0.0.0")
    set(_prerelease "")
  else()
    libra_message(STATUS "Extracted git project version ${_full}")
  endif()

  set(LIBRA_PROJECT_VERSION
      "${_full}"
      PARENT_SCOPE)
  set(LIBRA_PROJECT_VERSION_NUMERIC
      "${_numeric}"
      PARENT_SCOPE)
  set(LIBRA_PROJECT_VERSION_PRERELEASE
      "${_prerelease}"
      PARENT_SCOPE)
endfunction()

# cmake-format: off
# ------------------------------------------------------------------------------
# Internal helper: parse a raw tag string into _numeric and _prerelease.
#
# Accepts tags of the forms:
#   v1.5.0          -> _numeric = 1.5.0   _prerelease = ""
#   v1.5.0-dev.3    -> _numeric = 1.5.0   _prerelease = dev.3
#   v1.5.0-rc.1     -> _numeric = 1.5.0   _prerelease = rc.1
#
# Sets _numeric and _prerelease in the caller's local scope via macro (avoids
# PARENT_SCOPE boilerplate at every callsite inside the function).
# ------------------------------------------------------------------------------
# cmake-format: on
macro(_libra_parse_semver_tag _raw)
  string(REGEX REPLACE "^v" "" _stripped "${_raw}")

  if(_stripped MATCHES
     "^([0-9]+\\.[0-9]+\\.[0-9]+)(-([a-zA-Z0-9][a-zA-Z0-9._-]*))?$")
    set(_numeric "${CMAKE_MATCH_1}")
    set(_prerelease "${CMAKE_MATCH_3}")
  else()
    message(
      WARNING
        "[LIBRA] libra_extract_version: tag '${_raw}' does not match expected "
        "semver format (vMAJOR.MINOR.PATCH[-PRERELEASE]). Falling back to 0.0.0."
    )
    set(_numeric "0.0.0")
    set(_prerelease "")
  endif()
endmacro()
