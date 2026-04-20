#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#
include(libra/analyze/cppcheck)
include(libra/analyze/clang_tidy)
include(libra/analyze/clang_check)
include(libra/messaging)
include(libra/utils)

_libra_register_custom_target(analyze LIBRA_ANALYSIS NONE)
_libra_register_custom_target(fix LIBRA_ANALYSIS NONE)

#[[.rst:
.. cmake:command:: _libra_register_code_checkers

  Registers all code-checking analysis tools (distinct from documentation
  checking analysis tools). Currently this is:

  - cppcheck. Operates on sources and stubs.
  - clang-tidy. Operates on sources, headers, and stubs.
  - clang-check. Operates on sources and stubs.

  :param TARGET: The name of the target {sources,headers,stubs} are attached to.

  :param SRCS: Source files for checkers to check.

  :param HEADERS: Header files for checkers to check.

  :param STUBS: Stub C/C++ files which include a single header for checkers to
   check. Used to check headers which aren't included in any source file and
   thus don't have compdb entries.
]]
function(
  _libra_register_code_checkers
  TARGET
  SRCS
  HEADERS
  STUBS)
  list(APPEND CMAKE_MESSAGE_INDENT " ")
  if("${SRCS}" STREQUAL "")
    libra_error("No source files passed--misconfiguration?")
  endif()

  add_custom_target(analyze)

  set_target_properties(analyze PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1
                                           EXCLUDE_FROM_ALL 1)

  _libra_register_checker_cppcheck(${TARGET} ${SRCS} ${STUBS})
  _libra_register_checker_clang_tidy(${TARGET} "${SRCS}" "${HEADERS}"
                                     "${STUBS}")
  _libra_register_checker_clang_check(${TARGET} ${SRCS} ${STUBS})
  list(POP_BACK CMAKE_MESSAGE_INDENT)
endfunction()

#[[.rst:
.. cmake:command:: _libra_register_code_fixers

  Registers all code-fixing analysis tools. Currently this is:

  - clang-tidy
  - clang-check

  Fixing is limited to source files because fixing with raw header files and/or
  stubs is not very reliable.

  :param TARGET: The name of the target {sources,headers,stubs} are attached to.

  :param SRCS: Source files for checkers to check.

]]
function(_libra_register_code_fixers TARGET SRCS)
  list(APPEND CMAKE_MESSAGE_INDENT " ")
  if("${SRCS}" STREQUAL "")
    libra_error("No source files passed--misconfiguration?")
  endif()

  add_custom_target(fix)

  set_target_properties(fix PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1
                                       EXCLUDE_FROM_ALL 1)

  _libra_register_fixer_clang_tidy(${TARGET} "${SRCS}")
  _libra_register_fixer_clang_check(${TARGET} "${SRCS}")
  list(POP_BACK CMAKE_MESSAGE_INDENT)
endfunction()

#[[.rst:
.. cmake:command:: _libra_header_needs_stub

  Determine if a header file in the project needs a stub created for it so that
  analysis works reliably with a compilation database. A header needs a stub if
  it isn't included in any source file in the project.

  This is done by checking through every source file to see if a given header
  appears in it relative to a given interface include directory.

  :param HEADER: The header to check the status of.

  :param PARENT: The parent interface include directory to check against.

  :param RET: Name of variable in parent scope to set with yes/no.
]]
function(_libra_header_needs_stub HEADER PARENT_DIR RET)

  set(NEEDS_STUB YES)
  file(RELATIVE_PATH REL_HEADER "${PARENT_DIR}" "${HEADER}")
  foreach(SRC IN LISTS ${PROJECT_NAME}_C_SRC ${PROJECT_NAME}_CXX_SRC)
    file(READ "${SRC}" SRC_CONTENTS)
    if("${SRC_CONTENTS}" MATCHES "${REL_HEADER}")
      set(NEEDS_STUB NO)
      break()
    endif()
  endforeach()

  set(${RET}
      ${NEEDS_STUB}
      PARENT_SCOPE)
endfunction()

