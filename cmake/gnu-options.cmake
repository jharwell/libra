################################################################################
# Debugging Options                                                            #
################################################################################
set(LIBRA_DEBUG_OPTIONS "-ggdb3 -gdwarf -g3")

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

set(BASE_OPT_OPTIONS
  -march=native
  -mtune=native
  -flto
  -fno-stack-protector
  -ffast-math
  -ffinite-math-only
  -frename-registers
  )

if (LIBRA_OPENMP)
  set(BASE_OPT_OPTIONS ${BASE_OPT_OPTIONS}
    -fopenmp
    -D_GLIBCXX_PARALLEL
    )
endif()

set(LIBRA_C_OPT_OPTIONS ${BASE_OPT_OPTIONS})
set(LIBRA_CXX_OPT_OPTIONS ${BASE_OPT_OPTIONS})

if ("${CMAKE_BUILD_TYPE}" STREQUAL "OPT")
  set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -flto")
endif()

################################################################################
# Diagnostic Options                                                           #
################################################################################
set(BASE_DIAG_OPTIONS
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
  -Wsuggest-attribute=malloc
  -Wsuggest-final-types
  -Wsuggest-final-methods
  -Wmissing-attributes
  -Wfloat-equal
  -Wshadow
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
  -Wunused-macros
  -Wfloat-conversion
  -Wnarrowing
  -Wmultistatement-macros
  )

set(LIBRA_C_DIAG_OPTIONS ${BASE_DIAG_OPTIONS}
  -Wstrict-prototypes
  -Wmissing-prototypes
  -Wbad-function-cast
  -Wnested-externs
  )

set(LIBRA_CXX_DIAG_OPTIONS ${BASE_DIAG_OPTIONS}
  -Weffc++
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

if ("${WITH_CHECKS}" MATCHES "MEM")
  set(LIBRA_C_CHECK_OPTIONS ${MEM_CHECK_OPTIONS})
  set(LIBRA_CXX_CHECK_OPTIONS ${MEM_CHECK_OPTIONS})
  endif()
if ("${WITH_CHECKS}" MATCHES "ADDR")
  set(LIBRA_C_CHECK_OPTIONS ${ADDR_CHECK_OPTIONS})
  set(LIBRA_CXX_CHECK_OPTIONS ${ADDR_CHECK_OPTIONS})
endif()
if ("${WITH_CHECKS}" MATCHES "STACK")
  set(LIBRA_C_CHECK_OPTIONS ${STACK_CHECK_OPTIONS})
  set(LIBRA_CXX_CHECK_OPTIONS ${STACK_CHECK_OPTIONS})
endif()
if ("${WITH_CHECKS}" MATCHES "MISC")
  set(LIBRA_C_CHECK_OPTIONS ${MISC_CHECK_OPTIONS})
  set(LIBRA_CXX_CHECK_OPTIONS ${MISC_CHECK_OPTIONS})
endif()


################################################################################
# Reporting Options                                                            #
################################################################################
set(BASE_REPORT_OPTIONS
  -fopt-info-optimized-optall
  -fprofile-arcs
  -ftest-coverage
  )

if (WITH_REPORTS)
  set(LIBRA_C_REPORT_OPTIONS ${BASE_REPORT_OPTIONS})
  set(LIBRA_CXX_REPORT_OPTIONS ${BASE_REPORT_OPTIONS})
endif()
