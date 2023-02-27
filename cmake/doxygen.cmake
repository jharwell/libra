#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#
# check if Doxygen is installed
find_package(Doxygen)

if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/docs/Doxyfile.in")
  if (DOXYGEN_FOUND)
      # set input and output files
      set(DOXYGEN_IN ${CMAKE_CURRENT_SOURCE_DIR}/docs/Doxyfile.in)
      set(DOXYGEN_OUT ${CMAKE_BINARY_DIR}/docs/${PROJECT_NAME}/Doxyfile)

      # request to configure the file
      configure_file(${DOXYGEN_IN} ${DOXYGEN_OUT} @ONLY)

      add_custom_target(${PROJECT_NAME}-apidoc
        COMMAND ${DOXYGEN_EXECUTABLE} ${DOXYGEN_OUT}
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
        COMMENT "Generating ${PROJECT_NAME} API documentation with Doxygen" VERBATIM)

      add_custom_target(apidoc
        COMMAND ${DOXYGEN_EXECUTABLE} ${DOXYGEN_OUT}
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR})

      # To build ALL API documentation recursively.
      add_dependencies(apidoc ${PROJECT_NAME}-apidoc)

      message(STATUS "Created 'apidoc' target")
    else()
      message(WARNING "Doxygen not found but ${CMAKE_CURRENT_SOURCE_DIR}/docs/Doxyfile.in exists!")
    endif(DOXYGEN_FOUND)
else()
  message(STATUS "Not creating 'apidoc' target: ${CMAKE_CURRENT_SOURCE_DIR}/docs/Doxyfile.in missing")
endif()
