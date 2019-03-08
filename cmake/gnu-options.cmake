################################################################################
# Optimization Options                                                         #
################################################################################
if ("${CMAKE_BUILD_TYPE}" STREQUAL "DEV")
  set(OPT_LEVEL -O0 -ggdb)
elseif ("${CMAKE_BUILD_TYPE}" STREQUAL "DEVOPT")
  set(OPT_LEVEL -Og -ggdb)
elseif ("${CMAKE_BUILD_TYPE}" STREQUAL "OPT")
  set(OPT_LEVEL -O2 -ggdb)
endif()

set(BASE_OPT_OPTIONS
  -march=native
  -mtune=native
  -flto
  )

if (WITH_OPENMP)
  set(BASE_OPT_OPTIONS ${BASE_OPT_OPTIONS}
    -fopenmp
    -D_GLIBCXX_PARALLEL
    )
endif()

set(C_OPT_OPTIONS ${BASE_OPT_OPTIONS})
set(CXX_OPT_OPTIONS ${BASE_OPT_OPTIONS})

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
  -Wsuggest-attribute=noreturn
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
  -Wmissing-noreturn
  -Wmissing-format-attribute
  -Wunused-macros
  )

set(C_DIAG_OPTIONS ${BASE_DIAG_OPTIONS}
  -Wstrict-prototypes
  -Wmissing-prototypes
  -Wbad-function-cast
  -Wnested-externs
  )

set(CXX_DIAG_OPTIONS ${BASE_DIAG_OPTIONS}
  -Weffc++
  -Wsuggest-override
  -Wstrict-null-sentinel
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
  set(C_CHECK_OPTIONS ${MEM_CHECK_OPTIONS})
  set(CXX_CHECK_OPTIONS ${MEM_CHECK_OPTIONS})
  endif()
if ("${WITH_CHECKS}" MATCHES "ADDR")
  set(C_CHECK_OPTIONS ${ADDR_CHECK_OPTIONS})
  set(CXX_CHECK_OPTIONS ${ADDR_CHECK_OPTIONS})
endif()
if ("${WITH_CHECKS}" MATCHES "STACK")
  set(C_CHECK_OPTIONS ${STACK_CHECK_OPTIONS})
  set(CXX_CHECK_OPTIONS ${STACK_CHECK_OPTIONS})
endif()
if ("${WITH_CHECKS}" MATCHES "MISC")
  set(C_CHECK_OPTIONS ${MISC_CHECK_OPTIONS})
  set(CXX_CHECK_OPTIONS ${MISC_CHECK_OPTIONS})
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
  set(C_REPORT_OPTIONS ${BASE_REPORT_OPTIONS})
  set(CXX_REPORT_OPTIONS ${BASE_REPORT_OPTIONS})
endif()
