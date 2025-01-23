#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#
# ##############################################################################
# Language Standard
# ##############################################################################
include(libra/compile/standard)
include(libra/messaging)

# ##############################################################################
# Debugging Options
# ##############################################################################
if(LIBRA_NO_DEBUG_INFO)
  set(LIBRA_DEBUG_OPTIONS "-g0")
else()
  set(LIBRA_DEBUG_OPTIONS "-g2")
endif()

# ##############################################################################
# Fortifying Options
# ##############################################################################
set(LIBRA_FORTIFY_OPTIONS)
set(LIBRA_FORTIFY_MATCH NO)

if(NOT LIBRA_FORTIFY)
  set(LIBRA_FORTIFY "NONE")
endif()

if(NOT LIBRA_FORTIFY MATCHES "NONE")
  set(LIBRA_LTO ON)
endif()

# -fstack-protector-{strong,all} are also options which could be swapped
# in/added eventually.
set(LIBRA_FORTIFY_STACK -fstack-protector)
set(LIBRA_FORTIFY_SOURCE -D_FORTIFY_SOURCE=2)
set(LIBRA_FORTIFY_GOT -Wl,-z,relro -Wl,-z,now)
set(LIBRA_FORTIFY_FORMAT -Wformat-security -Werror=format=2)

if("${LIBRA_FORTIFY}" MATCHES "STACK")
  set(LIBRA_FORTIFY_MATCH YES)
  set(LIBRA_FORTIFY_OPTIONS "${LIBRA_FORTIFY_STACK}")
endif()

if("${LIBRA_FORTIFY}" MATCHES "SOURCE")
  set(LIBRA_FORTIFY_MATCH YES)
  set(LIBRA_FORTIFY_OPTIONS "${LIBRA_FORTIFY_SOURCE}")
endif()

if("${LIBRA_FORTIFY}" MATCHES "GOT")
  set(LIBRA_FORTIFY_MATCH YES)
  set(LIBRA_FORTIFY_OPTIONS "${LIBRA_FORTIFY_GOT}")
endif()

if("${LIBRA_FORTIFY}" MATCHES "FORMAT")
  set(LIBRA_FORTIFY_MATCH YES)
  set(LIBRA_FORTIFY_OPTIONS "${LIBRA_FORTIFY_FORMAT}")
endif()

if("${LIBRA_FORTIFY}" MATCHES "ALL")
  set(LIBRA_FORTIFY_MATCH YES)
  set(LIBRA_FORTIFY_OPTIONS
      "${LIBRA_FORTIFY_STACK} ${LIBRA_FORTIFY_SOURCE}  ${LIBRA_FORTIFY_GOT} ${LIBRA_FORTIFY_FORMAT}"
  )
endif()

if(NOT LIBRA_FORTIFY_MATCH AND NOT "${LIBRA_FORTIFY}" STREQUAL "NONE")
  libra_message(
    WARNING "Bad LIBRA_FORTIFY setting ${LIBRA_FORTIFY}: Must be subset \
of {STACK,SOURCE,GOT,FORMAT,ALL} or set to NONE for gcc")
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
  set(LIBRA_OPT_LEVEL -O0)
elseif("${CMAKE_BUILD_TYPE}" STREQUAL "Release")
  set(LIBRA_OPT_LEVEL -O2)
else()
  message(
    FATAL_ERROR
      "GNU compiler plugin is only configured for {Debug, Release} builds")
endif()

include(ProcessorCount)
ProcessorCount(N)

set(BASE_OPT_OPTIONS
    -march=native
    -mtune=native
    # 2023/6/29: Disable because it causes issues in RCSW unit tests. If in the
    # future I want/need to enable these again to get even more speed, I could
    # add another opt level/flag controlling it.
    #
    # -ffast-math -fno-unsafe-math-optimizations
    -frename-registers)

if(LIBRA_MT)
  set(BASE_OPT_OPTIONS ${BASE_OPT_OPTIONS} -fopenmp)
  set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_EXE_SHARED_FLAGS} -fopenmp")
  set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fopenmp")
endif()

