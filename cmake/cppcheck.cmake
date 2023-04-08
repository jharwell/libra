#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#
set(CPPCHECK_ENABLED OFF)

################################################################################
# Register a target for cppcheck
################################################################################
function(do_register_cppcheck CHECK_TARGET TARGET)
  set(includes "$<TARGET_PROPERTY:${TARGET},INCLUDE_DIRECTORIES>")
  add_custom_target(${CHECK_TARGET})

  foreach(file ${ARGN})
    add_custom_command(TARGET ${CHECK_TARGET}
      COMMAND
      ${cppcheck_EXECUTABLE}
      "$<$<BOOL:${includes}>:-I$<JOIN:${includes},\t-I>>"
      --enable=warning,style,performance,portability
      --template= "\"[{severity}][{id}] {message} {callstack} (On {file}:{line})\""
      --quiet
      --verbose
      --force
      --suppress=missingInclude
      --suppress=unusedFunction
      ${file}
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
      COMMENT "Running ${cppcheck_EXECUTABLE} on ${file}"
      )
  endforeach()
  set_target_properties(${CHECK_TARGET}
    PROPERTIES
    EXCLUDE_FROM_DEFAULT_BUILD 1
    )

  add_dependencies(${CHECK_TARGET} ${TARGET})
endfunction()

################################################################################
# Register all sources from the target with the cppcheck checker
################################################################################
function(register_cppcheck_checker TARGET)
  if (NOT CPPCHECK_ENABLED)
    return()
  endif()

  do_register_cppcheck(${TARGET}-cppcheck ${TARGET} ${ARGN})

  add_dependencies(${TARGET}-check ${TARGET}-cppcheck)
endfunction()

################################################################################
# Enable or disable cppcheck checking for a project
################################################################################
function(toggle_cppcheck status)
  message(CHECK_START "cppcheck")
    if(NOT ${status})
      set(CPPCHECK_ENABLED ${status} PARENT_SCOPE)
      message(CHECK_FAIL "[disabled=by user]")
      return()
    endif()

    find_package(cppcheck)

    if(NOT cppcheck_FOUND)
      message(CHECK_FAIL "[disabled=not found]")
    else()
      message(CHECK_PASS "[enabled=${cppcheck_EXECUTABLE}]")
    endif()

    set(CPPCHECK_ENABLED ${status} PARENT_SCOPE)
endfunction()
