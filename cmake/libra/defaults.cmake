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

set(LIBRA_STDLIB_DEFAULT "UNDEFINED")
set(LIBRA_CPPCHECK_EXTRA_ARGS_DEFAULT --library=googletest)
set(LIBRA_CPPCHECK_SUPPRESSIONS_DEFAULT unusedStructMember)

# 2025-07-21 [JRH]: readability-identifier-naming checks disabled so that we can
# run the other readability checks and be able to just do 'make
# analyze-clang-tidy'.
set(LIBRA_CLANG_TIDY_CHECKS_CONFIG_DEFAULT
    ,-cppcoreguidelines-avoid-do-while,-cppcoreguidelines-pro-bounds-constant-array-index,-clang-diagnostic-*,-fuchsia-default-argument-calls,-fuchsia-overloaded-operator,-modernize-pass-by-value,-portability-template-virtual-member-function,-cppcoreguidelines-avoid-magic-numbers,-readability-magic-numbers,-portability-avoid-pragma-once,-readability-redundant-member-init,-bugprone-crtp-constructor-accessibility,-google-readability-avoid-underscore-in-googletest-name
)

set(LIBRA_GCOVR_LINES_THRESH_DEFAULT 95)
set(LIBRA_GCOVR_FUNCTIONS_THRESH_DEFAULT 60)
set(LIBRA_GCOVR_BRANCHES_THRESH_DEFAULT 50)
set(LIBRA_GCOVR_DECISIONS_THRESH_DEFAULT 50)
