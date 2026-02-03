#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#

# ##############################################################################
# Modules
# ##############################################################################
include(libra/messaging)
include(libra/defaults)
include(libra/compile/standard)

# ##############################################################################
# Debugging Options
# ##############################################################################
#[[.rst:
.. cmake:variable:: LIBRA_DEBUG_INFO_CLANG

If enabled: ``-g2``. If disabled: ``-g0``.
]]
if(LIBRA_DEBUG_INFO)
  set(LIBRA_DEBUG_INFO_OPTIONS "-g2")
else()
  set(LIBRA_DEBUG_INFO_OPTIONS "-g0")
endif()

# ##############################################################################
# Diagnostic Options
# ##############################################################################
set(LIBRA_BASE_DIAG_CANDIDATES
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
      -fdiagnostics-show-template-tree
      -Wno-c++98-compat
      -Wno-c++98-compat-pedantic
      -Weffc++
      -Wno-c99-extensions)
else()
  libra_message(STATUS "Using provided diagnostic candidates for C++ compiler")
endif()

set(LIBRA_C_DIAG_OPTIONS)
foreach(flag ${LIBRA_C_DIAG_CANDIDATES})
  # Options of the form -foption=value confuse the cmake flag checker and result
  # in multiple flags being checked on each invocation. So change the variable
  # name that the result of the check is assigned to.
  string(REGEX REPLACE "[-=]" "_" flag ${flag})

  # A project can be C/C++ only
  if(CMAKE_C_COMPILER_LOADED)
    check_c_compiler_flag(${flag} LIBRA_C_COMPILER_SUPPORTS_${flag})
  endif()
  if(LIBRA_C_COMPILER_SUPPORTS_${flag})
    list(APPEND LIBRA_C_DIAG_OPTIONS ${flag})
  endif()
endforeach()

set(LIBRA_CXX_DIAG_OPTIONS)
foreach(flag ${LIBRA_CXX_DIAG_CANDIDATES})
  # Options of the form -foption=value confuse the cmake flag checker and result
  # in multiple flags being checked on each invocation. So change the variable
  # name that the result of the check is assigned to.
  string(REGEX REPLACE "[-=]" "_" checked_flag_output ${flag})

  # A project can be C/C++ only
  if(CMAKE_CXX_COMPILER_LOADED)
    check_cxx_compiler_flag(${flag}
                            LIBRA_CXX_COMPILER_SUPPORTS_${checked_flag_output})
  endif()

  if(LIBRA_CXX_COMPILER_SUPPORTS_${checked_flag_output})
    list(APPEND LIBRA_CXX_DIAG_OPTIONS ${flag})
  endif()
endforeach()

# ##############################################################################
# Build-time Profiling Options
# ##############################################################################
#[[.rst:
.. cmake:variable:: LIBRA_BUILD_PROF_CLANG

If enabled: ``-ftime-trace``.
]]
if(LIBRA_BUILD_PROF)
  set(LIBRA_BUILD_PROF_OPTIONS "-ftime-trace")
else()
  set(LIBRA_BUILD_PROF_OPTIONS)
endif()

# ##############################################################################
# Fortifying Options
# ##############################################################################
#[[.rst:
.. cmake:variable:: LIBRA_FORTIFY_CLANG

If STACK: ``-fstack-protector``.

If SOURCE: ``-D_FORTIFY_SOURCE=2``.

If FORMAT: ``-Wformat-security -Werror=format=2``.
]]
set(LIBRA_FORTIFY_OPTIONS)
set(LIBRA_FORTIFY_MATCH NO)

if(NOT DEFINED LIBRA_FORTIFY)
  set(LIBRA_FORTIFY ${LIBRA_FORTIFY_DEFAULT})
endif()

if(NOT LIBRA_FORTIFY MATCHES "NONE")
  set(LIBRA_LTO ON)
endif()

# -fstack-protector-{strong,all} are also options which could be swapped
# in/added eventually.
set(LIBRA_FORTIFY_STACK -fstack-protector)
set(LIBRA_FORTIFY_SOURCE -D_FORTIFY_SOURCE=2)
set(LIBRA_FORTIFY_FORMAT -Wformat-security -Werror=format-security)

if("${LIBRA_FORTIFY}" MATCHES "STACK")
  set(LIBRA_FORTIFY_MATCH YES)
  set(LIBRA_FORTIFY_OPTIONS "${LIBRA_FORTIFY_STACK}")
endif()

if("${LIBRA_FORTIFY}" MATCHES "SOURCE")
  set(LIBRA_FORTIFY_MATCH YES)
  set(LIBRA_FORTIFY_OPTIONS "${LIBRA_FORTIFY_SOURCE}")
endif()

if("${LIBRA_FORTIFY}" MATCHES "FORMAT")
  set(LIBRA_FORTIFY_MATCH YES)
  set(LIBRA_FORTIFY_OPTIONS "${LIBRA_FORTIFY_FORMAT}")
endif()

if("${LIBRA_FORTIFY}" MATCHES "ALL")
  set(LIBRA_FORTIFY_MATCH YES)
  set(LIBRA_FORTIFY_OPTIONS ${LIBRA_FORTIFY_STACK} ${LIBRA_FORTIFY_SOURCE}
                            ${LIBRA_FORTIFY_FORMAT})
