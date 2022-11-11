#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  LGPL-2.0-or-later
#
set(CLANG_TIDY_CHECK_ENABLED OFF)
set(CLANG_TIDY_FIX_ENABLED OFF)

################################################################################
# Register a target for clang-tidy checking
################################################################################
function(do_register_clang_tidy_check CHECK_TARGET TARGET)
  set(includes "$<TARGET_PROPERTY:${TARGET},INCLUDE_DIRECTORIES>")
  set(defs "$<TARGET_PROPERTY:${TARGET},COMPILE_DEFINITIONS>")

  add_custom_target(${CHECK_TARGET})

  foreach(file ${ARGN})
    add_custom_command(TARGET ${CHECK_TARGET}
      COMMAND
      ${clang_tidy_EXECUTABLE}
      --header-filter=${CMAKE_SOURCE_DIR}/include/*
      -p\t${PROJECT_BINARY_DIR}
      ${file}
      "$<$<NOT:$<BOOL:${CMAKE_EXPORT_COMPILE_COMMANDS}>>:--\t$<$<BOOL:${includes}>:-I$<JOIN:${includes},\t-I>>>"
      "$<$<NOT:$<BOOL:${CMAKE_EXPORT_COMPILE_COMMANDS}>>:--\t$<$<BOOL:${defs}>:-D$<JOIN:${defs},\t-D>>>"
      -extra-arg=-Wno-unknown-warning-option
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
      )
endforeach()
  set_target_properties(${CHECK_TARGET}
    PROPERTIES
    EXCLUDE_FROM_DEFAULT_BUILD 1
    )

  add_dependencies(${CHECK_TARGET} ${TARGET})
endfunction()

################################################################################
# Register all target sources with the clang_tidy checker
################################################################################
function(register_clang_tidy_checker TARGET)
  if (NOT CLANG_TIDY_CHECK_ENABLED)
    return()
  endif()

  do_register_clang_tidy_check(${TARGET}-tidy-check ${TARGET} ${ARGN})

  add_dependencies(${TARGET}-check ${TARGET}-tidy-check)

endfunction()

################################################################################
# Enable or disable clang-tidy checking for the project
################################################################################
function(toggle_clang_tidy_check status)
  message(CHECK_START "clang-tidy")
    if(NOT ${status})
      set(CLANG_TIDY_CHECK_ENABLED ${status} PARENT_SCOPE)
      message(CHECK_FAIL "[disabled=by user]")
      return()
    endif()

    find_package(clang_tidy)

    if(NOT clang_tidy_FOUND)
      set(CLANG_TIDY_CHECK_ENABLED OFF PARENT_SCOPE)
      message(CHECK_FAIL "[disabled=not found]")
    endif()

    set(CLANG_TIDY_CHECK_ENABLED ${status} PARENT_SCOPE)
    message(CHECK_PASS "[enabled=${clang_tidy_EXECUTABLE}]")
endfunction()

################################################################################
# register a target for clang-tidy fixing
################################################################################
function(do_register_clang_tidy_fix CHECK_TARGET TARGET)
  set(includes "$<TARGET_PROPERTY:${TARGET},INCLUDE_DIRECTORIES>")
  set(defs "$<TARGET_PROPERTY:${TARGET},COMPILE_DEFINITIONS>")

  add_custom_target(${CHECK_TARGET})

  foreach(file ${ARGN})
    add_custom_command(TARGET ${CHECK_TARGET}
      COMMAND
      ${clang_tidy_EXECUTABLE}
      --header-filter=${CMAKE_SOURCE_DIR}/include/*
      -p\t${PROJECT_BINARY_DIR}
      -fix
      -fix-errors
      ${file}
      "$<$<NOT:$<BOOL:${CMAKE_EXPORT_COMPILE_COMMANDS}>>:--\t$<$<BOOL:${includes}>:-I$<JOIN:${includes},\t-I>>>"
      "$<$<NOT:$<BOOL:${CMAKE_EXPORT_COMPILE_COMMANDS}>>:--\t$<$<BOOL:${defs}>:-D$<JOIN:${defs},\t-D>>>"
      -extra-arg=-Wno-unknown-warning-option
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
      )
  endforeach()
  set_target_properties(${CHECK_TARGET}
    PROPERTIES
    EXCLUDE_FROM_DEFAULT_BUILD 1
    )
    add_dependencies(${CHECK_TARGET} ${TARGET})
endfunction()

################################################################################
# Register all target sources with the clang_tidy fixer
################################################################################
function(register_clang_tidy_fix TARGET)
  if (NOT CLANG_TIDY_FIX_ENABLED)
    return()
  endif()

  do_register_clang_tidy_fix(${TARGET}-tidy-fix ${TARGET} ${ARGN})
  add_dependencies(${TARGET}-fix ${TARGET}-tidy-fix)
endfunction()

################################################################################
# Enable or disable clang-tidy fixing for the project
################################################################################
function(toggle_clang_tidy_fix status)
  message(CHECK_START "clang-tidy")
  if(NOT ${status})
    set(CLANG_TIDY_FIX_ENABLED ${status} PARENT_SCOPE)
    message(CHECK_FAIL "[disabled=by user]")
    return()
    endif()

    find_package(clang_tidy)

    if(NOT clang_tidy_FOUND)
      set(CLANG_TIDY_FIX_ENABLED OFF PARENT_SCOPE)
      message(CHECK_FAIL "[disabled=not found]")
      return()
    endif()

    set(CLANG_TIDY_FIX_ENABLED ${status} PARENT_SCOPE)
    message(CHECK_PASS "[enabled=${clang_tidy_EXECUTABLE}]")
endfunction()
