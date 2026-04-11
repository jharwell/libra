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
function(_libra_register_code_checkers TARGET SRCS STUBS)
  if("${SRCS}" STREQUAL "")
    libra_error("No source files passed--misconfiguration?")
  endif()

  add_custom_target(analyze)

  set_target_properties(analyze PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1)

  _libra_register_checker_cppcheck(${TARGET} ${SRCS} ${STUBS})
  _libra_register_checker_clang_tidy(${TARGET} ${SRCS} ${STUBS})
  _libra_register_checker_clang_check(${TARGET} ${SRCS} ${STUBS})
  _libra_register_checker_clang_format(${SRCS} ${${PROJECT_NAME}_CXX_HEADERS}
                                       ${${PROJECT_NAME}_C_HEADERS})
endfunction()

# Function to register a target for enabled automated formatters
function(_libra_register_code_formatters)
  if("${ARGN}" STREQUAL "")
    libra_error("No source files passed--misconfiguration?")
  endif()

  add_custom_target(format)

  set_target_properties(format PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1)

  _libra_register_formatter_clang_format(${ARGN})
endfunction()

# Function to register a target for enabled automated formatters for non-code
# things.
function(_libra_register_cmake_checkers)
  if("${ARGN}" STREQUAL "")
    libra_error("No CMake files passed--misconfiguration?")
  endif()

  _libra_register_checker_cmake_format(${ARGN})
endfunction()

# Function to register a target for checking format for non-code things.
function(_libra_register_cmake_formatters)
  if("${ARGN}" STREQUAL "")
    libra_error("No CMake files passed--misconfiguration?")
  endif()

  _libra_register_formatter_cmake_format(${ARGN})
endfunction()

# Function to register a target for enabled automated fixers
function(_libra_register_code_fixers TARGET SRCS STUBS)
  if("${SRCS}" STREQUAL "")
    libra_error("No source files passed--misconfiguration?")
  endif()

  add_custom_target(fix)
  set_target_properties(fix PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1)
  _libra_register_fixer_clang_tidy(${TARGET} ${SRCS} ${STUBS})
  _libra_register_fixer_clang_check(${TARGET} ${SRCS} ${STUBS})
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
  get_target_property(IFACE_INCLUDES ${TARGET} INTERFACE_INCLUDE_DIRECTORIES)
  if(NOT IFACE_INCLUDES)
    return()
  endif()

  _libra_get_analysis_language(_LANGUAGE)
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
    foreach(HEADER IN LISTS ${PROJECT_NAME}_C_HEADERS
                            ${PROJECT_NAME}_CXX_HEADERS)
      set(INCLUDED NO)
      foreach(SRC IN LISTS ${PROJECT_NAME}_C_SRC ${PROJECT_NAME}_CXX_SRC)
        file(READ "${SRC}" SRC_CONTENTS)
        file(RELATIVE_PATH REL_HEADER "${INCLUDE_DIR}" "${HEADER}")
        if("${SRC_CONTENTS}" MATCHES "${REL_HEADER}")
          set(INCLUDED YES)
          break()
        endif()
      endforeach()

      if(NOT INCLUDED)
        file(RELATIVE_PATH REL_HEADER "${INCLUDE_DIR}" "${HEADER}")
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
  get_target_property(IFACE_INCLUDES ${TARGET} INTERFACE_INCLUDE_DIRECTORIES)
  if(NOT IFACE_INCLUDES)
    return()
  endif()

  _libra_get_analysis_language(_LANGUAGE)
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

    foreach(HEADER IN LISTS ${PROJECT_NAME}_C_HEADERS
                            ${PROJECT_NAME}_CXX_HEADERS)
      # Skip headers that are included by at least one .cpp. AFAIK the only way
      # to do this is to check through (a) every public include dir, (b) every
      # header and (c) every source file and see if any include path relative to
      # a public include dir for a given header appears in a source file.
      set(INCLUDED NO)
      foreach(SRC IN LISTS ${PROJECT_NAME}_C_SRC ${PROJECT_NAME}_CXX_SRC)
        file(READ "${SRC}" SRC_CONTENTS)
        file(RELATIVE_PATH REL_HEADER "${INCLUDE_DIR}" "${HEADER}")
        if("${SRC_CONTENTS}" MATCHES "${REL_HEADER}")
          set(INCLUDED YES)
          math(EXPR skipped_count "${skipped_count} + 1")
          break()
        endif()
      endforeach()

      if(NOT INCLUDED)
        file(RELATIVE_PATH REL_HEADER "${INCLUDE_DIR}" "${HEADER}")
        string(REPLACE "/" "__" STUB_NAME "${REL_HEADER}")
        string(REPLACE "." "_" STUB_NAME "${STUB_NAME}")
        set(STUB_FILE "${STUB_DIR}/${STUB_NAME}.${_STUB_EXT}")

        if(NOT EXISTS "${STUB_FILE}" OR "${HEADER}" IS_NEWER_THAN
                                        "${STUB_FILE}")
          libra_message(STATUS "Generated header stub for <${REL_HEADER}>")

          file(WRITE "${STUB_FILE}"
               "// Auto-generated by libra -- DO NOT EDIT\n"
               "#include <${REL_HEADER}>\n")
        endif()
        math(EXPR stub_count "${stub_count} + 1")
        list(APPEND STUBS "${STUB_FILE}")
      endif()
    endforeach()
  endforeach()

  libra_message(
    STATUS
    "Header stubs: ${stub_count} generated, ${skipped_count} skipped (covered by .${_STUB_EXT} TUs)"
  )

  set(${STUBS_VAR}
      ${STUBS}
      PARENT_SCOPE)
