################################################################################
# Installation Options                                                         #
################################################################################
# Install .so and .a libraries
# install(
#   TARGETS ${target} EXPORT ${target}
#   EXPORT ${target}::${target}
#   LIBRARY DESTINATION ${CMAKE_INSTALL_PREFIX}/lib
#   ARCHIVE DESTINATION ${CMAKE_INSTALL_PREFIX}/lib
#   )

# # Install Header files
# install(
#   DIRECTORY include/${target}/
#   DESTINATION ${CMAKE_INSTALL_PREFIX}/include/${target}
#   FILES_MATCHING PATTERN "*.hpp"
#   )

################################################################################
# CPack Options                                                                #
################################################################################
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

################################################################################
# Export Options                                                               #
################################################################################
# export(PACKAGE ${target} FILE ../cmake/${target}-config.cmake)