endif()

if(NOT LIBRA_FORTIFY_MATCH AND NOT "${LIBRA_FORTIFY}" STREQUAL "NONE")
  libra_message(
    WARNING "Bad LIBRA_FORTIFY setting ${LIBRA_FORTIFY}: Must be subset \
of {STACK,SOURCE,FORMAT,ALL} or set to NONE for clang")
endif()

# ##############################################################################
# Optimization Options
# ##############################################################################
#[[.rst:
.. cmake:variable:: LIBRA_OPT_LEVEL_CLANG

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
  libra_message(
    FATAL_ERROR
    "clang compiler plugin is only configured for {Debug, Release} builds")
endif()

if(LIBRA_NATIVE_OPT)
  list(APPEND LIBRA_OPT_OPTIONS -march=native -mtune=native)
endif()

if("${CMAKE_BUILD_TYPE}" STREQUAL "Release")
  # For handling lto with static libraries on MSI
  set(CMAKE_AR "llvm-ar")
  set(CMAKE_NM "llvm-nm")
  set(CMAKE_RANLIB "llvm-ranlib")
endif()

# ##############################################################################
# Sanitizer Options
# ##############################################################################
#[[.rst:
.. cmake:variable:: LIBRA_SAN_GNU

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
  -fsanitize=safe-stack

If UBSAN is enabled::

  -fno-omit-frame-pointer
  -fsanitize=undefined
  -fsanitize=float-divide-by-zero
  -fsanitize=unsigned-integer-overflow
  -fsanitize=local-bounds
  -fsanitize=nullability

If TSAN is enabled::

  -fno-omit-frame-pointer -fsanitize=thread

]]

set(MSAN_OPTIONS -fno-omit-frame-pointer -fno-optimize-sibling-calls
                 -fsanitize=memory -fsanitize-memory-track-origins)
set(ASAN_OPTIONS -fno-omit-frame-pointer -fno-optimize-sibling-calls
                 -fsanitize=address,leak)
set(SSAN_OPTIONS -fno-omit-frame-pointer -fstack-protector-all
                 -fstack-protector-strong -fsanitize=safe-stack)
set(UBSAN_OPTIONS
    -fno-omit-frame-pointer
    -fsanitize=undefined
    -fsanitize=float-divide-by-zero
    -fsanitize=unsigned-integer-overflow
    -fsanitize=local-bounds
    -fsanitize=nullability)
set(TSAN_OPTIONS -fno-omit-frame-pointer -fsanitize=thread)

if(NOT LIBRA_SAN)
  set(LIBRA_SAN ${LIBRA_SAN_DEFAULT})
endif()

set(LIBRA_SAN_COMPILE_OPTIONS)
set(LIBRA_SAN_LINK_OPTIONS)
set(LIBRA_SAN_MATCH NO)

if("${LIBRA_SAN}" MATCHES "MSAN")
  set(LIBRA_SAN_MATCH YES)
  list(APPEND LIBRA_SAN_COMPILE_OPTIONS ${MSAN_OPTIONS})
  list(APPEND LIBRA_SAN_LINK_OPTIONS ${MSAN_OPTIONS})
endif()

if("${LIBRA_SAN}" MATCHES "ASAN")
  set(LIBRA_SAN_MATCH YES)
  list(APPEND LIBRA_SAN_COMPILE_OPTIONS ${ASAN_OPTIONS})
  list(APPEND LIBRA_SAN_LINK_OPTIONS ${ASAN_OPTIONS})
endif()

if("${LIBRA_SAN}" MATCHES "SSAN")
  set(LIBRA_SAN_MATCH YES)
  list(APPEND LIBRA_SAN_COMPILE_OPTIONS ${SSAN_OPTIONS})
  list(APPEND LIBRA_SAN_LINK_OPTIONS ${SSAN_OPTIONS})
endif()

if("${LIBRA_SAN}" MATCHES "UBSAN")
  set(LIBRA_SAN_MATCH YES)
  list(APPEND LIBRA_SAN_COMPILE_OPTIONS ${UBSAN_OPTIONS})
  list(APPEND LIBRA_SAN_LINK_OPTIONS ${UBSAN_OPTIONS})
endif()

if("${LIBRA_SAN}" MATCHES "TSAN")
  set(LIBRA_SAN_MATCH YES)
  list(APPEND LIBRA_SAN_COMPILE_OPTIONS ${TSAN_OPTIONS})
  list(APPEND LIBRA_SAN_LINK_OPTIONS ${TSAN_OPTIONS})
endif()

