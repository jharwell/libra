################################################################################
# Debugging Options                                                            #
################################################################################
set(LIBRA_DEBUG_OPTIONS "-g2")

################################################################################
# Optimization Options                                                         #
################################################################################
if ("${CMAKE_BUILD_TYPE}" STREQUAL "DEV")
  set(LIBRA_OPT_LEVEL -O0)
elseif ("${CMAKE_BUILD_TYPE}" STREQUAL "DEVOPT")
  set(LIBRA_OPT_LEVEL -Og)
elseif ("${CMAKE_BUILD_TYPE}" STREQUAL "OPT")
  set(LIBRA_OPT_LEVEL -O2)
endif()

include(ProcessorCount)
ProcessorCount(N)

set(BASE_OPT_OPTIONS
  -march=native
  -mtune=native
  -flto=${N}
  -fno-stack-protector
  -ffast-math
  -ffinite-math-only
  -frename-registers
  )

if (LIBRA_OPENMP)
  set(BASE_OPT_OPTIONS ${BASE_OPT_OPTIONS}
    -fopenmp
    )
endif()

set(LIBRA_C_OPT_OPTIONS ${BASE_OPT_OPTIONS})
set(LIBRA_CXX_OPT_OPTIONS ${BASE_OPT_OPTIONS})

if ("${CMAKE_BUILD_TYPE}" STREQUAL "OPT")
  # Without turning off these warnings we get a bunch of spurious warnings about
  # the attributes, even though they are already present.
  set(CMAKE_SHARED_LINKER_FLAGS
    "${CMAKE_SHARED_LINKER_FLAGS}\
    -flto=${N}\
    -Wno-suggest-attribute=pure\
    -Wno-suggest-attribute=const\
    -Wno-suggest-attribute=cold")
endif()

################################################################################
# Diagnostic Options                                                           #
#                                                                              #
# Omitting the following, as they are either not useful, or give too many      #
# positives:                                                                   #
#                                                                              #
# -Wconversion                                                                 #
# -Wsign-conversion                                                            #
# -Wswitch-enum                                                                #
################################################################################
set(BASE_DIAG_OPTIONS
  -fdiagnostics-color=always
  -W
  -Wall
  -Wextra
  -ansi

  -Wmissing-include-dirs
  -Wno-unknown-pragmas
  -Wundef

  -Wmissing-declarations
  -Wredundant-decls
  -Wshadow

  -Wstrict-overflow=5
  -Wfloat-conversion
  -Wdouble-promotion
  -Wfloat-equal

  -Wdisabled-optimization
  -Wunsafe-loop-optimizations


  -Wswitch-default
  -Wswitch-unreachable

  -Wcast-align
  -Wcast-qual

  -Wpointer-arith
  -Wstack-protector
  -Wunreachable-code
  -Wmissing-format-attribute
  -Wunused-parameter
  -Wunused-const-variable=1
  -Wduplicated-branches
  -Wduplicated-cond

  -Wsuggest-attribute=pure
  -Wsuggest-attribute=const
  -Wsuggest-attribute=format
  -Wsuggest-attribute=cold
  -Wsuggest-final-types
  -Wsuggest-final-methods

  -Wformat=2
  -Winit-self
  -Wlogical-op
  )

set(LIBRA_C_DIAG_OPTIONS ${BASE_DIAG_OPTIONS}
  -Wstrict-prototypes
  -Wmissing-prototypes
  -Wbad-function-cast
  -Wnested-externs
  )

set(LIBRA_CXX_DIAG_OPTIONS ${BASE_DIAG_OPTIONS}
  -Weffc++
  -Wuseless-cast
  -Wextra-semi
  -Wunused-macros
  -Wsuggest-override
  -Wstrict-null-sentinel
  -Wclass-memaccess
  -Wsign-promo
  -Wnoexcept
  -Wold-style-cast
  -Woverloaded-virtual
  -Wctor-dtor-privacy
  -Wdelete-non-virtual-dtor
  )

################################################################################
# Checking Options                                                             #
################################################################################
set(MEM_CHECK_OPTIONS
  -fno-omit-frame-pointer
  -fsanitize=leak
  )
set(ADDR_CHECK_OPTIONS
  -fno-omit-frame-pointer
  -fsanitize=address
  )
set(STACK_CHECK_OPTIONS
  -fno-omit-frame-pointer
  -fstack-protector-all
  -fstack-protector-strong
  )
set(MISC_CHECK_OPTIONS
  -fno-omit-frame-pointer
  -fsanitize=undefined
  )

if ("${LIBRA_CHECKS}" MATCHES "MEM")
  set(LIBRA_C_CHECK_OPTIONS ${MEM_CHECK_OPTIONS})
  set(LIBRA_CXX_CHECK_OPTIONS ${MEM_CHECK_OPTIONS})
  endif()
if ("${LIBRA_CHECKS}" MATCHES "ADDR")
  set(LIBRA_C_CHECK_OPTIONS ${ADDR_CHECK_OPTIONS})
  set(LIBRA_CXX_CHECK_OPTIONS ${ADDR_CHECK_OPTIONS})
endif()
if ("${LIBRA_CHECKS}" MATCHES "STACK")
  set(LIBRA_C_CHECK_OPTIONS ${STACK_CHECK_OPTIONS})
  set(LIBRA_CXX_CHECK_OPTIONS ${STACK_CHECK_OPTIONS})
endif()
if ("${LIBRA_CHECKS}" MATCHES "MISC")
  set(LIBRA_C_CHECK_OPTIONS ${MISC_CHECK_OPTIONS})
  set(LIBRA_CXX_CHECK_OPTIONS ${MISC_CHECK_OPTIONS})
endif()


################################################################################
# Profiling Options                                                            #
################################################################################
set(BASE_PGO_GEN_OPTIONS
  -fprofile-generate
  )
set(BASE_PGO_USE_OPTIONS
  -fprofile-use
  )

if (LIBRA_PGO_GEN)
  set(LIBRA_C_PGO_GEN_OPTIONS ${BASE_PGO_GEN_OPTIONS})
  set(LIBRA_CXX_PGO_GEN_OPTIONS ${BASE_PGO_GEN_OPTIONS})
endif()

if (LIBRA_PGO_USE)
  set(LIBRA_C_PGO_USE_OPTIONS ${BASE_PGO_USE_OPTIONS})
  set(LIBRA_CXX_PGO_USE_OPTIONS ${BASE_PGO_USE_OPTIONS})
endif()
