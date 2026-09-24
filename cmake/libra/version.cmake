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

#[[.rst:
.. cmake:command:: libra_resolve_self_version

  Resolve the version of the LIBRA framework itself and set
  :cmake:variable:`LIBRA_VERSION` in the calling scope.

  Independent of :cmake:command:`libra_extract_version`, which resolves the
  *consuming project's* version. Resolution order:

  1. **Baked** ``self.cmake`` with a real value: a Conan package, or a
     ``git archive`` tarball where ``export-subst`` expanded the template.
     Artifacts are authoritative about what they contain.

  2. **Git in LIBRA's own checkout** (CPM git fetch, submodule, development
     tree). Only trusted if the repository git finds is rooted exactly at
     LIBRA's root; a LIBRA copy without its own ``.git`` inside some other
     repository would otherwise report that repository's tags.

  3. ``0.0.0``.

  Emits no warnings for untagged LIBRA commits; that is normal when developing
  LIBRA via a local source override.
]]
function(libra_resolve_self_version)
  file(REAL_PATH "${_LIBRA_VERSION_CMAKE_DIR}/../.." _libra_root)

  _libra_resolve_from_baked(_v)
  if(NOT _v_full)
    _libra_resolve_from_git("${_libra_root}" TRUE FALSE _v)
  endif()
  if(NOT _v_full)
    set(_v_full "0.0.0")
  endif()

  set(LIBRA_VERSION
      "${_v_full}"
      CACHE INTERNAL "")
endfunction()

# cmake-format: off
# ------------------------------------------------------------------------------
# Internal helper: resolve a version from git in <dir>.
#
# If <require_toplevel> is true, git output is only trusted when the repository
# root is exactly <dir> (prevents walking up into an enclosing repository).
# If <warn> is true, an untagged commit emits a "not releasable" warning.
#
# Sets <prefix>_full, <prefix>_numeric, <prefix>_prerelease in the caller's
# scope; all empty if nothing could be resolved.
# ------------------------------------------------------------------------------
# cmake-format: on
function(
  _libra_resolve_from_git
  _dir
  _require_toplevel
  _warn
  _prefix)
  set(_full "")
  set(_numeric "")
  set(_prerelease "")
  set(_distance "")

  if(_require_toplevel)
    _libra_git("${_dir}" _top rev-parse --show-toplevel)
    if(_top)
      file(REAL_PATH "${_top}" _top)
    endif()
    if(NOT _top STREQUAL _dir)
      _libra_return_version(${_prefix})
      return()
    endif()
  endif()

  # 1. Exact tag on HEAD.
  _libra_git(
    "${_dir}"
    _tag
    describe
    --exact-match
    --tags)
  if(_tag)
    _libra_parse_semver_tag("${_tag}")
    _libra_assemble_full()
  endif()

  # 1. Nearest ancestor tag + commit distance.
  if(NOT _full)
    _libra_git(
      "${_dir}"
      _described
      describe
      --tags
      --long)
    if(_described)
      _libra_parse_git_describe("${_described}")
      _libra_assemble_full()
      if(NOT _full)
        message(WARNING "[LIBRA] unrecognized git describe format "
                        "'${_described}' in ${_dir}.")
      elseif(_distance AND _warn)
        message(WARNING "[LIBRA] libra_extract_version: building an untagged "
                        "commit; version ${_full} is not releasable.")
      endif()
    endif()
  endif()

  _libra_return_version(${_prefix})
endfunction()

# cmake-format: off
# ------------------------------------------------------------------------------
# Internal helper: read LIBRA's baked self.cmake.
#
# Accepts every form a bake can take:
#   0.13.13 / v0.13.13-dev.2          (Conan package() from a tag)
#   0.13.12+3.g5f7115c                (Conan package() from an untagged commit)
#   v0.13.12-3-g5f7115c               (git archive export-subst, untagged)
# The committed template (unexpanded $Format:...$) counts as "not baked".
#
# Sets <prefix>_full, <prefix>_numeric, <prefix>_prerelease in the caller's
# scope; all empty if nothing usable is baked.
# ------------------------------------------------------------------------------
# cmake-format: on
function(_libra_resolve_from_baked _prefix)
  set(_full "")
  set(_numeric "")
  set(_prerelease "")

  set(_self "${_LIBRA_VERSION_CMAKE_DIR}/self.cmake")
  if(EXISTS "${_self}")
    # Local to this function: including self.cmake must not leak the raw
    # (possibly template) LIBRA_VERSION into the caller.
    set(LIBRA_VERSION "")
    include("${_self}")
    if(LIBRA_VERSION AND NOT LIBRA_VERSION MATCHES "^\\$Format")
      _libra_parse_version_string("${LIBRA_VERSION}")
    endif()
  endif()

  _libra_return_version(${_prefix})
endfunction()

# cmake-format: off
# ------------------------------------------------------------------------------
# Internal helper: run git in <dir> and capture trimmed stdout into <out_var>.
#
# Sets <out_var> to the empty string on any failure -- git not installed
# (command not found), not a repo, no tags, no exact match, etc. -- so callers
# can treat "" as "unavailable" and fall through the resolution chain. Sets
# <out_var> in the caller's scope via macro.
# ------------------------------------------------------------------------------
# cmake-format: on
macro(_libra_git _git_dir _out_var)
  execute_process(
    COMMAND git ${ARGN}
    WORKING_DIRECTORY "${_git_dir}"
    OUTPUT_VARIABLE ${_out_var}
    OUTPUT_STRIP_TRAILING_WHITESPACE
    RESULT_VARIABLE _libra_git_rc
    ERROR_QUIET)
  if(NOT _libra_git_rc EQUAL 0)
    set(${_out_var} "")
  endif()
endmacro()

# Internal helper: export _full/_numeric/_prerelease as <prefix>_* to the caller
# of the enclosing function.
macro(_libra_return_version _pfx)
  set(${_pfx}_full
      "${_full}"
      PARENT_SCOPE)
  set(${_pfx}_numeric
      "${_numeric}"
      PARENT_SCOPE)
  set(${_pfx}_prerelease
      "${_prerelease}"
      PARENT_SCOPE)
endmacro()

# Internal helper: build _full from _numeric, _prerelease, _distance, _sha.
# _full is empty if _numeric is. A distance of 0 means HEAD is the tagged
# commit, so no build metadata is appended.
macro(_libra_assemble_full)
  set(_full "")
  if(_numeric)
    set(_full "${_numeric}")
    if(_prerelease)
      set(_full "${_full}-${_prerelease}")
    endif()
    if(_distance)
      set(_full "${_full}+${_distance}.g${_sha}")
    endif()
  endif()
endmacro()

# Internal helper: parse a version string that may be a tag, a SemVer version
# with +build metadata, or git-describe output. Sets _numeric, _prerelease,
# _full in the caller's scope.
macro(_libra_parse_version_string _raw_ver)
  set(_distance "")
  set(_sha "")
  set(_libra_build "")
  if("${_raw_ver}" MATCHES "^(.+)-([0-9]+)-g([0-9a-f]+)$")
    _libra_parse_git_describe("${_raw_ver}")
    _libra_assemble_full()
  else()
    set(_libra_base "${_raw_ver}")
    if(_libra_base MATCHES "^([^+]+)\\+([0-9A-Za-z.-]+)$")
      set(_libra_base "${CMAKE_MATCH_1}")
      set(_libra_build "${CMAKE_MATCH_2}")
    endif()
    _libra_parse_semver_tag("${_libra_base}")
    _libra_assemble_full()
    if(_full AND _libra_build)
      set(_full "${_full}+${_libra_build}")
    endif()
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
