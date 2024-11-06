#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#

# ##############################################################################
# Custom messaging
# ##############################################################################
include(libra/messaging)

# ##############################################################################
# Language Standard
# ##############################################################################
include(libra/compile/standard)

# ##############################################################################
# Debugging Options
# ##############################################################################
set(LIBRA_DEBUG_OPTIONS "-g2")

# ##############################################################################
# Optimization Options
# ##############################################################################
if("${CMAKE_BUILD_TYPE}" STREQUAL "DEV")
  set(LIBRA_OPT_LEVEL -O0)
elseif("${CMAKE_BUILD_TYPE}" STREQUAL "DEVOPT")
  set(LIBRA_OPT_LEVEL -Og)
elseif("${CMAKE_BUILD_TYPE}" STREQUAL "OPT")
  set(LIBRA_OPT_LEVEL -O2)
else()
  # Standard Cmake build types
endif()

set(BASE_OPT_OPTIONS
    -march=native
    -mtune=native
    -fno-stack-protector
    # 2023/6/29: Disable because it causes issues in RCSW unit tests. If in the
    # future I want/need to enable these again to get even more speed, I could
    # add another opt level/flag controlling it. -ffast-math
    # -fno-unsafe-math-optimizations
)

if(LIBRA_LTO)
  set(BASE_OPT_OPTIONS ${BASE_OPT_OPTIONS} -flto)
  set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_SHARED_FLAGS} -flto")
  set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_SHARED_FLAGS} -flto")
endif()

if(LIBRA_MT)
  set(BASE_OPT_OPTIONS ${BASE_OPT_OPTIONS} -fopenmp)
  set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fopenmp")
  set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_EXE_SHARED_FLAGS} -fopenmp")
endif()

set(LIBRA_C_OPT_OPTIONS ${BASE_OPT_OPTIONS})
set(LIBRA_CXX_OPT_OPTIONS ${BASE_OPT_OPTIONS})

if("${CMAKE_BUILD_TYPE}" STREQUAL "OPT")
  # For handling lto with static libraries on MSI
  set(CMAKE_AR "llvm-ar")
  set(CMAKE_NM "llvm-nm")
  set(CMAKE_RANLIB "llvm-ranlib")
endif()

set(CMAKE_EXE_LINKER_FLAGS
    "${CMAKE_EXE_LINKER_FLAGS} ${LIBRA_DEBUG_OPTS} -fuse-ld=gold")
set(CMAKE_SHARED_LINKER_FLAGS
    "${CMAKE_SHARED_LINKER_FLAGS} ${LIBRA_DEBUG_OPTS} -fuse-ld=gold")

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

set(LIBRA_C_DIAG_CANDIDATES ${LIBRA_BASE_DIAG_CANDIDATES})

set(LIBRA_CXX_DIAG_CANDIDATES
    ${LIBRA_BASE_DIAG_CANDIDATES} -fdiagnostics-show-template-tree
    -Wno-c++98-compat -Wno-c++98-compat-pedantic -Weffc++ -Wno-c99-extensions)

set(LIBRA_C_DIAG_OPTIONS)
foreach(flag ${LIBRA_C_DIAG_CANDIDATES})
  # Options of the form -foption=value confuse the cmake flag checker and result
  # in multiple flags being checked on each invocation. So change the variable
  # name the result of the check is assigned to.
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
  # name the result of the check is assigned to.
  string(REGEX REPLACE "[-=]" "_" flag ${flag})

  # A project can be C/C++ only
  if(CMAKE_CXX_COMPILER_LOADED)
    check_cxx_compiler_flag(${flag} LIBRA_CXX_COMPILER_SUPPORTS_${flag})
  endif()

  if(LIBRA_CXX_COMPILER_SUPPORTS_${flag})
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

set(LIBRA_SAN_DEFAULT "NONE")

if(NOT LIBRA_SAN)
  set(LIBRA_SAN ${LIBRA_SAN_DEFAULT})
endif()

# Only enable sanitizers by default for DEV builds and if they are not specified
# on the cmdline
if("${CMAKE_BUILD_TYPE}" STREQUAL "DEV" AND (NOT DEFINED LIBRA_SAN))
  set(LIBRA_SAN ${LIBRA_SAN_DEV_DEFAULT})
elseif("${CMAKE_BUILD_TYPE}" MATCHES "OPT" AND (NOT DEFINED LIBRA_SAN))
  set(LIBRA_SAN ${LIBRA_SAN_OPT_DEFAULT})
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
set(BASE_CODE_COV_OPTIONS -fprofile-instr-generate -fcoverage-mapping)

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
  set(LIBRA_STDLIB_OPTIONS "-nostdlib")
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
