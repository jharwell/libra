#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#
set(CLANG_TIDY_CHECK_ENABLED OFF)
set(CLANG_TIDY_FIX_ENABLED OFF)

# We want to be able to enable only SOME checks in clang-tidy in a single run,
# both to speed up pipelines, but also to fixing errors simpler when there are
# TONS. These seem to be a comprehensive set of errors in clang-19; may need to
# be updated in the future.
set(CLANG_TIDY_CATEGORIES
    cppcoreguidelines
    readability
    hicpp
    bugprone
    cert
    performance
    portability
    concurrency
    modernize
    misc
    google)

# ##############################################################################
# Register a target for clang-tidy checking
# ##############################################################################
function(do_register_clang_tidy_check CHECK_TARGET TARGET)
  set(includes $<TARGET_PROPERTY:${TARGET},INCLUDE_DIRECTORIES>)
  set(interface_includes
      ${includes} $<TARGET_PROPERTY:${TARGET},INTERFACE_INCLUDE_DIRECTORIES>)
  set(defs $<TARGET_PROPERTY:${TARGET},COMPILE_DEFINITIONS>)
  set(interface_defs ${defs}
                     $<TARGET_PROPERTY:${TARGET},INTERFACE_COMPILE_DEFINITIONS>)

  add_custom_target(${CHECK_TARGET})
  set_target_properties(${CHECK_TARGET} PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1)

  foreach(CATEGORY ${CLANG_TIDY_CATEGORIES})

    add_custom_target(${CHECK_TARGET}-${CATEGORY})
    add_dependencies(${CHECK_TARGET} ${CHECK_TARGET}-${CATEGORY})
    set_target_properties(${CHECK_TARGET}-${CATEGORY}
                          PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1)

    # We generate per-file commands so that we (a) get more fine-grained
    # feedback from clang-tidy, and (b) don't have to wait until clang-tidy
    # finishes running against ALL files to get feedback for a given file.
    foreach(file ${ARGN})
      add_custom_command(
        TARGET ${CHECK_TARGET}-${CATEGORY}
        COMMAND
          ${clang_tidy_EXECUTABLE} --header-filter=${CMAKE_SOURCE_DIR}/include/*
          -p\t${PROJECT_BINARY_DIR} ${file}
          "$<$<NOT:$<BOOL:${CMAKE_EXPORT_COMPILE_COMMANDS}>>:--\t$<$<BOOL:${includes}>:-I$<JOIN:${includes},\t-I>>>"
          "$<$<NOT:$<BOOL:${CMAKE_EXPORT_COMPILE_COMMANDS}>>:--\t$<$<BOOL:${interface_includes}>:-I$<JOIN:${interface_includes},\t-I>>>"
          "$<$<NOT:$<BOOL:${CMAKE_EXPORT_COMPILE_COMMANDS}>>:--\t$<$<BOOL:${defs}>:-D$<JOIN:${defs},\t-D>>>"
          "$<$<NOT:$<BOOL:${CMAKE_EXPORT_COMPILE_COMMANDS}>>:--\t$<$<BOOL:${interface_defs}>:-D$<JOIN:${interface_defs},\t-D>>>"
          --checks=-*,${CATEGORY}* -extra-arg=-Wno-unknown-warning-option ||
          true
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        COMMENT "Running ${clang_tidy_EXECUTABLE} on ${file}")
    endforeach()
  endforeach()

  set_target_properties(${CHECK_TARGET} PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1)
  add_dependencies(${CHECK_TARGET} ${TARGET})
endfunction()

# ##############################################################################
# Register all target sources with the clang_tidy checker
# ##############################################################################
function(register_clang_tidy_checker TARGET)
  if(NOT CLANG_TIDY_CHECK_ENABLED)
    return()
  endif()

  do_register_clang_tidy_check(check-clang-tidy ${TARGET} ${ARGN})
  add_dependencies(check check-clang-tidy)

endfunction()

# ##############################################################################
# Enable or disable clang-tidy checking for the project
# ##############################################################################
function(toggle_clang_tidy_check status)
  message(CHECK_START "Checking for clang-tidy")

  find_package(clang_tidy)

  if(NOT clang_tidy_FOUND)
    set(CLANG_TIDY_CHECK_ENABLED
        OFF
        PARENT_SCOPE)
    message(CHECK_FAIL "[disabled=not found]")
  endif()

  set(CLANG_TIDY_CHECK_ENABLED
      ${status}
      PARENT_SCOPE)
  message(CHECK_PASS "[enabled=${clang_tidy_EXECUTABLE}]")
endfunction()

# ##############################################################################
# register a target for clang-tidy fixing
# ##############################################################################
function(do_register_clang_tidy_fix FIX_TARGET TARGET)
  set(includes "$<TARGET_PROPERTY:${TARGET},INCLUDE_DIRECTORIES>")
  set(defs "$<TARGET_PROPERTY:${TARGET},COMPILE_DEFINITIONS>")

  add_custom_target(${FIX_TARGET})
  set_target_properties(${FIX_TARGET} PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1)

  foreach(CATEGORY ${CLANG_TIDY_CATEGORIES})

    add_custom_target(${FIX_TARGET}-${CATEGORY})
    add_dependencies(${FIX_TARGET} ${FIX_TARGET}-${CATEGORY})
    set_target_properties(${FIX_TARGET}-${CATEGORY}
                          PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1)

    foreach(file ${ARGN})
      add_custom_command(
        TARGET ${FIX_TARGET}-${CATEGORY}
        COMMAND
          ${clang_tidy_EXECUTABLE} --header-filter=${CMAKE_SOURCE_DIR}/include/*
          -p\t${PROJECT_BINARY_DIR} ${file}
          "$<$<NOT:$<BOOL:${CMAKE_EXPORT_COMPILE_COMMANDS}>>:--\t$<$<BOOL:${includes}>:-I$<JOIN:${includes},\t-I>>>"
          "$<$<NOT:$<BOOL:${CMAKE_EXPORT_COMPILE_COMMANDS}>>:--\t$<$<BOOL:${interface_includes}>:-I$<JOIN:${interface_includes},\t-I>>>"
          "$<$<NOT:$<BOOL:${CMAKE_EXPORT_COMPILE_COMMANDS}>>:--\t$<$<BOOL:${defs}>:-D$<JOIN:${defs},\t-D>>>"
          "$<$<NOT:$<BOOL:${CMAKE_EXPORT_COMPILE_COMMANDS}>>:--\t$<$<BOOL:${interface_defs}>:-D$<JOIN:${interface_defs},\t-D>>>"
          --checks=-*,${CATEGORY}* -extra-arg=-Wno-unknown-warning-option --fix
          --fix-errors
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        COMMENT "Running ${clang_tidy_EXECUTABLE} on ${file}")
    endforeach()
    set_target_properties(${FIX_TARGET} PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1)
    add_dependencies(${FIX_TARGET} ${TARGET})
  endforeach()

endfunction()

# ##############################################################################
# Register all target sources with the clang_tidy fixer
# ##############################################################################
function(register_clang_tidy_fix TARGET)
  if(NOT CLANG_TIDY_FIX_ENABLED)
    return()
  endif()

  do_register_clang_tidy_fix(fix-clang-tidy ${TARGET} ${ARGN})
  add_dependencies(fix fix-clang-tidy)
endfunction()

# ##############################################################################
# Enable or disable clang-tidy fixing for the project
# ##############################################################################
function(toggle_clang_tidy_fix status)
  message(CHECK_START "Checking for clang-tidy")

  find_package(clang_tidy)

  if(NOT clang_tidy_FOUND)
    set(CLANG_TIDY_FIX_ENABLED
        OFF
        PARENT_SCOPE)
    message(CHECK_FAIL "[disabled=not found]")
    return()
  endif()

  set(CLANG_TIDY_FIX_ENABLED
      ${status}
      PARENT_SCOPE)
  message(CHECK_PASS "[enabled=${clang_tidy_EXECUTABLE}]")
endfunction()
