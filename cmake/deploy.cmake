################################################################################
# Exports Configuration                                                        #
################################################################################
function(configure_exports_as TARGET)
  include(CMakePackageConfigHelpers)

  # Project exports file (i.e., the file which defines everything
  # necessary to use the project with find_package())
  if(NOT EXISTS "${PROJECT_SOURCE_DIR}/cmake/config.cmake.in")
    message(FATAL_ERROR "${PROJECT_SOURCE_DIR}/cmake/config.cmake.in does not exist")
  endif()

  configure_package_config_file(
    ${PROJECT_SOURCE_DIR}/cmake/config.cmake.in
    "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}-config.cmake"
    INSTALL_DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/cmake/${TARGET}"
    )

  # Install the configured exports file
  install(
    FILES "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}-config.cmake"
    DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/cmake/${TARGET}"
    )
endfunction()

function(register_extra_configs_for_install TARGET FILE PREFIX)
install(
  FILES ${FILE}
  DESTINATION "${PREFIX}/lib/cmake/${TARGET}"
  )
endfunction()

################################################################################
# Installation Options                                                         #
################################################################################
function(register_headers_for_install DIRECTORY PREFIX)
  install(
    DIRECTORY ${DIRECTORY}
    DESTINATION ${PREFIX}/include
    FILES_MATCHING
    PATTERN "*.hpp"
    PATTERN "*.h"
    )
endfunction()

function(register_target_for_install TARGET PREFIX)
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

################################################################################
# CPack Options                                                                #
################################################################################
function (configure_cpack)
  # Bare-bones project metadata
  set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_SOURCE_DIR}/LICENSE.md")
  set(CPACK_RESOURCE_FILE_README "${CMAKE_SOURCE_DIR}/README.md")
  set(CPACK_PACKAGE_VERSION_MAJOR ${PROJECT_VERSION_MAJOR})
  set(CPACK_PACKAGE_VERSION_MINOR ${PROJECT_VERSION_MINOR})
  set(CPACK_PACKAGE_VERSION_PATCH ${PROJECT_VERSION_PATCH})

  set(CPACK_GENERATOR "DEB")

  # Compute the .deb packages that this target needs
  set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS ON)

  include(CPack)

endfunction()
