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
function(libra_register_code_checkers TARGET)
  if("${ARGN}" STREQUAL "")
    libra_message(FATAL_ERROR "No source files passed--misconfiguration?")
  endif()

  add_custom_target(analyze)

  set_target_properties(analyze PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1)
  libra_register_checker_cppcheck(${TARGET} ${ARGN})
  libra_register_checker_clang_tidy(${TARGET} ${ARGN})
  libra_register_checker_clang_check(${TARGET} ${ARGN})
  libra_register_checker_clang_format(${TARGET} ${ARGN})
endfunction()

# Function to register a target for enabled automated formatters
function(libra_register_code_formatters TARGET)
  if("${ARGN}" STREQUAL "")
    libra_message(FATAL_ERROR "No source files passed--misconfiguration?")
  endif()

  add_custom_target(format)

  set_target_properties(format PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1)

  libra_register_formatter_clang_format(${TARGET} ${ARGN})
endfunction()

# Function to register a target for enabled automated formatters for non-code
# things.
function(libra_register_cmake_checkers TARGET)
  if("${ARGN}" STREQUAL "")
    libra_message(FATAL_ERROR "No CMake files passed--misconfiguration?")
  endif()

  libra_register_checker_cmake_format(${TARGET} ${ARGN})
endfunction()

# Function to register a target for checking format for non-code things.
function(libra_register_cmake_formatters TARGET)
  if("${ARGN}" STREQUAL "")
    libra_message(FATAL_ERROR "No CMake files passed--misconfiguration?")
  endif()

  libra_register_formatter_cmake_format(${TARGET} ${ARGN})
endfunction()

# Function to register a target for enabled automated fixers
function(libra_register_code_fixers TARGET)
  if("${ARGN}" STREQUAL "")
    libra_message(FATAL_ERROR "No source files passed--misconfiguration?")
  endif()

  add_custom_target(fix)

  set_target_properties(fix PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1)

  libra_register_fixer_clang_tidy(${TARGET} ${ARGN})
  libra_register_fixer_clang_check(${TARGET} ${ARGN})
endfunction()

function(analyze_clang_extract_args_from_target TARGET RET)
  set(INCLUDES $<TARGET_PROPERTY:${TARGET},INCLUDE_DIRECTORIES>)
  set(INTERFACE_INCLUDES
      $<TARGET_PROPERTY:${TARGET},INTERFACE_INCLUDE_DIRECTORIES>)
  set(INTERFACE_SYSTEM_INCLUDES
      $<TARGET_PROPERTY:${TARGET},INTERFACE_SYSTEM_INCLUDE_DIRECTORIES>)
  set(DEFS $<TARGET_PROPERTY:${TARGET},COMPILE_DEFINITIONS>)
  set(INTERFACE_DEFS $<TARGET_PROPERTY:${TARGET},INTERFACE_COMPILE_DEFINITIONS>)
  get_target_property(TARGET_TYPE ${TARGET} TYPE)

  # clang-XX doesn't work well with using a compilation database with header
  # only libraries, so we extract the necessary includes, defs, etc., directly
  # from the target itself in that case.
  set(USE_DATABASE YES)
  if("${TARGET_TYPE}" STREQUAL "INTERFACE_LIBRARY")
    set(USE_DATABASE NO)
  else()
    if(NOT CMAKE_EXPORT_COMPILE_COMMANDS
       OR NOT EXISTS "${PROJECT_BINARY_DIR}/compile_commands.json")
      set(USE_DATABASE NO)
    endif()
  endif()

  # We use --extra-arg=... instead of '-- ...' because the former is documented
  # and works, and the latter is undocumented and SORT OF works.
  set(${RET}
      $<$<BOOL:${USE_DATABASE}>:-p\t${PROJECT_BINARY_DIR}>
      $<$<NOT:$<BOOL:${USE_DATABASE}>>:\t$<$<BOOL:${INCLUDES}>:--extra-arg=-I$<JOIN:${INCLUDES},\t--extra-arg=-I>>>
      $<$<NOT:$<BOOL:${USE_DATABASE}>>:\t$<$<BOOL:${INTERFACE_INCLUDES}>:--extra-arg=-I$<JOIN:${INTERFACE_INCLUDES},\t--extra-arg=-I>>>
      $<$<NOT:$<BOOL:${USE_DATABASE}>>:\t$<$<BOOL:${INTERFACE_SYSTEM_INCLUDES}>:--extra-arg=-isystem$<JOIN:${INTERFACE_SYSTEM_INCLUDES},\t--extra-arg=-isystem>>>
      $<$<NOT:$<BOOL:${USE_DATABASE}>>:\t$<$<BOOL:${DEFS}>:--extra-arg=-D$<JOIN:${DEFS},\t--extra-arg=-D>>>
      $<$<NOT:$<BOOL:${USE_DATABASE}>>:\t$<$<BOOL:${INTERFACE_DEFS}>:--extra-arg=-D$<JOIN:${INTERFACE_DEFS},\t--extra-arg=-D>>>
      PARENT_SCOPE)
endfunction()
