#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#
# ##############################################################################
# Modules
# ##############################################################################
include(libra/compile/standard)
include(libra/messaging)
include(libra/defaults)

# ##############################################################################
# Debugging Options
# ##############################################################################
#[[.rst:
.. cmake:variable:: LIBRA_DEBUG_INFO_GNU

  If enabled: ``-g2``. If disabled: ``-g0``.
]]
if(LIBRA_DEBUG_INFO)
  set(_LIBRA_DEBUG_INFO_OPTIONS "-g2")
else()
  set(_LIBRA_DEBUG_INFO_OPTIONS "-g0")
endif()

# ##############################################################################
# Diagnostic Options
# ##############################################################################
set(LIBRA_BASE_DIAG_CANDIDATES
    -fdiagnostics-color=always
    -fdiagnostics-all-candidates
    -W
    -Wall
    -Wextra
    -Wconversion
    -Wcast-align
    -Wcast-qual
    -Wdisabled-optimization
    -Wformat=2
    -Winit-self
    -Wlogical-op
    -Wmissing-declarations
    -Wmissing-include-dirs
    -Wstrict-overflow=2
    -Wsuggest-attribute=pure
    -Wsuggest-attribute=const
    -Wsuggest-attribute=format
    -Wsuggest-attribute=cold
    -Wsuggest-final-types
    -Wsuggest-final-methods
    -Wfloat-equal
    -Wshadow
    -Wmisleading-indentation
    -Wduplicated-branches
    -Wduplicated-cond
    -Wredundant-decls
    -Wswitch-default
    -Wundef
    -Wpointer-arith
    -Wno-unknown-pragmas
    -Wstack-protector
    -Wunreachable-code
    -Wmissing-format-attribute
    -Wfloat-conversion
    -Wnarrowing
    -Wmultistatement-macros)

if(NOT DEFINED LIBRA_C_DIAG_CANDIDATES)
  libra_message(STATUS "Using LIBRA diagnostic candidates for C compiler")
  set(LIBRA_C_DIAG_CANDIDATES
      ${LIBRA_BASE_DIAG_CANDIDATES}
      -Wstrict-prototypes
      -Wmissing-prototypes
      -Wbad-function-cast
      -Wnested-externs
      -Wnull-dereference)
else()
  libra_message(STATUS "Using provided diagnostic candidates for C compiler")
endif()

if(NOT DEFINED LIBRA_CXX_DIAG_CANDIDATES)
  libra_message(STATUS "Using LIBRA diagnostic candidates for C++ compiler")
  set(LIBRA_CXX_DIAG_CANDIDATES
      ${LIBRA_BASE_DIAG_CANDIDATES}
      -Weffc++
      -Wunused-macros
      -Wsuggest-override
      -Wstrict-null-sentinel
      -Wclass-memaccess
      -Wsign-promo
      -Wnoexcept
      -Wold-style-cast
      -Woverloaded-virtual
      -Wnon-virtual-dtor
      -Wctor-dtor-privacy
      -Wdelete-non-virtual-dtor
      -fconcepts-diagnostics-depth=10
      -Wuseless-cast)
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
# Build-time Profiling Options
# ##############################################################################
#[[.rst:
.. cmake:variable:: LIBRA_BUILD_PROF_GNU

If enabled: ``-ftime-report``.
]]
if(LIBRA_BUILD_PROF)
  set(_LIBRA_BUILD_PROF_OPTIONS "-ftime-report")
else()
  set(_LIBRA_BUILD_PROF_OPTIONS)
endif()

# ##############################################################################
# Fortifying Options
# ##############################################################################
#[[.rst:
.. cmake:variable:: LIBRA_FORTIFY_GNU

If STACK: ``-fstack-protector``.

If SOURCE: ``-D_FORTIFY_SOURCE=2``.

If FORMAT: ``-Wformat-security -Werror=format=2``.
]]
set(_LIBRA_FORTIFY_OPTIONS)
set(_LIBRA_FORTIFY_MATCH NO)

set(LIBRA_FORTIFY_DEFAULT "NONE")

if(NOT LIBRA_FORTIFY MATCHES "NONE")
  set(LIBRA_LTO ON)
endif()

# -fstack-protector-{strong,all} are also options which could be swapped
# in/added eventually.
set(_LIBRA_FORTIFY_STACK -fstack-protector)
set(_LIBRA_FORTIFY_SOURCE -D_FORTIFY_SOURCE=2)
set(_LIBRA_FORTIFY_FORMAT -Wformat-security -Werror=format=2)