#[[.rst:
.. cmake:command:: _libra_prune_stale_stubs

  Remove stub files from STUB_DIR that no longer correspond to any
  header in the current project.

  Called before _libra_generate_header_stubs so that stubs for removed or
  renamed headers don't accumulate across reconfigures. Relies on the same
  naming convention used by _libra_generate_header_stubs to reconstruct the
  expected stub filename from each header path.

  This approach was chosen over nuking the stub directory on every configure for
  a few reasons:

  - The unconditional delete violates incremental build principles. CMake's
    configure step is supposed to be idempotent and cheap for unchanged
    inputs. Unconditionally deleting and regenerating all stubs means every
    cmake configure run with LIBRA_ANALYSIS=YES invalidates all stub object
    files, forcing a full stub recompile before any analysis can run — even if
    zero headers changed. For a project with hundreds of public headers this
    becomes a meaningful tax on every analysis run.

  - The IS_NEWER_THAN mechanism already exists for a reason: to avoid
    unnecessary regeneration. The unconditional delete defeats it entirely,
    making it dead code in practice.

  - This approach composes better with --fresh. A --fresh configure already
    wipes the binary directory entirely, so stale stubs are cleaned up
    naturally. The unconditional delete is redundant in the --fresh case and
    harmful in the incremental case.

  :param TARGET: The CMake target whose public headers define the expected stub
   set.

  :param STUB_DIR: Directory containing existing stubs to prune.
]]
function(_libra_prune_stale_stubs TARGET STUB_DIR)
  list(APPEND CMAKE_MESSAGE_INDENT " ")
  get_target_property(IFACE_INCLUDES ${TARGET} INTERFACE_INCLUDE_DIRECTORIES)
  if(NOT IFACE_INCLUDES)
    return()
  endif()

  _libra_get_project_language(_LANGUAGE)
  if("${_LANGUAGE}" STREQUAL "CXX")
    set(_STUB_EXT "cpp")
  elseif("${_LANGUAGE}" STREQUAL "C")
    set(_STUB_EXT "c")
  else()
    return()
  endif()

  # Build the set of expected stub filenames -- one per header that has no
  # .c/.cpp coverage (matching the logic in _libra_generate_header_stubs)
  set(EXPECTED_STUBS "")
  foreach(INCLUDE_DIR IN LISTS IFACE_INCLUDES)
    if(INCLUDE_DIR MATCHES "\\$<INSTALL_INTERFACE:.*>")
      continue()
    endif()
    string(REGEX REPLACE "\\$<BUILD_INTERFACE:(.+)>" "\\1" INCLUDE_DIR2
                         "${INCLUDE_DIR}")

    foreach(HEADER IN LISTS ${PROJECT_NAME}_C_HEADERS
                            ${PROJECT_NAME}_CXX_HEADERS)
      _libra_header_needs_stub(${HEADER} ${INCLUDE_DIR2} NEEDS_STUB)
      if(NEEDS_STUB)
        file(RELATIVE_PATH REL_HEADER "${INCLUDE_DIR2}" "${HEADER}")
        string(REPLACE "/" "__" STUB_NAME "${REL_HEADER}")
        string(REPLACE "." "_" STUB_NAME "${STUB_NAME}")
        list(APPEND EXPECTED_STUBS "${STUB_DIR}/${STUB_NAME}.${_STUB_EXT}")
      endif()
    endforeach()
  endforeach()

  # Remove any stubs on disk not in the expected set
  file(GLOB EXISTING_STUBS "${STUB_DIR}/*.c" "${STUB_DIR}/*.cpp")
  foreach(EXISTING IN LISTS EXISTING_STUBS)
    if(NOT "${EXISTING}" IN_LIST EXPECTED_STUBS)
      libra_message(STATUS "Removing stale stub: ${EXISTING}")
      file(REMOVE "${EXISTING}")
    endif()
  endforeach()
  list(POP_BACK CMAKE_MESSAGE_INDENT)
endfunction()

