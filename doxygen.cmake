# First we can indicate the documentation build as an option and set it to OFF
# by default.
option(WITH_DOCS "Build documentation as part of default build" OFF)

# check if Doxygen is installed
find_package(Doxygen)
if (DOXYGEN_FOUND)
  # set input and output files
  set(DOXYGEN_IN ${CMAKE_SOURCE_DIR}/docs/Doxyfile.in)
  set(DOXYGEN_OUT ${CMAKE_BINARY_DIR}/Doxyfile)

  # request to configure the file
  configure_file(${DOXYGEN_IN} ${DOXYGEN_OUT} @ONLY)
  execute_process(COMMAND cat ../VERSION OUTPUT_VARIABLE VERSION)
  string(STRIP "${VERSION}" VERSION)

  if (WITH_DOCS)
    if (NOT TARGET documentation)
      add_custom_target(documentation ALL
        COMMAND echo -n PROJECT_NUMBER = "${VERSION}" >> ${DOXYGEN_OUT}
        COMMAND ${DOXYGEN_EXECUTABLE} ${DOXYGEN_OUT}
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
        COMMENT "Generating API documentation with Doxygen" VERBATIM )
    endif()
    else()
    if (NOT TARGET documentation)
      add_custom_target(documentation
        COMMAND echo -n PROJECT_NUMBER = "${VERSION}" >> ${DOXYGEN_OUT}
        COMMAND ${DOXYGEN_EXECUTABLE} ${DOXYGEN_OUT}
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
        COMMENT "Generating API documentation with Doxygen" VERBATIM )
    endif()
  endif(WITH_DOCS)
else()
  message("Doxygen needs to be installed to generate the doxygen documentation!")
endif(DOXYGEN_FOUND)
