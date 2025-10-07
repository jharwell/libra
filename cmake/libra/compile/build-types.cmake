#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#
# This file maps all of the nice features LIBRA provides which map to compiler
# flags into the flag sets for the build types cmake provides. Currently only
# maps for the {Debug, Release} build types,as those are the most common.

# ##############################################################################
# Development/Debug Mode
# ##############################################################################
set(LIBRA_C_FLAGS_DEBUG "")

foreach(
  arg
  ${LIBRA_OPT_LEVEL}
  ${LIBRA_DEBUG_OPTIONS}
  ${LIBRA_BUILD_PROF_OPTIONS}
  ${LIBRA_STDLIB_OPTIONS}
  ${LIBRA_FORTIFY_OPTIONS}
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
  set(LIBRA_C_FLAGS_DEBUG "${LIBRA_C_FLAGS_DEBUG} ${arg}")
endforeach(arg)

set(CMAKE_C_FLAGS_DEBUG
    ${LIBRA_C_FLAGS_DEBUG}
    CACHE STRING
          "Flags used by the C compiler during development/debug builds." FORCE)

set(LIBRA_CXX_FLAGS_DEBUG "")
foreach(
  arg
  ${LIBRA_OPT_LEVEL}
  ${LIBRA_DEBUG_OPTIONS}
  ${LIBRA_BUILD_PROF_OPTIONS}
  ${LIBRA_STDLIB_OPTIONS}
  ${LIBRA_FORTIFY_OPTIONS}
  ${LIBRA_VALGRIND_COMPAT_OPTIONS}
  ${LIBRA_CXX_DIAG_OPTIONS}
  ${LIBRA_CXX_PARALLEL_OPTIONS}
  ${LIBRA_CXX_SAN_OPTIONS}
  ${LIBRA_CXX_REPORT_OPTIONS}
  ${LIBRA_CXX_SAN_OPTIONS}
  ${LIBRA_CXX_PGO_GEN_OPTIONS}
  ${LIBRA_CXX_PGO_USE_OPTIONS}
  ${LIBRA_CXX_CODE_COV_OPTIONS}
  ${LIBRA_COMMON_DEBUG_DEFS})
  set(LIBRA_CXX_FLAGS_DEBUG "${LIBRA_CXX_FLAGS_DEBUG} ${arg}")
endforeach(arg)

set(CMAKE_CXX_FLAGS_DEBUG
    ${LIBRA_CXX_FLAGS_DEBUG}
    CACHE STRING "Flags used by the CXX compiler during development builds."
          FORCE)

# ##############################################################################
# Optimized/Release Mode
# ##############################################################################
set(LIBRA_C_FLAGS_RELEASE "")
foreach(
  arg
  ${LIBRA_OPT_LEVEL}
  ${LIBRA_DEBUG_OPTIONS}
  ${LIBRA_BUILD_PROF_OPTIONS}
  ${LIBRA_STDLIB_OPTIONS}
  ${LIBRA_FORTIFY_OPTIONS}
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
  set(LIBRA_C_FLAGS_RELEASE "${LIBRA_C_FLAGS_RELEASE} ${arg}")
endforeach(arg)

set(CMAKE_C_FLAGS_RELEASE
    ${LIBRA_C_FLAGS_RELEASE}
    CACHE STRING "Flags used by the C compiler during optimized builds." FORCE)

set(LIBRA_CXX_FLAGS_RELEASE "")
foreach(
  arg
  ${LIBRA_OPT_LEVEL}
  ${LIBRA_DEBUG_OPTIONS}
  ${LIBRA_BUILD_PROF_OPTIONS}
  ${LIBRA_STDLIB_OPTIONS}
  ${LIBRA_FORTIFY_OPTIONS}
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
  set(LIBRA_CXX_FLAGS_RELEASE "${LIBRA_CXX_FLAGS_RELEASE} ${arg}")
endforeach(arg)
set(CMAKE_CXX_FLAGS_RELEASE
    ${LIBRA_CXX_FLAGS_RELEASE}
    CACHE STRING "Flags used by the C++ compiler during optimized builds."
          FORCE)
