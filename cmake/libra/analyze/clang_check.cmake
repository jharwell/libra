#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#

# ##############################################################################
# Register a target for clang-tidy checking
# ##############################################################################
function(do_register_clang_check_checker CHECK_TARGET TARGET)
  set(includes $<TARGET_PROPERTY:${TARGET},INCLUDE_DIRECTORIES>)
  set(interface_includes
      ${includes} $<TARGET_PROPERTY:${TARGET},INTERFACE_INCLUDE_DIRECTORIES>)
  set(defs $<TARGET_PROPERTY:${TARGET},COMPILE_DEFINITIONS>)
  set(interface_defs $<TARGET_PROPERTY:${TARGET},INTERFACE_COMPILE_DEFINITIONS>)

  add_custom_target(${CHECK_TARGET})
  # || true is to ignore all return code errors. I added this because Qt expects
  # to be compiled with -fPIC, and because it is not, the analyzer will stop on
  # the first Qt file it gets to.

  foreach(file ${ARGN})
    get_filename_component(fname ${file}, EXT)
    string(FIND ${fname} "cpp" position)
    if(NOT "${position}" MATCHES "-1")
      set(STD gnu++${CMAKE_CXX_STANDARD})
    else()
      set(STD gnu${CMAKE_C_STANDARD})
    endif()

    add_custom_command(
      TARGET ${CHECK_TARGET}
      POST_BUILD
      COMMAND
        ${clang_check_EXECUTABLE} -p\t${CMAKE_CURRENT_SOURCE_DIR} -analyze
        ${file} -ast-dump -- "$<$<BOOL:${includes}>:-I$<JOIN:${includes},\t-I>>"
        "$<$<BOOL:${interface_includes}>:-I$<JOIN:${interface_includes},\t-I>>"
        "$<$<BOOL:${defs}>:-D$<JOIN:${defs},\t-D>>"
        "$<$<BOOL:${interface_defs}>:-D$<JOIN:${interface_defs},\t-D>>"
        -std=${STD} || true
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
      COMMENT "Running ${clang_check_EXECUTABLE} on ${file}")

    add_custom_command(
      TARGET ${CHECK_TARGET}
      POST_BUILD
      COMMAND rm -rf ${CMAKE_CURRENT_SOURCE_DIR}/*.plist
              ${CMAKE_CURRENT_LIST_DIR}/*.plist)
  endforeach()

  set_target_properties(${CHECK_TARGET} PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1)

  add_dependencies(${CHECK_TARGET} ${TARGET})
endfunction()

# ##############################################################################
# Register all target sources with the clang_check checker
# ##############################################################################
function(libra_register_checker_clang_check TARGET)
  if(NOT clang_check_EXECUTABLE)
    return()
  endif()

  do_register_clang_check_checker(analyze-clang-check ${TARGET} ${ARGN})

  add_dependencies(analyze analyze-clang-check)
endfunction()

# ##############################################################################
# Enable or disable clang-check checking for the project
# ##############################################################################
function(libra_toggle_checker_clang_check request)
  if(NOT request)
    libra_message(STATUS "Disabling clang-check checker by request")
    set(clang_check_EXECUTABLE)
    return()
  endif()

  find_program(
    clang_check_EXECUTABLE
    NAMES clang-check-20
          clang-check-19
          clang-check-18
          clang-check-17
          clang-check-16
          clang-check-15
          clang-check-14
          clang-check-13
          clang-check-12
          clang-check-11
          clang-check-10
          clang-check
    PATHS "${clang_check_DIR}")

  if(NOT clang_check_EXECUTABLE)
    message(STATUS "clang-check [disabled=not found]")
    return()
  endif()

endfunction()
