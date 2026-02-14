#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#

# ##############################################################################
# Modules
# ##############################################################################
include(libra/compile/standard)
include(libra/defaults)

# ##############################################################################
# Debugging Options
# ##############################################################################
#[[.rst:
.. cmake:variable:: LIBRA_DEBUG_INFO_INTEL

  If enabled: ``-g2``. If disabled: ``-g0``.
]]
if(LIBRA_DEBUG_INFO)
  set(_LIBRA_DEBUG_INFO_OPTIONS "-g2")
else()
  set(_LIBRA_DEBUG_INFO_OPTIONS "-g0")
endif()

# cmake-format: off
# ##############################################################################
# Diagnostic Options
#
# 2259 - warnings about converting uint16_t to uint8_t losing precision
# 10382 - Telling me what option xHost was setting
# 2015 - One of the effective C++ warnings for always using // for comments
# 2012 - Another effective C++ warnings for not using #defines
# 11071 - Warnings about inlines not being honored
# 1476- Tail padding of a base class
# 1505 - Size of class affected by tail padding
# 383 - Value copied to temporary; reference to temporary used
# 411 - Class/struct defines no constructor to initialize member
# 3180 - Warnings about unknown OpenMP pragmas
# 177,869,593 - Unused variable/parameters
# ##############################################################################
# cmake-format: on

set(LIBRA_BASE_DIAG_CANDIDATES
    -w5
    -Wabi
    -Winline
    -Wshadow
    -Wremarks
    -Wcomment
    -wd10382
    -wd177
    -wd869
    -wd593)

if(NOT DEFINED LIBRA_C_DIAG_CANDIDATES)
  libra_message(STATUS "Using LIBRA diagnostic candidates for C compiler")
  set(LIBRA_C_DIAG_CANDIDATES ${LIBRA_BASE_DIAG_CANDIDATES})
else()
  libra_message(STATUS "Using provided diagnostic candidates for C compiler")
endif()

if(NOT DEFINED LIBRA_CXX_DIAG_CANDIDATES)
  libra_message(STATUS "Using LIBRA diagnostic candidates for C++ compiler")
  set(LIBRA_CXX_DIAG_CANDIDATES
      ${LIBRA_BASE_DIAG_CANDIDATES}
      -Weffc++
      -wd2015
      -wd2012
      -wd11071
      -wd1476
      -wd1505
      -wd383
      -wd411)

else()
  libra_message(STATUS "Using provided diagnostic candidates for C++ compiler")
endif()

set(_LIBRA_C_DIAG_OPTIONS)
foreach(flag ${LIBRA_C_DIAG_CANDIDATES})
  # Options of the form -foption=value confuse the cmake flag checker and result
  # in multiple flags being checked on each invocation. So change the variable
  # name that the result of the check is assigned to.
  string(REGEX REPLACE "[-=]" "_" checked_flag_output ${flag})

  # A project can be C/C++ only
  if(CMAKE_C_COMPILER_LOADED)
    check_c_compiler_flag(${flag}
                          _LIBRA_C_COMPILER_SUPPORTS_${checked_flag_output})
  endif()

  if(_LIBRA_C_COMPILER_SUPPORTS_${checked_flag_output})
    list(APPEND _LIBRA_C_DIAG_OPTIONS ${flag})
  endif()
endforeach()

set(_LIBRA_CXX_DIAG_OPTIONS)
foreach(flag ${LIBRA_CXX_DIAG_CANDIDATES})
  # Options of the form -foption=value confuse the cmake flag checker and result
  # in multiple flags being checked on each invocation. So change the variable
  # name that the result of the check is assigned to.
  string(REGEX REPLACE "[-=]" "_" checked_flag_output ${flag})

  # A project can be C/C++ only
  if(CMAKE_CXX_COMPILER_LOADED)
    check_cxx_compiler_flag(${flag}
                            _LIBRA_CXX_COMPILER_SUPPORTS_${checked_flag_output})
  endif()

  if(_LIBRA_CXX_COMPILER_SUPPORTS_${checked_flag_output})
    list(APPEND _LIBRA_CXX_DIAG_OPTIONS ${flag})
  endif()
endforeach()

