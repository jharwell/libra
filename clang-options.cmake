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
  -fsanitize=address,integer,undefined,dataflow
  -fsanitize-undefined-trap-on-error
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
  -Ofast
  )

set(C_OPT_OPTIONS ${BASE_OPT_OPTIONS})
set(CXX_OPT_OPTIONS ${BASE_OPT_OPTIONS})

################################################################################
# Reporting Options                                                            #
################################################################################
set(REPORT_OPTIONS)
