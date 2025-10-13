#
# Copyright 2025 John Harwell, All rights reserved.
#
# SPDX-License Identifier: MIT
#
cmake_minimum_required(VERSION 3.30 FATAL_ERROR)
project(libra)

include(CMakePackageConfigHelpers)

# Define install locations
include(GNUInstallDirs)
set(CMAKE_INSTALL_CMAKEDIR "${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}")

configure_package_config_file(
  ${PROJECT_SOURCE_DIR}/cmake/config.cmake.in
  "${CMAKE_CURRENT_BINARY_DIR}/libra-config.cmake"
  INSTALL_DESTINATION ${CMAKE_INSTALL_CMAKEDIR})

# Install the .cmake files
install(DIRECTORY ${CMAKE_SOURCE_DIR}/cmake/libra
        DESTINATION ${CMAKE_INSTALL_CMAKEDIR})

# The ../ is necessary to get the dotfiles to be found in the various places.
# Easier to make the change here than to try and figure out how to get conan to
# conform to what cmake does by default.
install(DIRECTORY ${CMAKE_SOURCE_DIR}/dots
        DESTINATION ${CMAKE_INSTALL_CMAKEDIR}/..)

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/libra-config.cmake
        DESTINATION ${CMAKE_INSTALL_CMAKEDIR})
