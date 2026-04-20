#
# Copyright 2026 John Harwell, All rights reserved.
#
# SPDX-License Identifier: MIT
#

#[[.rst
.. cmake:command:: _libra_configure_source_file_post

Do the actual work of configuring a source file. This is separate from
:cmake:command:`libra_configure_source_file()` because so the API version can be
available in project-local.cmake. Target compile flags/options/etc aren't
necessarily fully set until AFTER project-local.cmake is included, so if we try
to filter out build flags at that point, we will get nothing. This is not
pretty, but it does work.

This function does two-pass file generation to actually configure the source file:

Pass 1 - configure_file(): resolves @VAR@, ${VAR}, #cmakedefine, etc. into an
intermediate file. Any $<genex> the user wrote survive as literal text.

Pass 2 - file(GENERATE ...): takes the intermediate file, resolves all
remaining genexes in the context of TARGET so $<COMPILE_LANGUAGE:...>,
$<CONFIG:...>, etc. all work correctly.

This was done to avoid having to re-implement non-trivial chunks of CMake's
genex parser so that we could extract genex-based compiler flags/options/etc
from targets.

Variables available to the template:

- LIBRA_GIT_REV              - current git commit hash (or "N/A")
- LIBRA_GIT_DIFF             - "+" if working tree is dirty, else ""
- LIBRA_GIT_TAG              - current git tag (or "")
- LIBRA_GIT_BRANCH           - current git branch
- LIBRA_TARGET_FLAGS_COMPILE - space-separated compile options/definitions.
  COMPILE_LANGUAGE and LINK_LANGUAGE genex wrappers are unwrapped — the flag
  values are kept, the guards are dropped. This avoids the "written multiple
  times with different content" error from file(GENERATE ...) and means the
  string is usable directly without any genex evaluation.
