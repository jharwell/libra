#
# Copyright 2026 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#

# ##############################################################################
# Custom messaging
# ##############################################################################
include(libra/messaging)

#[[.rst:
.. cmake:command:: _libra_sphinx_configure

  Configures sphinx. If docs/conf.py doesn't exist, nothing is done. Checks if
  :cmake:variable:`LIBRA_SPHINXDOC_COMMAND` works. If it
  works, then the sphinx target is created.

  :param TARGET: Target to generate docs with sphinx.
]]
function(_libra_sphinxdoc_configure TARGET)
  list(APPEND CMAKE_MESSAGE_INDENT " ")

  if(NOT DEFINED LIBRA_SPHINXDOC_COMMAND)
    set(LIBRA_SPHINXDOC_COMMAND ${LIBRA_SPHINXDOC_COMMAND_DEFAULT})
  endif()

  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/docs/conf.py")
    separate_arguments(LIBRA_SPHINXDOC_COMMAND UNIX_COMMAND
                       "${LIBRA_SPHINXDOC_COMMAND}")

    execute_process(
      COMMAND ${LIBRA_SPHINXDOC_COMMAND} --version
      RESULT_VARIABLE SPHINX_RESULT
      OUTPUT_QUIET ERROR_QUIET)

    if(SPHINX_RESULT EQUAL 0)
      libra_message(
        STATUS
        "'${LIBRA_SPHINXDOC_COMMAND} --version' works--creating sphinxdoc target"
      )

      add_custom_target(
        ${TARGET}
        COMMAND ${LIBRA_SPHINXDOC_COMMAND} ${CMAKE_CURRENT_SOURCE_DIR}/docs
                ${CMAKE_CURRENT_SOURCE_DIR}/docs/_build -b html
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        COMMENT "Generating ${PROJECT_NAME} documentation with sphinx"
        VERBATIM)
      if(TARGET apidoc)
        add_dependencies(sphinxdoc apidoc)
        libra_message(STATUS "sphinxdoc depends on apidoc target")
      endif()
    else()
      libra_message(
        WARNING
        "'${LIBRA_SPHINXDOC_COMMAND} --version' not found or failed: ${SPHINX_RESULT}"
      )
    endif()
  else()
    libra_message(
      WARNING
      "Not creating sphinxdoc target: ${CMAKE_CURRENT_SOURCE_DIR}/docs/conf.py missing"
    )
  endif()
  list(POP_BACK CMAKE_MESSAGE_INDENT)
endfunction()