# ##############################################################################
# Optimization Options                                                         #
# ##############################################################################
if("${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
  if(NOT DEFINED LIBRA_OPT_LEVEL)
    set(LIBRA_OPT_LEVEL -O0)
  endif()
elseif("${CMAKE_BUILD_TYPE}" STREQUAL "Release")
  if(NOT DEFINED LIBRA_OPT_LEVEL)
    set(LIBRA_OPT_LEVEL -O3)
  endif()
else()
  libra_error(
    "Intel compiler plugin is only configured for {Debug, Release} builds")
endif()

#[[.rst:
.. cmake:variable:: LIBRA_NATIVE_OPT_INTEL

If enabled: ``-xHost``.
]]
if(LIBRA_NATIVE_OPT)
  list(APPEND _LIBRA_OPT_OPTIONS -xHost)
endif()

# ##############################################################################
# Checking Options
# ##############################################################################
#[[.rst:
.. cmake:variable:: LIBRA_SAN_INTEL

If MSAN enabled::

  -fno-omit-frame-pointer
  -fno-optimize-sibling-calls
  -fsanitize=memory
  -fsanitize-memory-track-origins

If ASAN is enabled::

  -fno-omit-frame-pointer
  -fno-optimize-sibling-calls
  -fsanitize=address,leak

If SSAN is enabled::

  -fno-omit-frame-pointer
  -fstack-protector-all
  -fstack-protector-strong
  -fstack-security-check

If UBSAN is enabled::

  -fno-omit-frame-pointer
  -fsanitize=undefined

If TSAN is enabled::

  -fno-omit-frame-pointer
  -fsanitize=thread

]]

set(MSAN_OPTIONS -fno-omit-frame-pointer -fno-optimize-sibling-calls
                 -fsanitize=memory -fsanitize-memory-track-origins)
set(ASAN_OPTIONS -fno-omit-frame-pointer -fno-optimize-sibling-calls
                 -fsanitize=address,leak)
set(SSAN_OPTIONS -fno-omit-frame-pointer -fstack-protector-all
                 -fstack-protector-strong -fstack-security-check)
set(UBSAN_OPTIONS -fno-omit-frame-pointer -fsanitize=undefined)
set(TSAN_OPTIONS -fno-omit-frame-pointer -fsanitize=thread)

if(NOT LIBRA_SAN)
  set(LIBRA_SAN ${LIBRA_SAN_DEFAULT})
endif()

set(_LIBRA_SAN_COMPILE_OPTIONS)
set(_LIBRA_SAN_LINK_OPTIONS)
set(_LIBRA_SAN_MATCH NO)

if("${LIBRA_SAN}" MATCHES "MSAN")
  set(_LIBRA_SAN_MATCH YES)
  list(APPEND _LIBRA_SAN_COMPILE_OPTIONS ${MSAN_OPTIONS})
  list(APPEND _LIBRA_SAN_LINK_OPTIONS ${MSAN_OPTIONS})
endif()

if("${LIBRA_SAN}" MATCHES "ASAN")
  set(_LIBRA_SAN_MATCH YES)
  list(APPEND _LIBRA_SAN_COMPILE_OPTIONS ${ASAN_OPTIONS})
  list(APPEND _LIBRA_SAN_LINK_OPTIONS ${ASAN_OPTIONS})
endif()

if("${LIBRA_SAN}" MATCHES "SSAN")
  set(_LIBRA_SAN_MATCH YES)
  list(APPEND _LIBRA_SAN_COMPILE_OPTIONS ${SSAN_OPTIONS})
  list(APPEND _LIBRA_SAN_LINK_OPTIONS ${SSAN_OPTIONS})
endif()

if("${LIBRA_SAN}" MATCHES "UBSAN")
  set(_LIBRA_SAN_MATCH YES)
  list(APPEND _LIBRA_SAN_COMPILE_OPTIONS ${UBSAN_OPTIONS})
  list(APPEND _LIBRA_SAN_LINK_OPTIONS ${UBSAN_OPTIONS})
endif()

if("${LIBRA_SAN}" MATCHES "TSAN")
  set(_LIBRA_SAN_MATCH YES)
  list(APPEND _LIBRA_SAN_COMPILE_OPTIONS ${TSAN_OPTIONS})
  list(APPEND _LIBRA_SAN_LINK_OPTIONS ${TSAN_OPTIONS})
