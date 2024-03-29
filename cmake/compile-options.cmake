#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#
################################################################################
# Configure CFLAGS and whatnot for different C/C++ compilers.
################################################################################
# Project options
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CUDA_STANDARD_REQUIRED ON)

# Configure CCache if available
find_program(CCACHE_FOUND ccache)
if (CCACHE_FOUND)
  message(STATUS "Using ccache")
  set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE ccache)
  set_property(GLOBAL PROPERTY RULE_LAUNCH_LINK ccache)
endif()


################################################################################
# Profile-Guided Optimization (PGO)
################################################################################
set(LIBRA_PGO_MODES NONE GEN USE)
if (NOT "${LIBRA_PGO}" IN_LIST LIBRA_PGO_MODES)
  message(FATAL_ERROR "Bad PGO specification '${LIBRA_PGO}. Must be [NONE,GEN,USE].")
endif()

################################################################################
# Definitions
################################################################################
set(LIBRA_COMMON_OPT_DEFS "${LIBRA_COMMON_OPT_DEFS} -DNDEBUG")

if("${LIBRA_FPC}" MATCHES "NONE")
  set(LIBRA_COMMON_DEV_DEFS "${LIBRA_COMMON_DEV_DEFS} -DLIBRA_FPC=LIBRA_FPC_NONE")
  set(LIBRA_COMMON_DEVOPT_DEFS "${LIBRA_COMMON_DEVOPT_DEFS} -DLIBRA_FPC=LIBRA_FPC_NONE")
  set(LIBRA_COMMON_OPT_DEFS "${LIBRA_COMMON_OPT_DEFS} -DLIBRA_FPC=LIBRA_FPC_NONE")
elseif("${LIBRA_FPC}" MATCHES "RETURN")
  set(LIBRA_COMMON_DEV_DEFS "${LIBRA_COMMON_DEV_DEFS} -DLIBRA_FPC=LIBRA_FPC_RETURN")
  set(LIBRA_COMMON_DEVOPT_DEFS "${LIBRA_COMMON_DEVOPT_DEFS} -DLIBRA_FPC=LIBRA_FPC_RETURN")
  set(LIBRA_COMMON_OPT_DEFS "${LIBRA_COMMON_OPT_DEFS} -DLIBRA_FPC=LIBRA_FPC_RETURN")
elseif("${LIBRA_FPC}" MATCHES "ABORT")
  set(LIBRA_COMMON_DEV_DEFS "${LIBRA_COMMON_DEV_DEFS} -DLIBRA_FPC=LIBRA_FPC_ABORT")
  set(LIBRA_COMMON_DEVOPT_DEFS "${LIBRA_COMMON_DEVOPT_DEFS} -DLIBRA_FPC=LIBRA_FPC_ABORT")
  set(LIBRA_COMMON_OPT_DEFS "${LIBRA_COMMON_OPT_DEFS} -DLIBRA_FPC=LIBRA_FPC_ABORT")
elseif ("${LIBRA_FPC}" MATCHES "INHERIT")
  message(STATUS "Inherit LIBRA_FPC from parent project")
  set(LIBRA_COMMON_DEV_DEFS "${LIBRA_COMMON_DEV_DEFS} -DLIBRA_FPC_INHERIT")
  set(LIBRA_COMMON_DEVOPT_DEFS "${LIBRA_COMMON_DEVOPT_DEFS} -DLIBRA_FPC_INHERIT")
  set(LIBRA_COMMON_OPT_DEFS "${LIBRA_COMMON_OPT_DEFS} -DLIBRA_FPC_INHERIT")
else()
  message(FATAL_ERROR "Bad Function Precondition Checking (FPC) specification '${LIBRA_FPC}'. Must be [NONE,ABORT,RETURN,INHERIT]")
endif()

if ("${LIBRA_ERL}" MATCHES "NONE")
  set(LIBRA_COMMON_DEV_DEFS "${LIBRA_COMMON_DEV_DEFS} -DLIBRA_ERL=LIBRA_ERL_NONE")
  set(LIBRA_COMMON_DEVOPT_DEFS "${LIBRA_COMMON_DEVOPT_DEFS} -DLIBRA_ERL=LIBRA_ERL_NONE")
  set(LIBRA_COMMON_OPT_DEFS "${LIBRA_COMMON_OPT_DEFS} -DLIBRA_ERL=LIBRA_ERL_NONE")
elseif ("${LIBRA_ERL}" MATCHES "FATAL")
  set(LIBRA_COMMON_DEV_DEFS "${LIBRA_COMMON_DEV_DEFS} -DLIBRA_ERL=LIBRA_ERL_FATAL")
  set(LIBRA_COMMON_DEVOPT_DEFS "${LIBRA_COMMON_DEVOPT_DEFS} -DLIBRA_ERL=LIBRA_ERL_FATAL")
  set(LIBRA_COMMON_OPT_DEFS "${LIBRA_COMMON_OPT_DEFS} -DLIBRA_ERL=LIBRA_ERL_FATAL")
elseif ("${LIBRA_ERL}" MATCHES "ERROR")
  set(LIBRA_COMMON_DEV_DEFS "${LIBRA_COMMON_DEV_DEFS} -DLIBRA_ERL=LIBRA_ERL_ERROR")
  set(LIBRA_COMMON_DEVOPT_DEFS "${LIBRA_COMMON_DEVOPT_DEFS} -DLIBRA_ERL=LIBRA_ERL_ERROR")
  set(LIBRA_COMMON_OPT_DEFS "${LIBRA_COMMON_OPT_DEFS} -DLIBRA_ERL=LIBRA_ERL_ERROR")
