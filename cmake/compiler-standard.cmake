#
# Copyright 2023 John Harwell, All rights reserved.
#
# SPDX-License Identifier: MIT
#
################################################################################
# Standard Options
#
# Automatically pick the most recent standard supported, unless
# overriden on cmdline.
################################################################################
include(CheckCCompilerFlag)
include(CheckCXXCompilerFlag)

set(LIBRA_C_STD_CANDIDATES
  11
  99
)

set(LIBRA_CXX_STD_CANDIDATES
  20
  17
  14
  11
)

if(NOT CMAKE_C_STANDARD)
  foreach(std ${LIBRA_C_STD_CANDIDATES})
    check_c_compiler_flag(-std=c${std} LIBRA_C_COMPILER_SUPPORTS_c${std})
    if(LIBRA_C_COMPILER_SUPPORTS_c${std})
      set(CMAKE_C_STANDARD ${std})
      set(LIBRA_C_STANDARD c${std})
      break()
    endif()
  endforeach()
  if(NOT CMAKE_C_STANDARD)
    message(FATAL_ERROR "Could not find supported C std: tried ${LIBRA_C_STD_CANDIDATES}")
  endif()
else()
  set(LIBRA_C_STANDARD c${CMAKE_C_STANDARD})
endif()

if(NOT CMAKE_CXX_STANDARD)
  foreach(std ${LIBRA_CXX_STD_CANDIDATES})
    check_cxx_compiler_flag(-std=c++${std} LIBRA_CXX_COMPILER_SUPPORTS_cxx${std})
    if(LIBRA_CXX_COMPILER_SUPPORTS_cxx${std})
      set(CMAKE_CXX_STANDARD ${std})
      set(LIBRA_CXX_STANDARD c++${std})
      break()
    endif()
  endforeach()
  if(NOT CMAKE_CXX_STANDARD)
    message(FATAL_ERROR "Could not find supported C++ std: tried ${LIBRA_CXX_STD_CANDIDATES}")
  endif()
else()
  set(LIBRA_CXX_STANDARD c++${CMAKE_CXX_STANDARD})
endif()
