#
# Copyright 2026 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#

# ##############################################################################
# Custom messaging
# ##############################################################################
include(libra/messaging)

function(_libra_sphinxdoc_configure)
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
        sphinxdoc
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
endfunction()
