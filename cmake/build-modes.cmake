#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#
################################################################################
# Development Mode                                                             #
################################################################################
set(LIBRA_C_FLAGS_DEV "")
foreach(arg
    ${LIBRA_OPT_LEVEL}
    ${LIBRA_DEBUG_OPTIONS}
    ${LIBRA_VALGRIND_COMPAT_OPTIONS}
    ${LIBRA_C_DIAG_OPTIONS}
    ${LIBRA_C_PARALLEL_OPTIONS}
    ${LIBRA_C_SAN_OPTIONS}
    ${LIBRA_C_REPORT_OPTIONS}
    ${LIBRA_C_SAN_OPTIONS}
    ${LIBRA_C_PGO_GEN_OPTIONS}
    ${LIBRA_C_PGO_USE_OPTIONS}
    ${LIBRA_C_CODE_COV_OPTIONS}
    ${LIBRA_COMMON_DEV_DEFS})
  set(LIBRA_C_FLAGS_DEV "${LIBRA_C_FLAGS_DEV} ${arg}")
endforeach(arg)

set(CMAKE_C_FLAGS_DEV ${LIBRA_C_FLAGS_DEV} CACHE STRING
  "Flags used by the C compiler during development builds."
  FORCE)

set(LIBRA_CXX_FLAGS_DEV "")
foreach(arg
    ${LIBRA_OPT_LEVEL}
    ${LIBRA_DEBUG_OPTIONS}
    ${LIBRA_VALGRIND_COMPAT_OPTIONS}
    ${LIBRA_CXX_DIAG_OPTIONS}
    ${LIBRA_CXX_PARALLEL_OPTIONS}
    ${LIBRA_CXX_SAN_OPTIONS}
    ${LIBRA_CXX_REPORT_OPTIONS}
    ${LIBRA_CXX_SAN_OPTIONS}
    ${LIBRA_CXX_PGO_GEN_OPTIONS}
    ${LIBRA_CXX_PGO_USE_OPTIONS}
    ${LIBRA_CXX_CODE_COV_OPTIONS}
    ${LIBRA_COMMON_DEV_DEFS})
  set(LIBRA_CXX_FLAGS_DEV "${LIBRA_CXX_FLAGS_DEV} ${arg}")
endforeach(arg)

set(CMAKE_CXX_FLAGS_DEV ${LIBRA_CXX_FLAGS_DEV} CACHE STRING
  "Flags used by the CXX compiler during development builds."
  FORCE)

################################################################################
# Development Optimized Mode                                                   #
################################################################################
set(LIBRA_C_FLAGS_DEVOPT "")
foreach(arg
    ${LIBRA_OPT_LEVEL}
    ${LIBRA_DEBUG_OPTIONS}
    ${LIBRA_VALGRIND_COMPAT_OPTIONS}
    ${LIBRA_C_DIAG_OPTIONS}
    ${LIBRA_C_PARALLEL_OPTIONS}
    ${LIBRA_C_SAN_OPTIONS}
    ${LIBRA_C_REPORT_OPTIONS}
    ${LIBRA_C_SAN_OPTIONS}
    ${LIBRA_C_PGO_GEN_OPTIONS}
    ${LIBRA_C_PGO_USE_OPTIONS}
    ${LIBRA_C_CODE_COV_OPTIONS}
    ${LIBRA_COMMON_DEVOPT_DEFS})
  set(LIBRA_C_FLAGS_DEVOPT "${LIBRA_C_FLAGS_DEVOPT} ${arg}")
endforeach(arg)

set(CMAKE_C_FLAGS_DEVOPT ${LIBRA_C_FLAGS_DEVOPT} CACHE STRING
  "Flags used by the C compiler during devopt builds."
  FORCE)

