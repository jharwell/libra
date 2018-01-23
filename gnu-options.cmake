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
  -g
  )

set(C_DIAG_OPTIONS ${BASE_DIAG_OPTIONS}
  -Wstrict-prototypes
  -Wmissing-prototypes
  )

set(CXX_DIAG_OPTIONS ${BASE_DIAG_OPTIONS}
  -Weffc++
  -Wsuggest-override
  )
################################################################################
# Checking Options                                                             #
################################################################################
set(BASE_CHECK_OPTIONS
  -fstack-protector-all
  -fstack-protector-strong`1`
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
  -Winline
  -DNDEBUG
  -flto
  )

set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -flto")
set(C_OPT_OPTIONS ${BASE_OPT_OPTIONS})
set(CXX_OPT_OPTIONS ${BASE_OPT_OPTIONS})

################################################################################
# Reporting Options                                                            #
################################################################################
set(REPORT_OPTIONS
  -fopt-info-optimized-optall=$(REPORTDIR)/$(patsubst %.o,%.rprt,$(notdir $@))
  )
