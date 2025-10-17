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
if(LIBRA_NO_DEBUG_INFO)
  set(LIBRA_DEBUG_OPTIONS "-g0")
else()
  set(LIBRA_DEBUG_OPTIONS "-g2")
endif()

# ##############################################################################
# Build-time Profiling Options
# ##############################################################################
if(LIBRA_BUILD_PROF)
  set(LIBRA_BUILD_PROF_OPTIONS "-ftime-trace")
else()
  set(LIBRA_BULID_PROF_OPTIONS)
endif()

# ##############################################################################
# Fortifying Options
# ##############################################################################
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
set(LIBRA_FORTIFY_STACK -fsanitize=safe-stack -fstack-protector)
set(LIBRA_FORTIFY_SOURCE -D_FORTIFY_SOURCE=2)
set(LIBRA_FORTIFY_CFI -fsanitize=cfi -fvisibility=hidden)
set(LIBRA_FORTIFY_GOT -Wl,-z,relro -Wl,-z,now)
set(LIBRA_FORTIFY_FORMAT -Wformat-security -Werror=format-security)
set(LIBRA_FORTIFY_LIBCXX_FAST
    -D_LIBCPP_HARDENING_MODE=_LIBCPP_HARDENING_MODE_FAST)
set(LIBRA_FORTIFY_LIBCXX_EXTENSIVE
    -D_LIBCPP_HARDENING_MODE_EXTENSIVE=_LIBCPP_HARDENING_MODE_EXTENSIVE)
set(LIBRA_FORTIFY_LIBCXX_DEBUG
    -D_LIBCPP_HARDENING_DEBUG=_LIBCPP_HARDENING_MODE_DEBUG)

if("${LIBRA_FORTIFY}" MATCHES "STACK")
  set(LIBRA_FORTIFY_MATCH YES)
  set(LIBRA_FORTIFY_OPTIONS "${LIBRA_FORTIFY_STACK}")
endif()

if("${LIBRA_FORTIFY}" MATCHES "SOURCE")
  set(LIBRA_FORTIFY_MATCH YES)
  set(LIBRA_FORTIFY_OPTIONS "${LIBRA_FORTIFY_SOURCE}")
endif()

if("${LIBRA_FORTIFY}" MATCHES "CFI")
  set(LIBRA_FORTIFY_MATCH YES)
  set(LIBRA_FORTIFY_OPTIONS "${LIBRA_FORTIFY_CFI}")
endif()

if("${LIBRA_FORTIFY}" MATCHES "GOT")
  set(LIBRA_FORTIFY_MATCH YES)
  set(LIBRA_FORTIFY_OPTIONS "${LIBRA_FORTIFY_GOT}")
endif()

if("${LIBRA_FORTIFY}" MATCHES "FORMAT")
  set(LIBRA_FORTIFY_MATCH YES)
  set(LIBRA_FORTIFY_OPTIONS "${LIBRA_FORTIFY_FORMAT}")
endif()

if("${LIBRA_FORTIFY}" MATCHES "LIBCXX_FAST")
  set(LIBRA_FORTIFY_MATCH YES)
  set(LIBRA_FORTIFY_OPTIONS "${LIBRA_FORTIFY_LIBCXX_FAST}")
endif()

if("${LIBRA_FORTIFY}" MATCHES "LIBCXX_EXTENSIVE")
  set(LIBRA_FORTIFY_MATCH YES)
  set(LIBRA_FORTIFY_OPTIONS "${LIBRA_FORTIFY_LIBCXX_EXTENSIVE}")
endif()

if("${LIBRA_FORTIFY}" MATCHES "LIBCXX_DEBUG")
  set(LIBRA_FORTIFY_MATCH YES)
  set(LIBRA_FORTIFY_OPTIONS "${LIBRA_FORTIFY_LIBCXX_DEBUG}")
endif()

