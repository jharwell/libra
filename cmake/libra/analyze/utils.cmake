#
# Copyright 2026 John Harwell, All rights reserved.
#
# SPDX-License-Identifier: MIT
#

#[[.rst:
.. cmake:command:: _libra_analyze_build_fixeddb_for_target

  Build a fixed compilation database (LLVM/clang terminology) for a target. A
  fixed compdb is the set of includes and #define which would otherwise be
  pulled out of the compilation database. These are then passed to the analysis
  tool just as they would be to the compiler. In theory this should be the same
  as a compilation database, but isn't necessarily guaranteed to be.

  The magic here is that we create a fake interface target to force transitive
  resolution of interface {include dirs, definitions}. Without this, we have to
  walk the PRIVATE deps of TARGET, which is bad, or be limited to a single level
  of resolution, which isn't sufficient for complex projects.

  :param TARGET: The target to build a fixeddb for.

  :param RET: Name of variable to set in parent scope with the args to add to
   the analysis tool.
]]
function(_libra_analyze_build_fixeddb_for_target TARGET RET)
  # Create a scratch interface target to force transitive resolution
  set(PROBE_TARGET _libra_probe_${TARGET})
  if(NOT TARGET ${PROBE_TARGET})
    add_library(${PROBE_TARGET} INTERFACE)
    target_link_libraries(${PROBE_TARGET} INTERFACE ${TARGET})
  endif()

  set(INTERFACE_INCLUDES
      $<REMOVE_DUPLICATES:$<TARGET_PROPERTY:${PROBE_TARGET},INTERFACE_INCLUDE_DIRECTORIES>>
  )

  set(INTERFACE_SYSTEM_INCLUDES
      $<REMOVE_DUPLICATES:$<TARGET_PROPERTY:${PROBE_TARGET},INTERFACE_SYSTEM_INCLUDE_DIRECTORIES>>
  )
  set(INTERFACE_DEFS
      $<REMOVE_DUPLICATES:$<TARGET_PROPERTY:${PROBE_TARGET},INTERFACE_COMPILE_DEFINITIONS>>
  )
  set(USE_DATABASE ${LIBRA_USE_COMPDB})
  if(USE_DATABASE AND NOT EXISTS "${PROJECT_BINARY_DIR}/compile_commands.json")
    libra_message(
      WARNING
      "LIBRA_USE_COMPDB=YES but compile_commands.json doesn't exist--falling back to fixed-DB"
    )
  endif()
  set(${RET}
      $<$<BOOL:${INTERFACE_INCLUDES}>:-I$<JOIN:${INTERFACE_INCLUDES},\t-I>>
      $<$<BOOL:${INTERFACE_SYSTEM_INCLUDES}>:-isystem$<JOIN:${INTERFACE_SYSTEM_INCLUDES},\t-isystem>>
      $<$<BOOL:${INTERFACE_DEFS}>:-D$<JOIN:${INTERFACE_DEFS},\t-D>>
      PARENT_SCOPE)

endfunction()

#[[.rst:
.. cmake:command:: libra_analyze_build_adhocdb_for_target

  Same as :cmake:command:`_libra_analyze_build_fixeddb_for_target`, but
  clang tools only. Instead of fixeddb, we build a set of ``--extra-arg`` arguments
  which are passed en masse to clang tools. In theory this should be the same as a
  compilation database, but isn't necessarily guaranteed to be.

  :param TARGET: The target to build a adhocdb for.

  :param RET: Name of variable to set in parent scope with the args to add to
   the analysis tool.
]]
function(libra_analyze_clang_build_adhocdb_for_target TARGET RET)
  # Create a scratch interface target to force transitive resolution
  set(PROBE_TARGET _libra_probe_${TARGET})
  if(NOT TARGET ${PROBE_TARGET})
    add_library(${PROBE_TARGET} INTERFACE)
    target_link_libraries(${PROBE_TARGET} INTERFACE ${TARGET})
  endif()

  set(INTERFACE_INCLUDES
      $<REMOVE_DUPLICATES:$<TARGET_PROPERTY:${PROBE_TARGET},INTERFACE_INCLUDE_DIRECTORIES>>
  )

  set(INTERFACE_SYSTEM_INCLUDES
      $<REMOVE_DUPLICATES:$<TARGET_PROPERTY:${PROBE_TARGET},INTERFACE_SYSTEM_INCLUDE_DIRECTORIES>>
  )

  set(INTERFACE_DEFS
      $<REMOVE_DUPLICATES:$<TARGET_PROPERTY:${PROBE_TARGET},INTERFACE_COMPILE_DEFINITIONS>>
  )
  set(USE_DATABASE ${LIBRA_USE_COMPDB})
  if(USE_DATABASE AND NOT EXISTS "${PROJECT_BINARY_DIR}/compile_commands.json")
    libra_message(
      WARNING
      "LIBRA_USE_COMPDB=YES but compile_commands.json doesn't exist--falling back to fixed-DB"
    )
  endif()
  set(${RET}
      $<$<BOOL:${INTERFACE_INCLUDES}>:--extra-arg=-I$<JOIN:${INTERFACE_INCLUDES},\t--extra-arg=-I>>
      $<$<BOOL:${INTERFACE_SYSTEM_INCLUDES}>:--extra-arg=-isystem$<JOIN:${INTERFACE_SYSTEM_INCLUDES},\t--extra-arg=-isystem>>
      $<$<BOOL:${INTERFACE_DEFS}>:--extra-arg=-D$<JOIN:${INTERFACE_DEFS},\t--extra-arg=-D>>
      PARENT_SCOPE)

endfunction()

#[[.rst:
.. cmake:command:: _libra_analyze_clang_extract_args_from_target

  For clang-based analysis tools, extract necessary args for a target so that
  analysis will work on all input files.

  This can be:

  - Telling the tool to use a compdb (default).
  - Telling the tool to use a fixed compdb via
    :cmake:variable:`LIBRA_CLANG_TOOLS_USE_FIXED_DB`.
  - Telling the tool to use an adhocdb via
    :cmake:variable:`LIBRA_CLANG_TOOLS_USE_FIXED_DB`.

  :param TARGET: The target to extract args from.

  :param RET: Name of variable to set in parent scope with the args to add to
   the analysis tool.
]]
function(_libra_analyze_clang_extract_args_from_target TARGET RET)
  set(USE_DATABASE ${LIBRA_USE_COMPDB})
  if(USE_DATABASE)
    set(${RET}
        -p\t${PROJECT_BINARY_DIR}
        PARENT_SCOPE)
  else()
    if(LIBRA_CLANG_TOOLS_USE_FIXED_DB)
      _libra_analyze_build_fixeddb_for_target(${TARGET} TMP)
      set(${RET}
          ${TMP}
          PARENT_SCOPE)
    else()
      _libra_analyze_clang_build_adhocdb_for_target(${TARGET} TMP)
      set(${RET}
          ${TMP}
          PARENT_SCOPE)
    endif()
  endif()
endfunction()
