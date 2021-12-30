set(CLANG_STATIC_CHECK_ENABLED OFF)

################################################################################
# Register a target for clang-tidy checking
################################################################################
function(do_register_clang_check_checker CHECK_TARGET TARGET)
  set(includes "$<TARGET_PROPERTY:${TARGET},INCLUDE_DIRECTORIES>")
  set(defs "$<TARGET_PROPERTY:${TARGET},COMPILE_DEFINITIONS>")

  add_custom_target(${CHECK_TARGET})
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

    add_custom_command(TARGET ${CHECK_TARGET}
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
  add_custom_command(TARGET ${CHECK_TARGET} COMMAND
    rm -rf ${CMAKE_CURRENT_SOURCE_DIR}/*.plist ${CMAKE_CURRENT_LIST_DIR}/*.plist)
  endforeach()

  set_target_properties(${CHECK_TARGET}
    PROPERTIES
    EXCLUDE_FROM_DEFAULT_BUILD 1
    )

  add_dependencies(${CHECK_TARGET} ${TARGET})
endfunction()

################################################################################
# Register all target sources with the clang_check checker
################################################################################
function(register_clang_check_checker TARGET)
  if (NOT CLANG_STATIC_CHECK_ENABLED)
    return()
  endif()

  do_register_clang_check_checker(${TARGET}-clang-check ${TARGET} ${ARGN})

  add_dependencies(${TARGET}-check ${TARGET}-clang-check)
endfunction()

################################################################################
# Enable or disable clang-check checking for the project
################################################################################
function(toggle_clang_static_check status)
  message(CHECK_START "clang-check")
    if(NOT ${status})
      set(CLANG_STATIC_CHECK_ENABLED ${status} PARENT_SCOPE)
      message(CHECK_FAIL "[disabled=by user]")
      return()
    endif()

    find_package(clang_check)

    if(NOT clang_check_FOUND)
      set(CLANG_STATIC_CHECK_ENABLED OFF PARENT_SCOPE)
      message(CHECK_FAIL "[disabled=not found]")
      return()
    endif()

    set(CLANG_STATIC_CHECK_ENABLED ${status} PARENT_SCOPE)
    message(CHECK_PASS "[enabled=${clang_check_EXECUTABLE}]")
endfunction()
