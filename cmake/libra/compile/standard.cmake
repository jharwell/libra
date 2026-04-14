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
    set(CMAKE_C_STANDARD_REQUIRED ON)
    if(CMAKE_C_STANDARD)
      set(LIBRA_C_STANDARD
          ${CMAKE_C_STANDARD}
          CACHE STRING "" FORCE)
    else()
      if(NOT LIBRA_C_STANDARD)
        foreach(std ${_LIBRA_C_STD_CANDIDATES})
          check_c_compiler_flag(-std=c${std} _LIBRA_C_COMPILER_SUPPORTS_c${std})
          if(_LIBRA_C_COMPILER_SUPPORTS_c${std})
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

    # Always apply the standard to the target
    if(TARGET ${TARGET})
      # 2026-02-17 [JRH]: We allow GNU extensions for C, because that's very
      # common on linux. Sort of gross, but seems less gross than requiring
      # e.g., -D_POSIX_C_SOURCE=200112L to get them. This may be revisited in
      # the future.
      set_target_properties(
        ${TARGET}
        PROPERTIES C_STANDARD ${LIBRA_C_STANDARD}
                   C_STANDARD_REQUIRED ON
                   C_EXTENSIONS ON)
      libra_message(DEBUG "Configured ${TARGET} to C${LIBRA_C_STANDARD}")
    endif()
  else()
    set(LIBRA_C_STANDARD
        "N/A"
        CACHE STRING "" FORCE)
  endif()

  if(CMAKE_CXX_COMPILER_LOADED)
    set(CMAKE_CXX_STANDARD_REQUIRED ON)
    if(CMAKE_CXX_STANDARD)
      set(LIBRA_CXX_STANDARD
          ${CMAKE_CXX_STANDARD}
          CACHE STRING "" FORCE)
    else()
      if(NOT LIBRA_CXX_STANDARD)
        foreach(std ${_LIBRA_CXX_STD_CANDIDATES})
          check_cxx_compiler_flag(-std=c++${std}
                                  _LIBRA_CXX_COMPILER_SUPPORTS_cxx${std})
          if(_LIBRA_CXX_COMPILER_SUPPORTS_cxx${std})
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
    # Always apply the standard to the target
    if(TARGET ${TARGET})
      # 2026-02-17 [JRH]: We allow GNU extensions for C++, because that's very
      # common on linux. Sort of gross, but seems less gross than requiring
      # e.g., -D_POSIX_C_SOURCE=200112L to get them. This may be revisited in
      # the future.
      set_target_properties(
        ${TARGET}
        PROPERTIES CXX_STANDARD ${LIBRA_CXX_STANDARD}
                   CXX_STANDARD_REQUIRED ON
                   CXX_EXTENSIONS ON)
      libra_message(DEBUG "Configured ${TARGET} to C++${LIBRA_CXX_STANDARD}")

    else()
      libra_error("${TARGET} is not a target?")
    endif()
  else()
    set(LIBRA_CXX_STANDARD
        "N/A"
        CACHE STRING "" FORCE)
  endif()
endfunction()
