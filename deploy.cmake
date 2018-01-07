################################################################################
# Installation Options                                                         #
################################################################################
if ("${CMAKE_CURRENT_SOURCE_DIR}" STREQUAL "${CMAKE_SOURCE_DIR}")
  install(TARGETS ${target} EXPORT ${target}
    LIBRARY DESTINATION ${CMAKE_INSTALL_PREFIX}/lib
    ARCHIVE DESTINATION ${CMAKE_INSTALL_PREFIX}/lib)

  install(DIRECTORY include/${target}/ DESTINATION ${CMAKE_INSTALL_PREFIX}/include/${target}
    FILES_MATCHING PATTERN "*.hpp")
endif()

################################################################################
# Export Options                                                               #
################################################################################
# export(PACKAGE ${target} FILE ../cmake/${target}-config.cmake)