endfunction()

function(analyze_clang_extract_args_from_target TARGET RET)
  # Create a scratch interface target to force transitive resolution
  set(PROBE_TARGET _libra_probe_${TARGET})
  if(NOT TARGET ${PROBE_TARGET})
    add_library(${PROBE_TARGET} INTERFACE)
    target_link_libraries(${PROBE_TARGET} INTERFACE ${TARGET})
  endif()

  set(INCLUDES
      $<REMOVE_DUPLICATES:$<TARGET_PROPERTY:${PROBE_TARGET},INTERFACE_INCLUDE_DIRECTORIES>>
  )

  set(INTERFACE_SYSTEM_INCLUDES
      $<REMOVE_DUPLICATES:$<TARGET_PROPERTY:${PROBE_TARGET},INTERFACE_SYSTEM_INCLUDE_DIRECTORIES>>
  )
  set(DEFS
      $<REMOVE_DUPLICATES:$<TARGET_PROPERTY:${PROBE_TARGET},INTERFACE_COMPILE_DEFINITIONS>>
  )

  set(INTERFACE_DEFS
      $<REMOVE_DUPLICATES:$<TARGET_PROPERTY:${PROBE_TARGET},INTERFACE_COMPILE_DEFINITIONS>>
  )
  if(NOT LIBRA_USE_COMPDB)
    set(USE_DATABASE NO)
    if(NOT CMAKE_EXPORT_COMPILE_COMMANDS
       OR NOT EXISTS "${PROJECT_BINARY_DIR}/compile_commands.json")
      set(USE_DATABASE NO)
    endif()
  else()
    get_target_property(TARGET_TYPE ${TARGET} TYPE)
    set(USE_DATABASE ${LIBRA_USE_COMPDB})
    if("${TARGET_TYPE}" STREQUAL "INTERFACE_LIBRARY" AND LIBRA_USE_COMPDB)
      libra_message(
        STATUS
        "${TARGET} is INTERFACE_LIBRARY -- compdb has no entries for it, "
        "using fixed-DB path instead")
      set(USE_DATABASE NO)
    endif()

    if(USE_DATABASE AND NOT EXISTS
                        "${PROJECT_BINARY_DIR}/compile_commands.json")
      libra_message(
        WARNING
        "LIBRA_USE_COMPDB=YES but compile_commands.json doesn't exist--falling back to fixed-DB"
      )
    endif()
  endif()

  if(USE_DATABASE)
    set(${RET}
        -p\t${PROJECT_BINARY_DIR}
        PARENT_SCOPE)
  else()
    if(LIBRA_CLANG_TOOLS_USE_FIXED_DB)
      set(${RET}
          $<$<BOOL:${INCLUDES}>:-I$<JOIN:${INCLUDES},\t-I>>
          $<$<BOOL:${INTERFACE_INCLUDES}>:-I$<JOIN:${INTERFACE_INCLUDES},\t-I>>
          $<$<BOOL:${INTERFACE_SYSTEM_INCLUDES}>:-isystem$<JOIN:${INTERFACE_SYSTEM_INCLUDES},\t-isystem>>
          $<$<BOOL:${DEFS}>:-D$<JOIN:${DEFS},\t-D>>
          $<$<BOOL:${INTERFACE_DEFS}>:-D$<JOIN:${INTERFACE_DEFS},\t-D>>
          PARENT_SCOPE)
    else()
      set(${RET}
          $<$<BOOL:${INCLUDES}>:--extra-arg=-I$<JOIN:${INCLUDES},\t--extra-arg=-I>>
          $<$<BOOL:${INTERFACE_INCLUDES}>:--extra-arg=-I$<JOIN:${INTERFACE_INCLUDES},\t--extra-arg=-I>>
          $<$<BOOL:${INTERFACE_SYSTEM_INCLUDES}>:--extra-arg=-isystem$<JOIN:${INTERFACE_SYSTEM_INCLUDES},\t--extra-arg=-isystem>>
          $<$<BOOL:${DEFS}>:--extra-arg=-D$<JOIN:${DEFS},\t--extra-arg=-D>>
          $<$<BOOL:${INTERFACE_DEFS}>:--extra-arg=-D$<JOIN:${INTERFACE_DEFS},\t--extra-arg=-D>>
          PARENT_SCOPE)
    endif()
  endif()
