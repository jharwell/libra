#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#

# ##############################################################################
# Register a target for cppcheck
#
# Since cppcheck doesn't use a compilation database, you have to manually get
# the includes, #defines, etc. for the target and add them to the cppcheck
# command.
# ##############################################################################
set(cppcheck_EXECUTABLE)

function(do_register_cppcheck CHECK_TARGET TARGET)
  set(includes $<TARGET_PROPERTY:${TARGET},INCLUDE_DIRECTORIES>)
  set(interface_includes
      ${includes} $<TARGET_PROPERTY:${TARGET},INTERFACE_INCLUDE_DIRECTORIES>)
  set(defs $<TARGET_PROPERTY:${TARGET},COMPILE_DEFINITIONS>)
  set(interface_defs $<TARGET_PROPERTY:${TARGET},INTERFACE_COMPILE_DEFINITIONS>)
  add_custom_target(${CHECK_TARGET})

  foreach(file ${ARGN})
    add_custom_command(
      TARGET ${CHECK_TARGET}
      COMMAND
        ${cppcheck_EXECUTABLE}
        "$<$<BOOL:${includes}>:-I$<JOIN:${includes},\t-I>>"
        "$<$<BOOL:${interface_includes}>:-I$<JOIN:${interface_includes},\t-I>>"
        "$<$<BOOL:${defs}>:-D$<JOIN:${defs},\t-D>>"
        "$<$<BOOL:${interface_defs}>:-D$<JOIN:${interface_defs},\t-D>>"
        --enable=warning,style,performance,portability --template=
        "\"[{severity}][{id}] {message} {callstack} (On {file}:{line})\""
        --quiet --verbose --force --suppress=missingInclude
        --suppress=unusedFunction ${file}
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
      COMMENT "Running ${cppcheck_EXECUTABLE} on ${file}")
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

  do_register_cppcheck(check-cppcheck ${TARGET} ${ARGN})

  add_dependencies(check check-cppcheck)
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
