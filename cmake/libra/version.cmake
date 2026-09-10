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
     result is annotated with the commit distance and abbreviated SHA as
     SemVer build metadata so the version string is unique and clearly
     non-releasable.  A warning is emitted.

  3. **No git / no tags — baked fallback** — git is unavailable, HEAD has no
     reachable tag, or the tree is a source tarball / shallow clone.  The
     value baked into ``self.cmake`` at release time (``LIBRA_VERSION``) is
     used so diagnostics still report a meaningful version.  A warning is
     emitted.

  4. **Nothing available** — none of the above resolved; all version
     variables are set to ``0.0.0`` with an empty prerelease component and a
     warning is emitted.

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
  set(_numeric "")
  set(_full "")
  set(_prerelease "")

  # ---------------------------------------------------------------------------
  # 1. Exact tag on HEAD.
  # ---------------------------------------------------------------------------
  _libra_git(_tag describe --exact-match --tags)
  if(_tag)
    _libra_parse_semver_tag("${_tag}")
    set(_full "${_numeric}")
    if(_prerelease)
      set(_full "${_numeric}-${_prerelease}")
    endif()
  else()
    # -------------------------------------------------------------------------
    # 1. Nearest ancestor tag + commit distance.
    # -------------------------------------------------------------------------
    _libra_git(_described describe --tags --long)
    if(_described)
      _libra_parse_git_describe("${_described}")
      if(NOT _numeric)
        message(
          WARNING
            "[LIBRA] libra_extract_version: unrecognized git describe format "
            "'${_described}'. Falling back to baked/0.0.0.")
      elseif(_distance STREQUAL "" OR _distance STREQUAL "0")
        # HEAD is the tagged commit (0 commits ahead): behave like an exact tag.
        set(_full "${_numeric}")
        if(_prerelease)
          set(_full "${_numeric}-${_prerelease}")
        endif()
      else()
        # Untagged commit: annotate with SemVer build metadata (+distance.gsha).
        set(_full "${_numeric}")
        if(_prerelease)
          set(_full "${_full}-${_prerelease}")
        endif()
        set(_full "${_full}+${_distance}.g${_sha}")
        message(
          WARNING "[LIBRA] libra_extract_version: building an untagged commit; "
                  "version ${_full} is not releasable.")
      endif()
    endif()
  endif()

  # ---------------------------------------------------------------------------
  # 1. Git-less fallback: baked LIBRA_VERSION in self.cmake (CPM / tarballs).
  # ---------------------------------------------------------------------------
  if(NOT _full)
    set(_self "${_LIBRA_VERSION_CMAKE_DIR}/self.cmake")
    if(EXISTS "${_self}")
      include("${_self}")
      if(LIBRA_VERSION)
        _libra_parse_semver_tag("${LIBRA_VERSION}")
        set(_full "${_numeric}")
        if(_prerelease)
          set(_full "${_numeric}-${_prerelease}")
        endif()
      endif()
    endif()
  endif()

  # ---------------------------------------------------------------------------
  # 1. Nothing available.
  # ---------------------------------------------------------------------------
  if(NOT _full)
    libra_message(WARNING "Failed to extract version from git or self.cmake."
                  "Falling back to 0.0.0.")
    set(_numeric "0.0.0")
    set(_full "0.0.0")
    set(_prerelease "")
  else()
    libra_message(STATUS "Extracted project version ${_full}")
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
# Internal helper: run git and capture trimmed stdout into <out_var>.
#
# Sets <out_var> to the empty string on any failure -- git not installed
# (command not found), not a repo, no tags, no exact match, etc. -- so callers
# can treat "" as "unavailable" and fall through the resolution chain. Sets
# <out_var> in the caller's scope via macro.
# ------------------------------------------------------------------------------
# cmake-format: on
macro(_libra_git _out_var)
  execute_process(
    COMMAND git ${ARGN}
    OUTPUT_VARIABLE ${_out_var}
    OUTPUT_STRIP_TRAILING_WHITESPACE
    RESULT_VARIABLE _libra_git_rc
    ERROR_QUIET)
  if(NOT _libra_git_rc EQUAL 0)
    set(${_out_var} "")
  endif()
endmacro()

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
# PARENT_SCOPE boilerplate at every callsite inside the function). On a
# non-matching tag, sets _numeric to "" so callers can detect the failure and
# continue down the resolution chain rather than hard-coding 0.0.0 here.
# ------------------------------------------------------------------------------
# cmake-format: on
macro(_libra_parse_semver_tag _raw)
  string(REGEX REPLACE "^v" "" _stripped "${_raw}")

  if(_stripped MATCHES
     "^([0-9]+\\.[0-9]+\\.[0-9]+)(-([a-zA-Z0-9][a-zA-Z0-9._-]*))?$")
    set(_numeric "${CMAKE_MATCH_1}")
    set(_prerelease "${CMAKE_MATCH_3}")
  else()
    set(_numeric "")
    set(_prerelease "")
  endif()
endmacro()

# cmake-format: off
# ------------------------------------------------------------------------------
# Internal helper: parse `git describe --tags --long` output into
# _numeric, _prerelease, _distance, _sha.
#
# Handles tags of the form:
#   v1.2.3-2-gabcdef1           -> 1.2.3   ""      2   abcdef1
#   v1.2.3-dev.4-2-gabcdef1     -> 1.2.3   dev.4   2   abcdef1
#   v1.2.3-rc-1-2-gabcdef1      -> 1.2.3   rc-1    2   abcdef1
#
# CMake regex has no lazy quantifier, so we cannot express a greedy-minimal
# prerelease group directly. Instead we peel the anchored `-<distance>-g<sha>`
# suffix off the END first (that grammar is unambiguous: distance is digits, sha
# is hex after `-g`), then parse the remaining base with
# _libra_parse_semver_tag. This keeps a prerelease that itself contains hyphens
# (e.g. rc-1) intact instead of misattributing it to the suffix.  Sets the four
# vars in the caller's local scope via macro.
# ------------------------------------------------------------------------------
# cmake-format: on
macro(_libra_parse_git_describe _described)
  set(_distance "")
  set(_sha "")

  if("${_described}" MATCHES "^(.+)-([0-9]+)-g([0-9a-f]+)$")
    set(_base "${CMAKE_MATCH_1}")
    set(_distance "${CMAKE_MATCH_2}")
    set(_sha "${CMAKE_MATCH_3}")
  else()
    set(_base "${_described}")
  endif()

  _libra_parse_semver_tag("${_base}")
endmacro()
