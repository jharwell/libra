#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#

# ##############################################################################
# Custom messaging
# ##############################################################################
include(libra/messaging)
include(libra/analyze/analyze)
include(libra/utils)

#[[.rst:
.. cmake:command:: _libra_apidoc_configure_doxygen

  Configures doxygen. If docs/Doxyfile.in doesn't exist, nothing is done. If it
  does exist, then the parameter targets are created.

  :param APIDOC_TARGET: Target to generate API docs with doxygen.

  :param APIDOC_CHECK_TARGET: Parent target to check API documentation for all
   configured source files. All warnings from doxygen are treated as errors,
   which can be a little pedantic.
]]
function(_libra_apidoc_configure_doxygen APIDOC_TARGET APIDOC_CHECK_TARGET)
  list(APPEND CMAKE_MESSAGE_INDENT " ")

  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/docs/Doxyfile.in")
    if(DOXYGEN_FOUND)
      # set input and output files
      set(DOXYFILE_IN ${CMAKE_CURRENT_SOURCE_DIR}/docs/Doxyfile.in)
      set(DOXYFILE_OUT ${CMAKE_BINARY_DIR}/docs/${PROJECT_NAME}/Doxyfile)

      # request to configure the file
      configure_file(${DOXYFILE_IN} ${DOXYFILE_OUT} @ONLY)

      add_custom_target(
        ${APIDOC_TARGET}
        COMMAND echo WARN_AS_ERROR=NO >> ${DOXYFILE_OUT} && echo QUIET=NO >>
                ${DOXYFILE_OUT} && ${DOXYGEN_EXECUTABLE} ${DOXYFILE_OUT}
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
        COMMENT "Generating ${PROJECT_NAME} API documentation with doxygen"
        VERBATIM)
      set_target_properties(
        ${APIDOC_TARGET} PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1
                                    EXCLUDE_FROM_ALL 1)

      set(DOXYGEN_WARN_AS_ERROR YES)

      add_custom_target(
        ${APIDOC_CHECK_TARGET}-doxygen
        COMMAND
          echo WARN_AS_ERROR=FAIL_ON_WARNINGS >> ${DOXYFILE_OUT} && echo
          QUIET=YES >> ${DOXYFILE_OUT} && ${DOXYGEN_EXECUTABLE} ${DOXYFILE_OUT}
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
        COMMENT "Checking ${PROJECT_NAME} API documentation with doxygen")
      set_target_properties(
        ${APIDOC_CHECK_TARGET}-doxygen PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1
                                                  EXCLUDE_FROM_ALL 1)
      add_dependencies(${APIDOC_CHECK_TARGET} ${APIDOC_CHECK_TARGET}-doxygen)

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
  list(POP_BACK CMAKE_MESSAGE_INDENT)
endfunction()

#[[.rst:
.. cmake:command:: _libra_apidoc_register_clang

  Configures clang for API doc checking. Uses a fixeddb unconditionally, since
  we need very little actual syntax checking for the code to check the docs.
]]
function(_libra_apidoc_register_clang CHECK_TARGET)
  list(APPEND CMAKE_MESSAGE_INDENT " ")

  add_custom_target(${CHECK_TARGET})
  set_target_properties(${CHECK_TARGET} PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1
                                                   EXCLUDE_FROM_ALL 1)
  analyze_build_fixeddb_for_target(${PROJECT_NAME} EXTRACTED_ARGS)

  get_filename_component(clang_NAME ${clang_EXECUTABLE} NAME)

  _libra_get_project_language(_LANG)
  if("${_LANG}" STREQUAL "CXX")
    set(STD_ARG --std=gnu++${LIBRA_CXX_STANDARD})
  else()
    set(STD_ARG --std=gnu${LIBRA_C_STANDARD})
  endif()

  foreach(file ${ARGN})
    # We create one target per file we want to check so that we can do analysis
    # in parallel if desired. Targets can't have '/' on '.' in their names,
    # hence the replacements.
    string(REPLACE "/" "_" file_target "${file}")
    string(REPLACE "." "_" file_target "${file_target}")

    add_custom_target(
      ${CHECK_TARGET}-${file_target}
      COMMAND
        ${clang_EXECUTABLE} ${STD_ARG} ${EXTRACTED_ARGS} -fsyntax-only
        -Wno-everything -Wdocumentation -Wdocumentation-pedantic -Werror ${file}
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
      COMMENT "Checking doxygen markup on ${file} with ${clang_NAME}")
    add_dependencies(${CHECK_TARGET} ${CHECK_TARGET}-${file_target})
  endforeach()

  add_dependencies(apidoc-check apidoc-check-clang)

  list(LENGTH ARGN LEN)
  libra_message(STATUS "Registered ${LEN} files with ${clang_NAME} checker")
  list(POP_BACK CMAKE_MESSAGE_INDENT)
endfunction()