if("${LIBRA_FORTIFY}" MATCHES "STACK")
  set(_LIBRA_FORTIFY_MATCH YES)
  set(_LIBRA_FORTIFY_OPTIONS "${_LIBRA_FORTIFY_STACK}")
endif()

if("${LIBRA_FORTIFY}" MATCHES "SOURCE")
  set(_LIBRA_FORTIFY_MATCH YES)
  set(_LIBRA_FORTIFY_OPTIONS "${_LIBRA_FORTIFY_SOURCE}")
endif()

if("${LIBRA_FORTIFY}" MATCHES "FORMAT")
  set(_LIBRA_FORTIFY_MATCH YES)
  set(_LIBRA_FORTIFY_OPTIONS "${_LIBRA_FORTIFY_FORMAT}")
endif()

if("${LIBRA_FORTIFY}" MATCHES "ALL")
  set(_LIBRA_FORTIFY_MATCH YES)
  set(_LIBRA_FORTIFY_OPTIONS ${_LIBRA_FORTIFY_STACK} ${_LIBRA_FORTIFY_SOURCE}
                             ${_LIBRA_FORTIFY_FORMAT})
endif()

if(NOT LIBRA_FORTIFY_MATCH AND NOT "${LIBRA_FORTIFY}" STREQUAL "NONE")
  libra_message(
    WARNING "Bad LIBRA_FORTIFY setting ${LIBRA_FORTIFY}: Must be subset \
of {STACK,SOURCE,FORMAT,ALL} or set to NONE for gcc")
endif()

# ##############################################################################
# Optimization Options
# ##############################################################################
#[[.rst:
.. cmake:variable:: LIBRA_OPT_LEVEL_GNU

Set to ``-O0`` on Debug builds and ``-O3`` on release builds, unless overriden.
]]

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
    "GNU compiler plugin is only configured for {Debug, Release} builds")
endif()

#[[.rst:
.. cmake:variable:: LIBRA_NATIVE_OPT_GNU

If enabled: ``-march=native -mtune=native``.
]]
if(LIBRA_NATIVE_OPT)
  list(APPEND _LIBRA_OPT_OPTIONS -march=native -mtune=native)
endif()

if("${CMAKE_BUILD_TYPE}" STREQUAL "Release")
  # For handling lto with static libraries on MSI
  set(CMAKE_AR "gcc-ar")
  set(CMAKE_NM "gcc-nm")
  set(CMAKE_RANLIB "gcc-ranlib")

  # Without turning off these warnings we get a bunch of spurious warnings about
  # the attributes, even though they are already present.
  target_link_options(
    ${PROJECT_NAME}
    PUBLIC
    -Wno-suggest-attribute=pure
    -Wno-suggest-attribute=const
    -Wno-suggest-attribute=cold)

endif()

# ##############################################################################
# Sanitizer Options
# ##############################################################################
#[[.rst:
.. cmake:variable:: LIBRA_SAN_GNU

If MSAN enabled::

  -fno-omit-frame-pointer
  -fno-optimize-sibling-calls
  -fsanitize=leak
  -fsanitize-recover=all

If ASAN is enabled::

  -fno-omit-frame-pointer
  -fno-optimize-sibling-calls
  -fsanitize=address
  -fsanitize-address-use-after-scope
  -fsanitize=pointer-compare
  -fsanitize=pointer-subtract
  -fsanitize-recover=all

If SSAN is enabled::

  -fno-omit-frame-pointer
  -fstack-protector-all
  -fstack-protector-strong
  -fsanitize-recover=all.

If UBSAN is enabled::

  -fno-omit-frame-pointer
  -fsanitize=undefined
  -fsanitize=float-divide-by-zero
  -fsanitize=float-cast-overflow
  -fsanitize=null
  -fsanitize=signed-integer-overflow
  -fsanitize=bool
  -fsanitize=enum
  -fsanitize=builtin
  -fsanitize=bounds
  -fsanitize=vptr
  -fsanitize=pointer-overflow
  -fsanitize-recover=all

If TSAN is enabled::

  -fno-omit-frame-pointer
  -fsanitize=thread
  -fsanitize-recover=all

]]

set(MSAN_OPTIONS -fno-omit-frame-pointer -fno-optimize-sibling-calls
                 -fsanitize=leak -fsanitize-recover=all)