set(LIBRA_CXX_FLAGS_DEVOPT "")
foreach(arg
    ${LIBRA_OPT_LEVEL}
    ${LIBRA_DEBUG_OPTIONS}
    ${LIBRA_VALGRIND_COMPAT_OPTIONS}
    ${LIBRA_CXX_DIAG_OPTIONS}
    ${LIBRA_CXX_PARALLEL_OPTIONS}
    ${LIBRA_CXX_SAN_OPTIONS}
    ${LIBRA_CXX_REPORT_OPTIONS}
    ${LIBRA_CXX_SAN_OPTIONS}
    ${LIBRA_CXX_PGO_GEN_OPTIONS}
    ${LIBRA_CXX_PGO_USE_OPTIONS}
    ${LIBRA_CXX_CODE_COV_OPTIONS}
    ${LIBRA_COMMON_DEVOPT_DEFS})
  set(LIBRA_CXX_FLAGS_DEVOPT "${LIBRA_CXX_FLAGS_DEVOPT} ${arg}")
endforeach(arg)

set(CMAKE_CXX_FLAGS_DEVOPT ${LIBRA_CXX_FLAGS_DEVOPT} CACHE STRING
  "Flags used by the CXX compiler during devopt builds."
  FORCE)

################################################################################
# Optimized Mode                                                               #
################################################################################
set(LIBRA_C_FLAGS_OPT "")
foreach(arg
    ${LIBRA_OPT_LEVEL}
    ${LIBRA_DEBUG_OPTIONS}
    ${LIBRA_VALGRIND_COMPAT_OPTIONS}
    ${LIBRA_C_OPT_OPTIONS}
    ${LIBRA_C_DIAG_OPTIONS}
    ${LIBRA_C_PARALLEL_OPTIONS}
    ${LIBRA_C_SAN_OPTIONS}
    ${LIBRA_C_REPORT_OPTIONS}
    ${LIBRA_C_SAN_OPTIONS}
    ${LIBRA_C_PGO_GEN_OPTIONS}
    ${LIBRA_C_PGO_USE_OPTIONS}
    ${LIBRA_C_CODE_COV_OPTIONS}
    ${LIBRA_COMMON_OPT_DEFS})
  set(LIBRA_C_FLAGS_OPT "${LIBRA_C_FLAGS_OPT} ${arg}")
endforeach(arg)

set(CMAKE_C_FLAGS_OPT ${LIBRA_C_FLAGS_OPT} CACHE STRING
  "Flags used by the C compiler during optimized builds."
  FORCE)

set(LIBRA_CXX_FLAGS_OPT "")
foreach(arg
    ${LIBRA_OPT_LEVEL}
    ${LIBRA_DEBUG_OPTIONS}
    ${LIBRA_VALGRIND_COMPAT_OPTIONS}
    ${LIBRA_CXX_OPT_OPTIONS}
    ${LIBRA_CXX_DIAG_OPTIONS}
    ${LIBRA_CXX_PARALLEL_OPTIONS}
    ${LIBRA_CXX_SAN_OPTIONS}
    ${LIBRA_CXX_REPORT_OPTIONS}
    ${LIBRA_CXX_SAN_OPTIONS}
    ${LIBRA_CXX_PGO_GEN_OPTIONS}
    ${LIBRA_CXX_PGO_USE_OPTIONS}
    ${LIBRA_CXX_CODE_COV_OPTIONS}
    ${LIBRA_COMMON_OPT_DEFS})
  set(LIBRA_CXX_FLAGS_OPT "${LIBRA_CXX_FLAGS_OPT} ${arg}")
endforeach(arg)
set(CMAKE_CXX_FLAGS_OPT ${LIBRA_CXX_FLAGS_OPT} CACHE STRING
  "Flags used by the C++ compiler during optimized builds."
  FORCE)

# Update the documentation string of CMAKE_BUILD_TYPE for GUIs
set( CMAKE_BUILD_TYPE "${CMAKE_BUILD_TYPE}" CACHE STRING
  "Choose the type of build, options are: DEV DEVOPT OPT."
      FORCE )
