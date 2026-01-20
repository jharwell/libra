#
# Copyright 2025 John Harwell, All rights reserved.
#
# SPDX-License Identifier: MIT
#
cmake_minimum_required(VERSION 3.30 FATAL_ERROR)

cmake_policy(SET CMP0177 NEW) # Normalize paths

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

include(cmake/libra/version.cmake)

project(
  libra
  VERSION ${LIBRA_VERSION}
  LANGUAGES C CXX)

include(cmake/libra/package/install.cmake)
include(cmake/libra/package/deploy.cmake)

set(CMAKE_INSTALL_CMAKEDIR "${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}")

# Configure cmake config export for install
libra_configure_exports(${PROJECT_NAME})

libra_register_extra_configs_for_install(TARGET ${PROJECT_NAME} FILES_OR_DIRS
                                         ${CMAKE_SOURCE_DIR}/cmake/libra)

# The ../ is necessary to get the dotfiles to be found in the various places.
# Easier to make the change here than to try and figure out how to get conan to
# conform to what cmake does by default.
install(DIRECTORY ${CMAKE_SOURCE_DIR}/dots
        DESTINATION ${CMAKE_INSTALL_CMAKEDIR}/..)

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
