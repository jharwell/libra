#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#
# This file maps all of the nice features LIBRA provides which map to compiler
# flags into the flag sets for the build types cmake provides. Currently only
# maps for the {Debug, Release} build types,as those are the most common.
#
# Further, we switch on the enables languages to avoid setting e.g. C flags for
# a C++ only project.
# ##############################################################################
# Common Bits
# ##############################################################################
set(LIBRA_COMMON_C_FLAGS
    ${LIBRA_OPT_LEVEL}
    ${LIBRA_DEBUG_INFO_OPTIONS}
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
    ${LIBRA_C_CODE_COV_OPTIONS})

set(LIBRA_COMMON_CXX_FLAGS
    ${LIBRA_OPT_LEVEL}
    ${LIBRA_DEBUG_INFO_OPTIONS}
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
    ${LIBRA_CXX_CODE_COV_OPTIONS})

get_property(LANGUAGES_LIST GLOBAL PROPERTY ENABLED_LANGUAGES)
# ##############################################################################
# Development/Debug Mode
# ##############################################################################
if("${CMAKE_BUILD_TYPE}" STREQUAL "Debug")

  if("C" IN_LIST LANGUAGES_LIST)
    foreach(target ${LIBRA_TARGETS})
      target_compile_options(
        ${target} PRIVATE $<$<COMPILE_LANGUAGE:C>:${LIBRA_COMMON_C_FLAGS}>)
      target_compile_definitions(
        ${target} PRIVATE $<$<COMPILE_LANGUAGE:C>:${LIBRA_PRIVATE_DEV_DEFS}>)
      target_compile_definitions(
        ${target} PUBLIC $<$<COMPILE_LANGUAGE:C>:${LIBRA_PUBLIC_DEV_DEFS}>)
    endforeach()

    if(LIBRA_GLOBAL_C_FLAGS)
      add_compile_options(
        "$<$<AND:$<CONFIG:Debug>,$<COMPILE_LANGUAGE:C>>:${LIBRA_COMMON_C_FLAGS}>"
        "$<$<AND:$<CONFIG:Debug>,$<COMPILE_LANGUAGE:C>>:${LIBRA_C_OPT_OPTIONS}>"
        "$<$<AND:$<CONFIG:Debug>,$<COMPILE_LANGUAGE:C>>:${LIBRA_PUBLIC_OPT_DEFS}>"
        "$<$<AND:$<CONFIG:Debug>,$<COMPILE_LANGUAGE:C>>:${LIBRA_PRIVATE_OPT_DEFS}>"
      )
    endif()
  endif()

  if("CXX" IN_LIST LANGUAGES_LIST)
    foreach(target ${LIBRA_TARGETS})
      target_compile_options(
        ${target} PRIVATE $<$<COMPILE_LANGUAGE:CXX>:${LIBRA_COMMON_CXX_FLAGS}>)
      target_compile_definitions(
        ${target} PRIVATE $<$<COMPILE_LANGUAGE:CXX>:${LIBRA_PRIVATE_DEV_DEFS}>)
      target_compile_definitions(
        ${target} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:${LIBRA_PUBLIC_DEV_DEFS}>)

    endforeach()

    if(LIBRA_GLOBAL_CXX_FLAGS)
      add_compile_options(
        "$<$<AND:$<CONFIG:Debug>,$<COMPILE_LANGUAGE:CXX>>:${LIBRA_COMMON_CXX_FLAGS}>"
        "$<$<AND:$<CONFIG:Debug>,$<COMPILE_LANGUAGE:CXX>>:${LIBRA_CXX_OPT_OPTIONS}>"
        "$<$<AND:$<CONFIG:Debug>,$<COMPILE_LANGUAGE:CXX>>:${LIBRA_PUBLIC_OPT_DEFS}>"
        "$<$<AND:$<CONFIG:Debug>,$<COMPILE_LANGUAGE:CXX>>:${LIBRA_PRIVATE_OPT_DEFS}>"
      )
    endif()
  endif()
endif()

# ##############################################################################
# Optimized/Release Mode
# ##############################################################################
if("${CMAKE_BUILD_TYPE}" STREQUAL "Release")
  if("C" IN_LIST LANGUAGES_LIST)
    foreach(target ${LIBRA_TARGETS})
      target_compile_options(
        ${target} PRIVATE $<$<COMPILE_LANGUAGE:C>:${LIBRA_COMMON_C_FLAGS}>
                          $<$<COMPILE_LANGUAGE:C>:${LIBRA_C_OPT_OPTIONS}>)
      target_compile_definitions(
        ${target} PRIVATE $<$<COMPILE_LANGUAGE:C>:${LIBRA_PRIVATE_OPT_DEFS}>)
      target_compile_definitions(
        ${target} PUBLIC $<$<COMPILE_LANGUAGE:C>:${LIBRA_PUBLIC_OPT_DEFS}>)
    endforeach()
    if(LIBRA_GLOBAL_C_FLAGS)
      add_compile_options(
        "$<$<AND:$<CONFIG:Release>,$<COMPILE_LANGUAGE:C>>:${LIBRA_COMMON_C_FLAGS}>"
        "$<$<AND:$<CONFIG:Release>,$<COMPILE_LANGUAGE:C>>:${LIBRA_C_OPT_OPTIONS}>"
        "$<$<AND:$<CONFIG:Release>,$<COMPILE_LANGUAGE:C>>:${LIBRA_PUBLIC_OPT_DEFS}>"
        "$<$<AND:$<CONFIG:Release>,$<COMPILE_LANGUAGE:C>>:${LIBRA_PRIVATE_OPT_DEFS}>"
      )
    endif()
  endif()

  if("CXX" IN_LIST LANGUAGES_LIST)
    foreach(target ${LIBRA_TARGETS})
      target_compile_options(
        ${target} PRIVATE $<$<COMPILE_LANGUAGE:CXX>:${LIBRA_COMMON_CXX_FLAGS}>
                          $<$<COMPILE_LANGUAGE:CXX>:${LIBRA_CXX_OPT_OPTIONS}>)
      target_compile_definitions(
        ${target} PRIVATE $<$<COMPILE_LANGUAGE:CXX>:${LIBRA_PRIVATE_OPT_DEFS}>)
      target_compile_definitions(
        ${target} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:${LIBRA_PUBLIC_OPT_DEFS}>)
    endforeach()

    if(LIBRA_GLOBAL_CXX_FLAGS)
      add_compile_options(
        "$<$<AND:$<CONFIG:Release>,$<COMPILE_LANGUAGE:CXX>>:${LIBRA_COMMON_CXX_FLAGS}>"
        "$<$<AND:$<CONFIG:Release>,$<COMPILE_LANGUAGE:CXX>>:${LIBRA_CXX_OPT_OPTIONS}>"
        "$<$<AND:$<CONFIG:Release>,$<COMPILE_LANGUAGE:CXX>>:${LIBRA_PUBLIC_OPT_DEFS}>"
        "$<$<AND:$<CONFIG:Release>,$<COMPILE_LANGUAGE:CXX>>:${LIBRA_PRIVATE_OPT_DEFS}>"
      )
    endif()
  endif()
endif()
