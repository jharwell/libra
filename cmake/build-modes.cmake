################################################################################
# Development Mode                                                             #
################################################################################
set(DEV_CFLAGS "")
foreach(arg
    ${LIBRA_OPT_LEVEL}
    ${LIBRA_DEBUG_OPTIONS}
    ${LIBRA_C_DIAG_OPTIONS}
    ${LIBRA_C_PARALLEL_OPTIONS}
    ${LIBRA_C_CHECK_OPTIONS}
    ${LIBRA_C_REPORT_OPTIONS}
    ${LIBRA_C_CHECK_OPTIONS}
    ${LIBRA_C_PGO_GEN_OPTIONS}
    ${LIBRA_C_PGO_USE_OPTIONS}
    ${CC_DEV_DEFS})
  set(DEV_CFLAGS "${DEV_CFLAGS} ${arg}")
endforeach(arg)

set(CMAKE_C_FLAGS_DEV ${DEV_CFLAGS} CACHE STRING
  "Flags used by the C compiler during development builds."
  FORCE)

set(DEV_CXXFLAGS "")
foreach(arg
    ${LIBRA_OPT_LEVEL}
    ${LIBRA_DEBUG_OPTIONS}
    ${LIBRA_CXX_DIAG_OPTIONS}
    ${LIBRA_CXX_PARALLEL_OPTIONS}
    ${LIBRA_CXX_CHECK_OPTIONS}
    ${LIBRA_CXX_REPORT_OPTIONS}
    ${LIBRA_CXX_CHECK_OPTIONS}
    ${LIBRA_CXX_PGO_GEN_OPTIONS}
    ${LIBRA_CXX_PGO_USE_OPTIONS}
    ${CC_DEV_DEFS})
  set(DEV_CXXFLAGS "${DEV_CXXFLAGS} ${arg}")
endforeach(arg)

set(CMAKE_CXX_FLAGS_DEV ${DEV_CXXFLAGS} CACHE STRING
  "Flags used by the CXX compiler during development builds."
  FORCE)

################################################################################
# Development Optimized Mode                                                   #
################################################################################
set(DEVOPT_CFLAGS "")
foreach(arg
    ${LIBRA_OPT_LEVEL}
    ${LIBRA_DEBUG_OPTIONS}
    ${LIBRA_C_DIAG_OPTIONS}
    ${LIBRA_C_PARALLEL_OPTIONS}
    ${LIBRA_C_CHECK_OPTIONS}
    ${LIBRA_C_REPORT_OPTIONS}
    ${LIBRA_C_CHECK_OPTIONS}
    ${LIBRA_C_PGO_GEN_OPTIONS}
    ${LIBRA_C_PGO_USE_OPTIONS}
    ${CC_DEVOPT_DEFS})
  set(DEVOPT_CFLAGS "${DEVOPT_CFLAGS} ${arg}")
endforeach(arg)

set(CMAKE_C_FLAGS_DEVOPT ${DEVOPT_CFLAGS} CACHE STRING
  "Flags used by the C compiler during devopt builds."
  FORCE)

set(DEVOPT_CXXFLAGS "")
foreach(arg
    ${LIBRA_OPT_LEVEL}
    ${LIBRA_DEBUG_OPTIONS}
    ${LIBRA_CXX_DIAG_OPTIONS}
    ${LIBRA_CXX_PARALLEL_OPTIONS}
    ${LIBRA_CXX_CHECK_OPTIONS}
    ${LIBRA_CXX_REPORT_OPTIONS}
    ${LIBRA_CXX_CHECK_OPTIONS}
    ${LIBRA_CXX_PGO_GEN_OPTIONS}
    ${LIBRA_CXX_PGO_USE_OPTIONS}
    ${CC_DEVOPT_DEFS})
  set(DEVOPT_CXXFLAGS "${DEVOPT_CXXFLAGS} ${arg}")
endforeach(arg)

set(CMAKE_CXX_FLAGS_DEVOPT ${DEVOPT_CXXFLAGS} CACHE STRING
  "Flags used by the CXX compiler during devopt builds."
  FORCE)

################################################################################
# Optimized Mode                                                               #
################################################################################
set(OPT_CFLAGS "")
foreach(arg
    ${LIBRA_OPT_LEVEL}
    ${LIBRA_DEBUG_OPTIONS}
    ${LIBRA_C_OPT_OPTIONS}
    ${LIBRA_C_DIAG_OPTIONS}
    ${LIBRA_C_PARALLEL_OPTIONS}
    ${LIBRA_C_CHECK_OPTIONS}
    ${LIBRA_C_REPORT_OPTIONS}
    ${LIBRA_C_CHECK_OPTIONS}
    ${LIBRA_C_PGO_GEN_OPTIONS}
    ${LIBRA_C_PGO_USE_OPTIONS}
    ${CC_OPT_DEFS})
  set(OPT_CFLAGS "${OPT_CFLAGS} ${arg}")
endforeach(arg)

set(CMAKE_C_FLAGS_OPT ${OPT_CFLAGS} CACHE STRING
  "Flags used by the C compiler during optimized builds."
  FORCE)

set(OPT_CXXFLAGS "")
foreach(arg
    ${LIBRA_OPT_LEVEL}
    ${LIBRA_DEBUG_OPTIONS}
    ${LIBRA_CXX_OPT_OPTIONS}
    ${LIBRA_CXX_DIAG_OPTIONS}
    ${LIBRA_CXX_PARALLEL_OPTIONS}
    ${LIBRA_CXX_CHECK_OPTIONS}
    ${LIBRA_CXX_REPORT_OPTIONS}
    ${LIBRA_CXX_CHECK_OPTIONS}
    ${LIBRA_CXX_PGO_GEN_OPTIONS}
    ${LIBRA_CXX_PGO_USE_OPTIONS}
    ${CC_OPT_DEFS})
  set(OPT_CXXFLAGS "${OPT_CXXFLAGS} ${arg}")
endforeach(arg)
set(CMAKE_CXX_FLAGS_OPT ${OPT_CXXFLAGS} CACHE STRING
  "Flags used by the C++ compiler during optimized builds."
  FORCE)

# Update the documentation string of CMAKE_BUILD_TYPE for GUIs
set( CMAKE_BUILD_TYPE "${CMAKE_BUILD_TYPE}" CACHE STRING
  "Choose the type of build, options are: DEV DEVOPT OPT."
      FORCE )
