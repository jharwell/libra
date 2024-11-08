#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#
set(CLANG_FORMAT_ENABLED OFF)

# ##############################################################################
# Register a target for clang_format
# ##############################################################################
function(do_register_clang_format FMT_TARGET TARGET)
  add_custom_target(
    ${FMT_TARGET}
    COMMAND ${clang_format_EXECUTABLE} -style=file -i ${ARGN}
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    COMMENT "Running ${clang_format_EXECUTABLE} on ${file}")

  set_target_properties(${FMT_TARGET} PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1)

  add_dependencies(${FMT_TARGET} ${TARGET})
endfunction()

# ##############################################################################
# Register all target sources with the clang_format formatter
# ##############################################################################
function(register_clang_format TARGET)
  if(NOT CLANG_FORMAT_ENABLED)
    return()
  endif()

  do_register_clang_format(fmt-clang-format ${TARGET} ${ARGN})
  add_dependencies(format fmt-clang-format)

endfunction()

# ##############################################################################
# Enable or disable clang_format for auto-formatting for the project
# ##############################################################################
function(toggle_clang_format status)
  message(CHECK_START "Checking for clang-format")
  if(NOT ${status})
    set(CLANG_FORMAT_ENABLED
        ${status}
        PARENT_SCOPE)
    message(CHECK_FAIL "[disabled=by user]")
    return()
  endif()

  find_package(clang_format)

  if(NOT clang_format_FOUND)
    message(CHECK_FAIL "[disabled=not found]")
  else()
    message(CHECK_PASS "[enabled=${clang_format_EXECUTABLE}]")
  endif()

  set(CLANG_FORMAT_ENABLED
      ${status}
      PARENT_SCOPE)
endfunction()
