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
set(_LIBRA_COMMON_COMPILE_OPTIONS
    ${LIBRA_OPT_LEVEL}
    ${_LIBRA_DEBUG_INFO_OPTIONS}
    ${_LIBRA_BUILD_PROF_OPTIONS}
    ${_LIBRA_FORTIFY_OPTIONS}
    ${_LIBRA_PGO_GEN_COMPILE_OPTIONS}
    ${_LIBRA_PGO_USE_COMPILE_OPTIONS}
    ${_LIBRA_VALGRIND_COMPAT_OPTIONS}
    ${_LIBRA_SAN_COMPILE_OPTIONS}
    ${_LIBRA_OPT_REPORT_COMPILE_OPTIONS}
    ${_LIBRA_CODE_COV_COMPILE_OPTIONS})
set(_LIBRA_C_COMPILE_OPTIONS
    ${_LIBRA_COMMON_COMPILE_OPTIONS} ${_LIBRA_C_DIAG_OPTIONS}
    ${_LIBRA_C_REPORT_OPTIONS} ${_LIBRA_C_STDLIB_COMPILE_OPTIONS})

set(_LIBRA_CXX_COMPILE_OPTIONS
    ${_LIBRA_COMMON_COMPILE_OPTIONS} ${_LIBRA_CXX_DIAG_OPTIONS}
    ${_LIBRA_CXX_REPORT_OPTIONS} ${_LIBRA_CXX_STDLIB_COMPILE_OPTIONS})

set(_LIBRA_COMMON_LINK_OPTIONS
    ${LIBRA_OPT_LEVEL}
    ${_LIBRA_PGO_GEN_LINK_OPTIONS}
    ${_LIBRA_PGO_USE_LINK_OPTIONS}
    ${_LIBRA_SAN_LINK_OPTIONS}
    ${_LIBRA_CODE_COV_LINK_OPTIONS}
    ${_LIBRA_OPT_REPORT_LINK_OPTIONS})

set(_LIBRA_C_LINK_OPTIONS ${_LIBRA_COMMON_LINK_OPTIONS}
                          ${_LIBRA_C_STDLIB_LINK_OPTIONS})
set(_LIBRA_CXX_LINK_OPTIONS ${_LIBRA_COMMON_LINK_OPTIONS}
                            ${_LIBRA_CXX_STDLIB_LINK_OPTIONS})

get_property(LANGUAGES_LIST GLOBAL PROPERTY ENABLED_LANGUAGES)

# We have to do this by target, because setting
# CMAKE_INTERPROCEDURAL_OPTIMIZATION in the per-compiler .cmake files only
# affects targets created AFTER that, and since that stuff is currently included
# AFTER project-local.cmake, it has no effect.
foreach(target ${_LIBRA_TARGETS})
  if(LIBRA_LTO)
    set_target_properties(${target} PROPERTIES INTERPROCEDURAL_OPTIMIZATION
                                               TRUE)
  endif()
  target_compile_options(
    ${target} PRIVATE $<$<COMPILE_LANGUAGE:C>:${_LIBRA_C_COMPILE_OPTIONS}>)
  target_compile_options(
    ${target} PRIVATE $<$<COMPILE_LANGUAGE:CXX>:${_LIBRA_CXX_COMPILE_OPTIONS}>)

  target_link_options(${target} PUBLIC
                      $<$<LINK_LANGUAGE:C>:${_LIBRA_C_LINK_OPTIONS}>)
  target_link_options(${target} PUBLIC
                      $<$<LINK_LANGUAGE:CXX>:${_LIBRA_CXX_LINK_OPTIONS}>)

endforeach()

# ##############################################################################
# Application To Specific Targets
# ##############################################################################
if("${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
  foreach(target ${_LIBRA_TARGETS})
    target_compile_definitions(${target} PRIVATE ${_LIBRA_PRIVATE_DEV_DEFS})
    target_compile_definitions(${target} PUBLIC ${_LIBRA_PUBLIC_DEV_DEFS})
  endforeach()
endif()

if("${CMAKE_BUILD_TYPE}" STREQUAL "Release")
  foreach(target ${_LIBRA_TARGETS})
    target_compile_definitions(${target} PRIVATE ${_LIBRA_PRIVATE_OPT_DEFS})
    target_compile_definitions(${target} PUBLIC ${_LIBRA_PUBLIC_OPT_DEFS})
    target_compile_options(${target} PRIVATE ${_LIBRA_OPT_OPTIONS})
  endforeach()
endif()

# ##############################################################################
# Global Application
# ##############################################################################
if(LIBRA_GLOBAL_C_FLAGS AND "C" IN_LIST LANGUAGES_LIST)
  add_compile_options(
    "$<$<CONFIG:Release>:${_LIBRA_C_COMPILE_OPTIONS} ${_LIBRA_OPT_OPTIONS} ${_LIBRA_PUBLIC_OPT_DEFS} ${_LIBRA_PRIVATE_OPT_DEFS}>"
  )
  add_compile_options(
    "$<$<CONFIG:Debug>:${_LIBRA_C_COMPILE_OPTIONS} ${_LIBRA_PUBLIC_DEV_DEFS} ${_LIBRA_PRIVATE_DEV_DEFS}>"
  )
  add_link_options(${_LIBRA_C_LINK_OPTIONS})
endif()

if(_LIBRA_GLOBAL_CXX_FLAGS)
  add_compile_options(
    "$<$<CONFIG:Release>:${_LIBRA_CXX_COMPILE_OPTIONS} ${_LIBRA_OPT_OPTIONS} ${_LIBRA_PUBLIC_OPT_DEFS} ${_LIBRA_PRIVATE_OPT_DEFS}>"
  )
  add_compile_options(
    "$<$<CONFIG:Debug>:${_LIBRA_CXX_COMPILE_OPTIONS} ${_LIBRA_PUBLIC_DEV_DEFS} ${_LIBRA_PRIVATE_DEV_DEFS}>"
  )
  add_link_options(${_LIBRA_CXX_LINK_OPTIONS})
endif()
