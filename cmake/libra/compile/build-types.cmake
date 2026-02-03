#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#
# This file maps all of the nice features LIBRA provides which map to compiler
# flags into the flag sets for the build types cmake provides. Currently only
# maps for the {Debug, Release} build types, as those are the most common.
#
# Further, we switch on the enabled languages to avoid setting e.g. C flags for
# a C++ only project.
# ##############################################################################
# Common Bits
# ##############################################################################
set(LIBRA_COMMON_COMPILE_OPTIONS
    ${LIBRA_OPT_LEVEL}
    ${LIBRA_DEBUG_INFO_OPTIONS}
    ${LIBRA_BUILD_PROF_OPTIONS}
    ${LIBRA_FORTIFY_OPTIONS}
    ${LIBRA_PGO_GEN_COMPILE_OPTIONS}
    ${LIBRA_PGO_USE_COMPILE_OPTIONS}
    ${LIBRA_VALGRIND_COMPAT_OPTIONS}
    ${LIBRA_SAN_COMPILE_OPTIONS}
    ${LIBRA_OPT_REPORT_COMPILE_OPTIONS}
    ${LIBRA_CODE_COV_COMPILE_OPTIONS})
set(LIBRA_C_COMPILE_OPTIONS
    ${LIBRA_COMMON_COMPILE_OPTIONS} ${LIBRA_C_DIAG_OPTIONS}
    ${LIBRA_C_REPORT_OPTIONS} ${LIBRA_C_STDLIB_COMPILE_OPTIONS})

set(LIBRA_CXX_COMPILE_OPTIONS
    ${LIBRA_COMMON_COMPILE_OPTIONS} ${LIBRA_CXX_DIAG_OPTIONS}
    ${LIBRA_CXX_REPORT_OPTIONS} ${LIBRA_CXX_STDLIB_COMPILE_OPTIONS})

set(LIBRA_COMMON_LINK_OPTIONS
    ${LIBRA_OPT_LEVEL}
    ${LIBRA_PGO_GEN_LINK_OPTIONS}
    ${LIBRA_PGO_USE_LINK_OPTIONS}
    ${LIBRA_SAN_LINK_OPTIONS}
    ${LIBRA_CODE_COV_LINK_OPTIONS}
    ${LIBRA_OPT_REPORT_LINK_OPTIONS})

set(LIBRA_C_LINK_OPTIONS ${LIBRA_COMMON_LINK_OPTIONS}
                         ${LIBRA_C_STDLIB_LINK_OPTIONS})
set(LIBRA_CXX_LINK_OPTIONS ${LIBRA_COMMON_LINK_OPTIONS}
                           ${LIBRA_CXX_STDLIB_LINK_OPTIONS})

get_property(LANGUAGES_LIST GLOBAL PROPERTY ENABLED_LANGUAGES)

# We have to do this by target, because setting
# CMAKE_INTERPROCEDURAL_OPTIMIZATION in the per-compiler .cmake files only
# affects targets created AFTER that, and since that stuff is currently included
# AFTER project-local.cmake, it has no effect.
foreach(target ${LIBRA_TARGETS})
  if(LIBRA_LTO)
    set_target_properties(${target} PROPERTIES INTERPROCEDURAL_OPTIMIZATION
                                               TRUE)
  endif()
  target_compile_options(
    ${target} PRIVATE $<$<COMPILE_LANGUAGE:C>:${LIBRA_C_COMPILE_OPTIONS}>)
  target_compile_options(
    ${target} PRIVATE $<$<COMPILE_LANGUAGE:CXX>:${LIBRA_CXX_COMPILE_OPTIONS}>)

  target_link_options(${target} PUBLIC
                      $<$<LINK_LANGUAGE:C>:${LIBRA_C_LINK_OPTIONS}>)
  target_link_options(${target} PUBLIC
                      $<$<LINK_LANGUAGE:CXX>:${LIBRA_CXX_LINK_OPTIONS}>)

endforeach()

# ##############################################################################
# Application To Specific Targets
# ##############################################################################
if("${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
  foreach(target ${LIBRA_TARGETS})
    target_compile_definitions(${target} PRIVATE ${LIBRA_PRIVATE_DEV_DEFS})
    target_compile_definitions(${target} PUBLIC ${LIBRA_PUBLIC_DEV_DEFS})
  endforeach()
endif()

if("${CMAKE_BUILD_TYPE}" STREQUAL "Release")
  foreach(target ${LIBRA_TARGETS})
    target_compile_definitions(${target} PRIVATE ${LIBRA_PRIVATE_OPT_DEFS})
    target_compile_definitions(${target} PUBLIC ${LIBRA_PUBLIC_OPT_DEFS})
    target_compile_options(${target} PRIVATE ${LIBRA_OPT_OPTIONS})
  endforeach()
endif()

# ##############################################################################
# Global Application
# ##############################################################################
if(LIBRA_GLOBAL_C_FLAGS AND "C" IN_LIST LANGUAGES_LIST)
  add_compile_options(
    "$<$<CONFIG:Release>:${LIBRA_C_COMPILE_OPTIONS} ${LIBRA_OPT_OPTIONS} ${LIBRA_PUBLIC_OPT_DEFS} ${LIBRA_PRIVATE_OPT_DEFS}>"
  )
  add_compile_options(
    "$<$<CONFIG:Debug>:${LIBRA_C_COMPILE_OPTIONS} ${LIBRA_PUBLIC_DEV_DEFS} ${LIBRA_PRIVATE_DEV_DEFS}>"
  )
  add_link_options(${LIBRA_C_LINK_OPTIONS})
endif()

if(LIBRA_GLOBAL_CXX_FLAGS)
  add_compile_options(
    "$<$<CONFIG:Release>:${LIBRA_CXX_COMPILE_OPTIONS} ${LIBRA_OPT_OPTIONS} ${LIBRA_PUBLIC_OPT_DEFS} ${LIBRA_PRIVATE_OPT_DEFS}>"
  )
  add_compile_options(
    "$<$<CONFIG:Debug>:${LIBRA_CXX_COMPILE_OPTIONS} ${LIBRA_PUBLIC_DEV_DEFS} ${LIBRA_PRIVATE_DEV_DEFS}>"
  )
  add_link_options(${LIBRA_CXX_LINK_OPTIONS})
endif()
