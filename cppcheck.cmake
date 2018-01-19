set(CPPCHECK_ENABLED OFF)

# Function to register a target for cppcheck
function(do_register_cppcheck check_target target)
  set(includes "$<TARGET_PROPERTY:${target},INCLUDE_DIRECTORIES>")
  add_custom_target(${check_target})

  foreach(file ${ARGN})
    add_custom_command(TARGET ${check_target}
      COMMAND
      ${cppcheck_EXECUTABLE}
      "$<$<BOOL:${includes}>:-I$<JOIN:${includes},\t-I>>"
      --enable=warning,style,performance,portability
      --template= "\"[{severity}][{id}] {message} {callstack} (On {file}:{line})\""
      --quiet
      --verbose
      --suppress=missingInclude
      --suppress=unusedFunction
      ${file}
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
      )
  endforeach()
  set_target_properties(${check_target}
    PROPERTIES
    EXCLUDE_FROM_DEFAULT_BUILD 1
    )

  add_dependencies(${check_target} ${target})
endfunction()

# Registers all sources with the cppcheck checker
function(register_cppcheck_checker target)
  if (NOT CPPCHECK_ENABLED)
    return()
  endif()

  if(NOT TARGET cppcheck-all)
    add_custom_target(cppcheck-all)

    set_target_properties(cppcheck-all
      PROPERTIES
      EXCLUDE_FROM_DEFAULT_BUILD 1
      )
  endif()

  if (IS_ROOT_TARGET)
    do_register_cppcheck(cppcheck-${target} ${target} ${ARGN})
  else()
    do_register_cppcheck(cppcheck-${target} ${root_target}-${target} ${ARGN})
  endif()

  add_dependencies(cppcheck-all cppcheck-${target})
  add_dependencies(check-${target} cppcheck-all)
endfunction()

# Enable or disable cppcheck for health checks
function(toggle_cppcheck status)
    if(NOT ${status})
      set(CPPCHECK_ENABLED ${status} PARENT_SCOPE)
      if (IS_ROOT_PROJECT)
        message(STATUS "  Checker cppcheck skipped: [disabled]")
        endif()
        return()
    endif()

    find_package(cppcheck)

    if(NOT cppcheck_FOUND)
      set(CPPCHECK_ENABLED OFF PARENT_SCOPE)
      if (IS_ROOT_PROJECT)
        message(WARNING "  Checker cppcheck skipped: [cppcheck not found]")
      endif()
        return()
    endif()

    set(CPPCHECK_ENABLED ${status} PARENT_SCOPE)
    if (IS_ROOT_PROJECT)
      message(STATUS "  Checker cppcheck [enabled]")
    endif()
endfunction()