#[[.rst:
.. cmake:command:: _libra_generate_header_stubs

  Generate stub .cpp files for standalone header analysis.

  Each stub contains a single #include of its corresponding header, expressed
  as a path relative to the include directory it was found under. This ensures
  the header is analyzed with the same include path form as real consumers
  would use, and that any missing self-containment or include-order bugs are
  caught as real errors rather than papered over.

  Stubs are written to STUB_DIR and only regenerated if the header is newer
  than the existing stub, avoiding spurious rebuilds.

  Only headers under the target's INTERFACE_INCLUDE_DIRECTORIES are stubbed,
  which is correct: those are the headers that form the public API and must
  be self-contained. Private/internal headers that are not exposed via
  INTERFACE_INCLUDE_DIRECTORIES are intentionally excluded.

  :param TARGET: The CMake target whose public headers are stubbed.

  :param STUB_DIR: Directory under which stub .cpp files are written. Typically
   ${CMAKE_BINARY_DIR}/libra_header_stubs.

  :param STUBS_VAR: Name of the variable in caller's scope that receives the
   list of generated stub file paths.
]]
function(_libra_generate_header_stubs TARGET STUB_DIR STUBS_VAR)
  list(APPEND CMAKE_MESSAGE_INDENT " ")
  get_target_property(IFACE_INCLUDES ${TARGET} INTERFACE_INCLUDE_DIRECTORIES)
  if(NOT IFACE_INCLUDES)
    return()
  endif()

  _libra_get_project_language(_LANGUAGE)
  # Determine stub extension and language from project language
  if("${_LANGUAGE}" STREQUAL "CXX")
    set(_STUB_EXT "cpp")
  elseif("${_LANGUAGE}" STREQUAL "C")
    set(_STUB_EXT "c")
  endif()

  set(STUBS "")
  set(skipped_count 0)
  set(stub_count 0)
  foreach(INCLUDE_DIR IN LISTS IFACE_INCLUDES)
    if(INCLUDE_DIR MATCHES "\\$<INSTALL_INTERFACE:.*>")
      continue()
    endif()
    string(REGEX REPLACE "\\$<BUILD_INTERFACE:(.+)>" "\\1" INCLUDE_DIR2
                         "${INCLUDE_DIR}")

    foreach(HEADER IN LISTS ${PROJECT_NAME}_C_HEADERS
                            ${PROJECT_NAME}_CXX_HEADERS)
      _libra_header_needs_stub(${HEADER} ${INCLUDE_DIR2} NEEDS_STUB)
      if(NOT NEEDS_STUB)
        math(EXPR skipped_count "${skipped_count} + 1")
        continue()
      endif()

      file(RELATIVE_PATH REL_HEADER "${INCLUDE_DIR2}" "${HEADER}")
      string(REPLACE "/" "__" STUB_NAME "${REL_HEADER}")
      string(REPLACE "." "_" STUB_NAME "${STUB_NAME}")
      set(STUB_FILE "${STUB_DIR}/${STUB_NAME}.${_STUB_EXT}")

      if(NOT EXISTS "${STUB_FILE}" OR "${HEADER}" IS_NEWER_THAN "${STUB_FILE}")
        libra_message(STATUS "Generated header stub for <${REL_HEADER}>")

        file(WRITE "${STUB_FILE}" "// Auto-generated by libra -- DO NOT EDIT\n"
                                  "#include <${REL_HEADER}>\n")
      endif()
      math(EXPR stub_count "${stub_count} + 1")
      list(APPEND STUBS "${STUB_FILE}")
    endforeach()
  endforeach()

  libra_message(
    STATUS
    "Header stubs: ${stub_count} generated, ${skipped_count} skipped (covered by .${_STUB_EXT} TUs)"
  )

  set(${STUBS_VAR}
      ${STUBS}
      PARENT_SCOPE)
  list(POP_BACK CMAKE_MESSAGE_INDENT)
endfunction()

#[[.rst:
.. cmake:command:: analyze_build_fixeddb_for_target

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
function(analyze_build_fixeddb_for_target TARGET RET)
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
.. cmake:command:: analyze_build_adhocdb_for_target

  Same as :cmake:command:`analyze_build_fixeddb_for_target`, but
  clang tools only. Instead of fixeddb, we build a set of ``--extra-arg`` arguments
  which are passed en masse to clang tools. In theory this should be the same as a
  compilation database, but isn't necessarily guaranteed to be.

  :param TARGET: The target to build a adhocdb for.

  :param RET: Name of variable to set in parent scope with the args to add to
   the analysis tool.
]]
function(analyze_clang_build_adhocdb_for_target TARGET RET)
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
.. cmake:command:: analyze_clang_extract_args_from_target

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
function(analyze_clang_extract_args_from_target TARGET RET)
  set(USE_DATABASE ${LIBRA_USE_COMPDB})
  if(USE_DATABASE)
    set(${RET}
        -p\t${PROJECT_BINARY_DIR}
        PARENT_SCOPE)
  else()
    if(LIBRA_CLANG_TOOLS_USE_FIXED_DB)
      analyze_build_fixeddb_for_target(${TARGET} TMP)
      set(${RET}
          ${TMP}
          PARENT_SCOPE)
    else()
      analyze_clang_build_adhocdb_for_target(${TARGET} TMP)
      set(${RET}
          ${TMP}
          PARENT_SCOPE)
    endif()
  endif()
endfunction()

