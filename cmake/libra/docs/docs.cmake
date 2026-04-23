#
# Copyright 2026 John Harwell, All rights reserved.
#
# SPDX-License-Identifier: MIT
#
_libra_register_custom_target(apidoc-check LIBRA_DOCS NONE)
_libra_register_custom_target(apidoc-check-clang LIBRA_DOCS clang_EXECUTABLE)
_libra_register_custom_target(apidoc-check-doxygen LIBRA_DOCS
                              DOXYGEN_EXECUTABLE)
_libra_register_custom_target(apidoc LIBRA_DOCS DOXYGEN_EXECUTABLE)
_libra_register_custom_target(sphinxdoc LIBRA_DOCS LIBRA_SPHINXDOC_COMMAND)

# Put this AFTER sourcing the project-local.cmake to enable disabling
# documentation builds for projects that don't have docs.
if(LIBRA_DOCS AND CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
  libra_message(STATUS "Configuring documentation generation")
  include(libra/docs/doxygen)

  add_custom_target(apidoc-check)
  set_target_properties(apidoc-check PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1
                                                EXCLUDE_FROM_ALL 1)

  _libra_calculate_srcs("APIDOC" ${PROJECT_NAME}_DOCS_SRC
                        ${PROJECT_NAME}_DOCS_HEADERS)
  # Should not be needed, but just for safety
  if("${LIBRA_DRIVER}" MATCHES "CONAN")
    list(
      FILTER
      ${PROJECT_NAME}_DOCS_SRC
      EXCLUDE
      REGEX
      "\.conan2")
    list(
      FILTER
      ${PROJECT_NAME}_DOCS_HEADERS
      EXCLUDE
      REGEX
      "\.conan2")
  endif()

  # check if Doxygen is installed
  find_package(Doxygen)
  _libra_apidoc_configure_doxygen(apidoc apidoc-check)
  _libra_find_apidoc_analyzers()

  # Handy checking tools
  libra_message(STATUS "Configuring apidoc tools: checkers")
  _libra_apidoc_register_clang(apidoc-check-clang ${${PROJECT_NAME}_DOCS_SRC}
                               ${${PROJECT_NAME}_DOCS_HEADERS})

  libra_message(STATUS "Configuring sphinxdoc")
  include(libra/docs/sphinx)
  _libra_sphinxdoc_configure(sphinxdoc apidoc)
endif()
