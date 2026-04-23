#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#
include(libra/messaging)
include(libra/defaults)

set(CMAKE_REQUIRED_QUIET ON) # Don't emit diagnostics for EVERY flag tested...

# ##############################################################################
# ccache
# ##############################################################################
if(NOT LIBRA_NO_CCACHE)
  # Configure CCache if available
  find_program(CCACHE_EXECUTABLE ccache)

  if(CCACHE_EXECUTABLE)
    # 2026-02-20 [JRH]: You can't set CMAKE_{C,CXX}_COMPILER_LAUNCHER set,
    # because for those to work they have to be set BEFORE project(), and this
    # file is included after that. Also, using those launcher variables can
    # result in the LINKER_LANGUAGE not being correctly detected in some cases,
    # so this is a much better way of doing it.
    set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE ${CCACHE_EXECUTABLE})
    set_property(GLOBAL PROPERTY RULE_LAUNCH_LINK ${CCACHE_EXECUTABLE})

    libra_message(STATUS "Using ccache=${CCACHE_EXECUTABLE}")
  else()
    libra_message(STATUS "Not using ccache [disabled=notfound]")
  endif()
else()
  libra_message(STATUS "Disabling ccache by request")
endif()

# Remove default optimization flags for release
set(CMAKE_CXX_FLAGS_RELEASE
    ""
    CACHE STRING "Flags used by the C++ compiler for release builds." FORCE)
set(CMAKE_C_FLAGS_RELEASE
    ""
    CACHE STRING "Flags used by the C compiler for release builds." FORCE)
#
# ##############################################################################
# Profile-Guided Optimization (PGO)
# ##############################################################################
set(_LIBRA_PGO_MODES NONE GEN USE)

if(NOT ${LIBRA_PGO} IN_LIST _LIBRA_PGO_MODES)
  libra_error("Bad PGO specification '${LIBRA_PGO}'. Must be {NONE,GEN,USE}.")
endif()

# ##############################################################################
# GNU Compiler Options
# ##############################################################################
if("${CMAKE_C_COMPILER_ID}" MATCHES "GNU" OR "${CMAKE_CXX_COMPILER_ID}" MATCHES
                                             "GNU")
  include(libra/compile/gnu)
  set(_SUPPORTED_COMPILER YES)
endif()

# ##############################################################################
# clang Compiler Options
# ##############################################################################
if("${CMAKE_C_COMPILER_ID}" MATCHES "Clang" OR "${CMAKE_CXX_COMPILER_ID}"
                                               MATCHES "Clang")
  include(libra/compile/clang)
  set(_SUPPORTED_COMPILER YES)
endif()

# ##############################################################################
# Intel Compiler Options
# ##############################################################################
if(("${CMAKE_C_COMPILER_ID}" MATCHES "Intel" OR "${CMAKE_CXX_COMPILER_ID}"
                                                MATCHES "Intel")
   AND NOT ("${CMAKE_C_COMPILER_ID}" MATCHES "IntelLLVM"
            OR "${CMAKE_CXX_COMPILER_ID}" MATCHES "IntelLLVM"))
  libra_message(
    WARNING
    "Support for the classic Intel compilers icc/icpc is deprecated and may break without warning"
  )
endif()

if("${CMAKE_C_COMPILER_ID}" MATCHES "Intel"
   OR "${CMAKE_CXX_COMPILER_ID}" MATCHES "Intel"
   OR "${CMAKE_C_COMPILER_ID}" MATCHES "IntelLLVM"
   OR "${CMAKE_CXX_COMPILER_ID}" MATCHES "IntelLLVM")
  set(_SUPPORTED_COMPILER YES)

  include(libra/compile/intel)
endif()

if(NOT _SUPPORTED_COMPILER)
  libra_error(
    "C/C++ compiler ${CMAKE_C_COMPILER_ID}/${CMAKE_CXX_COMPILER_ID} not supported"
  )
endif()

# ##############################################################################
# Definitions
#
# Needs to be after including compilers, in case some of the defs depending on
# LIBRA_ variables being set.
# ##############################################################################
macro(_gen_fpc_defs DEFS)
  if("${LIBRA_FPC}" MATCHES "NONE")
    list(APPEND ${DEFS} -DLIBRA_FPC=LIBRA_FPC_NONE)
  elseif("${LIBRA_FPC}" MATCHES "RETURN")
    list(APPEND ${DEFS} -DLIBRA_FPC=LIBRA_FPC_RETURN)
  elseif("${LIBRA_FPC}" MATCHES "ABORT")
    list(APPEND ${DEFS} -DLIBRA_FPC=LIBRA_FPC_ABORT)
  elseif("${LIBRA_FPC}" MATCHES "INHERIT")

  else()
    libra_error("Bad Function Precondition Checking (FPC) specification
    '${LIBRA_FPC}'. Must be {NONE,ABORT,RETURN,INHERIT}")
  endif()
endmacro()

macro(_gen_erl_defs DEFS)
  if("${LIBRA_ERL}" MATCHES "NONE")
    list(APPEND ${DEFS} -DLIBRA_ERL=LIBRA_ERL_NONE)
  elseif("${LIBRA_ERL}" MATCHES "FATAL")
    list(APPEND ${DEFS} -DLIBRA_ERL=LIBRA_ERL_FATAL)
  elseif("${LIBRA_ERL}" MATCHES "ERROR")
    list(APPEND ${DEFS} -DLIBRA_ERL=LIBRA_ERL_ERROR)
  elseif("${LIBRA_ERL}" MATCHES "WARN")
    list(APPEND ${DEFS} -DLIBRA_ERL=LIBRA_ERL_WARN)
  elseif("${LIBRA_ERL}" MATCHES "INFO")
    list(APPEND ${DEFS} -DLIBRA_ERL=LIBRA_ERL_INFO)
  elseif("${LIBRA_ERL}" MATCHES "DEBUG")
    list(APPEND ${DEFS} -DLIBRA_ERL=LIBRA_ERL_DEBUG)
  elseif("${LIBRA_ERL}" MATCHES "TRACE")
    list(APPEND ${DEFS} -DLIBRA_ERL=LIBRA_ERL_TRACE)
  elseif("${LIBRA_ERL}" MATCHES "ALL")
    list(APPEND ${DEFS} -DLIBRA_ERL=LIBRA_ERL_ALL)
  elseif("${LIBRA_ERL}" MATCHES "INHERIT")

  else()
    libra_error("Bad Event Reporting (ER) specification '${LIBRA_ERL}'.
    Must be {ALL,FATAL,ERROR,WARN,INFO,DEBUG,TRACE,NONE,INHERIT}")
  endif()

endmacro()

set(_LIBRA_PUBLIC_DEFS)
set(_LIBRA_PRIVATE_DEFS)

if(LIBRA_FPC_EXPORT)
  _gen_fpc_defs(_LIBRA_PUBLIC_DEFS)
else()
  _gen_fpc_defs(_LIBRA_PRIVATE_DEFS)
endif()

if(LIBRA_ERL_EXPORT)
  _gen_erl_defs(_LIBRA_PUBLIC_DEFS)
else()
  _gen_erl_defs(_LIBRA_PRIVATE_DEFS)
endif()

if("${LIBRA_STDLIB}" MATCHES "NONE")
  list(APPEND _LIBRA_PUBLIC_DEFS -D__nostdlib__)
endif()
