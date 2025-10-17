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
target_compile_options(
  ${PROJECT_NAME}
  PRIVATE ${LIBRA_OPT_LEVEL}
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
          ${LIBRA_C_CODE_COV_OPTIONS})
target_compile_definitions(${PROJECT_NAME} PUBLIC ${LIBRA_COMMON_DEBUG_DEFS})

if(LIBRA_GLOBAL_C_FLAGS)
  set(CMAKE_C_FLAGS_DEBUG
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
      ${LIBRA_COMMON_OPT_DEFS}
      CACHE STRING "Flags used by the C compiler during debug builds." FORCE)

endif()
target_compile_options(
  ${PROJECT_NAME}
  PRIVATE ${LIBRA_OPT_LEVEL}
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
          ${LIBRA_CXX_CODE_COV_OPTIONS})
target_compile_definitions(${PROJECT_NAME} PUBLIC ${LIBRA_COMMON_DEBUG_DEFS})

if(LIBRA_GLOBAL_CXX_FLAGS)
  set(CMAKE_CXX_FLAGS_DEBUG
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
      ${LIBRA_COMMON_OPT_DEFS}
      CACHE STRING "Flags used by the C++ compiler during debug builds." FORCE)

endif()

# ##############################################################################
# Optimized/Release Mode
# ##############################################################################
target_compile_options(
  ${PROJECT_NAME}
  PRIVATE ${LIBRA_OPT_LEVEL}
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
          ${LIBRA_C_CODE_COV_OPTIONS})
target_compile_definitions(${PROJECT_NAME} PUBLIC ${LIBRA_COMMON_OPT_DEFS})

if(LIBRA_GLOBAL_C_FLAGS)
  set(CMAKE_C_FLAGS_RELEASE
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
      ${LIBRA_COMMON_OPT_DEFS}
      CACHE STRING "Flags used by the C compiler during optimized builds."
            FORCE)

endif()
target_compile_options(
  ${PROJECT_NAME}
  PRIVATE ${LIBRA_OPT_LEVEL}
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
          ${LIBRA_CXX_CODE_COV_OPTIONS})
target_compile_definitions(${PROJECT_NAME} PUBLIC ${LIBRA_COMMON_OPT_DEFS})

if(LIBRA_GLOBAL_CXX_FLAGS)
  set(CMAKE_CXX_FLAGS_RELEASE
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
      ${LIBRA_COMMON_OPT_DEFS}
      CACHE STRING "Flags used by the C++ compiler during optimized builds."
            FORCE)

endif()
