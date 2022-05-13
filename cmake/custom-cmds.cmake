# Set policy if policy is available
function(set_policy POL VAL)

    if(POLICY ${POL})
        cmake_policy(SET ${POL} ${VAL})
    endif()

endfunction(set_policy)

# Define function "source_group_by_path with three mandatory arguments (PARENT_PATH, REGEX, GROUP, ...)
# to group source files in folders (e.g. for MSVC solutions).
#
# Example:
# source_group_by_path("${CMAKE_CURRENT_SOURCE_DIR}/src" "\\\\.h$|\\\\.inl$|\\\\.cpp$|\\\\.c$|\\\\.ui$|\\\\.qrc$" "Source Files" ${sources})
function(source_group_by_path PARENT_PATH REGEX GROUP)

    foreach (FILENAME ${ARGN})

        get_filename_component(FILEPATH "${FILENAME}" REALPATH)
        file(RELATIVE_PATH FILEPATH ${PARENT_PATH} ${FILEPATH})
        get_filename_component(FILEPATH "${FILEPATH}" DIRECTORY)

        string(REPLACE "/" "\\" FILEPATH "${FILEPATH}")

	source_group("${GROUP}\\${FILEPATH}" REGULAR_EXPRESSION "${REGEX}" FILES ${FILENAME})

    endforeach()

endfunction(source_group_by_path)

# Function that extract entries matching a given regex from a list.
# ${OUTPUT} will store the list of matching filenames.
function(list_extract OUTPUT REGEX)
  foreach(FILENAME ${ARGN})
    if(${FILENAME} MATCHES "${REGEX}")
      list(APPEND ${OUTPUT} ${FILENAME})
    endif()
  endforeach()

  set(${OUTPUT} ${${OUTPUT}} PARENT_SCOPE)

endfunction(list_extract)

# Get all the subdirectories in a directory.
macro(subdirlist result curdir)
  file(GLOB children RELATIVE ${curdir} ${curdir}/*)
  set(dirlist "")
  foreach(child ${children})
    if(IS_DIRECTORY ${curdir}/${child})
      list(APPEND dirlist ${child})
    endif()
  endforeach()
  set(${result} ${dirlist})
endmacro()

function(add_mpi_executable EXECUTABLE)
  add_executable(${EXECUTABLE})
  target_link_libraries(${EXECUTABLE} ${MPI_C_LIBRARIES})
endfunction(add_mpi_executable)

macro(dual_scope_set name value)
  # Set a variable in parent scope and make it visible in current scope
  set(${name} "${value}" PARENT_SCOPE)
  set(${name} "${value}")
endmacro()

################################################################################
# Summary                                                                      #
################################################################################
function(libra_config_summary)
message(STATUS "")
message(STATUS "")
message(STATUS "LIBRA Configuration Summary:")
message(STATUS "")

message(STATUS "Build type............................: CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}")
message(STATUS "Install prefix........................: CMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}")
message(STATUS "Build target architecture.............: CMAKE_SYSTEM_PROCESSOR=${CMAKE_SYSTEM_PROCESSOR}")
message(STATUS "Project dependencies prefix...........: LIBRA_DEPS_PREFIX=${LIBRA_DEPS_PREFIX}")
message(STATUS "Build tests...........................: LIBRA_TESTS=${LIBRA_TESTS}")
message(STATUS "Enable OpenMP.........................: LIBRA_OPENMP=${LIBRA_OPENMP}")
message(STATUS "Enable MPI............................: LIBRA_MPI=${LIBRA_MPI}")
message(STATUS "Enable PGO generation.................: LIBRA_PGO_GEN=${LIBRA_PGO_GEN}")
message(STATUS "Enable PGO use........................: LIBRA_PGO_USE=${LIBRA_PGO_USE}")
message(STATUS "ReadTheDocs build.....................: LIBRA_RTD_BUILD=${LIBRA_RTD_BUILD}")
message(STATUS "Enable code coverage inst.............: LIBRA_CODE_COV=${LIBRA_CODE_COV}")
message(STATUS "Enable documentation..................: LIBRA_DOCS=${LIBRA_DOCS}")
message(STATUS "Function precondition checking........: LIBRA_FPC=${LIBRA_FPC}")
message(STATUS "Event reporting.......................: LIBRA_ER=${LIBRA_ER}")
message(STATUS "Sanitizers {MSAN,ASAN,SSAN,TSAN}......: LIBRA_SAN=${LIBRA_SAN}")

endfunction()
