################################################################################
# Diagnostic Options                                                           #
################################################################################
set(BASE_DIAG_OPTIONS
  -W
  -Wall
  -Wextra
  -fmessage-length=0
  -fdiagnostics-color=always
  -Wsuggest-attribute=pure
  -Wsuggest-attribute=const
  -Wsuggest-attribute=noreturn
  -Wfloat-equal
  -Wshadow
  -Wcast-align
  -Wcast-qual
  -Wdisabled-optimization
  -Wformat=2
  -Winit-self
  -Wlogical-op
  -Wmissing-declarations
  -Wmissing-include-dirs
  -Wredundant-decls
  -Wstrict-overflow
  -Wswitch-default
  -Wundef
  -g
  )

set(C_DIAG_OPTIONS ${BASE_DIAG_OPTIONS}
  -Wstrict-prototypes
  -Wmissing-prototypes
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
  )

################################################################################
# Checking Options                                                             #
################################################################################
set(BASE_CHECK_OPTIONS
  -fstack-protector-all
  -fstack-protector-strong
  -fsanitize=address,undefined
  -O1
  -fno-omit-frame-pointer
  )

if (WITH_CHECKS)
  set(C_CHECK_OPTIONS ${BASE_CHECK_OPTIONS})
  set(CXX_CHECK_OPTIONS ${BASE_CHECK_OPTIONS}
    -fsanitize=vptr
    )
endif()

################################################################################
# Optimization Options                                                         #
################################################################################
set(BASE_OPT_OPTIONS
  -O3
  -fno-trapping-math
  -fno-signed-zeros
  -frename-registers
  -funroll-loops
  -march=native
  -mtune=native
  -flto
  )

set(C_OPT_OPTIONS ${BASE_OPT_OPTIONS})
set(CXX_OPT_OPTIONS ${BASE_OPT_OPTIONS})

if ("${CMAKE_BUILD_TYPE}" STREQUAL "OPT")
  set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -flto")
  set(CMAKE_AR "gcc-ar")
  set(CMAKE_RANLIB "gcc-ranlib")
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
