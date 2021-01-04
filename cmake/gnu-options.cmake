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
  -fno-unsafe-math-optimizations
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
  # For handling lto with static libraries on MSI
  set(CMAKE_AR "gcc-ar")
  set(CMAKE_NM "gcc-nm")
  set(CMAKE_RANLIB "gcc-ranlib")

  # Without turning off these warnings we get a bunch of spurious warnings
  # about the attributes, even though they are already present.
  set(CMAKE_SHARED_LINKER_FLAGS
    "${CMAKE_SHARED_LINKER_FLAGS}\
    -Wno-suggest-attribute=pure\
    -Wno-suggest-attribute=const\
    -Wno-suggest-attribute=cold\
    -flto=${N}")
endif()



################################################################################
# Diagnostic Options                                                           #
################################################################################
set(BASE_DIAG_OPTIONS
  -fdiagnostics-color=always
  -W
  -Wall
  -Wextra
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
  -Wstrict-overflow
  -Wswitch-default
  -Wundef
  -ansi
  -Wpointer-arith
  -Wno-unknown-pragmas
  -Wstack-protector
  -Wunreachable-code
  -Wmissing-format-attribute
  -Wfloat-conversion
  -Wnarrowing
  -Wmultistatement-macros
  )

set(LIBRA_C_DIAG_OPTIONS ${BASE_DIAG_OPTIONS}
  -Wstrict-prototypes
  -Wmissing-prototypes
  -Wbad-function-cast
  -Wnested-externs
  -Wnull-dereference
  )

set(LIBRA_CXX_DIAG_OPTIONS ${BASE_DIAG_OPTIONS}
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
  -Wuseless-cast
  )

################################################################################
# Checking Options                                                             #
################################################################################
set(MSAN_OPTIONS
  -fno-omit-frame-pointer
  -fno-optimize-sibling-calls
  -fsanitize=leak
  )
set(ASAN_OPTIONS
  -fno-omit-frame-pointer
  -fno-optimize-sibling-calls
  -fsanitize=address
  -fsanitize-address-use-after-scope
  -fsanitize=pointer-compare
  -fsanitize=pointer-subtract
  )
set(SSAN_OPTIONS
  -fno-omit-frame-pointer
  -fstack-protector-all
  -fstack-protector-strong
  )
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
  )
set(TSAN_OPTIONS
  -fno-omit-frame-pointer
  -fsanitize=thread
  )

set(BASE_SAN_OPTIONS)
if ("${LIBRA_SAN}" MATCHES "MSAN")
  set(BASE_SAN_OPTIONS "${BASE_SAN_OPTIONS} ${MSAN_OPTIONS}")
endif()

if ("${LIBRA_SAN}" MATCHES "ASAN")
  set(BASE_SAN_OPTIONS "${BASE_SAN_OPTIONS} ${ASAN_OPTIONS}")
endif()

if ("${LIBRA_SAN}" MATCHES "SSAN")
  set(BASE_SAN_OPTIONS "${BASE_SAN_OPTIONS} ${SSAN_OPTIONS}")
endif()

if ("${LIBRA_SAN}" MATCHES "UBSAN")
  set(BASE_SAN_OPTIONS "${BASE_SAN_OPTIONS} ${UBSAN_OPTIONS}")
endif()

if ("${LIBRA_SAN}" MATCHES "TSAN")
  set(BASE_SAN_OPTIONS "${BASE_SAN_OPTIONS} ${TSAN_OPTIONS}")
endif()

set(LIBRA_C_SAN_OPTIONS ${BASE_SAN_OPTIONS})
set(LIBRA_CXX_SAN_OPTIONS ${BASE_SAN_OPTIONS})

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

################################################################################
# Code Coverage Options                                                        #
################################################################################
set(BASE_CODE_COV_OPTIONS
  # synonym for "-fprofile-arcs -ftest-coverage" when compiling and "-lgcov"
  # when linking
  --coverage
  )

if (LIBRA_CODE_COV)
  set(LIBRA_C_CODE_COV_OPTIONS ${BASE_CODE_COV_OPTIONS})
  set(LIBRA_CXX_CODE_COV_OPTIONS ${BASE_CODE_COV_OPTIONS})
endif()