set(ASAN_OPTIONS
    -fno-omit-frame-pointer
    -fno-optimize-sibling-calls
    -fsanitize=address
    -fsanitize-address-use-after-scope
    -fsanitize=pointer-compare
    -fsanitize=pointer-subtract
    -fsanitize-recover=all)
set(SSAN_OPTIONS -fno-omit-frame-pointer -fstack-protector-all
                 -fstack-protector-strong -fsanitize-recover=all)
set(UBSAN_OPTIONS
    -fno-omit-frame-pointer
    -fsanitize=undefined
    -fsanitize=float-divide-by-zero
    -fsanitize=float-cast-overflow
    -fsanitize=null
    -fsanitize=signed-integer-overflow
    -fsanitize=bool
    -fsanitize=enum
    -fsanitize=builtin
    -fsanitize=bounds
    -fsanitize=vptr
    -fsanitize=pointer-overflow
    -fsanitize-recover=all)
set(TSAN_OPTIONS -fno-omit-frame-pointer -fsanitize=thread
                 -fsanitize-recover=all)

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
  libra_message(WARNING "Bad LIBRA_SAN setting ${LIBRA_SAN}: Must be subset \
of {MSAN,ASAN,SSAN,UBSAN,TSAN} or set to NONE")
endif()

# ##############################################################################
# Profiling Options
# ##############################################################################
#[[.rst:
.. cmake:variable:: LIBRA_PGO_GNU

If GEN: ``-fprofile-generate``.

If USE: ``-fprofile-use``.
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
# Code Coverage Options
#
# We don't use the --coverage alias, because while that works for both compiling
# and linking, additional warning options like -fno-inline fail when linking
# ##############################################################################
#[[.rst:
.. cmake:variable:: LIBRA_CODE_COV_GNU

If enabled: ``-fprofile-arcs -ftest-coverage -fno-inline
-fprofile-update=atomic`` to compiler, and ``-fprofile-arcs`` to linker.
]]
if(LIBRA_CODE_COV)
  if(NOT LIBRA_CODE_COV_NATIVE)
    libra_message(
      WARNING
      "Non-native code coverage instrumentation format selected for GNU; LIBRA's common format is GNU. Configuration error?"
    )
  endif()
  set(_LIBRA_CODE_COV_COMPILE_OPTIONS
      -fprofile-arcs
      -ftest-coverage
      # Suppress template inlining for more accurate coverage reports
      -fno-inline
      # Thread-safe updates to coverage counters
      -fprofile-update=atomic)

  set(_LIBRA_CODE_COV_LINK_OPTIONS -fprofile-arcs)
endif()

# ##############################################################################
# Valgrind Compatibility Options
# ##############################################################################
#[[.rst:
.. cmake:variable:: LIBRA_VALGRIND_COMPAT_CLANG

If enabled: ``-mno-sse3`` to compiler.
]]
if(LIBRA_VALGRIND_COMPAT)
  set(_LIBRA_VALGRIND_COMPAT_OPTIONS "-mno-sse3")
endif()

# ##############################################################################
# Stdlib options
# ##############################################################################
#[[.rst:
.. cmake:variable:: LIBRA_STDLIB_GNU

If NONE: ``-nostdlib`` during at link, both C/C++.

If STDCXX: N/A.

If CXX: N/A.

]]

if(NOT LIBRA_STDLIB)
  set(LIBRA_STDLIB ${LIBRA_STDLIB_DEFAULT})
endif()

set(_LIBRA_STDLIB_LINK_OPTIONS)
set(_LIBRA_STDLIB_MATCH NO)

if("${LIBRA_STDLIB}" MATCHES "NONE")
  set(_LIBRA_STDLIB_MATCH YES)
  set(_LIBRA_C_STDLIB_LINK_OPTIONS -nostdlib)
  set(_LIBRA_CXX_STDLIB_LINK_OPTIONS -nostdlib)
endif()
if(NOT ${_LIBRA_STDLIB_MATCH} AND NOT "${LIBRA_STDLIB}" STREQUAL "UNDEFINED")
  libra_message(
    WARNING
    "Bad LIBRA_STDLIB setting ${LIBRA_STDLIB}: Must be one of {NONE,STDCXX,CXX}"
  )
endif()

# ##############################################################################
# Filtering build flags for versioning
#
# * No warnings, since they have no effect on the build
# ##############################################################################
set(_LIBRA_TARGET_FLAGS_COMPILE_FILTER_REGEX "^-W")

# Regex intentionally matches nothing
set(_LIBRA_TARGET_FLAGS_LINK_FILTER_REGEX "XXXXNOMATCHXXXX")
