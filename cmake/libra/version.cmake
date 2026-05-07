#
# Copyright 2026 John Harwell, All rights reserved.
#
# SPDX-License-Identifier: MIT
#
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

  # --------------------------------------------------------------------------
  # Priority 1: exact tag on HEAD (normal consumable state).
  # --------------------------------------------------------------------------
  execute_process(
    COMMAND git describe --exact-match --tags
    OUTPUT_VARIABLE _exact_tag
    ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE)

  if(NOT "${_exact_tag}" STREQUAL "")
    _libra_parse_semver_tag("${_exact_tag}")

    if(_prerelease STREQUAL "")
      set(_full "${_numeric}")
    else()
      set(_full "${_numeric}-${_prerelease}")
    endif()

    message(STATUS "[LIBRA] libra_extract_version: ${_full} (tagged)")

  else()
    # --------------------------------------------------------------------------
    # Priority 2: nearest ancestor tag + commit distance.
    # --------------------------------------------------------------------------
    execute_process(
      COMMAND git describe --tags --long
      OUTPUT_VARIABLE _describe
      ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE)

    if(NOT "${_describe}" STREQUAL "")
      # Strip the trailing -N-gSHA that git appended to recover the base tag,
      # then reattach the distance and SHA as a build-metadata suffix so the
      # resulting string is unique and clearly non-releasable.
      string(REGEX MATCH "-([0-9]+)-g([0-9a-f]+)$" _suffix_match "${_describe}")
      set(_distance "${CMAKE_MATCH_1}")
      set(_sha "${CMAKE_MATCH_2}")

      string(REGEX REPLACE "-[0-9]+-g[0-9a-f]+$" "" _base_tag "${_describe}")

      _libra_parse_semver_tag("${_base_tag}")

      # Construct a synthetic prerelease that preserves the original label (if
      # any), appends the commit distance, and records the SHA. The '+'
      # separator is semver build-metadata -- it signals identity information
      # rather than version precedence.
      if(_prerelease STREQUAL "")
        set(_synthetic "untagged.${_distance}+g${_sha}")
      else()
        set(_synthetic "${_prerelease}.untagged.${_distance}+g${_sha}")
      endif()

      set(_full "${_numeric}-${_synthetic}")
      set(_prerelease "${_synthetic}")

      message(
        WARNING
          "[LIBRA] libra_extract_version: HEAD is not on a tagged commit. "
          "Derived version: ${_full}. "
          "Tag a commit or run the release CI workflow to produce a "
          "releasable version identifier.")

    else()
      # --------------------------------------------------------------------------
      # Priority 3: no git repository or no reachable tags.
      # --------------------------------------------------------------------------
      message(
        WARNING
          "[LIBRA] libra_extract_version: no git repository or no reachable "
          "tags found. Version set to 0.0.0. Build metadata will not be "
          "meaningful. This is expected for source tarballs and shallow clones."
      )

      set(_numeric "0.0.0")
      set(_prerelease "")
      set(_full "0.0.0")
    endif()
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
