################################################################################
# Configure CFLAGS and whatnot for different C/C++ compilers.                  #
################################################################################
# Project options
set(CMAKE_C_STANDARD 99)
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if (BUILD_SHARED_LIBS)
  set(CMAKE_POSITION_INDEPENDENT_CODE ON)
endif()

# Include directories
set(root_include_path "${CMAKE_SOURCE_DIR}/include/")
include_directories(${root_include_path})

file(GLOB_RECURSE all_headers "${root_include_path}/*.h")
set(root_test_dir "${CMAKE_SOURCE_DIR}/tests")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -g")
link_libraries(pthread)

# Configure CCache if available
find_program(CCACHE_FOUND ccache)
if (CCACHE_FOUND)
  set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE ccache)
  set_property(GLOBAL PROPERTY RULE_LAUNCH_LINK ccache)
endif()

# Configure iwyu if available
find_program(iwyu_path NAMES include-what-you-use iwyu)

#################################################################################
# Definitions                                                                   #
#################################################################################
set(CC_DEV_DEFS "-DFPC_TYPE=FPC_ABORT")
set(CC_OPT_DEFS "-DFPC_TYPE=FPC_RETURN -DNDEBUG")

if (WITH_ER_NREPORT)
  set(CC_OPT_DEFS "${CC_OPT_DEFS} -DER_NREPORT=1")
endif()

#################################################################################
# GNU Compiler Options                                                          #
#################################################################################
if ("${CMAKE_C_COMPILER_ID}" MATCHES "GNU" OR
    "${CMAKE_CXX_COMPILER_ID}" MATCHES "GNU" )
  include(gnu-options)
endif ()

#################################################################################
# clang Compiler Options                                                        #
#################################################################################
if ("${CMAKE_C_COMPILER_ID}" MATCHES "Clang" OR
    "${CMAKE_CXX_COMPILER_ID}" MATCHES "Clang" )
    include(clang-options)
endif ()

#################################################################################
# Intel Compiler Options                                                        #
#################################################################################
if ("${CMAKE_C_COMPILER_ID}" MATCHES "Intel" OR
    "${CMAKE_CXX_COMPILER_ID}" MATCHES "Intel" )
  include(intel-options)
endif ()

# Setup MPI
if (WITH_MPI)
  find_package(MPI REQUIRED)
  include_directories(SYSTEM ${MPI_INCLUDE_PATH})
endif()