endif()

if(NOT ${_LIBRA_SAN_MATCH} AND NOT "${LIBRA_SAN}" STREQUAL "NONE")
  libra_message(WARNING "Bad LIBRA_SAN setting ${LIBRA_SAN}: Must be subset of \
{MSAN,ASAN,SSAN,UBSAN,TSAN} or set to NONE")
endif()

# ##############################################################################
# Profiling Options
# ##############################################################################
#[[.rst:
.. cmake:variable:: LIBRA_PGO_INTEL

If GEN: ``-fprofile-generate``. Also passed as linker options to
`${PROJECT_NAME}``.

If USE: ``-fprofile-use``

This is software PGO. Intel also supports HWPGO experimentally, but it isn't
ready for prime time yet.
]]

if("${LIBRA_PGO}" MATCHES "GEN")
  set(_LIBRA_PGO_GEN_COMPILE_OPTIONS -fprofile-generate)
  set(_LIBRA_PGO_GEN_LINK_OPTIONS -fprofile-generate)
endif()

if("${LIBRA_PGO}" MATCHES "USE")
  set(_LIBRA_PGO_USE_COMPILE_OPTIONS -fprofile-use)
  set(_LIBRA_PGO_USE_LINK_OPTIONS -fprofile-use)
endif()

# ##############################################################################
# Stdlib options
# ##############################################################################
#[[.rst:
.. cmake:variable:: LIBRA_STDLIB_INTEL

If NONE: ``-nostdlib`` at link, both C/C++.

If STDCXX: ``-stdlib=libstdc++`` at link, C++ only.

If CXX: ``-stdlib=libc++`` at link, C++ only.

]]

if(NOT LIBRA_STDLIB)
  set(LIBRA_STDLIB ${LIBRA_STDLIB_DEFAULT})
endif()

set(_LIBRA_STDLIB_LINK_OPTIONS)
set(_LIBRA_STDLIB_MATCH NO)

if("${LIBRA_STDLIB}" MATCHES "NONE")
  set(_LIBRA_C_STDLIB_LINK_OPTIONS -nostdlib)
  set(_LIBRA_CXX_STDLIB_LINK_OPTIONS -nostdlib)
elseif("${LIBRA_STDLIB}" MATCHES "STDCXX")
  set(_LIBRA_CXX_STDLIB_COMPILE_OPTIONS -stdlib=libstdc++)
  set(_LIBRA_CXX_STDLIB_LINK_OPTIONS -stdlib=libstdc++)
elseif("${LIBRA_STDLIB}" MATCHES "CXX")
  set(_LIBRA_CXX_STDLIB_COMPILE_OPTIONS -stdlib=libc++)
  set(_LIBRA_CXX_STDLIB_LINK_OPTIONS -stdlib=libc++)
endif()

if(NOT ${_LIBRA_STDLIB_MATCH} AND NOT "${LIBRA_STDLIB}" STREQUAL "UNDEFINED")
  libra_message(
    WARNING "Bad LIBRA_STDLIB setting ${LIBRA_STDLIB}: Must be one of
{NONE,STDCXX,CXX}")
endif()

# ##############################################################################
# Reporting Options
# ##############################################################################
#[[.rst:
.. cmake:variable:: LIBRA_OPT_REPORT_INTEL

If enabled: ``-qopt-report=3 -qopt-report-phase=all`` at compile.

]]
if(LIBRA_OPT_REPORT)
  set(_LIBRA_OPT_REPORT_COMPILE_OPTIONS -qopt-report=3 -qopt-report-phase=all)
  if(LIBRA_LTO)
    set(_LIBRA_OPT_REPORT_LINK_OPTIONS -qopt-report=3 -qopt-report-phase=all)
  endif()
endif()

# ##############################################################################
# Filtering build flags for versioning
#
# * No warnings, since they have no effect on the build
# ##############################################################################
set(_LIBRA_TARGET_FLAGS_COMPILE_FILTER_REGEX "^-w")
set(_LIBRA_TARGET_FLAGS_LINK_FILTER_REGEX "^q")
