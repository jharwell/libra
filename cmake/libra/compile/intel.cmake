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
# Diagnostic Options
# ##############################################################################
set(_LIBRA_BASE_DIAG_CANDIDATES
    -Wabi
    -Wshadow
    -Wremarks
    -Wcomment
    -Wall
    -Wintrinsic-promote
    -Wdeprecated
    -Wformat
    -Wunknown-pragmas
    -Wrecommended-option
    -Wreorder
    -Wshadow
    -Wextra-tokens
    -Weverything
    -fdiagnostics-color=always
    -Wno-reserved-id-macro
    -Wno-padded
    -Wno-packed
    -Wno-gnu-zero-variadic-macro-arguments
    -Wno-language-extension-token
    -Wno-gnu-statement-expression
    -Wshorten-64-to-32
    -Wno-cast-align
    -Wno-weak-vtables
    -Wno-documentation
    -Wno-extra-semi-stmt
    -Wno-extra-semi
    -Wno-global-constructors
    -Wno-exit-time-destructors
    -fcomment-block-commands=internal,endinternal)

if(LIBRA_WERROR)
  list(APPEND _LIBRA_BASE_DIAG_CANDIDATES -Werror)
endif()

if(NOT DEFINED LIBRA_C_DIAG_CANDIDATES)
  libra_message(STATUS "Using LIBRA diagnostic candidates for C compiler")
  set(LIBRA_C_DIAG_CANDIDATES ${_LIBRA_BASE_DIAG_CANDIDATES})
else()
  libra_message(STATUS "Using provided diagnostic candidates for C compiler")
endif()

if(NOT DEFINED LIBRA_CXX_DIAG_CANDIDATES)
  libra_message(STATUS "Using LIBRA diagnostic candidates for C++ compiler")
  set(LIBRA_CXX_DIAG_CANDIDATES
      ${_LIBRA_BASE_DIAG_CANDIDATES}
      -fdiagnostics-show-template-tree
      -Wno-c++98-compat
      -Wno-c++98-compat-pedantic
      -Wno-c99-extensions)

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
# Optimization Options
# ##############################################################################
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
  set(_LIBRA_STDLIB_MATCH YES)
elseif("${LIBRA_STDLIB}" MATCHES "STDCXX")
  set(_LIBRA_CXX_STDLIB_COMPILE_OPTIONS -stdlib=libstdc++)
  set(_LIBRA_CXX_STDLIB_LINK_OPTIONS -stdlib=libstdc++)
  set(_LIBRA_STDLIB_MATCH YES)
elseif("${LIBRA_STDLIB}" MATCHES "CXX")
  set(_LIBRA_CXX_STDLIB_COMPILE_OPTIONS -stdlib=libc++)
  set(_LIBRA_CXX_STDLIB_LINK_OPTIONS -stdlib=libc++)
  set(_LIBRA_STDLIB_MATCH YES)
endif()

if(NOT ${_LIBRA_STDLIB_MATCH} AND NOT "${LIBRA_STDLIB}" STREQUAL "UNDEFINED")
  libra_message(
    WARNING
    "Bad LIBRA_STDLIB setting '${LIBRA_STDLIB}': Must be one of {NONE,STDCXX,CXX}"
  )
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
# * No warnings
# * No -fdiagnostics-XX options
# * No -fcomment-XX options
# ##############################################################################
set(_LIBRA_TARGET_FLAGS_COMPILE_FILTER_REGEX "^-W|diagnostics|comment")
# Regex intentionally matches nothing
set(_LIBRA_TARGET_FLAGS_LINK_FILTER_REGEX "XXXXNOMATCHXXXX")
