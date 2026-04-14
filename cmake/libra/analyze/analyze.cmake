#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#
include(libra/analyze/cppcheck)
include(libra/analyze/clang_tidy)
include(libra/analyze/clang_format)
include(libra/analyze/clang_check)
include(libra/analyze/cmake_format)
include(libra/messaging)

# Function to register a target for enabled code checkers
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

  set_target_properties(analyze PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1)

  _libra_register_checker_cppcheck(${TARGET} ${SRCS} ${STUBS})
  _libra_register_checker_clang_tidy(${TARGET} "${SRCS}" "${HEADERS}"
                                     "${STUBS}")
  _libra_register_checker_clang_check(${TARGET} ${SRCS} ${STUBS})
  _libra_register_checker_clang_format(${SRCS} ${HEADERS})
  list(POP_BACK CMAKE_MESSAGE_INDENT)
endfunction()

# Function to register a target for enabled automated formatters
function(_libra_register_code_formatters)
  list(APPEND CMAKE_MESSAGE_INDENT " ")
  if("${ARGN}" STREQUAL "")
    libra_error("No source files passed--misconfiguration?")
  endif()

  add_custom_target(format)

  set_target_properties(format PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1)

  _libra_register_formatter_clang_format(${ARGN})
  list(POP_BACK CMAKE_MESSAGE_INDENT)
endfunction()

# Function to register a target for enabled automated fixers
function(
  _libra_register_code_fixers
  TARGET
  SRCS
  HEADERS
  STUBS)
  list(APPEND CMAKE_MESSAGE_INDENT " ")
  if("${SRCS}" STREQUAL "")
    libra_error("No source files passed--misconfiguration?")
  endif()

  add_custom_target(fix)
  set_target_properties(fix PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1)
  _libra_register_fixer_clang_tidy(${TARGET} "${SRCS}")
  _libra_register_fixer_clang_check(${TARGET} ${SRCS} ${STUBS})
  list(POP_BACK CMAKE_MESSAGE_INDENT)
endfunction()

function(_libra_header_needs_stub HEADER PARENT_DIR RET)

  # Assume a stub is needed unless we find a source file that already includes
  # this header. AFAIK the only way to do this is to check through (a) every
  # public include dir, (b) every header and (c) every source file and see if
  # any include path relative to a public include dir for a given header appears
  # in a source file.
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

# cmake-format: off
# ##############################################################################
# @brief Remove stub files from STUB_DIR that no longer correspond to any
#        header in the current project.
#
# Called before _libra_generate_header_stubs so that stubs for removed or
# renamed headers don't accumulate across reconfigures. Relies on the same
# naming convention used by _libra_generate_header_stubs to reconstruct the
# expected stub filename from each header path.
#
# This approach was chosen over nuking the stub directory on every configure for
# a few reasons:
#
# - The unconditional delete violates incremental build principles. CMake's
#   configure step is supposed to be idempotent and cheap for unchanged
#   inputs. Unconditionally deleting and regenerating all stubs means every
#   cmake configure run with LIBRA_ANALYSIS=YES invalidates all stub object
#   files, forcing a full stub recompile before any analysis can run — even if
#   zero headers changed. For a project with hundreds of public headers this
#   becomes a meaningful tax on every analysis run.
#
# - The IS_NEWER_THAN mechanism already exists for a reason: to avoid
#   unnecessary regeneration. The unconditional delete defeats it entirely,
#   making it dead code in practice.
#
# - This approach composes better with --fresh. A --fresh configure already
#   wipes the binary directory entirely, so stale stubs are cleaned up
#   naturally. The unconditional delete is redundant in the --fresh case and
#   harmful in the incremental case.
#
# @param[in] TARGET   The CMake target whose public headers define the
#                     expected stub set.
# @param[in] STUB_DIR Directory containing existing stubs to prune.
# ##############################################################################
# cmake-format: on
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

