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
  set(includes $<TARGET_PROPERTY:${TARGET},INCLUDE_DIRECTORIES>)
  set(interface_includes
      ${includes} $<TARGET_PROPERTY:${TARGET},INTERFACE_INCLUDE_DIRECTORIES>)
  set(defs $<TARGET_PROPERTY:${TARGET},COMPILE_DEFINITIONS>)
  set(interface_defs $<TARGET_PROPERTY:${TARGET},INTERFACE_COMPILE_DEFINITIONS>)
  add_custom_target(${CHECK_TARGET})

  if(NOT LIBRA_CPPCHECK_SUPPRESSIONS)
    set(LIBRA_CPPCHECK_SUPPRESSIONS missingInclude unusedFunction)
  endif()

  set(SUPPRESSIONS "${LIBRA_CPPCHECK_SUPPRESSIONS}")
  set(IGNORES "${LIBRA_CPPCHECK_IGNORES}")
  set(EXTRA_ARGS "${LIBRA_CPPCHECK_EXTRA_ARGS}")
  set(USE_DATABASE YES)

  if(NOT CMAKE_EXPORT_COMPILE_COMMANDS
     OR NOT EXISTS "${PROJECT_BINARY_DIR}/compile_commands.json")
    set(USE_DATABASE NO)
  endif()

  get_filename_component(cppcheck_NAME ${cppcheck_EXECUTABLE} NAME)

  foreach(file ${ARGN})
    add_custom_command(
      TARGET ${CHECK_TARGET}
      POST_BUILD
      COMMAND
        ${cppcheck_EXECUTABLE}
        "$<$<BOOL:${USE_DATABASE}>:--project=${PROJECT_BINARY_DIR}/compile_commands.json>"
        "$<$<NOT:$<BOOL:${USE_DATABASE}>>:\t$<$<BOOL:${includes}>:-I$<JOIN:${includes},\t-I>>>"
        "$<$<NOT:$<BOOL:${USE_DATABASE}>>:\t$<$<BOOL:${interface_includes}>:-I$<JOIN:${interface_includes},\t-I>>>"
        "$<$<NOT:$<BOOL:${USE_DATABASE}>>:\t$<$<BOOL:${defs}>:-D$<JOIN:${defs},\t-D>>>"
        "$<$<NOT:$<BOOL:${USE_DATABASE}>>:\t$<$<BOOL:${interface_defs}>:-D$<JOIN:${interface_defs},\t-D>>>"
        --enable=warning,style,performance,portability --template=
        "\"[{severity}][{id}] {message} {callstack} (On {file}:{line})\""
        --quiet --verbose --force --std=${LIBRA_CXX_STANDARD} --inline-suppr
        "$<$<BOOL:${SUPPRESSIONS}>:--suppress=$<JOIN:${SUPPRESSIONS},\t--suppress=>>"
        "$<$<BOOL:${IGNORES}>:-i$<JOIN:${IGNORES},\t-i>>" "${EXTRA_ARGS}"
        ${file}
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
      COMMENT
        "Running ${cppcheck_NAME} with$<$<NOT:$<BOOL:${USE_DATABASE}>>:out> compdb on ${file}"
    )
  endforeach()
  set_target_properties(${CHECK_TARGET} PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1)

  add_dependencies(${CHECK_TARGET} ${TARGET})
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
    message(STATUS "cppcheck [disabled=not found]")
    return()
  endif()
endfunction()
