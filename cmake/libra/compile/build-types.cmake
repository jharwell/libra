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
    ${_LIBRA_OPT_OPTIONS}
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
  if(NOT TARGET ${target})
    continue()
  endif()
  get_target_property(_imported ${target} IMPORTED)
  get_target_property(_target_dir ${target} SOURCE_DIR)

  if(_imported OR NOT "${_LIBRA_TARGET_OWNER_${target}}" STREQUAL
                  "${PROJECT_NAME}")
    libra_message(
      STATUS
      "Skipping ${target} for build type configuration - not owned by ${PROJECT_NAME}"
    )
    continue()
  endif()

  if(LIBRA_LTO)
    set_target_properties(${target} PROPERTIES INTERPROCEDURAL_OPTIMIZATION
                                               TRUE)
  endif()
  foreach(_opt IN LISTS _LIBRA_C_COMPILE_OPTIONS)
    target_compile_options(${target} PRIVATE $<$<COMPILE_LANGUAGE:C>:${_opt}>)
  endforeach()
  foreach(_opt IN LISTS _LIBRA_CXX_COMPILE_OPTIONS)
    target_compile_options(${target} PRIVATE $<$<COMPILE_LANGUAGE:CXX>:${_opt}>)
  endforeach()

  foreach(_opt IN LISTS _LIBRA_C_LINK_OPTIONS)
    target_link_options(${target} PRIVATE $<$<LINK_LANGUAGE:C>:${_opt}>)
  endforeach()
  foreach(_opt IN LISTS _LIBRA_CXX_LINK_OPTIONS)
    target_link_options(${target} PRIVATE $<$<LINK_LANGUAGE:CXX>:${_opt}>)
  endforeach()

  target_compile_definitions(${target} PRIVATE ${_LIBRA_PRIVATE_DEFS})
  target_compile_definitions(${target} PUBLIC ${_LIBRA_PUBLIC_DEFS})

  # 2026-02-18 [JRH]: CMake doesn't set the link-time optimization level by
  # build type the same way it does for compile-time optimization level. This
  # only matters for IPO, and we want to maximize effectiveness. We do this in
  # general for consistency.
  #
  # We don't modify the CMAKE_C_FLAGS_XX or CMAKE_CXX_FLAGS_XX variables because
  # that's a global change, and changes the definition of those built-in build
  # types, which others may rely on.
  get_target_property(lang ${target} LINKER_LANGUAGE)

  set(opt_genex "")
  foreach(config DEBUG RELEASE RELWITHDEBINFO MINSIZEREL)
    string(REGEX MATCH "-O[0-9sgz]?" opt_flag
                 "${CMAKE_${lang}_FLAGS_${config}}")
    if(opt_flag)
      string(APPEND opt_genex "$<$<CONFIG:${config}>:${opt_flag}>")
    endif()
  endforeach()
  if(opt_genex)
    target_link_options(${target} PRIVATE ${opt_genex})
  endif()
endforeach()

# ##############################################################################
# Global Application
# ##############################################################################
if(LIBRA_GLOBAL_C_FLAGS AND "C" IN_LIST LANGUAGES_LIST)
  foreach(opt IN LISTS _LIBRA_C_COMPILE_OPTIONS)
    add_compile_options($<$<CONFIG:Release>:${opt}> $<$<CONFIG:Debug>:${opt}>)
  endforeach()

  foreach(def IN LISTS _LIBRA_PUBLIC_DEFS _LIBRA_PRIVATE_DEFS)
    add_compile_options($<$<CONFIG:Release>:${def}> $<$<CONFIG:Debug>:${def}>)
  endforeach()

  set(opt_genex "")
  foreach(config DEBUG RELEASE RELWITHDEBINFO MINSIZEREL)
    string(REGEX MATCH "-O[0-9sgz]?" opt_flag "${CMAKE_C_FLAGS_${config}}")
    if(opt_flag)
      string(APPEND opt_genex "$<$<CONFIG:${config}>:${opt_flag}>")
    endif()
  endforeach()
  if(opt_genex)
    add_link_options(${opt_genex})
  endif()
endif()

if(LIBRA_GLOBAL_CXX_FLAGS AND "CXX" IN_LIST LANGUAGES_LIST)
  foreach(opt IN LISTS _LIBRA_CXX_COMPILE_OPTIONS)
    add_compile_options($<$<CONFIG:Release>:${opt}> $<$<CONFIG:Debug>:${opt}>)
  endforeach()

  foreach(def IN LISTS _LIBRA_PUBLIC_DEFS _LIBRA_PRIVATE_DEFS)
    add_compile_options($<$<CONFIG:Release>:${def}> $<$<CONFIG:Debug>:${def}>)
  endforeach()

  foreach(_opt IN LISTS _LIBRA_CXX_LINK_OPTIONS)
    add_link_options(${_opt})
  endforeach()
  foreach(config DEBUG RELEASE RELWITHDEBINFO MINSIZEREL)
    string(REGEX MATCH "-O[0-9sgz]?" opt_flag "${CMAKE_CXX_FLAGS_${config}}")
    if(opt_flag)
      string(APPEND opt_genex "$<$<CONFIG:${config}>:${opt_flag}>")
    endif()
  endforeach()
  if(opt_genex)
    add_link_options(${opt_genex})
  endif()
endif()