# cmake-format: off
# ##############################################################################
# @brief Generate stub .cpp files for standalone header analysis.
#
# Each stub contains a single #include of its corresponding header, expressed
# as a path relative to the include directory it was found under. This ensures
# the header is analyzed with the same include path form as real consumers
# would use, and that any missing self-containment or include-order bugs are
# caught as real errors rather than papered over.
#
# Stubs are written to STUB_DIR and only regenerated if the header is newer
# than the existing stub, avoiding spurious rebuilds.
#
# Only headers under the target's INTERFACE_INCLUDE_DIRECTORIES are stubbed,
# which is correct: those are the headers that form the public API and must
# be self-contained. Private/internal headers that are not exposed via
# INTERFACE_INCLUDE_DIRECTORIES are intentionally excluded.
#
# @param[in]  TARGET   The CMake target whose public headers are stubbed.
# @param[in]  STUB_DIR Directory under which stub .cpp files are written.
#                      Typically ${CMAKE_BINARY_DIR}/libra_header_stubs.
# @param[out] STUBS_VAR Name of the variable in caller's scope that receives
#                       the list of generated stub file paths.
# ##############################################################################
# cmake-format: on
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
          clang-tidy-13
          clang-tidy-12
          clang-tidy-11
          clang-tidy-10
          clang-tidy
    PATHS "${clang_tidy_DIR}")
  if(NOT clang_tidy_EXECUTABLE)
    libra_message(STATUS "clang-tidy [disabled=not found]")
  endif()

  # cppcheck
  find_program(
    cppcheck_EXECUTABLE
    NAMES cppcheck
    PATHS "${cppcheck_DIR}" "$ENV{CPPCHECK_DIR}")

  if(NOT cppcheck_EXECUTABLE)
    libra_message(STATUS "cppcheck [disabled=not found]")
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
          clang-check-13
          clang-check-12
          clang-check-11
          clang-check-10
          clang-check
    PATHS "${clang_check_DIR}")

  if(NOT clang_check_EXECUTABLE)
    libra_message(STATUS "clang-check [disabled=not found]")
  endif()

  # clang-format
  find_program(
    clang_format_EXECUTABLE
    NAMES clang-format-21
          clang-format-20
          clang-format-19
          clang-format-18
          clang-format-17
          clang-format-16
          clang-format-15
          clang-format-14
          clang-format-13
          clang-format-12
          clang-format-11
          clang-format-10
          clang-format
    PATHS "${clang_format_DIR}")

  if(NOT clang_format_EXECUTABLE)
    libra_message(STATUS "clang-format [disabled=not found]")
  endif()

  # cmake-format
  find_program(
    cmake_format_EXECUTABLE
    NAMES cmake-format
    PATHS "${cmake_format_DIR}")

  if(NOT cmake_format_EXECUTABLE)
    libra_message(STATUS "cmake-format [disabled=not found]")
  endif()

  list(POP_BACK CMAKE_MESSAGE_INDENT)
endfunction()

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
          clang-13
          clang-12
          clang-11
          clang-10
          clang
    PATHS "${clang_DIR}")

  if(NOT clang_EXECUTABLE)
    libra_message(STATUS "clang [disabled=not found]")
  endif()
  list(POP_BACK CMAKE_MESSAGE_INDENT)
endfunction()

if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
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

  # Handy checking tools
  libra_message(STATUS "Enabling analysis tools: checkers")
  _libra_register_code_checkers(
    ${PROJECT_NAME} "${${PROJECT_NAME}_ANALYSIS_SRC}"
    "${${PROJECT_NAME}_ANALYSIS_HEADERS}" "${${PROJECT_NAME}_ANALYSIS_STUBS}")

  _libra_register_checker_cmake_format(${${PROJECT_NAME}_CMAKE_SRC})

  # Handy formatting tools
  libra_message(STATUS "Enabling analysis tools: formatters")
  _libra_register_code_formatters("${${PROJECT_NAME}_ANALYSIS_SRC}"
                                  "${${PROJECT_NAME}_ANALYSIS_HEADERS}")
  _libra_register_formatter_cmake_format(${${PROJECT_NAME}_CMAKE_SRC})

  # Handy fixing tools
  libra_message(STATUS "Enabling analysis tools: fixers")
  _libra_register_code_fixers(
    ${PROJECT_NAME} "${${PROJECT_NAME}_ANALYSIS_SRC}"
    "${${PROJECT_NAME}_ANALYSIS_HEADERS}" "${${PROJECT_NAME}_ANALYSIS_STUBS}")
endif()
