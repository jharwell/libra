#
# Copyright 2025 John Harwell, All rights reserved.
#
# SPDX-License Identifier: MIT
#
# ##############################################################################
# Basic Setup
# ##############################################################################

cmake_minimum_required(VERSION 3.31 FATAL_ERROR)

cmake_policy(SET CMP0177 NEW) # Normalize paths
option(LIBRA_INSTALL_MAN "Generate and install the libra(1) manpage" ON)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

include(cmake/libra/version.cmake)

if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
  # Top-level/when LIBRA itself is being installed: need a language for
  # GNUInstallDirs architecture detection
  project(
    libra
    VERSION ${LIBRA_VERSION}
    LANGUAGES C)
else()
  # Consumed downstream: no language detection needed or wanted since LIBRA is
  # already installed and is pure cmake.
  project(
    libra
    VERSION ${LIBRA_VERSION}
    LANGUAGES NONE)
endif()

include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/libra/package/install.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/libra/package/deploy.cmake)

# Configure cmake config export for install
libra_configure_exports(${PROJECT_NAME})

libra_register_extra_configs_for_install(
  TARGET ${PROJECT_NAME} FILES_OR_DIRS ${CMAKE_CURRENT_SOURCE_DIR}/cmake/libra)

# The ../ is necessary to get the dotfiles to be found in the various places.
# Easier to make the change here than to try and figure out how to get conan to
# conform to what cmake does by default.
install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/dots
        DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/..)

# ##############################################################################
# CLI
# ##############################################################################
if(LIBRA_INSTALL_MAN)
  find_program(HELP2MAN help2man)

  if(NOT HELP2MAN)
    message(
      WARNING
        "help2man not found: skipping manpage generation. "
        "Install help2man or set LIBRA_INSTALL_MAN=OFF to suppress this warning."
    )
  else()
    # Step 2: generate libra.1 from libra --help
    add_custom_command(
      OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/clibra.1
      COMMAND
        ${HELP2MAN} --no-info --name="LIBRA CMake automation framework CLI"
        --manual="LIBRA Manual" --source="LIBRA ${LIBRA_VERSION}"
        --output=${CMAKE_CURRENT_BINARY_DIR}/clibra.1
        ${CMAKE_CURRENT_SOURCE_DIR}/cli/clibra.sh
      DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/cli/clibra.sh
      COMMENT "Generating libra.1 via help2man"
      VERBATIM)

    add_custom_target(libra-man ALL
                      DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/clibra.1)

    install(
      FILES ${CMAKE_CURRENT_BINARY_DIR}/clibra.1
      DESTINATION ${CMAKE_INSTALL_MANDIR}/man1
      COMPONENT man)
  endif()
endif()

install(
  PROGRAMS ${CMAKE_CURRENT_SOURCE_DIR}/cli/clibra.sh
  DESTINATION ${CMAKE_INSTALL_BINDIR}
  COMPONENT runtime)

# ##############################################################################
# Deployment
# ##############################################################################
set(CMAKE_PACKAGE_VERSION "${LIBRA_VERSION}")
set(LIBRA_DESCRIPTION
    "Reusable CMake build automation, to reduce boilerplate/copy-paste across
CMake projects. Features:

* Polymorphic compiler flag plumbing to enable features such as sanitizers, code
  coverage, optimization, etc. across compilers.
* Simple package generation via CPack.
* Automatic API documentation generation and checking.
* Automatic source file registration with various static analyzers, code
  formatting tools, etc.,  and checking.
* Automatic {unit, regression, integration} test registration and execution.
")
libra_configure_cpack(
  "DEB;RPM"
  "Reusable CMake build automation layer"
  ${LIBRA_DESCRIPTION}
  "John Harwell"
  "https://jharwell.github.io/libra"
  "John Harwell <john.r.harwell@gmail.com>")
