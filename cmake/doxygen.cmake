#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#
# check if Doxygen is installed
find_package(Doxygen)

if (DOXYGEN_FOUND)
  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/docs/Doxyfile.in")
      # set input and output files
      set(DOXYGEN_IN ${CMAKE_CURRENT_SOURCE_DIR}/docs/Doxyfile.in)
      set(DOXYGEN_OUT ${CMAKE_BINARY_DIR}/docs/${PROJECT_NAME}/Doxyfile)

      # request to configure the file
      configure_file(${DOXYGEN_IN} ${DOXYGEN_OUT} @ONLY)

      add_custom_target(${PROJECT_NAME}-documentation
        COMMAND ${DOXYGEN_EXECUTABLE} ${DOXYGEN_OUT}
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
        COMMENT "Generating ${PROJECT_NAME} API documentation with Doxygen" VERBATIM)

      add_custom_target(documentation
        COMMAND ${DOXYGEN_EXECUTABLE} ${DOXYGEN_OUT}
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR})
      # To build ALL documentation recursively.
      add_dependencies(documentation ${PROJECT_NAME}-documentation)
  else()
    message(WARNING "Doxygen found but ${CMAKE_CURRENT_SOURCE_DIR}/docs/Doxyfile.in does not exist")
  endif(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/docs/Doxyfile.in")
else()
  message(WARNING "Doxygen needs to be installed to generate the documentation!")
endif(DOXYGEN_FOUND)
