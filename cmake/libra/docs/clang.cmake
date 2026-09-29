#
# Copyright 2026 John Harwell, All rights reserved.
#
# SPDX-License-Identifier: MIT
#
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
  _libra_analyze_build_fixeddb_for_target(${PROJECT_NAME} EXTRACTED_ARGS)

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
