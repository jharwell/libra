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

set(LIBRA_CLANG_TIDY_CHECKS_CONFIG_DEFAULT
    ,-cppcoreguidelines-avoid-do-while,-cppcoreguidelines-pro-bounds-constant-array-index,-clang-diagnostic-*,-fuchsia-default-argument-calls,-fuchsia-overloaded-operator,-modernize-pass-by-value,-portability-template-virtual-member-function,-cppcoreguidelines-avoid-magic-numbers,-readability-magic-numbers,-portability-avoid-pragma-once,-readability-redundant-member-init,-bugprone-crtp-constructor-accessibility,-google-readability-avoid-underscore-in-googletest-name,-readability-named-parameter,-readability-implicit-bool-conversion,-readability-uppercase-literal-suffix,-cppcoreguidelines-avoid-goto
)

set(LIBRA_GCOVR_LINES_THRESH_DEFAULT 95)
set(LIBRA_GCOVR_FUNCTIONS_THRESH_DEFAULT 60)
set(LIBRA_GCOVR_BRANCHES_THRESH_DEFAULT 50)
set(LIBRA_GCOVR_DECISIONS_THRESH_DEFAULT 50)
