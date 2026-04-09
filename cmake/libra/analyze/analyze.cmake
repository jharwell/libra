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
function(_libra_register_code_checkers TARGET)
  if("${ARGN}" STREQUAL "")
    libra_error("No source files passed--misconfiguration?")
  endif()

  add_custom_target(analyze)

  set_target_properties(analyze PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1)
  _libra_register_checker_cppcheck(${TARGET} ${ARGN})
  _libra_register_checker_clang_tidy(${TARGET} ${ARGN})
  _libra_register_checker_clang_check(${TARGET} ${ARGN})
  _libra_register_checker_clang_format(${ARGN})
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
function(_libra_register_code_fixers TARGET)
  if("${ARGN}" STREQUAL "")
    libra_error("No source files passed--misconfiguration?")
  endif()

  add_custom_target(fix)
  set_target_properties(fix PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1)
  _libra_register_fixer_clang_tidy(${TARGET} ${ARGN})
  _libra_register_fixer_clang_check(${TARGET} ${ARGN})
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
  get_target_property(TARGET_TYPE ${TARGET} TYPE)

  if(NOT ${LIBRA_USE_COMPDB})
    set(USE_DATABASE NO)
    if("${TARGET_TYPE}" STREQUAL "INTERFACE_LIBRARY")
      set(USE_DATABASE NO)
    else()
      if(NOT CMAKE_EXPORT_COMPILE_COMMANDS
         OR NOT EXISTS "${PROJECT_BINARY_DIR}/compile_commands.json")
        set(USE_DATABASE NO)
      endif()
    endif()
  else()
    set(USE_DATABASE ${LIBRA_USE_COMPDB})
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
