# The Episci License
#
# Copyright (c) 2025 EpiSys Science, Inc.
#
# The software provided is the sole and exclusive property of EpiSys Science,
# Inc. The user shall use the software only in support of the agreed upon
# experimental purpose only and shall preserve and protect the software from
# disclosure to any person or persons, other than employees, consultants, and
# contracted staff of the corporation with a need to know, through an exercise
# of care equivalent to the degree of care it uses to preserve and protect its
# own intellectual property. Unauthorized use of the software is prohibited
# without written consent.
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

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
set(LIBRA_USE_COMPDB YES)
set(LIBRA_CPPCHECK_EXTRA_ARGS_DEFAULT --library=googletest)
set(LIBRA_CPPCHECK_SUPPRESSIONS_DEFAULT unusedStructMember)

# 2025-07-21 [JRH]: readability-identifier-naming checks disabled so that we can
# run the other readability checks and be able to just do 'make
# analyze-clang-tidy'.
set(LIBRA_CLANG_TIDY_CHECKS_CONFIG_DEFAULT
    ,-cppcoreguidelines-avoid-do-while,-cppcoreguidelines-pro-bounds-constant-array-index,-clang-diagnostic-*,-fuchsia-default-argument-calls,-fuchsia-overloaded-operator,-modernize-pass-by-value,-portability-template-virtual-member-function,-cppcoreguidelines-avoid-magic-numbers,-readability-magic-numbers,-portability-avoid-pragma-once,-readability-redundant-member-init,-bugprone-crtp-constructor-accessibility
)

set(LIBRA_GCOVR_LINES_THRESH_DEFAULT 95)
set(LIBRA_GCOVR_FUNCTIONS_THRESH_DEFAULT 60)
set(LIBRA_GCOVR_BRANCHES_THRESH_DEFAULT 50)
set(LIBRA_GCOVR_DECISIONS_THRESH_DEFAULT 50)
