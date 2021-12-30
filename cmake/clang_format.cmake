set(CLANG_FORMAT_ENABLED OFF)

################################################################################
# Register a target for clang_format
################################################################################
function(do_register_clang_format CHECK_TARGET TARGET)
  file(GLOB INCLUDES ${CMAKE_SOURCE_DIR}/include/${TARGET}/*/*.hpp)
  add_custom_target(
    ${CHECK_TARGET}
    COMMAND
    ${clang_format_EXECUTABLE}
    -style=file
    -i
    ${ARGN} ${INCLUDES}
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    )


  set_target_properties(${CHECK_TARGET}
    PROPERTIES
    EXCLUDE_FROM_DEFAULT_BUILD 1
    )

  add_dependencies(${CHECK_TARGET} ${TARGET})
endfunction()

################################################################################
# Register all target sources with the clang_format formatter
################################################################################
function(register_clang_format TARGET)
    if (NOT CLANG_FORMAT_ENABLED)
    return()
  endif()

  do_register_clang_format(${TARGET}-clang-format ${TARGET} ${ARGN})
  add_dependencies(${TARGET}-format ${TARGET}-clang-format)

endfunction()

################################################################################
# Enable or disable clang_format for auto-formatting for the project
################################################################################
function(toggle_clang_format status)
  message(CHECK_START "clang-format")
  if(NOT ${status})
      set(CLANG_FORMAT_ENABLED ${status} PARENT_SCOPE)
      message(CHECK_FAIL "[disabled=by user]")
      return()
    endif()

    find_package(clang_format)

    if(NOT clang_format_FOUND)
      set(CLANG_FORMAT_ENABLED OFF PARENT_SCOPE)
      message(CHECK_FAIL "[disabled=not found]")
    endif()

    set(CLANG_FORMAT_ENABLED ${status} PARENT_SCOPE)
    message(CHECK_PASS "[enabled=${clang_format_EXECUTABLE}]")
endfunction()
