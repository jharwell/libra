#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#
include(libra/messaging)

# ##############################################################################
# Register a target for cppcheck
#
# Since cppcheck can work without a compilation database, you have to manually
# get the includes, #defines, etc. for the target and add them to the cppcheck
# command if one isn't found.
# ##############################################################################
function(do_register_cppcheck CHECK_TARGET TARGET)
  set(INCLUDES $<TARGET_PROPERTY:${TARGET},INCLUDE_DIRECTORIES>)
  set(INTERFACE_INCLUDES
      $<TARGET_PROPERTY:${TARGET},INTERFACE_INCLUDE_DIRECTORIES>)
  set(INTERFACE_SYSTEM_INCLUDES
      $<TARGET_PROPERTY:${TARGET},INTERFACE_SYSTEM_INCLUDE_DIRECTORIES>)
  set(DEFS $<TARGET_PROPERTY:${TARGET},COMPILE_DEFINITIONS>)
  set(INTERFACE_DEFS $<TARGET_PROPERTY:${TARGET},INTERFACE_COMPILE_DEFINITIONS>)
  get_target_property(TARGET_TYPE ${TARGET} TYPE)

  if(NOT DEFINED LIBRA_CPPCHECK_SUPPRESSIONS)
    set(LIBRA_CPPCHECK_SUPPRESSIONS "${LIBRA_CPPCHECK_SUPPRESSIONS_DEFAULT}")
  endif()

  if(NOT DEFINED LIBRA_CPPCHECK_EXTRA_ARGS)
    set(LIBRA_CPPCHECK_EXTRA_ARGS "${LIBRA_CPPCHECK_EXTRA_ARGS_DEFAULT}")
  endif()

  # cppcheck doesn't work well with using a compilation database with header
  # only libraries, so we extract the necessary includes, defs, etc., directly
  # from the target itself in that case by default; the user can override this
  # and force it if they want to.
  if(DEFINED LIBRA_USE_COMPDB)
    set(USE_DATABASE ${LIBRA_USE_COMPDB})
  else()
    set(USE_DATABASE YES)

    if("${TARGET_TYPE}" STREQUAL "INTERFACE_LIBRARY")
      set(USE_DATABASE NO)
    else()
      if(NOT CMAKE_EXPORT_COMPILE_COMMANDS
         OR NOT EXISTS "${PROJECT_BINARY_DIR}/compile_commands.json")
        set(USE_DATABASE NO)
      endif()

    endif()
  endif()

  get_filename_component(cppcheck_NAME ${cppcheck_EXECUTABLE} NAME)

  # If a compilation database is used, cppcheck doesn't let you check a specific
  # file.
  if(USE_DATABASE)
    add_custom_target(
      ${CHECK_TARGET}
      COMMAND
        ${cppcheck_EXECUTABLE}
        --project=${PROJECT_BINARY_DIR}/compile_commands.json
        --enable=warning,style,performance,portability --verbose
        --check-level=exhaustive --std=${LIBRA_CXX_STANDARD} --inline-suppr
        "$<$<BOOL:${LIBRA_CPPCHECK_SUPPRESSIONS}>:--suppress=$<JOIN:${LIBRA_CPPCHECK_SUPPRESSIONS},\t--suppress=>>"
        "$<$<BOOL:${LIBRA_CPPCHECK_IGNORES}>:-i$<JOIN:${LIBRA_CPPCHECK_IGNORES},\t-i>>"
        "${LIBRA_CPPCHECK_EXTRA_ARGS}" --error-exitcode=1
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/src
      COMMENT "Running ${cppcheck_NAME} with compdb")
  else()
    add_custom_target(${CHECK_TARGET})
    foreach(file ${ARGN})
      # We create one target per file we want to analyze so that we can do
      # analysis in parallel if desired. Targets can't have '/' on '.' in their
      # names, hence the replacements.
      string(REPLACE "/" "_" file_target "${file}")
      string(REPLACE "." "_" file_target "${file_target}")

      add_custom_target(
        ${CHECK_TARGET}-${file_target}
        COMMAND
          ${cppcheck_EXECUTABLE}
          "$<$<BOOL:${INCLUDES}>:-I$<JOIN:${INCLUDES},\t-I>>"
          "$<$<BOOL:${INTERFACE_INCLUDES}>:-I$<JOIN:${INTERFACE_INCLUDES},\t-I>>"
          "$<$<BOOL:${INTERFACE_SYSTEM_INCLUDES}>:-isystem$<JOIN:${INTERFACE_SYSTEMINCLUDES},\t-isystem>>"
          "$<$<BOOL:${DEFS}>:-D$<JOIN:${DEFS},\t-D>>"
          "$<$<BOOL:${INTERFACE_DEFS}>:-D$<JOIN:${INTERFACE_DEFS},\t-D>>"
          --enable=warning,style,performance,portability --verbose
          --std=${LIBRA_CXX_STANDARD} --inline-suppr
          "$<$<BOOL:${LIBRA_CPPCHECK_SUPPRESSIONS}>:--suppress=$<JOIN:${LIBRA_CPPCHECK_SUPPRESSIONS},\t--suppress=>>"
          "$<$<BOOL:${LIBRA_CPPCHECK_IGNORES}>:-i$<JOIN:${LIBRA_CPPCHECK_IGNORES},\t-i>>"
          "${LIBRA_CPPCHECK_EXTRA_ARGS}" --error-exitcode=1 ${file}
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        COMMENT "Running ${cppcheck_NAME} without compdb on ${file}")
      add_dependencies(${CHECK_TARGET} ${CHECK_TARGET}-${file_target})
    endforeach()
  endif()

  set_target_properties(${CHECK_TARGET} PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1)

  list(LENGTH ARGN LEN)
  libra_message(STATUS "Registered ${LEN} files with ${cppcheck_NAME}")
endfunction()

# ##############################################################################
# Register all sources from the target with the cppcheck checker
# ##############################################################################
function(libra_register_checker_cppcheck TARGET)
  if(NOT cppcheck_EXECUTABLE)
    return()
  endif()
  do_register_cppcheck(analyze-cppcheck ${TARGET} ${ARGN})

  add_dependencies(analyze analyze-cppcheck)
endfunction()

# ##############################################################################
# Enable or disable cppcheck checking for a project
# ##############################################################################
function(libra_toggle_checker_cppcheck request)
  if(NOT request)
    libra_message(STATUS "Disabling cppcheck checker by request")
    set(cppcheck_EXECUTABLE)
    return()
  endif()

  find_program(
    cppcheck_EXECUTABLE
    NAMES cppcheck
    PATHS "${cppcheck_DIR}" "$ENV{CPPCHECK_DIR}")

  if(NOT cppcheck_EXECUTABLE)
    libra_message(STATUS "cppcheck [disabled=not found]")
    return()
  endif()
endfunction()
