#
# Copyright 2026 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#

# ##############################################################################
# Custom messaging
# ##############################################################################
include(libra/messaging)
include(libra/utils)

#[[.rst:
.. cmake:command:: _libra_sphinxdoc_configure

  Configures sphinx. If docs/conf.py doesn't exist, nothing is done. Checks if
  :cmake:variable:`LIBRA_SPHINXDOC_COMMAND` works. If it
  works, then the sphinx target is created.

  :param SPHINXDOC_TARGET: Target to generate docs with sphinx.

  :param APIDOC_TARGET: Target to generate API docs. If it exists, the the
   sphinx target will depend on it.
]]
function(_libra_sphinxdoc_configure SPHINXDOC_TARGET APIDOC_TARGET)
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
        "'${LIBRA_SPHINXDOC_COMMAND} --version' works--creating ${SPHINXDOC_TARGET} target"
      )

      add_custom_target(
        ${SPHINXDOC_TARGET}
        COMMAND ${LIBRA_SPHINXDOC_COMMAND} ${CMAKE_CURRENT_SOURCE_DIR}/docs
                ${CMAKE_CURRENT_SOURCE_DIR}/docs/_build -b html
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        COMMENT "Generating ${PROJECT_NAME} documentation with sphinx"
        VERBATIM)
      if(TARGET ${APIDOC_TARGET})
        add_dependencies(${SPHINXDOC_TARGET} ${APIDOC_TARGET})
        libra_message(STATUS "${SPHINXDOC_TARGET} depends on apidoc target")
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
