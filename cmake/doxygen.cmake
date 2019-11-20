# check if Doxygen is installed
find_package(Doxygen)

if (DOXYGEN_FOUND)
  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/docs/Doxyfile.in")
      # set input and output files
      set(DOXYGEN_IN ${CMAKE_CURRENT_SOURCE_DIR}/docs/Doxyfile.in)
      set(DOXYGEN_OUT ${CMAKE_BINARY_DIR}/docs/${target}/Doxyfile)

      # request to configure the file
      configure_file(${DOXYGEN_IN} ${DOXYGEN_OUT} @ONLY)

      # We are a subproject, and we also have to test if the documentation
      # target already exists, because the same subproject can be present in
      # multiple dependencies for the root project.
    if (NOT TARGET ${target}-documentation AND
        NOT "${target}" STREQUAL "${root_target}")
      add_custom_target(${target}-documentation
        COMMAND ${DOXYGEN_EXECUTABLE} ${DOXYGEN_OUT}
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        COMMENT "Generating ${target} API documentation with Doxygen" VERBATIM)
      # To build ALL documentation recursively.
      add_dependencies(documentation ${target}-documentation)
    elseif("${target}" STREQUAL "${root_target}")
      add_custom_target(${root_target}-documentation
        COMMAND ${DOXYGEN_EXECUTABLE} ${DOXYGEN_OUT}
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
        COMMENT "Generating ${target} API documentation with Doxygen" VERBATIM)

      add_custom_target(documentation
        COMMAND ${DOXYGEN_EXECUTABLE} ${DOXYGEN_OUT}
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR})
      # To build ALL documentation recursively.
      add_dependencies(documentation ${target}-documentation)
    endif()

  else()
    message(WARNING "Doxygen found but ${CMAKE_CURRENT_SOURCE_DIR}/docs/Doxyfile.in does not exist")
  endif(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/docs/Doxyfile.in")
else()
  message(WARNING "Doxygen needs to be installed to generate the documentation!")
endif(DOXYGEN_FOUND)