endfunction()

macro(_libra_get_analysis_language OUT)
  # Prefer C++ over C if a project enables both languages.
  if(CMAKE_CXX_COMPILER_LOADED)
    set(${OUT} CXX)
  elseif(CMAKE_C_COMPILER_LOADED)
    set(${OUT} C)
  endif()

endmacro()

macro(_libra_calculate_srcs SOURCE SRCS_RET HEADERS_RET)
  _libra_get_analysis_language(_LANGUAGE)

  if("${_LANGUAGE}" MATCHES "CXX")
    libra_message(STATUS "Detected language C++ for project")
  elseif("${_LANGUAGE}" MATCHES "C")
    libra_message(STATUS "Detected language C project")
  endif()

  if(NOT _LANGUAGE)
    libra_message(
      WARNING
      "Unable to autodetect languages for static analysis--assuming CXX.")
    set(_LANGUAGE CXX)
  endif()

  if("${_LANGUAGE}" STREQUAL "C")
    if("${SOURCE}" STREQUAL "APIDOC")
      set(${SRCS_RET} ${${PROJECT_NAME}_C_SRC})
      set(${HEADERS_RET} ${${PROJECT_NAME}_C_HEADERS})
    else()
      set(${SRCS_RET} ${${PROJECT_NAME}_C_SRC} ${${PROJECT_NAME}_C_TESTS_SRC})
      set(${HEADERS_RET} ${${PROJECT_NAME}_C_HEADERS})
    endif()
  elseif("${_LANGUAGE}" STREQUAL "CXX")
    if("${SOURCE}" STREQUAL "APIDOC")
      set(${SRCS_RET} ${${PROJECT_NAME}_CXX_SRC})
      set(${HEADERS_RET} ${${PROJECT_NAME}_CXX_HEADERS})
    else()
      set(${SRCS_RET} ${${PROJECT_NAME}_CXX_SRC}
                      ${${PROJECT_NAME}_CXX_TESTS_SRC})
      set(${HEADERS_RET} ${${PROJECT_NAME}_CXX_HEADERS})
    endif()
  else()
    libra_error("Bad language '${_LANGUAGE}' for project: must be {C,CXX}")
  endif()
endmacro()
