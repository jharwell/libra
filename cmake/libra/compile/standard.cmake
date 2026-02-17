#
# Copyright 2023 John Harwell, All rights reserved.
#
# SPDX-License Identifier: MIT
#
include(libra/messaging)
include(CheckCCompilerFlag)
include(CheckCXXCompilerFlag)

# ##############################################################################
# Standard Options
#
# Automatically pick the most recent standard supported, unless overriden on
# cmdline.
#
# 2025-10-17 [JRH]: These are ordered in from greatest to least precedence.
# ##############################################################################
set(_LIBRA_C_STD_CANDIDATES 23 17 11 99)
set(_LIBRA_CXX_STD_CANDIDATES
    23
    20
    17
    14
    11)

set(LIBRA_C_STANDARD
    ""
    CACHE
      STRING
      "Standard to apply to all LIBRA C-enabled targets (autodetected if empty)"
)
set(LIBRA_CXX_STANDARD
    ""
    CACHE STRING "Standard to apply to all LIBRA C++-enabled targets
    (autodetected if empty)")

function(_libra_configure_standard TARGET)
  if(CMAKE_C_COMPILER_LOADED)
    if(CMAKE_C_STANDARD)
      set(LIBRA_C_STANDARD
          ${CMAKE_C_STANDARD}
          CACHE STRING "" FORCE)

    else()
      if(NOT LIBRA_C_STANDARD)
        foreach(std ${_LIBRA_C_STD_CANDIDATES})
          # A project can be C/C++ only
          check_c_compiler_flag(-std=c${std} _LIBRA_C_COMPILER_SUPPORTS_c${std})

          if(_LIBRA_C_COMPILER_SUPPORTS_c${std})
            if(TARGET ${TARGET})
              set_target_properties(${TARGET} PROPERTIES C_STANDARD ${std})
            endif()
            set(LIBRA_C_STANDARD
                ${std}
                CACHE STRING "" FORCE)
            break()
          endif()
        endforeach()
        if(NOT LIBRA_C_STANDARD)
          libra_error(
            "Could not find supported C std: tried ${_LIBRA_C_STD_CANDIDATES}")
        endif()
      endif()
    endif()
  else()
    set(LIBRA_C_STANDARD
        "N/A"
        CACHE STRING "" FORCE)
  endif()

  if(CMAKE_CXX_COMPILER_LOADED)
    if(CMAKE_CXX_STANDARD)
      set(LIBRA_CXX_STANDARD
          ${CMAKE_CXX_STANDARD}
          CACHE STRING "" FORCE)
    else()
      if(NOT LIBRA_CXX_STANDARD)
        foreach(std ${_LIBRA_CXX_STD_CANDIDATES})
          # A project can be C/C++ only
          check_cxx_compiler_flag(-std=c++${std}
                                  _LIBRA_CXX_COMPILER_SUPPORTS_cxx${std})

          if(_LIBRA_CXX_COMPILER_SUPPORTS_cxx${std})
            if(TARGET ${TARGET})
              set_target_properties(${TARGET} PROPERTIES CXX_STANDARD ${std})
            endif()
            set(LIBRA_CXX_STANDARD
                ${std}
                CACHE STRING "" FORCE)
            break()
          endif()
        endforeach()
        if(NOT LIBRA_CXX_STANDARD)
          libra_error(
            "Could not find supported C++ std: tried ${_LIBRA_CXX_STD_CANDIDATES}"
          )
        endif()
      endif()
    endif()
  else()
    set(LIBRA_CXX_STANDARD
        "N/A"
        CACHE STRING "" FORCE)
  endif()
endfunction()
