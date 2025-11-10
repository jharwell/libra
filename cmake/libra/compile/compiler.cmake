#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#
# ##############################################################################
# Custom messaging
# ##############################################################################
include(libra/messaging)
include(libra/defaults)

# ##############################################################################
# Configure CFLAGS and whatnot for different C/C++ compilers.
# ##############################################################################
# Project options
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(NOT LIBRA_NO_CCACHE)
  # Configure CCache if available
  find_program(CCACHE_FOUND ccache)

  if(CCACHE_FOUND)
    libra_message(STATUS "Using ccache")
    set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE ccache)
    set_property(GLOBAL PROPERTY RULE_LAUNCH_LINK ccache)
  else()
    libra_message(STATUS "Not using ccache [disabled=notfound]")
  endif()
else()
  libra_message(STATUS "Disabling ccache by request")
endif()

# ##############################################################################
# Profile-Guided Optimization (PGO)
# ##############################################################################
set(LIBRA_PGO_MODES NONE GEN USE)

if(NOT ${LIBRA_PGO} IN_LIST LIBRA_PGO_MODES)
  libra_message(FATAL_ERROR
                "Bad PGO specification '${LIBRA_PGO}'. Must be {NONE,GEN,USE}.")
endif()

# ##############################################################################
# Definitions
# ##############################################################################
if("${CMAKE_BUILD_TYPE}" STREQUAL "Release")
  set(LIBRA_COMMON_OPT_DEFS -DNDEBUG)
endif()

if("${LIBRA_FPC}" MATCHES "NONE")
  list(APPEND LIBRA_COMMON_DEV_DEFS -DLIBRA_FPC=LIBRA_FPC_NONE)
  list(APPEND LIBRA_COMMON_OPT_DEFS -DLIBRA_FPC=LIBRA_FPC_NONE)
elseif("${LIBRA_FPC}" MATCHES "RETURN")
  list(APPEND LIBRA_COMMON_DEV_DEFS -DLIBRA_FPC=LIBRA_FPC_RETURN)
  list(APPEND LIBRA_COMMON_OPT_DEFS -DLIBRA_FPC=LIBRA_FPC_RETURN)
elseif("${LIBRA_FPC}" MATCHES "ABORT")
  list(APPEND LIBRA_COMMON_DEV_DEFS -DLIBRA_FPC=LIBRA_FPC_ABORT)
  list(APPEND LIBRA_COMMON_OPT_DEFS -DLIBRA_FPC=LIBRA_FPC_ABORT)
elseif("${LIBRA_FPC}" MATCHES "INHERIT")
  libra_message(STATUS "Inherit LIBRA_FPC from parent project")
  list(APPEND LIBRA_COMMON_DEV_DEFS -DLIBRA_FPC_INHERIT)
  list(APPEND LIBRA_COMMON_OPT_DEFS -DLIBRA_FPC_INHERIT)
