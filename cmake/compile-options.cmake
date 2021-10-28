################################################################################
# Configure CFLAGS and whatnot for different C/C++ compilers.                  #
################################################################################
# Project options
set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)

set(CMAKE_CXX_STANDARD_REQUIRED ON)
# Include directories
set(root_include_path "${CMAKE_SOURCE_DIR}/include/")
include_directories(${root_include_path})

file(GLOB_RECURSE all_headers "${root_include_path}/*.h")
set(root_test_dir "${CMAKE_SOURCE_DIR}/tests")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${LIBRA_DEBUG_OPTS} -fuse-ld=gold")

# Configure CCache if available
find_program(CCACHE_FOUND ccache)
if (CCACHE_FOUND)
  message(STATUS "  Found ccache")
  set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE ccache)
  set_property(GLOBAL PROPERTY RULE_LAUNCH_LINK ccache)
endif()

#################################################################################
# Definitions                                                                   #
#################################################################################
set(CC_DEV_DEFS "-DRCSW_FPC_TYPE=RCSW_FPC_RETURN")
set(CC_DEVOPT_DEFS "-DRCSW_FPC_TYPE=RCSW_FPC_RETURN")
set(CC_OPT_DEFS "-DRCSW_FPC_TYPE=RCSW_FPC_RETURN -DNDEBUG")

if ("${LIBRA_ER}" MATCHES "NONE")
  set(CC_DEV_DEFS "${CC_DEV_DEFS} -DLIBRA_ER=LIBRA_ER_NONE")
  set(CC_DEVOPT_DEFS "${CC_DEVOPT_DEFS} -DLIBRA_ER=LIBRA_ER_NONE")
  set(CC_OPT_DEFS "${CC_OPT_DEFS} -DLIBRA_ER=LIBRA_ER_NONE")
  message(STATUS "Event reporting disabled: NONE")
elseif ("${LIBRA_ER}" MATCHES "FATAL")
  set(CC_DEV_DEFS "${CC_DEV_DEFS} -DLIBRA_ER=LIBRA_ER_FATAL")
  set(CC_DEVOPT_DEFS "${CC_DEVOPT_DEFS} -DLIBRA_ER=LIBRA_ER_FATAL")
  set(CC_OPT_DEFS "${CC_OPT_DEFS} -DLIBRA_ER=LIBRA_ER_FATAL")
  message(STATUS "Event reporting enabled: FATAL only")
elseif("${LIBRA_ER}" MATCHES "ALL")
  message(STATUS "Event reporting enabled: ALL")
  set(CC_DEV_DEFS "${CC_DEV_DEFS} -DLIBRA_ER=LIBRA_ER_ALL")
  set(CC_DEVOPT_DEFS "${CC_DEVOPT_DEFS} -DLIBRA_ER=LIBRA_ER_ALL")
  set(CC_OPT_DEFS "${CC_OPT_DEFS} -DLIBRA_ER=LIBRA_ER_ALL")
else ()
  message(FATAL_ERROR "Bad event reporting specification '${LIBRA_ER}'. Must be [ALL,FATAL,NONE]")
endif()

#################################################################################
# GNU Compiler Options                                                          #
#################################################################################
if ("${CMAKE_C_COMPILER_ID}" MATCHES "GNU" OR
    "${CMAKE_CXX_COMPILER_ID}" MATCHES "GNU" )
  set(CMAKE_CXX_STANDARD 17)

  if (NOT "${LIBRA_RTD_BUILD}")
    if(CMAKE_C_COMPILER_VERSION VERSION_LESS 9.0)
      message(FATAL_ERROR "gcc version must be at least 9.0!")
    endif()
    if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS 9.0)
      message(FATAL_ERROR "g++ version must be at least 9.0!")
    endif()
    include(gnu-options)
  endif()
endif()

#################################################################################
# clang Compiler Options                                                        #
#################################################################################
if ("${CMAKE_C_COMPILER_ID}" MATCHES "Clang" OR
    "${CMAKE_CXX_COMPILER_ID}" MATCHES "Clang" )
  set(CMAKE_CXX_STANDARD 17)

  if(CMAKE_C_COMPILER_VERSION VERSION_LESS 10.0)
    message(FATAL_ERROR "clang version must be at least 10.0!")
  endif()
  if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS 10.0)
    message(FATAL_ERROR "clang++ version must be at least 10.0!")
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
