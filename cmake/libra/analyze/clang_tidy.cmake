#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#

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
  set(interface_defs $<TARGET_PROPERTY:${TARGET},INTERFACE_COMPILE_DEFINITIONS>)

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
        POST_BUILD
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
        COMMENT
          "Running ${clang_tidy_EXECUTABLE} on ${file}, category=${CATEGORY}")
    endforeach()
  endforeach()

  set_target_properties(${CHECK_TARGET} PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1)
  add_dependencies(${CHECK_TARGET} ${TARGET})
endfunction()

# ##############################################################################
# Register all target sources with the clang_tidy checker
# ##############################################################################
function(libra_register_checker_clang_tidy TARGET)
  if(NOT clang_tidy_EXECUTABLE)
    return()
  endif()

  do_register_clang_tidy_check(analyze-clang-tidy ${TARGET} ${ARGN})
  add_dependencies(analyze analyze-clang-tidy)
endfunction()

# ##############################################################################
# Enable or disable clang-tidy checking for the project
# ##############################################################################
function(libra_toggle_checker_clang_tidy request)
  if(NOT request)
    libra_message(STATUS "Disabling clang-tidy checker by request")
    set(clang_tidy_EXECUTABLE)
    return()
  endif()

  find_program(
    clang_tidy_EXECUTABLE
    NAMES clang-tidy-20
          clang-tidy-19
          clang-tidy-18
          clang-tidy-17
          clang-tidy-16
          clang-tidy-15
          clang-tidy-14
          clang-tidy-13
          clang-tidy-12
          clang-tidy-11
          clang-tidy-10
          clang-tidy
    PATHS "${clang_tidy_DIR}")

  if(NOT clang_tidy_EXECUTABLE)
    message(STATUS "clang-tidy [disabled=not found]")
    return()
  endif()
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
        POST_BUILD
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
        COMMENT
          "Running ${clang_tidy_EXECUTABLE} on ${file}, category=${CATEGORY}")
    endforeach()
    set_target_properties(${FIX_TARGET} PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1)
    add_dependencies(${FIX_TARGET} ${TARGET})
  endforeach()

endfunction()

# ##############################################################################
# Register all target sources with the clang_tidy fixer
# ##############################################################################
function(libra_register_fixer_clang_tidy TARGET)
  if(NOT clang_tidy_EXECUTABLE)
    return()
  endif()

  do_register_clang_tidy_fix(fix-clang-tidy ${TARGET} ${ARGN})
  add_dependencies(fix fix-clang-tidy)
endfunction()

# ##############################################################################
# Enable or disable clang-tidy fixing for the project
# ##############################################################################
function(libra_toggle_fixer_clang_tidy request)
  if(NOT request)
    libra_message(STATUS "Disabling clang-tidy fixer by request")
    set(clang_tidy_EXECUTABLE)
    return()
  endif()

  find_program(
    clang_tidy_EXECUTABLE
    NAMES clang-tidy-19
          clang-tidy-18
          clang-tidy-17
          clang-tidy-16
          clang-tidy-15
          clang-tidy-14
          clang-tidy-13
          clang-tidy-12
          clang-tidy-11
          clang-tidy-10
          clang-tidy
    PATHS "${clang_tidy_DIR}")

  if(NOT clang_tidy_EXECUTABLE)
    message(STATUS "clang-tidy [disabled=not found]")
    return()
  endif()
endfunction()
