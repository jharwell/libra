set(CLANG_STATIC_CHECK_ENABLED OFF)

# Function to register a target for clang-tidy checking
function(do_register_clang_check_checker check_target target)
  set(includes "$<TARGET_PROPERTY:${target},INCLUDE_DIRECTORIES>")
  set(defs "$<TARGET_PROPERTY:${target},COMPILE_DEFINITIONS>")

  add_custom_target(${check_target})
  # || true is to ignore all return code errors. I added this because Qt
  # expects to be compiled with -fPIC, and because it is not, the analyzer
  # will stop on the first Qt file it gets to.

  foreach(file ${ARGN})
    get_filename_component(fname ${file}, EXT)
    string(FIND ${fname} "cpp" position)
    if(NOT "${position}" MATCHES "-1")
      set(STD gnu++${CMAKE_CXX_STANDARD})
    else()
      set(STD gnu${CMAKE_C_STANDARD})
    endif()

    add_custom_command(TARGET ${check_target}
      COMMAND
      ${clang_check_EXECUTABLE}
      -p\t${CMAKE_CURRENT_SOURCE_DIR}
      -analyze
      ${file}
      -ast-dump --
      "$<$<BOOL:${includes}>:-I$<JOIN:${includes},\t-I>>"
      "$<$<BOOL:${defs}>:-D$<JOIN:${defs},\t-D>>"
      -std=${STD}
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

# Registers all sources with the clang_check checker
function(register_clang_check_checker target)
  if (NOT CLANG_STATIC_CHECK_ENABLED)
    return()
  endif()

  if(NOT TARGET static-check-all)
    add_custom_target(static-check-all)

    set_target_properties(static-check-all
      PROPERTIES
      EXCLUDE_FROM_DEFAULT_BUILD 1
      )
  endif()

  if (IS_ROOT_TARGET)
    do_register_clang_check_checker(static-check-${target} ${target} ${ARGN})
  else()
    do_register_clang_check_checker(static-check-${target} ${root_target}-${target} ${ARGN})
  endif()

  add_dependencies(static-check-all static-check-${target})
  add_dependencies(check-${target} static-check-all)
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
        message(WARNING "  Checker clang-check skipped: [clang-check not found (>= 3.8 required)]")
      endif()
        return()
    endif()

    set(CLANG_STATIC_CHECK_ENABLED ${status} PARENT_SCOPE)
    if (IS_ROOT_PROJECT)
    message(STATUS "  Checker clang-check [enabled=${clang_check_EXECUTABLE}]")
    endif()
    set(CMAKE_EXPORT_COMPILE_COMMANDS On PARENT_SCOPE)
endfunction()
