set(CLANG_STATIC_CHECK_ENABLED OFF)

# Function to register a target for clang-tidy checking
function(register_clang_static_check check_target target)
  set(includes "$<TARGET_PROPERTY:${target},INCLUDE_DIRECTORIES>")

  add_custom_target(${check_target})
  # || true is to ignore all return code errors. I added this because Qt
  # expects to be compiled with -fPIC, and because it is not, the analyzer
  # will stop on the first Qt file it gets to.
  foreach(file ${ARGN})
    add_custom_command(TARGET ${check_target}
      COMMAND
      ${clang_check_EXECUTABLE}
      -p\t${CMAKE_SOURCE_DIR}
      -analyze
      ${file}
      -ast-dump --
      "$<$<BOOL:${includes}>:-I$<JOIN:${includes},\t-I>>"
      -std=c++${CMAKE_CXX_STANDARD}
       || true
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
  add_custom_command(TARGET ${check_target} COMMAND
    rm -rf ${CMAKE_CURRENT_SOURCE_DIR}/*.plist ${CMAKE_CURRENT_LIST_DIR}/*.plist)
  endforeach()

  set_target_properties(${check_target}
    PROPERTIES
    EXCLUDE_FROM_DEFAULT_BUILD 1
    )

  add_dependencies(${check_target} ${target})
endfunction()

# Enable or disable clang-check checking
function(toggle_clang_static_check status)
    if(NOT ${status})
      set(CLANG_STATIC_CHECK_ENABLED ${status} PARENT_SCOPE)
      if (IS_ROOT_PROJECT)
        message(STATUS "  Checker clang-check skipped: [disabled]")
        endif()
        return()
    endif()

    find_package(clang_check)

    if(NOT clang_check_FOUND)
      set(CLANG_STATIC_CHECK_ENABLED OFF PARENT_SCOPE)
      if (IS_ROOT_PROJECT)
        message(WARNING "  Checker clang-check skipped: [clang-check not found]")
      endif()
        return()
    endif()

    set(CLANG_STATIC_CHECK_ENABLED ${status} PARENT_SCOPE)
    if (IS_ROOT_PROJECT)
    message(STATUS "  Checker clang-check [enabled]")
    endif()
    set(CMAKE_EXPORT_COMPILE_COMMANDS On PARENT_SCOPE)
endfunction()