if(NOT ${LIBRA_SAN_MATCH} AND NOT "${LIBRA_SAN}" STREQUAL "NONE")
  libra_message(WARNING "Bad LIBRA_SAN setting ${LIBRA_SAN}: Must be subset of
{MSAN,ASAN,SSAN,UBSAN,TSAN} or set to NONE")
endif()

# ##############################################################################
# Profiling Options
# ##############################################################################
#[[.rst:
.. cmake:variable:: LIBRA_PGO_CLANG

If GEN: ``-fprofile-generate``. Also passed as linker options to
`${PROJECT_NAME}``.

If USE: ``-fprofile-use``.
]]

if("${LIBRA_PGO}" MATCHES "GEN")
  set(LIBRA_PGO_GEN_COMPILE_OPTIONS -fprofile-generate)
  set(LIBRA_PGO_GEN_LINK_OPTIONS -fprofile-generate)
endif()

if("${LIBRA_PGO}" MATCHES "USE")
  set(LIBRA_PGO_USE_COMPILE_OPTIONS -fprofile-use)
endif()

# ##############################################################################
# Code Coverage Options
# ##############################################################################
#[[.rst:
.. cmake:variable:: LIBRA_CODE_COV_CLANG

If enabled: ``--coverage -fno-inline`` to compiler, ``--coverage`` to linker. This
makes clang emit .gcno files which are compatible with ``gcovr``, and therefore
with the various ``gcovr-`` targets.

This *also* eliminates the need for an intermediate processing step before
coverage can be shown. If we use the LLVM toolchain, we would pass
``-fprofile-instr-generate -fcoverage-mapping`` to the compiler, and
``-fprofile-instr-generate`` to the linker, run our code, and then have to do::

  llvm-profdata merge default.profraw -o default.profdata

before we can view the coverage with ``llvm-cov``.

]]

if(LIBRA_CODE_COV)
  set(LIBRA_CODE_COV_COMPILE_OPTIONS --coverage -fno-inline)
  set(LIBRA_CODE_COV_LINK_OPTIONS --coverage)
endif()

# ##############################################################################
# Valgrind Compatibility Options
# ##############################################################################
#[[.rst:
.. cmake:variable:: LIBRA_VALGRIND_COMPAT_CLANG

If enabled: ``-mno-sse3`` to compiler.
]]

if(LIBRA_VALGRIND_COMPAT)
  set(LIBRA_VALGRIND_COMPAT_OPTIONS "-mno-sse3")
endif()

# ##############################################################################
# Stdlib options
# ##############################################################################
#[[.rst:
.. cmake:variable:: LIBRA_STDLIB_CLANG

If NONE: ``-nostdlib`` at link, both C/C++.

If STDCXX: ``-stdlib=libstdc++`` at link, C++ only.

If CXX: ``-stdlib=libc++`` at link, C++ only.
]]
if(NOT LIBRA_STDLIB)
  set(LIBRA_STDLIB ${LIBRA_STDLIB_DEFAULT})
endif()

set(LIBRA_STDLIB_LINK_OPTIONS)
set(LIBRA_STDLIB_MATCH NO)

if("${LIBRA_STDLIB}" MATCHES "NONE")
  set(LIBRA_C_STDLIB_LINK_OPTIONS -nostdlib)
  set(LIBRA_CXX_STDLIB_LINK_OPTIONS -nostdlib)
  set(LIBRA_STDLIB_MATCH YES)
elseif("${LIBRA_STDLIB}" MATCHES "STDCXX")
  set(LIBRA_CXX_STDLIB_LINK_OPTIONS -stdlib=libstdc++)
  set(LIBRA_CXX_STDLIB_COMPILE_OPTIONS -stdlib=libstdc++)
  set(LIBRA_STDLIB_MATCH YES)
elseif("${LIBRA_STDLIB}" MATCHES "CXX")
  set(LIBRA_CXX_STDLIB_COMPILE_OPTIONS -stdlib=libc++)
  set(LIBRA_CXX_STDLIB_LINK_OPTIONS -stdlib=libc++)
  set(LIBRA_STDLIB_MATCH YES)
endif()

if(NOT ${LIBRA_STDLIB_MATCH} AND NOT "${LIBRA_STDLIB}" STREQUAL "UNDEFINED")
  libra_message(
    WARNING
    "Bad LIBRA_STDLIB setting ${LIBRA_STDLIB}: Must be one of {NONE,STDCXX,CXX}"
  )
endif()

# ##############################################################################
# Reporting Options
# ##############################################################################
#[[.rst:
.. cmake:variable:: LIBRA_OPT_REPORT_CLANG

If enabled: ``-Rpass=.* -Rpass-missed=.* -Rpass-analysis=.* -fsave-optimization-record`` at compile.

]]
if(LIBRA_OPT_REPORT)
  set(LIBRA_OPT_REPORT_COMPILE_OPTIONS
      -Rpass=.* -Rpass-missed=.* -Rpass-analysis=.* -fsave-optimization-record)
  if(LIBRA_LTO)
    set(LIBRA_OPT_REPORT_LINK_OPTIONS -Rpass=.* -Rpass-missed=.*
                                      -Rpass-analysis=.*)
  endif()
endif()

# ##############################################################################
# Filtering build flags for versioning
#
# * No warnings, since they have no effect on the build
# ##############################################################################
set(LIBRA_TARGET_FLAGS_COMPILE_FILTER_REGEX "^-W")
# Regex intentionally matches nothing
set(LIBRA_TARGET_FLAGS_LINK_FILTER_REGEX "XXXXNOMATCHXXXX")