if("${LIBRA_FORTIFY}" MATCHES "ALL")
  set(LIBRA_FORTIFY_MATCH YES)
  set(LIBRA_FORTIFY_OPTIONS
      "${LIBRA_FORTIFY_STACK} ${LIBRA_FORTIFY_SOURCE} ${LIBRA_FORTIFY_CFI}
  ${LIBRA_FORTIFY_GOT} ${LIBRA_FORTIFY_FORMAT} ${LIBRA_FORTIFY_LIBCXX_FAST}
  ${LIBRA_FORTIFY_LIBCXX_EXTENSIVE} ${LIBRA_FORTIFY_LIBCXX_DEBUG}")
endif()

if(NOT LIBRA_FORTIFY_MATCH AND NOT "${LIBRA_FORTIFY}" STREQUAL "NONE")
  libra_message(
    WARNING "Bad LIBRA_FORTIFY setting ${LIBRA_FORTIFY}: Must be subset \
of {STACK,SOURCE,CFI,GOT,FORMAT,LIBCXX_FAST,LIBCXX_EXTENSIVE,LIBCXX_DEBUG,ALL} \
or set to NONE for clang")
endif()

set(LIBRA_C_FORTIFY_OPTIONS ${LIBRA_FORTIFY_OPTIONS})
set(LIBRA_CXX_FORTIFY_OPTIONS ${LIBRA_FORTIFY_OPTIONS})

# ##############################################################################
# LTO Options
# ##############################################################################
if(LIBRA_LTO)
  set(CMAKE_INTERPROCEDURAL_OPTIMIZATION ON)
endif()

# ##############################################################################
# Optimization Options
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
  libra_message(
    FATAL_ERROR
    "clang compiler plugin is only configured for {Debug, Release} builds")
endif()

if(LIBRA_UNSAFE_OPT)
  set(LIBRA_UNSAFE_OPT_OPTIONS -march=native -mtune=native)
  set(LIBRA_OPT_OPTIONS "${LIBRA_OPT_OPTIONS} ${LIBRA_UNSAFE_OPT_OPTIONS}")
endif()

if(LIBRA_MT)
  set(LIBRA_OPT_OPTIONS "${LIBRA_OPT_OPTIONS} -fopenmp")
  set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fopenmp")
  set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_EXE_SHARED_FLAGS} -fopenmp")
endif()

set(LIBRA_C_OPT_OPTIONS ${LIBRA_OPT_OPTIONS})
set(LIBRA_CXX_OPT_OPTIONS ${LIBRA_OPT_OPTIONS})

if("${CMAKE_BUILD_TYPE}" STREQUAL "Release")
  # For handling lto with static libraries on MSI
  set(CMAKE_AR "llvm-ar")
  set(CMAKE_NM "llvm-nm")
  set(CMAKE_RANLIB "llvm-ranlib")
endif()

set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fuse-ld=gold")
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -fuse-ld=gold")

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
      ${LIBRA_BASE_DIAG_CANDIDATES} -fdiagnostics-show-template-tree
      -Wno-c++98-compat -Wno-c++98-compat-pedantic -Weffc++ -Wno-c99-extensions)
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
    set(LIBRA_C_DIAG_OPTIONS ${LIBRA_C_DIAG_OPTIONS} ${flag})
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
    set(LIBRA_CXX_DIAG_OPTIONS ${LIBRA_CXX_DIAG_OPTIONS} ${flag})
  endif()
endforeach()

# ##############################################################################
# Checking Options
# ##############################################################################
set(MSAN_OPTIONS -fno-omit-frame-pointer -fno-optimize-sibling-calls
                 -fsanitize=memory,leak -fsanitize-memory-track-origins)
set(ASAN_OPTIONS -fno-omit-frame-pointer -fno-optimize-sibling-calls
                 -fsanitize=address)
set(SSAN_OPTIONS -fno-omit-frame-pointer -fstack-protector-all
                 -fstack-protector-strong)
set(UBSAN_OPTIONS
    -fno-omit-frame-pointer -fsanitize=undefined
    -fsanitize=float-divide-by-zero -fsanitize=unsigned-integer-overflow
    -fsanitize=local-bounds -fsanitize=nullability)
set(TSAN_OPTIONS -fno-omit-frame-pointer -fsanitize=thread)

if(NOT LIBRA_SAN)
  set(LIBRA_SAN ${LIBRA_SAN_DEFAULT})
endif()

set(LIBRA_SAN_OPTIONS)
set(LIBRA_SAN_MATCH NO)

if("${LIBRA_SAN}" MATCHES "MSAN")
  set(LIBRA_SAN_MATCH YES)
  set(LIBRA_SAN_OPTIONS "${LIBRA_SAN_OPTIONS} ${MSAN_OPTIONS}")
endif()

if("${LIBRA_SAN}" MATCHES "ASAN")
  set(LIBRA_SAN_MATCH YES)
  set(LIBRA_SAN_OPTIONS "${LIBRA_SAN_OPTIONS} ${ASAN_OPTIONS}")
endif()

if("${LIBRA_SAN}" MATCHES "SSAN")
  set(LIBRA_SAN_MATCH YES)
  set(LIBRA_SAN_OPTIONS "${LIBRA_SAN_OPTIONS} ${SSAN_OPTIONS}")
