#
# Copyright 2026 John Harwell, All rights reserved.
#
# SPDX-License Identifier: MIT
#

set(LIBRA_SAN_DEFAULT "NONE")
set(LIBRA_FORTIFY_DEFAULT "NONE")

set(LIBRA_UNIT_TEST_MATCHER_DEFAULT -utest)
set(LIBRA_INTEGRATION_TEST_MATCHER_DEFAULT -itest)
set(LIBRA_REGRESSION_TEST_MATCHER_DEFAULT -rtest)
set(LIBRA_TEST_HARNESS_MATCHER_DEFAULT _test)
set(LIBRA_CTEST_INCLUDE_UNIT_TESTS_DEFAULT YES)
set(LIBRA_CTEST_INCLUDE_INTEGRATION_TESTS_DEFAULT YES)
set(LIBRA_CTEST_INCLUDE_REGRESSION_TESTS_DEFAULT YES)
set(LIBRA_SPHINXDOC_COMMAND_DEFAULT sphinx-build)
set(LIBRA_ANALYSIS_LANGUAGE_DEFAULT CXX)
set(LIBRA_STDLIB_DEFAULT "UNDEFINED")
set(LIBRA_CPPCHECK_EXTRA_ARGS_DEFAULT --library=googletest)
set(LIBRA_CPPCHECK_SUPPRESSIONS_DEFAULT unusedStructMember)
set(LIBRA_CLANG_TOOLS_USE_FIXED_DB YES)
set(LIBRA_CLANG_TIDY_CATEGORIES_DEFAULT
    clang-analyzer-core
    abseil
    cppcoreguidelines
    readability
    hicpp
    bugprone
    cert
    performance
    portability
    concurrency
    modernize
    misc
    google)

# ##############################################################################
# clang-tidy checks disabled by default
#
# LIBRA runs clang-tidy with --checks='*<list>' (or '-*,<category>*<list>' per
# category), so each list below is a comma-separated set of '-<check>' globs
# with a leading comma. A project's LIBRA_CLANG_TIDY_CHECKS_CONFIG replaces
# these defaults rather than adding to them.
# ##############################################################################

# C projects. C projects often have C++ tests, which are analyzed with this same
# list, so it also disables C++-only checks that don't suit C-style code.
set(_LIBRA_CLANG_TIDY_CHECKS_C_DISABLED
    # Compiler warnings are the compiler's job
    -clang-diagnostic-*
    # memset: memcpy, memmove, sprintf, sscanf, strcat, strncpy, and even printf
    # and fprintf. In a typical C codebase it fires on most lines that touch
    # memory or strings, which buries real findings and trains people to ignore
    # the analyzer
    -clang-analyzer-security.insecureAPI.DeprecatedOrUnsafeBufferHandling
    # Style checks that don't fit idiomatic C
    -readability-magic-numbers
    -readability-implicit-bool-conversion # if (ptr) / if (count)
    -readability-named-parameter
    -readability-uppercase-literal-suffix
    -readability-use-concise-preprocessor-directives # #if defined() -> #ifdef
    -portability-avoid-pragma-once
    -llvm-header-guard # flags every #pragma once header
    # Whole families that don't fit C
    -abseil-* # Abseil C++ library
    -altera-* # OpenCL FPGA kernels
    -android-* # O_CLOEXEC etc. for Android
    -fuchsia-* # Fuchsia C++ conventions
    -llvmlibc-* # LLVM libc's own conventions
    -cppcoreguidelines-* # C++ guidelines; the C-applicable ones are aliases
    -modernize-* # in C: C-style cast, nullptr, and macro-to-enum suggestions
    -hicpp-* # mostly aliases; signed-bitwise/no-assembler noisy for C
    -google-readability-* # aliases of readability-* checks
    # Aliases that would otherwise still fire
    -cert-dcl16-c # = readability-uppercase-literal-suffix
    -cert-dcl51-cpp # = bugprone-reserved-identifier (cert-dcl37-c)
    # C++-only checks that don't suit C-style C++ tests
    -cert-dcl50-cpp # C-style variadic functions
    -cert-err58-cpp # exceptions from static initializers
    -misc-const-correctness
    -misc-no-recursion
    -misc-use-anonymous-namespace # tests use static, as in C
    -performance-enum-size)

list(JOIN _LIBRA_CLANG_TIDY_CHECKS_C_DISABLED ","
     _LIBRA_CLANG_TIDY_CHECKS_C_DISABLED)
set(LIBRA_CLANG_TIDY_CHECKS_CONFIG_C_DEFAULT
    ",${_LIBRA_CLANG_TIDY_CHECKS_C_DISABLED}")

# C++ projects.
set(_LIBRA_CLANG_TIDY_CHECKS_CXX_DISABLED
    # Compiler warnings are the compiler's job
    -clang-diagnostic-*
    -bugprone-crtp-constructor-accessibility
    -cppcoreguidelines-avoid-do-while
    -cppcoreguidelines-avoid-goto
    -cppcoreguidelines-avoid-magic-numbers
    -cppcoreguidelines-pro-bounds-constant-array-index
    -fuchsia-default-argument-calls
    -fuchsia-overloaded-operator
    -google-readability-avoid-underscore-in-googletest-name
    -modernize-pass-by-value
    -portability-avoid-pragma-once
    -portability-template-virtual-member-function
    -readability-implicit-bool-conversion
    -readability-magic-numbers
    -readability-named-parameter
    -readability-redundant-member-init
    -bugprone-crtp-constructor-accessibility
    -google-readability-avoid-underscore-in-googletest-name
    -readability-named-parameter
    -readability-implicit-bool-conversion
    -readability-uppercase-literal-suffix
    -cppcoreguidelines-avoid-goto
    -misc-no-recursion)

list(JOIN _LIBRA_CLANG_TIDY_CHECKS_CXX_DISABLED ","
     _LIBRA_CLANG_TIDY_CHECKS_CXX_DISABLED)
set(LIBRA_CLANG_TIDY_CHECKS_CONFIG_CXX_DEFAULT
    ",${_LIBRA_CLANG_TIDY_CHECKS_CXX_DISABLED}")

set(LIBRA_GCOVR_LINES_THRESH_DEFAULT 95)
set(LIBRA_GCOVR_FUNCTIONS_THRESH_DEFAULT 60)
set(LIBRA_GCOVR_BRANCHES_THRESH_DEFAULT 50)
set(LIBRA_GCOVR_DECISIONS_THRESH_DEFAULT 50)
