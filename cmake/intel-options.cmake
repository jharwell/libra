################################################################################
# Debugging Options                                                            #
################################################################################
set(LIBRA_DEBUG_OPTIONS "-g2")

################################################################################
# Optimization Options                                                         #
################################################################################
if ("${CMAKE_BUILD_TYPE}" STREQUAL "DEV")
  set(LIBRA_OPT_LEVEL -O0)
elseif ("${CMAKE_BUILD_TYPE}" STREQUAL "DEVOPT")
  set(LIBRA_OPT_LEVEL -Og)
elseif ("${CMAKE_BUILD_TYPE}" STREQUAL "OPT")
  set(LIBRA_OPT_LEVEL -O2)
endif()

set(BASE_OPT_OPTIONS
  -no-prec-div
  -xHost
  -fp-model fast=2
  -ipo
  )

if (LIBRA_OPENMP)
  set(BASE_OPT_OPTIONS ${BASE_OPT_OPTIONS}
    -qopenmp
    -parallel
    -parallel-source-info=2
    )
endif ()

if(GUIDED_OPT)
  set(BASE_OPT_OPTIONS ${BASE_OPT_OPTIONS}
    -guide
    -guide-par
    -guide-vec
    -guide-data-trans
    )
endif()

set(LIBRA_C_OPT_OPTIONS ${BASE_OPT_OPTIONS})
set(LIBRA_CXX_OPT_OPTIONS ${BASE_OPT_OPTIONS})

if ("${CMAKE_BUILD_TYPE}" STREQUAL "OPT")
  set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_EXE_SHARED_FLAGS} -ipo")
endif()

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
  )

# If I have a bad OpenMP pragma when OpenMP is enable, warn about it. Otherwise
# OpenMP is disabled and all OpenMP pragma warnings are spurious.
if(NOT LIBRA_OPENMP)
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
  # cmake 3.10 does not know how to set std=c++17 for icpc, so I have to do it
  # manually.
  -std=c++17
  )

################################################################################
# Checking Options                                                             #
################################################################################
set(BASE_CHECK_OPTIONS
  -fno-omit-frame-pointer
  )
set(MEM_CHECK_OPTIONS
  -check-pointers=rw
  -check-pointers-dangling=all
  -check-pointers-undimensioned
  )
set(STACK_CHECK_OPTIONS
  -check=conversions,stack,uninit
  -fstack-protector-all
  -fstack-protector-strong
  )
if ("${LIBRA_CHECKS}" MATCHES "MEM")
  set(LIBRA_C_CHECK_OPTIONS ${BASE_CHECK_OPTIONS} ${MEM_CHECK_OPTIONS})
  set(LIBRA_CXX_CHECK_OPTIONS ${BASE_CHECK_OPTIONS} ${MEM_CHECK_OPTIONS})
endif()
if ("${LIBRA_CHECKS}" MATCHES "STACK")
  set(LIBRA_C_CHECK_OPTIONS ${BASE_CHECK_OPTIONS} ${STACK_CHECK_OPTIONS})
  set(LIBRA_CXX_CHECK_OPTIONS ${BASE_CHECK_OPTIONS} ${STACK_CHECK_OPTIONS})
endif()

################################################################################
# Profiling Options                                                            #
################################################################################
set(BASE_PGO_GEN_OPTIONS
  -prof-gen=srcpos,globaldata,
  -prof-gen-sampling
  )
set(BASE_PGO_USE_OPTIONS
  -prof-use
  -prof-use-sampling
  )

if (LIBRA_OPENMP)
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

if (LIBRA_PGO_GEN)
  set(LIBRA_C_PGO_GEN_OPTIONS ${BASE_PGO_GEN_OPTIONS})
  set(LIBRA_CXX_PGO_GEN_OPTIONS ${BASE_PGO_GEN_OPTIONS})
endif()

if (LIBRA_PGO_USE)
  set(LIBRA_C_PGO_USE_OPTIONS ${BASE_PGO_USE_OPTIONS})
  set(LIBRA_CXX_PGO_USE_OPTIONS ${BASE_PGO_USE_OPTIONS})
endif()

################################################################################
# Reporting Options                                                            #
################################################################################
set(BASE_REPORT_OPTIONS
  -qopt-report-phase=all
  -qopt-report=4
  -qopt-report-file=${REPORT_DIR}/opt.rprt
  )

if (WITH_REPORTS)
  set(LIBRA_C_REPORT_OPTIONS ${BASE_REPORT_OPTIONS})
  set(LIBRA_CXX_REPORT_OPTIONS ${BASE_REPORT_OPTIONS})
endif()
