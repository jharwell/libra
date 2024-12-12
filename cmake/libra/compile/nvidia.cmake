#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#

# ##############################################################################
# Language Standard
# ##############################################################################
include(libra/compile/standard)

# ##############################################################################
# Debugging Options
# ##############################################################################
if(LIBRA_NO_DEBUG_INFO)
  set(LIBRA_DEBUG_OPTIONS "-g0")
else()
  set(LIBRA_DEBUG_OPTIONS "-g2")
endif()

# ##############################################################################
# Optimization Options
# ##############################################################################
if("${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
  set(LIBRA_OPT_LEVEL -O0)
elseif("${CMAKE_BUILD_TYPE}" STREQUAL "Relese")
  set(LIBRA_OPT_LEVEL -O2)
else()
  message(
    FATAL_ERROR
      "NVIDIA compiler plugin is only configured for {Debug, Release} builds")
endif()

set(BASE_OPT_OPTIONS)

if(LIBRA_LTO)
  set(BASE_OPT_OPTIONS ${BASE_OPT_OPTIONS} -flto)
  set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_SHARED_FLAGS} -flto=")
  set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_SHARED_FLAGS} -flto")
endif()

set(LIBRA_CUDA_OPT_OPTIONS ${BASE_OPT_OPTIONS})

# ##############################################################################
# Diagnostic Options
# ##############################################################################
set(BASE_DIAG_OPTIONS)

set(LIBRA_CUDA_DIAG_OPTIONS
    ${BASE_DIAG_OPTIONS} -fdiagnostics-show-template-tree -Wno-c++98-compat
    -Wno-c++98-compat-pedantic -Weffc++ -Wno-c99-extensions)

# ##############################################################################
# Checking Options
# ##############################################################################

# ##############################################################################
# Profiling Options
# ##############################################################################

# ##############################################################################
# Code Coverage Options
# ##############################################################################

# ##############################################################################
# Valgrind Compatibility Options
# ##############################################################################