set(LIBRA_C_OPT_OPTIONS ${BASE_OPT_OPTIONS})
set(LIBRA_CXX_OPT_OPTIONS ${BASE_OPT_OPTIONS})

if("${CMAKE_BUILD_TYPE}" STREQUAL "Release")
  # For handling lto with static libraries on MSI
  set(CMAKE_AR "gcc-ar")
  set(CMAKE_NM "gcc-nm")
  set(CMAKE_RANLIB "gcc-ranlib")

  # Without turning off these warnings we get a bunch of spurious warnings about
  # the attributes, even though they are already present.
  set(CMAKE_SHARED_LINKER_FLAGS
      "${CMAKE_SHARED_LINKER_FLAGS}\
    -Wno-suggest-attribute=pure\
    -Wno-suggest-attribute=const\
    -Wno-suggest-attribute=cold")
endif()

set(CMAKE_EXE_LINKER_FLAGS
    "${CMAKE_EXE_LINKER_FLAGS} ${LIBRA_DEBUG_OPTS} -fuse-ld=gold")
set(CMAKE_SHARED_LINKER_FLAGS
    "${CMAKE_SHARED_LINKER_FLAGS} ${LIBRA_DEBUG_OPTS} -fuse-ld=gold")

# ##############################################################################
# Diagnostic Options
# ##############################################################################
set(LIBRA_BASE_DIAG_CANDIDATES
    -fdiagnostics-color=always
    -W
    -Wall
    -Wextra
    -Wpedantic
    -Wconversion
    -Wcast-align
    -Wcast-qual
    -Wdisabled-optimization
    -Wformat=2
    -Winit-self
    -Wlogical-op
    -Wmissing-declarations
    -Wmissing-include-dirs
    -Wstrict-overflow=5
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
      ${LIBRA_BASE_DIAG_CANDIDATES} -Wstrict-prototypes -Wmissing-prototypes
      -Wbad-function-cast -Wnested-externs -Wnull-dereference)
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
      -Wuseless-cast)
else()
  libra_message(STATUS "Using provided diagnostic candidates for C++ compiler")
endif()

set(LIBRA_C_DIAG_OPTIONS)
foreach(flag ${LIBRA_C_DIAG_CANDIDATES})
  # Options of the form -foption=value confuse the cmake flag checker and result
  # in multiple flags being checked on each invocation. So change the variable
  # name that the result of the check is assigned to.
  string(REGEX REPLACE "[-=]" "_" checked_flag_output ${flag})

  # A project can be C/C++ only
  if(CMAKE_C_COMPILER_LOADED)
    check_c_compiler_flag(${flag}
                          LIBRA_C_COMPILER_SUPPORTS_${checked_flag_output})
  endif()

  if(LIBRA_C_COMPILER_SUPPORTS_${checked_flag_output})
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

set(LIBRA_SAN_DEFAULT "NONE")

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
  libra_message(WARNING "Bad LIBRA_SAN setting ${LIBRA_SAN}: Must be subset \
of {MSAN,ASAN,SSAN,UBSAN,TSAN} or set to NONE")
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
set(BASE_CODE_COV_OPTIONS
    # Alias for "-fprofile-arcs -ftest-coverage" when compiling and "-lgcov"
    # when linking
    --coverage)

if(LIBRA_CODE_COV)
  set(LIBRA_C_CODE_COV_OPTIONS ${BASE_CODE_COV_OPTIONS})
  set(LIBRA_CXX_CODE_COV_OPTIONS ${BASE_CODE_COV_OPTIONS})
  set(CMAKE_EXE_LINKER_FLAGS
      "${CMAKE_EXE_LINKER_FLAGS} ${LIBRA_C_CODE_COV_OPTIONS}")
  set(CMAKE_SHARED_LINKER_FLAGS
      "${CMAKE_SHARED_LINKER_FLAGS} ${LIBRA_CXX_CODE_COV_OPTIONS}")
endif()

# ##############################################################################
# Valgrind Compatibility Options
# ##############################################################################
if(LIBRA_VALGRIND_COMPAT)
  set(LIBRA_VALGRIND_COMPAT_OPTIONS "-mno-sse3")
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