- LIBRA_TARGET_FLAGS_LINK    - space-separated link options. LINK_LANGUAGE
  genex wrappers are likewise unwrapped — flag values kept, guards dropped.
]]
function(_libra_configure_source_file_post TARGET INFILE OUTFILE)
  # --------------------------------------------------------------------------
  # Git information
  # --------------------------------------------------------------------------
  execute_process(
    COMMAND git log --pretty=format:%H -n 1
    OUTPUT_VARIABLE LIBRA_GIT_REV
    ERROR_QUIET)

  # Check whether we got any revision (which isn't always the case, e.g. when
  # someone downloaded a zip file from Github instead of a checkout)
  if("${LIBRA_GIT_REV}" STREQUAL "")
    libra_message(
      WARNING
      "libra_configure_source_file: Not in a git repository - stubbing version information\n"
      "  Git-related variables will be set to 'N/A'")
    set(LIBRA_GIT_REV "N/A")
    set(LIBRA_GIT_DIFF "")
    set(LIBRA_GIT_TAG "N/A")
    set(LIBRA_GIT_BRANCH "N/A")
  else()
    execute_process(COMMAND bash -c "git diff --quiet --exit-code || echo +"
                    OUTPUT_VARIABLE LIBRA_GIT_DIFF)
    execute_process(
      COMMAND git describe --exact-match --tags
      OUTPUT_VARIABLE LIBRA_GIT_TAG
      ERROR_QUIET)
    execute_process(COMMAND git rev-parse --abbrev-ref HEAD
                    OUTPUT_VARIABLE LIBRA_GIT_BRANCH)

    string(STRIP "${LIBRA_GIT_REV}" LIBRA_GIT_REV)
    string(STRIP "${LIBRA_GIT_DIFF}" LIBRA_GIT_DIFF)
    string(STRIP "${LIBRA_GIT_TAG}" LIBRA_GIT_TAG)
    string(STRIP "${LIBRA_GIT_BRANCH}" LIBRA_GIT_BRANCH)
  endif()

  # --------------------------------------------------------------------------
  # Collect compile flags.
  #
  # build-types.cmake now emits one genex per flag:
  #   $<$<COMPILE_LANGUAGE:X>:flag>
  # so COMPILE_OPTIONS contains individual well-formed entries with no embedded
  # semicolons. We can safely iterate with foreach(IN LISTS ...) and join with
  # spaces. file(GENERATE ...) resolves the COMPILE_LANGUAGE wrappers correctly
  # when TARGET is supplied.
  #
  # LINK_OPTIONS entries are $<$<LINK_LANGUAGE:X>:flag> which file(GENERATE ...)
  # forbids entirely. Instead we build LIBRA_TARGET_FLAGS_LINK directly from the
  # plain _LIBRA_C_LINK_OPTIONS / _LIBRA_CXX_LINK_OPTIONS lists, which are in
  # scope here (diagnostics_post.cmake is included after build-types.cmake).
  # --------------------------------------------------------------------------
  get_target_property(_compile_opts ${TARGET} COMPILE_OPTIONS)
  get_target_property(_compile_defs ${TARGET} COMPILE_DEFINITIONS)

  set(_compile_parts "")

  # Helper macro: append items from a list, unwrapping genex guards that
  # file(GENERATE ...) cannot handle:
  #
  #   $<$<COMPILE_LANGUAGE:X>:flag>  — unwrap, keep flag value. The language
  #     guard is only needed for the compiler invocation; for embedding all
  #     flags are relevant. Leaving the wrapper causes "written multiple times
  #     with different content" because file(GENERATE ...) evaluates the genex
  #     differently per language context.
  #
  #   $<COMPILE_LANGUAGE:X> (bare/empty) — drop, nothing useful to embed.
  #
  #   Everything else — keep as-is (plain flags, other genexes).
  macro(_libra_collect_compile _items)
    foreach(_item IN LISTS ${_items})
      string(STRIP "${_item}" _item)
      if(NOT _item)
        continue()
      endif()
      if(_item MATCHES "^[$][<][$][<]COMPILE_LANGUAGE:[^>]+[>]:(.+)[>]$")
        list(APPEND _compile_parts "${CMAKE_MATCH_1}")
      elseif(_item MATCHES "COMPILE_LANGUAGE")
        continue()
      else()
        list(APPEND _compile_parts "${_item}")
      endif()
    endforeach()
  endmacro()

  _libra_collect_compile(_compile_opts)
  _libra_collect_compile(_compile_defs)

  # Collect PUBLIC compile definitions from directly-linked libraries.
  # get_target_property(COMPILE_DEFINITIONS) only returns definitions set
  # directly on this target; it does not traverse the link graph.
  # INTERFACE_COMPILE_DEFINITIONS on each linked library is exactly the
  # PUBLIC-only view that target_compile_definitions(...PUBLIC...) populates, so
  # reading it here gives us the transitively-propagated defines without needing
  # generator expressions.
  get_target_property(_link_libs ${TARGET} LINK_LIBRARIES)
  if(_link_libs)
    foreach(_lib IN LISTS _link_libs)
      if(TARGET ${_lib})
        get_target_property(_iface_defs ${_lib} INTERFACE_COMPILE_DEFINITIONS)
        _libra_collect_compile(_iface_defs)
      endif()
    endforeach()
  endif()

  # Plain per-build-type flags — no genex wrapper, safe to append directly.
  string(TOUPPER "${CMAKE_BUILD_TYPE}" _build_type_upper)
  foreach(_flag IN LISTS CMAKE_CXX_FLAGS_${_build_type_upper}
                         CMAKE_C_FLAGS_${_build_type_upper})
    string(STRIP "${_flag}" _flag)
    if(_flag)
      list(APPEND _compile_parts "${_flag}")
    endif()
  endforeach()

  if(LIBRA_LTO)
    foreach(_flag IN LISTS CMAKE_CXX_COMPILE_OPTIONS_IPO
                           CMAKE_C_COMPILE_OPTIONS_IPO)
      string(STRIP "${_flag}" _flag)
      if(_flag)
        list(APPEND _compile_parts "${_flag}")
      endif()
    endforeach()
  endif()

  list(REMOVE_DUPLICATES _compile_parts)
  list(JOIN _compile_parts " " LIBRA_TARGET_FLAGS_COMPILE)

  # --------------------------------------------------------------------------
  # Collect link flags from the target's LINK_OPTIONS property so user-supplied
  # options (added outside LIBRA) are included.
  #
  # $<LINK_LANGUAGE:...> is forbidden by file(GENERATE ...) in all forms, so we
  # unwrap $<$<LINK_LANGUAGE:X>:flag> entries — stripping the genex guard and
  # keeping the flag value. Plain flags and other genexes pass through as-is.
  # Empty-value or bare LINK_LANGUAGE entries (nothing useful to embed) are
  # skipped.
  #
  # IPO link flags are appended separately since they come from CMake built-in
  # variables, not from the target property.
  # --------------------------------------------------------------------------
  get_target_property(_link_opts ${TARGET} LINK_OPTIONS)

  set(_link_parts "")
  if(_link_opts)
    foreach(_opt IN LISTS _link_opts)
      string(STRIP "${_opt}" _opt)
      if(NOT _opt)
        continue()
      endif()
      # Unwrap $<$<LINK_LANGUAGE:X>:flag> — capture the flag value after the
      # colon and discard the genex wrapper.
      if(_opt MATCHES "^[$][<][$][<]LINK_LANGUAGE:[^>]+[>]:(.+)[>]$")
        list(APPEND _link_parts "${CMAKE_MATCH_1}")
      elseif(_opt MATCHES "LINK_LANGUAGE")
        # Bare or empty-value LINK_LANGUAGE form — nothing useful to embed.
        continue()
      else()
        # Plain flag or non-LINK_LANGUAGE genex — keep as-is.
        list(APPEND _link_parts "${_opt}")
      endif()
    endforeach()
  endif()

  if(LIBRA_LTO)
    foreach(_flag IN LISTS CMAKE_CXX_LINK_OPTIONS_IPO CMAKE_C_LINK_OPTIONS_IPO)
      string(STRIP "${_flag}" _flag)
      if(_flag)
        list(APPEND _link_parts "${_flag}")
      endif()
    endforeach()
  endif()

  list(REMOVE_DUPLICATES _link_parts)
  list(JOIN _link_parts " " LIBRA_TARGET_FLAGS_LINK)

  # --------------------------------------------------------------------------
  # Pass 1: configure_file() — resolves @VAR@, ${VAR}, #cmakedefine, etc. The
  # intermediate file retains any $<genex> the user wrote verbatim.
  # --------------------------------------------------------------------------
  get_filename_component(_outfile_name "${OUTFILE}" NAME)
  set(_intermediate
      "${CMAKE_BINARY_DIR}/CMakeFiles/${TARGET}.dir/${_outfile_name}.in")
  configure_file("${INFILE}" "${_intermediate}" @ONLY)

  # --------------------------------------------------------------------------
  # Pass 2: file(GENERATE ...) — resolves genexes in the context of TARGET. The
  # output file is marked GENERATED so CMake doesn't require it to exist at
  # configure time.
  # --------------------------------------------------------------------------
  set_source_files_properties("${OUTFILE}" PROPERTIES GENERATED TRUE)
  file(
    GENERATE
    OUTPUT "${OUTFILE}"
    INPUT "${_intermediate}"
    TARGET "${TARGET}")
  target_sources(${TARGET} PRIVATE "${OUTFILE}")

  libra_message(STATUS "Configured source file: ${INFILE} -> ${OUTFILE}")
