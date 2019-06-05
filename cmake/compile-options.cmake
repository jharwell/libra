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
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${LIBRA_DEBUG_OPTS} -fuse-ld=gold")
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
set(CC_DEVOPT_DEFS "-DFPC_TYPE=FPC_RETURN")
set(CC_OPT_DEFS "-DFPC_TYPE=FPC_RETURN -DNDEBUG")

if (LIBRA_ER_NREPORT)
  set(CC_OPT_DEFS "${CC_OPT_DEFS} -DRCPPSW_ER_NREPORT=1")
endif()

#################################################################################
# GNU Compiler Options                                                          #
#################################################################################
if ("${CMAKE_C_COMPILER_ID}" MATCHES "GNU" OR
    "${CMAKE_CXX_COMPILER_ID}" MATCHES "GNU" )

  if(CMAKE_C_COMPILER_VERSION VERSION_LESS 8.0)
    message(FATAL_ERROR "gcc version must be at least 8.0!")
  endif()
  if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS 8.0)
    message(FATAL_ERROR "g++ version must be at least 8.0!")
  endif()
  include(gnu-options)
endif ()

#################################################################################
# clang Compiler Options                                                        #
#################################################################################
if ("${CMAKE_C_COMPILER_ID}" MATCHES "Clang" OR
    "${CMAKE_CXX_COMPILER_ID}" MATCHES "Clang" )
  if(CMAKE_C_COMPILER_VERSION VERSION_LESS 6.0)
    message(FATAL_ERROR "clang version must be at least 6.0!")
  endif()
  if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS 6.0)
    message(FATAL_ERROR "clang++ version must be at least 6.0!")
  endif()
  include(clang-options)
endif ()

#################################################################################
# Intel Compiler Options                                                        #
#################################################################################
if ("${CMAKE_C_COMPILER_ID}" MATCHES "Intel" OR
    "${CMAKE_CXX_COMPILER_ID}" MATCHES "Intel" )
  if(CMAKE_C_COMPILER_VERSION VERSION_LESS 18.0)
    message(FATAL_ERROR "icc version must be at least 18.0!")
  endif()
  if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS 18.0)
    message(FATAL_ERROR "icpc version must be at least 18.0!")
  endif()
  include(intel-options)
endif ()

# Setup MPI
if (LIBRA_MPI)
  find_package(MPI REQUIRED)
  include_directories(SYSTEM ${MPI_INCLUDE_PATH})
endif()