#[[.rst:
.. cmake:command:: _libra_find_code_analyzers

  Finds acceptable versions of all analysis tools libra uses for analyze code.

  Currently this is:

  - clang-tidy
  - clang-check
  - cppcheck
]]
function(_libra_find_code_analyzers)
  list(APPEND CMAKE_MESSAGE_INDENT " ")

  # clang-tidy
  find_program(
    clang_tidy_EXECUTABLE
    NAMES clang-tidy-21
          clang-tidy-20
          clang-tidy-19
          clang-tidy-18
          clang-tidy-17
          clang-tidy-16
          clang-tidy-15
          clang-tidy-14
          clang-tidy
    PATHS "${clang_tidy_DIR}")
  if(NOT clang_tidy_EXECUTABLE)
    libra_message(STATUS "clang-tidy [disabled=notfound]")
  endif()

  # cppcheck
  find_program(
    cppcheck_EXECUTABLE
    NAMES cppcheck
    PATHS "${cppcheck_DIR}" "$ENV{CPPCHECK_DIR}")

  if(NOT cppcheck_EXECUTABLE)
    libra_message(STATUS "cppcheck [disabled=notfound]")
  endif()

  # clang-check
  find_program(
    clang_check_EXECUTABLE
    NAMES clang-check-21
          clang-check-20
          clang-check-19
          clang-check-18
          clang-check-17
          clang-check-16
          clang-check-15
          clang-check-14
          clang-check
    PATHS "${clang_check_DIR}")

  if(NOT clang_check_EXECUTABLE)
    libra_message(STATUS "clang-check [disabled=notfound]")
  endif()

  list(POP_BACK CMAKE_MESSAGE_INDENT)
endfunction()

#[[.rst:
.. cmake:command:: _libra_find_apidoc_analyzers

  Finds acceptable versions of all analysis tools libra uses for analyze
  documentation.

  Currently this is:

  - clang
  - doxygen
]]
function(_libra_find_apidoc_analyzers)
  list(APPEND CMAKE_MESSAGE_INDENT " ")

  # clang
  find_program(
    clang_EXECUTABLE
    NAMES clang-20
          clang-19
          clang-18
          clang-17
          clang-16
          clang-15
          clang-14
          clang
    PATHS "${clang_DIR}")

  if(NOT clang_EXECUTABLE)
    libra_message(STATUS "clang [disabled=notfound]")
  endif()

  find_program(doxygen PATHS "${doxygen_DIR}")

  list(POP_BACK CMAKE_MESSAGE_INDENT)
endfunction()

if(LIBRA_ANALYSIS AND CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
  _libra_calculate_srcs("STATIC_ANALYSIS" ${PROJECT_NAME}_ANALYSIS_SRC
                        ${PROJECT_NAME}_ANALYSIS_HEADERS)

  # Should not be needed, but just for safety
  if("${LIBRA_DRIVER}" MATCHES "CONAN")
    list(
      FILTER
      ${PROJECT_NAME}_ANALYSIS_SRC
      EXCLUDE
      REGEX
      "\.conan2")
    list(
      FILTER
      ${PROJECT_NAME}_ANALYSIS_HEADERS
      EXCLUDE
      REGEX
      "\.conan2")
  endif()

  set(STUB_DIR "${CMAKE_BINARY_DIR}/libra_header_stubs")
  file(MAKE_DIRECTORY "${STUB_DIR}")
  _libra_prune_stale_stubs(${PROJECT_NAME} "${STUB_DIR}")
  _libra_generate_header_stubs(${PROJECT_NAME} "${STUB_DIR}"
                               ${PROJECT_NAME}_ANALYSIS_STUBS)

  if(${PROJECT_NAME}_ANALYSIS_STUBS)
    # Now stubs get compdb entries and --header-filter picks up their headers
    add_library(_${PROJECT_NAME}_analysis_stubs OBJECT
                EXCLUDE_FROM_ALL ${${PROJECT_NAME}_ANALYSIS_STUBS})
    target_link_libraries(_${PROJECT_NAME}_analysis_stubs
                          PRIVATE ${PROJECT_NAME})
  endif()
  list(LENGTH ${PROJECT_NAME}_ANALYSIS_STUBS STUBS_LEN)
  list(LENGTH ${PROJECT_NAME}_ANALYSIS_SRC SRC_LEN)
  libra_message(STATUS "Registering ${STUBS_LEN}+${SRC_LEN} stubs+source files")

  # Find tools
  _libra_find_code_analyzers()

  # Configure checking tools
  libra_message(STATUS "Enabling analysis tools: checkers")
  _libra_register_code_checkers(
    ${PROJECT_NAME} "${${PROJECT_NAME}_ANALYSIS_SRC}"
    "${${PROJECT_NAME}_ANALYSIS_HEADERS}" "${${PROJECT_NAME}_ANALYSIS_STUBS}")

  # Configure fixing tools
  libra_message(STATUS "Enabling analysis tools: fixers")
  _libra_register_code_fixers(${PROJECT_NAME} "${${PROJECT_NAME}_ANALYSIS_SRC}")
endif()