endfunction()

foreach(target ${_LIBRA_TARGETS})
  if(NOT TARGET ${target})
    continue()
  endif()

  # Skip if already processed - prevents double-processing when consumed as a
  # dependency
  get_property(_already_done GLOBAL PROPERTY _LIBRA_${target}_POST_CONFIGURED)
  if(_already_done)
    libra_message(
      STATUS
      "Skipping ${target} for source file configuration - already processed")
    continue()
  endif()

  get_target_property(_imported ${target} IMPORTED)
  get_target_property(_target_dir ${target} SOURCE_DIR)

  if(_imported OR NOT _target_dir MATCHES "^${CMAKE_CURRENT_SOURCE_DIR}")
    libra_message(
      STATUS
      "Skipping ${target} for source file configuration - not owned by ${PROJECT_NAME}"
    )
    continue()
  endif()

  get_property(_src_files GLOBAL
               PROPERTY _LIBRA_${target}_CONFIGURED_SOURCE_FILES_SRC)
  get_property(_dest_files GLOBAL
               PROPERTY _LIBRA_${target}_CONFIGURED_SOURCE_FILES_DEST)

  list(LENGTH _src_files N_SRC)
  list(LENGTH _dest_files N_DEST)

  if(NOT N_SRC EQUAL N_DEST)
    libra_error(
      "Configured file list length mismatch! SRC=${N_SRC}, DEST=${N_DEST}")
  endif()

  if(N_SRC GREATER 0)
    math(EXPR N_SRC "${N_SRC} - 1")

    foreach(i RANGE ${N_SRC})
      list(GET _src_files ${i} INFILE)
      list(GET _dest_files ${i} OUTFILE)

      _libra_configure_source_file_post("${target}" "${INFILE}" "${OUTFILE}")
    endforeach()
  endif()

  # Mark as processed so re-entrant calls from dependent projects are skipped.
  # This has to be AFTER the loop completes so the guard at the top is only
  # tripped on the second attempt from a dependent project's cmake context.
  set_property(GLOBAL PROPERTY _LIBRA_${target}_POST_CONFIGURED TRUE)
endforeach()
