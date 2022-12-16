#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#
################################################################################
# Exports Configuration
################################################################################

################################################################################
# Configure the exports for a TARGET to be installed at PREFIX
#
# Enables the installed project to then be used with find_package()
#
################################################################################
function(libra_configure_exports_as TARGET PREFIX)
  include(CMakePackageConfigHelpers)

  # Project exports file (i.e., the file which defines everything
  # necessary to use the project with find_package())
  if(NOT EXISTS "${PROJECT_SOURCE_DIR}/cmake/config.cmake.in")
    message(FATAL_ERROR "${PROJECT_SOURCE_DIR}/cmake/config.cmake.in does not exist")
  endif()

  configure_package_config_file(
    ${PROJECT_SOURCE_DIR}/cmake/config.cmake.in
    "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}-config.cmake"
    INSTALL_DESTINATION "${PREFIX}/lib/cmake/${TARGET}"
    )

  # Install the configured exports file
  install(
    FILES "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}-config.cmake"
    DESTINATION "${PREFIX}/lib/cmake/${TARGET}"
    )
endfunction()

################################################################################
# Register extra files for a TARGET to be installed at PREFIX
#
# Can be any file, but SHOULD be .cmake files if your project has
# reusable functionality you want to expose to child projects.
function(libra_register_extra_configs_for_install TARGET FILES PREFIX)
install(
  FILES ${FILES}
  DESTINATION "${PREFIX}/lib/cmake/${TARGET}"
  )
endfunction()

################################################################################
# Installation Options                                                         #
################################################################################
function(libra_register_headers_for_install DIRECTORY PREFIX)
  install(
    DIRECTORY ${DIRECTORY}
    DESTINATION ${PREFIX}/include
    FILES_MATCHING
    PATTERN "*.hpp"
    PATTERN "*.h"
    )
endfunction()

function(libra_register_target_for_install TARGET PREFIX)
# Install .so and .a libraries
install(
  # Install the target
  TARGETS ${TARGET}
  # Associate target with <target>-exports.cmake
  EXPORT ${TARGET}-exports
  LIBRARY DESTINATION ${PREFIX}/lib
  PUBLIC_HEADER DESTINATION ${PREFIX}/include
  )

install(
  EXPORT ${TARGET}-exports
  FILE ${TARGET}-exports.cmake
  DESTINATION ${PREFIX}/lib/cmake/${TARGET}
  NAMESPACE ${TARGET}::
  )
endfunction()