endif()

if("${LIBRA_SAN}" MATCHES "UBSAN")
  set(LIBRA_SAN_MATCH YES)
  set(LIBRA_SAN_OPTIONS "${LIBRA_SAN_OPTIONS} ${UBSAN_OPTIONS}")
endif()

if("${LIBRA_SAN}" MATCHES "TSAN")
  set(LIBRA_SAN_MATCH YES)
  set(LIBRA_SAN_OPTIONS "${LIBRA_SAN_OPTIONS} ${TSAN_OPTIONS}")
endif()

if(NOT ${LIBRA_SAN_MATCH} AND NOT "${LIBRA_SAN}" STREQUAL "NONE")
  libra_message(WARNING "Bad LIBRA_SAN setting ${LIBRA_SAN}: Must be subset of
{MSAN,ASAN,SSAN,UBSAN,TSAN} or set to NONE")
endif()

set(LIBRA_C_SAN_OPTIONS ${LIBRA_SAN_OPTIONS})
set(LIBRA_CXX_SAN_OPTIONS ${LIBRA_SAN_OPTIONS})

# ##############################################################################
# Profiling Options
# ##############################################################################
set(BASE_PGO_GEN_OPTIONS -fprofile-generate)
set(BASE_PGO_USE_OPTIONS -fprofile-use)

if("${LIBRA_PGO}" MATCHES "GEN")
  set(LIBRA_C_PGO_GEN_OPTIONS ${BASE_PGO_GEN_OPTIONS})
  set(LIBRA_CXX_PGO_GEN_OPTIONS ${BASE_PGO_GEN_OPTIONS})
endif()

if("${LIBRA_PGO}" MATCHES "USE")
  set(LIBRA_C_PGO_USE_OPTIONS ${BASE_PGO_USE_OPTIONS})
  set(LIBRA_CXX_PGO_USE_OPTIONS ${BASE_PGO_USE_OPTIONS})
endif()

# ##############################################################################
# Code Coverage Options
# ##############################################################################
set(BASE_CODE_COV_OPTIONS -fprofile-instr-generate -fcoverage-mapping
                          -fno-inline)

if(LIBRA_CODE_COV)
  set(LIBRA_C_CODE_COV_OPTIONS ${BASE_CODE_COV_OPTIONS})
  set(LIBRA_CXX_CODE_COV_OPTIONS ${BASE_CODE_COV_OPTIONS})
endif()

# ##############################################################################
# Valgrind Compatibility Options
# ##############################################################################
if(LIBRA_VALGRIND_BUILD)
  set(LIBRA_VALGRIND_BUILD_OPTIONS "-mno-sse3")
endif()

# ##############################################################################
# Stdlib options
# ##############################################################################
if(NOT LIBRA_STDLIB)
  set(LIBRA_STDLIB ${LIBRA_STDLIB_DEFAULT})
endif()

set(LIBRA_STDLIB_OPTIONS)
set(LIBRA_STDLIB_MATCH NO)

if("${LIBRA_STDLIB}" MATCHES "NONE")
  set(LIBRA_STDLIB_OPTIONS -nostdlib)
elseif("${LIBRA_STDLIB}" MATCHES "STDCXX")
  set(LIBRA_STDLIB_OPTIONS -stdlib=libstdc++)
elseif("${LIBRA_STDLIB}" MATCHES "CXX")
  set(LIBRA_STDLIB_OPTIONS -stdlib=libc++)
endif()

if(NOT ${LIBRA_STDLIB_MATCH} AND NOT "${LIBRA_STDLIB}" STREQUAL "UNDEFINED")
  libra_message(
    WARNING "Bad LIBRA_STDLIB setting ${LIBRA_STDLIB}: Must be one of
{NONE,STDCXX,CXX}")
endif()

# ##############################################################################
# Filtering build flags for versioning
#
# * No warnings, since they have no effect on the build
# * Include -D, -O -g flags
# * Include -m[arch|tune], -flto, anything with 'math' in in it
# * Include -fopenmp, anything with 'sanitize' in it.
# * Include anything with 'profile' or 'coverage' in it.
# * Include anything with 'stack', 'frame', or 'optimize' in it.
# ##############################################################################
set(LIBRA_BUILD_FLAGS_FILTER_REGEX
    "-[D]|[O]|[g][0-9+]|march|mtune|flto|math|rename|openmp|sanitize|profile|coverage|stack|frame|optimize.*"
)
