#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#

# ##############################################################################
# Custom messaging
# ##############################################################################
include(libra/messaging)

# check if Doxygen is installed
find_package(Doxygen)

function(libra_apidoc_configure_doxygen)
  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/docs/Doxyfile.in")
    if(DOXYGEN_FOUND)
      # set input and output files
      set(DOXYFILE_IN ${CMAKE_CURRENT_SOURCE_DIR}/docs/Doxyfile.in)
      set(DOXYFILE_OUT ${CMAKE_BINARY_DIR}/docs/${PROJECT_NAME}/Doxyfile)

      # request to configure the file
      configure_file(${DOXYFILE_IN} ${DOXYFILE_OUT} @ONLY)

      add_custom_target(
        apidoc
        COMMAND echo WARN_AS_ERROR=NO >> ${DOXYFILE_OUT} && echo QUIET=NO >>
                ${DOXYFILE_OUT} && ${DOXYGEN_EXECUTABLE} ${DOXYFILE_OUT}
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
        COMMENT "Generating ${PROJECT_NAME} API documentation with doxygen"
        VERBATIM)
      set(DOXYGEN_WARN_AS_ERROR YES)

      add_custom_target(
        apidoc-check-doxygen
        COMMAND
          echo WARN_AS_ERROR=FAIL_ON_WARNINGS >> ${DOXYFILE_OUT} && echo
          QUIET=YES >> ${DOXYFILE_OUT} && ${DOXYGEN_EXECUTABLE} ${DOXYFILE_OUT}
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
        COMMENT "Checking ${PROJECT_NAME} API documentation with doxygen")
      add_dependencies(apidoc-check apidoc-check-doxygen)

    else()
      libra_message(
        WARNING
        "Doxygen not found but ${CMAKE_CURRENT_SOURCE_DIR}/docs/Doxyfile.in exists!"
      )
    endif(DOXYGEN_FOUND)
  else()
    libra_message(
      WARNING
      "Not creating apidoc target: ${CMAKE_CURRENT_SOURCE_DIR}/docs/Doxyfile.in missing"
    )
  endif()
endfunction()

function(libra_apidoc_register_clang CHECK_TARGET)
  add_custom_target(${CHECK_TARGET})

  set(INCLUDES $<TARGET_PROPERTY:${PROJECT_NAME},INCLUDE_DIRECTORIES>)
  set(INTERFACE_INCLUDES
      $<TARGET_PROPERTY:${PROJECT_NAME},INTERFACE_INCLUDE_DIRECTORIES>)
  set(INTERFACE_SYSTEM_INCLUDES
      $<TARGET_PROPERTY:${PROJECT_NAME},INTERFACE_SYSTEM_INCLUDE_DIRECTORIES>)
  set(DEFS $<TARGET_PROPERTY:${PROJECT_NAME},COMPILE_DEFINITIONS>)
  set(INTERFACE_DEFS
      $<TARGET_PROPERTY:${PROJECT_NAME},INTERFACE_COMPILE_DEFINITIONS>)

  get_filename_component(clang_NAME ${clang_EXECUTABLE} NAME)

  foreach(file ${ARGN})
    # We create one target per file we want to checu so that we can do analysis
    # in parallel if desired. Targets can't have '/' on '.' in their names,
    # hence the replacements.
    string(REPLACE "/" "_" file_target "${file}")
    string(REPLACE "." "_" file_target "${file_target}")

    add_custom_target(
      ${CHECK_TARGET}-${file_target}
      COMMAND
        ${clang_EXECUTABLE} "$<$<BOOL:${INCLUDES}>:-I$<JOIN:${INCLUDES},\t-I>>"
        "$<$<BOOL:${INTERFACE_INCLUDES}>:-I$<JOIN:${INTERFACE_INCLUDES},\t-I>>"
        "$<$<BOOL:${INTERFACE_SYSTEM_INCLUDES}>:-isystem$<JOIN:${INTERFACE_SYSTEMINCLUDES},\t-isystem>>"
        "$<$<BOOL:${DEFS}>:-D$<JOIN:${DEFS},\t-D>>"
        "$<$<BOOL:${INTERFACE_DEFS}>:-D$<JOIN:${INTERFACE_DEFS},\t-D>>"
        --std=${LIBRA_CXX_STANDARD} -fsyntax-only -Wno-everything
        -Wdocumentation -Wdocumentation-pedantic -Werror
        ${LIBRA_CLANG_EXTRA_ARGS} ${file}
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
      COMMENT "Checking doxygen markup on ${file} with ${clang_NAME}")
    add_dependencies(${CHECK_TARGET} ${CHECK_TARGET}-${file_target})
  endforeach()

  add_dependencies(apidoc-check apidoc-check-clang)

  list(LENGTH ARGN LEN)
  libra_message(STATUS "Registered ${LEN} files with ${clang_NAME} checker")
endfunction()

# ##############################################################################
# Enable or disable clang-tidy checking for the project
# ##############################################################################
function(libra_toggle_clang request)
  if(NOT request)
    libra_message(STATUS "Disabling clang by request")
    set(clang_EXECUTABLE)
    return()
  endif()

  find_program(
    clang_EXECUTABLE
    NAMES clang-20
          clang-19
          clang-18
          clang-17
          clang-16
          clang-15
          clang-14
          clang-13
          clang-12
          clang-11
          clang-10
          clang
    PATHS "${clang_tidy_DIR}")

  if(NOT clang_EXECUTABLE)
    libra_message(STATUS "clang [disabled=not found]")
    return()
  endif()
endfunction()
