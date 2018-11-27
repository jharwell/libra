################################################################################
# Development Mode                                                             #
################################################################################
set(DEV_CFLAGS "")
foreach(arg ${OPT_LEVEL} ${C_DIAG_OPTIONS} ${C_PARALLEL_OPTIONS} ${C_CHECK_OPTIONS} ${C_REPORT_OPTIONS} ${C_CHECK_OPTIONS} ${CC_DEV_DEFS})
  set(DEV_CFLAGS "${DEV_CFLAGS} ${arg}")
endforeach(arg)

set(CMAKE_C_FLAGS_DEV ${DEV_CFLAGS} CACHE string
  "Flags used by the C compiler during development builds."
  FORCE)

set(DEV_CXXFLAGS "")
foreach(arg ${OPT_LEVEL} ${CXX_DIAG_OPTIONS} ${CXX_PARALLEL_OPTIONS} ${CXX_CHECK_OPTIONS} ${CXX_REPORT_OPTIONS} ${CC_DEV_DEFS})
  set(DEV_CXXFLAGS "${DEV_CXXFLAGS} ${arg}")
endforeach(arg)

set(CMAKE_CXX_FLAGS_DEV ${DEV_CXXFLAGS} CACHE string
  "Flags used by the CXX compiler during development builds."
  FORCE)

################################################################################
# Development Optimized Mode                                                   #
################################################################################
set(DEVOPT_CFLAGS "")
foreach(arg ${OPT_LEVEL} ${C_DIAG_OPTIONS} ${C_PARALLEL_OPTIONS} ${C_CHECK_OPTIONS} ${C_REPORT_OPTIONS} ${C_CHECK_OPTIONS} ${CC_DEVOPT_DEFS})
  set(DEVOPT_CFLAGS "${DEVOPT_CFLAGS} ${arg}")
endforeach(arg)

set(CMAKE_C_FLAGS_DEVOPT ${DEVOPT_CFLAGS} CACHE string
  "Flags used by the C compiler during devopt builds."
  FORCE)

set(DEVOPT_CXXFLAGS "")
foreach(arg ${OPT_LEVEL} ${CXX_DIAG_OPTIONS} ${CXX_PARALLEL_OPTIONS} ${CXX_CHECK_OPTIONS} ${CXX_REPORT_OPTIONS} ${CC_DEVOPT_DEFS})
  set(DEVOPT_CXXFLAGS "${DEVOPT_CXXFLAGS} ${arg}")
endforeach(arg)

set(CMAKE_CXX_FLAGS_DEVOPT ${DEVOPT_CXXFLAGS} CACHE string
  "Flags used by the CXX compiler during devopt builds."
  FORCE)

################################################################################
# Optimized Mode                                                               #
################################################################################
set(OPT_CFLAGS "")
foreach(arg ${OPT_LEVEL} ${C_OPT_OPTIONS} ${C_DIAG_OPTIONS} ${C_PARALLEL_OPTIONS} ${C_REPORT_OPTIONS} ${C_CHECK_OPTIONS} ${CC_OPT_DEFS})
  set(OPT_CFLAGS "${OPT_CFLAGS} ${arg}")
endforeach(arg)

set(CMAKE_C_FLAGS_OPT ${OPT_CFLAGS} CACHE string
  "Flags used by the C compiler during optimized builds."
  FORCE)

set(OPT_CXXFLAGS "")
foreach(arg ${OPT_LEVEL} ${CXX_OPT_OPTIONS} ${CXX_DIAG_OPTIONS} ${CXX_PARALLEL_OPTIONS} ${CXX_REPORT_OPTIONS} ${CXX_CHECK_OPTIONS} ${CC_OPT_DEFS})
  set(OPT_CXXFLAGS "${OPT_CXXFLAGS} ${arg}")
endforeach(arg)
set(CMAKE_CXX_FLAGS_OPT ${OPT_CXXFLAGS} CACHE string
  "Flags used by the C++ compiler during optimized builds."
  FORCE)

# Update the documentation string of CMAKE_BUILD_TYPE for GUIs
set( CMAKE_BUILD_TYPE "${CMAKE_BUILD_TYPE}" CACHE STRING
  "Choose the type of build, options are: DEV DEVOPT OPT."
      FORCE )
