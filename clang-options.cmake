################################################################################
# Diagnostic Options                                                           #
################################################################################
set(BASE_DIAG_OPTIONS
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
  -fcomment-block-commands=internal,endinternal
  -g
  )

set(C_DIAG_OPTIONS ${BASE_DIAG_OPTIONS})
set(CXX_DIAG_OPTIONS ${BASE_DIAG_OPTIONS}
  -fdiagnostics-show-template-tree
  -Wno-c++98-compat
  -Wno-c++98-compat-pedantic
  -Weffc++
  )

################################################################################
# Checking Options                                                             #
################################################################################
set(BASE_CHECK_OPTIONS
  -fno-omit-frame-pointer
  )
set(MEM_CHECK_OPTIONS
  -fsanitize=memory
  -fsanitize-memory-track-origins
  -fsanitize-memory-use-after-dtor
  )
set(ADDR_CHECK_OPTIONS
  -fsanitize=address,leak
  )
set(STACK_CHECK_OPTIONS
  -fstack-protector-all
  -fstack-protector-strong
  )
set(MISC_CHECK_OPTIONS
  -fsanitize=undefined
  )

set(C_CHECK_OPTIONS ${BASE_CHECK_OPTIONS})
set(CXX_CHECK_OPTIONS ${BASE_CHECK_OPTIONS})
if ("${WITH_CHECKS}" MATCHES "MEM")
  set(C_CHECK_OPTIONS ${C_CHECK_OPTIONS} ${MEM_CHECK_OPTIONS})
  set(CXX_CHECK_OPTIONS ${CXX_CHECK_OPTIONS} ${MEM_CHECK_OPTIONS})
endif()
if ("${WITH_CHECKS}" MATCHES "ADDR")
  set(C_CHECK_OPTIONS ${C_CHECK_OPTIONS} ${ADDR_CHECK_OPTIONS})
  set(CXX_CHECK_OPTIONS ${CXX_CHECK_OPTIONS} ${ADDR_CHECK_OPTIONS})
endif()
if ("${WITH_CHECKS}" MATCHES "STACK")
  set(C_CHECK_OPTIONS ${C_CHECK_OPTIONS} ${STACK_CHECK_OPTIONS})
  set(CXX_CHECK_OPTIONS ${CXX_CHECK_OPTIONS} ${STACK_CHECK_OPTIONS})
endif()
if ("${WITH_CHECKS}" MATCHES "MISC")
  set(C_CHECK_OPTIONS ${C_CHECK_OPTIONS} ${MISC_CHECK_OPTIONS})
  set(CXX_CHECK_OPTIONS ${CXX_CHECK_OPTIONS} ${MISC_CHECK_OPTIONS})
endif()

################################################################################
# Optimization Options                                                         #
################################################################################
set(BASE_OPT_OPTIONS
  -O3
  -Ofast
  -fno-trapping-math
  -fno-signed-zeros
  -funroll-loops
  -march=native
  -fno-stack-protector
  -flto
  )

if (WITH_OPENMP)
  set(BASE_OPT_OPTIONS ${BASE_OPT_OPTIONS}
    -fopenmp
    )
endif()
set(C_OPT_OPTIONS ${BASE_OPT_OPTIONS})
set(CXX_OPT_OPTIONS ${BASE_OPT_OPTIONS})

if ("${CMAKE_BUILD_TYPE}" STREQUAL "OPT")
  set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -flto")
endif()

################################################################################
# Reporting Options                                                            #
################################################################################
set(REPORT_OPTIONS)
