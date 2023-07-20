#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#

################################################################################
# Language Standard
################################################################################
include(compiler-standard)

################################################################################
# Debugging Options
################################################################################
set(LIBRA_DEBUG_OPTIONS "-g2")

###############################################################################
# Optimization Options                                                         #
################################################################################
if ("${CMAKE_BUILD_TYPE}" STREQUAL "DEV")
  set(LIBRA_OPT_LEVEL -O0)
elseif ("${CMAKE_BUILD_TYPE}" STREQUAL "DEVOPT")
  set(LIBRA_OPT_LEVEL -Og)
elseif ("${CMAKE_BUILD_TYPE}" STREQUAL "OPT")
  set(LIBRA_OPT_LEVEL -O2)
else()
  message(FATAL_ERROR "Bad build type: Must be [DEV, DEVOPT, OPT].")
endif()

set(BASE_OPT_OPTIONS
  -no-prec-div
  -xHost
  -fp-model fast=2
)

if (LIBRA_MT)
  set(BASE_OPT_OPTIONS ${BASE_OPT_OPTIONS}
    -qopenmp
    -parallel
    -parallel-source-info=2
  )
endif ()

if(LIBRA_LTO)
  set(BASE_OPT_OPTIONS ${BASE_OPT_OPTIONS} -ipo)
  if ("${CMAKE_BUILD_TYPE}" STREQUAL "OPT")
    set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_EXE_SHARED_FLAGS} -ipo")
  endif()

endif()

set(LIBRA_C_OPT_OPTIONS ${BASE_OPT_OPTIONS})
set(LIBRA_CXX_OPT_OPTIONS ${BASE_OPT_OPTIONS})


###############################################################################
# Diagnostic Options
#
# 2259 - warnings about converting uint16_t to uint8_t losing precision
# 10382 - Telling me what option xHost was setting
# 2015 - One of the effective C++ warnings for always using // for comments
# 2012 - Another effective C++ warnings for not using #defines
# 11071 - Warnings about inlines not being honored
# 1476 - Tail padding of a base class
# 1505 - Size of class affected by tail padding
# 383 - Value copied to temporary; reference to temporary used
# 411 - Class/struct defines no constructor to initialize member
# 3180 - Warnings about unknown OpenMP pragmas
# 177,869,593 - Unused variable/parameters
###############################################################################
set(BASE_DIAG_OPTIONS
  -w5
  -Wabi
  -Wcheck
  -Winline
  -Wshadow
  -Wremarks
  -Wcomment
  -wd10382
  -wd177
  -wd869
  -wd593
)

# If I have a bad OpenMP pragma when OpenMP is enabled, warn about it. Otherwise
# OpenMP is disabled and all OpenMP pragma warnings are spurious.
if(NOT LIBRA_MT)
  set(BASE_DIAG_OPTIONS "${BASE_DIAG_OPTIONS} -wd3180")
endif()

set(LIBRA_C_DIAG_OPTIONS
  ${BASE_DIAG_OPTIONS})

set(LIBRA_CXX_DIAG_OPTIONS ${BASE_DIAG_OPTIONS}
  -Weffc++
  -wd2015
  -wd2012
  -wd11071
  -wd1476
  -wd1505
  -wd383
  -wd411
)

set(CMAKE_C_LINK_EXECUTABLE "xild")
set(CMAKE_CXX_LINK_EXECUTABLE "xild")

################################################################################
# Checking Options
################################################################################
set(MSAN_OPTIONS
  -fno-omit-frame-pointer
  -check-pointers=rw
  -check-pointers-dangling=all
  -check-pointers-undimensioned
)
set(SSAN_OPTIONS
  -fno-omit-frame-pointer
  -check=stack
  -fstack-protector-all
  -fstack-protector-strong
)
set(UBSAN_OPTIONS
  -fno-omit-frame-pointer
  -check=conversions,uninit

)
set(LIBRA_SAN_DEFAULT "NONE")

if (NOT LIBRA_SAN)
  set(LIBRA_SAN ${LIBRA_SAN_DEFAULT})
endif()

# Only enable sanitizers by default for DEV builds and if they are not
# specified on the cmdline
if ("${CMAKE_BUILD_TYPE}" STREQUAL "DEV" AND (NOT DEFINED LIBRA_SAN))
  set(LIBRA_SAN ${LIBRA_SAN_DEV_DEFAULT})