else()
  libra_message(
    FATAL_ERROR "Bad Function Precondition Checking (FPC) specification
    '${LIBRA_FPC}'. Must be {NONE,ABORT,RETURN,INHERIT}")
endif()

if("${LIBRA_ERL}" MATCHES "NONE")
  list(APPEND LIBRA_COMMON_DEV_DEFS -DLIBRA_ERL=LIBRA_ERL_NONE)
  list(APPEND LIBRA_COMMON_OPT_DEFS -DLIBRA_ERL=LIBRA_ERL_NONE)
elseif("${LIBRA_ERL}" MATCHES "FATAL")
  list(APPEND LIBRA_COMMON_DEV_DEFS -DLIBRA_ERL=LIBRA_ERL_FATAL)
  list(APPEND LIBRA_COMMON_OPT_DEFS -DLIBRA_ERL=LIBRA_ERL_FATAL)
elseif("${LIBRA_ERL}" MATCHES "ERROR")
  list(APPEND LIBRA_COMMON_DEV_DEFS -DLIBRA_ERL=LIBRA_ERL_ERROR)
  list(APPEND LIBRA_COMMON_OPT_DEFS -DLIBRA_ERL=LIBRA_ERL_ERROR)
elseif("${LIBRA_ERL}" MATCHES "WARN")
  list(APPEND LIBRA_COMMON_DEV_DEFS -DLIBRA_ERL=LIBRA_ERL_WARN)
  list(APPEND LIBRA_COMMON_OPT_DEFS -DLIBRA_ERL=LIBRA_ERL_WARN)
elseif("${LIBRA_ERL}" MATCHES "INFO")
  list(APPEND LIBRA_COMMON_DEV_DEFS -DLIBRA_ERL=LIBRA_ERL_INFO)
  list(APPEND LIBRA_COMMON_OPT_DEFS -DLIBRA_ERL=LIBRA_ERL_INFO)
elseif("${LIBRA_ERL}" MATCHES "DEBUG")
  list(APPEND LIBRA_COMMON_DEV_DEFS -DLIBRA_ERL=LIBRA_ERL_DEBUG)
  list(APPEND LIBRA_COMMON_OPT_DEFS -DLIBRA_ERL=LIBRA_ERL_DEBUG)
elseif("${LIBRA_ERL}" MATCHES "TRACE")
  list(APPEND LIBRA_COMMON_DEV_DEFS -DLIBRA_ERL=LIBRA_ERL_TRACE)
  list(APPEND LIBRA_COMMON_OPT_DEFS -DLIBRA_ERL=LIBRA_ERL_TRACE)
elseif("${LIBRA_ERL}" MATCHES "ALL")
  list(APPEND LIBRA_COMMON_DEV_DEFS -DLIBRA_ERL=LIBRA_ERL_ALL)
  list(APPEND LIBRA_COMMON_OPT_DEFS -DLIBRA_ERL=LIBRA_ERL_ALL)
elseif("${LIBRA_ERL}" MATCHES "INHERIT")
  libra_message(STATUS "Inherit LIBRA_ERL from parent project")
  list(APPEND LIBRA_COMMON_DEV_DEFS -DLIBRA_ERL=LIBRA_ERL_INHERIT)
  list(APPEND LIBRA_COMMON_OPT_DEFS -DLIBRA_ERL=LIBRA_ERL_INHERIT)
else()
  libra_message(
    FATAL_ERROR "Bad Event Reporting (ER) specification '${LIBRA_ERL}'.
    Must be {ALL,FATAL,ERROR,WARN,INFO,DEBUG,TRACE,NONE,INHERIT}")
endif()

if("${LIBRA_NOSTDLIB}" MATCHES "NONE")
  list(APPEND LIBRA_COMMON_DEV_DEFS -D__nostdlib__)
  list(APPEND LIBRA_COMMON_OPT_DEFS -D__nostdlib__)
endif()

libra_message(STATUS "Configuring compiler diagnostics")
set(CMAKE_REQUIRED_QUIET ON) # Don't emit diagnostics for EVERY flag tested...

if(NOT "${CMAKE_CXX_COMPILER_ID}" MATCHES "${CMAKE_C_COMPILER_ID}")
  libra_message(WARNING "C compiler family=${CMAKE_C_COMPILER_ID}, CXX compiler
  family=${CMAKE_CXX_COMPILER_ID}; are you sure you want to mix?")
endif()

# ##############################################################################
# GNU Compiler Options
# ##############################################################################
if("${CMAKE_C_COMPILER_ID}" MATCHES "GNU" OR "${CMAKE_CXX_COMPILER_ID}" MATCHES
                                             "GNU")
  include(libra/compile/gnu)
endif()

# ##############################################################################
# clang Compiler Options
# ##############################################################################
if("${CMAKE_C_COMPILER_ID}" MATCHES "Clang" OR "${CMAKE_CXX_COMPILER_ID}"
                                               MATCHES "Clang")
  include(libra/compile/clang)
endif()

# ##############################################################################
# Intel Compiler Options
# ##############################################################################
if("${CMAKE_C_COMPILER_ID}" MATCHES "Intel"
   OR "${CMAKE_CXX_COMPILER_ID}" MATCHES "Intel
    ")
  include(libra/compile/intel)
endif()

# Setup MPI
if(LIBRA_MP)
  find_package(MPI REQUIRED)
  include_directories(SYSTEM ${MPI_INCLUDE_PATH})
endif()