elseif ("${LIBRA_ERL}" MATCHES "WARN")
  set(LIBRA_COMMON_DEV_DEFS "${LIBRA_COMMON_DEV_DEFS} -DLIBRA_ERL=LIBRA_ERL_WARN")
  set(LIBRA_COMMON_DEVOPT_DEFS "${LIBRA_COMMON_DEVOPT_DEFS} -DLIBRA_ERL=LIBRA_ERL_WARN")
  set(LIBRA_COMMON_OPT_DEFS "${LIBRA_COMMON_OPT_DEFS} -DLIBRA_ERL=LIBRA_ERL_WARN")
elseif ("${LIBRA_ERL}" MATCHES "INFO")
  set(LIBRA_COMMON_DEV_DEFS "${LIBRA_COMMON_DEV_DEFS} -DLIBRA_ERL=LIBRA_ERL_INFO")
  set(LIBRA_COMMON_DEVOPT_DEFS "${LIBRA_COMMON_DEVOPT_DEFS} -DLIBRA_ERL=LIBRA_ERL_INFO")
  set(LIBRA_COMMON_OPT_DEFS "${LIBRA_COMMON_OPT_DEFS} -DLIBRA_ERL=LIBRA_ERL_INFO")
elseif ("${LIBRA_ERL}" MATCHES "DEBUG")
  set(LIBRA_COMMON_DEV_DEFS "${LIBRA_COMMON_DEV_DEFS} -DLIBRA_ERL=LIBRA_ERL_DEBUG")
  set(LIBRA_COMMON_DEVOPT_DEFS "${LIBRA_COMMON_DEVOPT_DEFS} -DLIBRA_ERL=LIBRA_ERL_DEBUG")
  set(LIBRA_COMMON_OPT_DEFS "${LIBRA_COMMON_OPT_DEFS} -DLIBRA_ERL=LIBRA_ERL_DEBUG")
elseif ("${LIBRA_ERL}" MATCHES "TRACE")
  set(LIBRA_COMMON_DEV_DEFS "${LIBRA_COMMON_DEV_DEFS} -DLIBRA_ERL=LIBRA_ERL_TRACE")
  set(LIBRA_COMMON_DEVOPT_DEFS "${LIBRA_COMMON_DEVOPT_DEFS} -DLIBRA_ERL=LIBRA_ERL_TRACE")
  set(LIBRA_COMMON_OPT_DEFS "${LIBRA_COMMON_OPT_DEFS} -DLIBRA_ERL=LIBRA_ERL_TRACE")
elseif("${LIBRA_ERL}" MATCHES "ALL")
  set(LIBRA_COMMON_DEV_DEFS "${LIBRA_COMMON_DEV_DEFS} -DLIBRA_ERL=LIBRA_ERL_ALL")
  set(LIBRA_COMMON_DEVOPT_DEFS "${LIBRA_COMMON_DEVOPT_DEFS} -DLIBRA_ERL=LIBRA_ERL_ALL")
  set(LIBRA_COMMON_OPT_DEFS "${LIBRA_COMMON_OPT_DEFS} -DLIBRA_ERL=LIBRA_ERL_ALL")
elseif ("${LIBRA_ERL}" MATCHES "INHERIT")
  message(STATUS "Inherit LIBRA_ERL from parent project")
  set(LIBRA_COMMON_DEV_DEFS "${LIBRA_COMMON_DEV_DEFS} -DLIBRA_ERL_INHERIT")
  set(LIBRA_COMMON_DEVOPT_DEFS "${LIBRA_COMMON_DEVOPT_DEFS} -DLIBRA_ERL_INHERIT")
  set(LIBRA_COMMON_OPT_DEFS "${LIBRA_COMMON_OPT_DEFS} -DLIBRA_ERL_INHERIT")
else()
  message(FATAL_ERROR "Bad Event Reporting (ER) specification '${LIBRA_ERL}'. Must be [ALL,FATAL,ERROR,WARN,INFO,DEBUG,TRACE,NONE,INHERIT]")
endif()

if (${LIBRA_NOSTDLIB})
  set(LIBRA_COMMON_DEV_DEFS "${LIBRA_COMMON_DEV_DEFS} -D__nostdlib__")
  set(LIBRA_COMMON_DEVOPT_DEFS "${LIBRA_COMMON_DEVOPT_DEFS} -D__nostdlib__")
  set(LIBRA_COMMON_OPT_DEFS "${LIBRA_COMMON_OPT_DEFS} -D__nostdlib__")
endif()

message(STATUS "Detecting features and configuring compiler")
set(CMAKE_REQUIRED_QUIET ON) # Don't emit diagnostics for EVERY flag tested...

################################################################################
# GNU Compiler Options
################################################################################
if ("${CMAKE_C_COMPILER_ID}" MATCHES "GNU" OR
    "${CMAKE_CXX_COMPILER_ID}" MATCHES "GNU" )
  include(gnu-options)
endif()

################################################################################
# clang Compiler Options
################################################################################
if ("${CMAKE_C_COMPILER_ID}" MATCHES "Clang" OR
    "${CMAKE_CXX_COMPILER_ID}" MATCHES "Clang" )
  include(clang-options)
endif ()

################################################################################
# NVIDIA Compiler Options
################################################################################
if ("${CMAKE_CUDA_COMPILER_ID}" MATCHES "NVIDIA")
  include(nvidia-options)
endif ()

################################################################################
# Intel Compiler Options
################################################################################
if ("${CMAKE_C_COMPILER_ID}" MATCHES "Intel" OR
    "${CMAKE_CXX_COMPILER_ID}" MATCHES "Intel" )
  include(intel-options)
endif ()

# Setup MPI
if (LIBRA_MP)
  find_package(MPI REQUIRED)
  include_directories(SYSTEM ${MPI_INCLUDE_PATH})
endif()
