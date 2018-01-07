set(CPPCHECK_ENABLED OFF)

# Function to register a target for cppcheck
function(register_cppcheck check_target target)
  set(includes "$<TARGET_PROPERTY:${target},INCLUDE_DIRECTORIES>")
  add_custom_target(${check_target})

  foreach(file ${ARGN})
    add_custom_command(TARGET ${check_target}
      COMMAND
      ${cppcheck_EXECUTABLE}
      "$<$<BOOL:${includes}>:-I$<JOIN:${includes},\t-I>>"
      --check-config
      --enable=all
      --template= "\"[{severity}][{id}] {message} {callstack} (On {file}:{line})\""
      --quiet
      --std=c++11
      --verbose
      --suppress=missingIncludeSystem
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