elseif ("${CMAKE_BUILD_TYPE}" MATCHES "OPT" AND (NOT DEFINED LIBRA_SAN))
  set(LIBRA_SAN ${LIBRA_SAN_OPT_DEFAULT})
endif()

set(LIBRA_SAN_OPTIONS)
set(LIBRA_SAN_MATCH NO)

if ("${LIBRA_SAN}" MATCHES "MSAN")
  set(LIBRA_SAN_MATCH YES)
  set(LIBRA_SAN_OPTIONS "${LIBRA_SAN_OPTIONS} ${MSAN_OPTIONS}")
endif()

if ("${LIBRA_SAN}" MATCHES "ASAN")
  set(LIBRA_SAN_MATCH YES)
  set(LIBRA_SAN_OPTIONS "${LIBRA_SAN_OPTIONS} ${ASAN_OPTIONS}")
endif()

if ("${LIBRA_SAN}" MATCHES "SSAN")
  set(LIBRA_SAN_MATCH YES)
  set(LIBRA_SAN_OPTIONS "${LIBRA_SAN_OPTIONS} ${SSAN_OPTIONS}")
endif()

if ("${LIBRA_SAN}" MATCHES "UBSAN")
  set(LIBRA_SAN_MATCH YES)
  set(LIBRA_SAN_OPTIONS "${LIBRA_SAN_OPTIONS} ${UBSAN_OPTIONS}")
endif()

if ("${LIBRA_SAN}" MATCHES "TSAN")
  set(LIBRA_SAN_MATCH YES)
  set(LIBRA_SAN_OPTIONS "${LIBRA_SAN_OPTIONS} ${TSAN_OPTIONS}")
endif()

if(NOT ${LIBRA_SAN_MATCH} AND NOT "${LIBRA_SAN}" STREQUAL "NONE")
  message(WARNING "Bad LIBRA_SAN setting ${LIBRA_SAN}: Must be either
 one or more from {MSAN,ASAN,SSAN,UBSAN,TSAN} or set to NONE")
endif()

set(LIBRA_C_SAN_OPTIONS ${LIBRA_SAN_OPTIONS})
set(LIBRA_CXX_SAN_OPTIONS ${LIBRA_SAN_OPTIONS})

################################################################################
# Profiling Options
################################################################################
set(BASE_PGO_GEN_OPTIONS
  -prof-gen=srcpos,globaldata,
  -prof-gen-sampling
)
set(BASE_PGO_USE_OPTIONS
  -prof-use
  -prof-use-sampling
)

if (LIBRA_MT)
  set(BASE_PGO_GEN_OPTIONS
    "${BASE_PGO_GEN_OPTIONS}"
    -prof-gen=threadsafe)
else()
  set(BASE_PGO_GEN_OPTIONS
    "${BASE_PGO_GEN_OPTIONS}"
    -profile-functions
    -profile-loops=all
    -profile-loops-report=2)
endif()

if ("${LIBRA_PGO}" MATCHES "GEN")
  set(LIBRA_C_PGO_GEN_OPTIONS ${BASE_PGO_GEN_OPTIONS})
  set(LIBRA_CXX_PGO_GEN_OPTIONS ${BASE_PGO_GEN_OPTIONS})
endif()

if ("${LIBRA_PGO}" MATCHES "USE")
  set(LIBRA_C_PGO_USE_OPTIONS ${BASE_PGO_USE_OPTIONS})
  set(LIBRA_CXX_PGO_USE_OPTIONS ${BASE_PGO_USE_OPTIONS})
endif()

################################################################################
# Reporting Options
################################################################################
set(BASE_REPORT_OPTIONS
  -qopt-report-phase=all
  -qopt-report=4
  -qopt-report-file=${REPORT_DIR}/opt.rprt
)

if (LIBRA_OPT_REPORT)
  set(BASE_REPORT_OPTIONS ${BASE_REPORT_OPTIONS}
    -guide
    -guide-par
    -guide-vec
    -guide-data-trans
  )
  set(LIBRA_C_REPORT_OPTIONS ${BASE_REPORT_OPTIONS})
  set(LIBRA_CXX_REPORT_OPTIONS ${BASE_REPORT_OPTIONS})

endif()
