#!/usr/bin/env bash
#
# Copyright 2025 John Harwell, All rights reserved.
#
# SPDX-License-Identifier: MIT
#
# run_suite_installed_package.sh
#
# Runs the full LIBRA BATS test suite with LIBRA consumed via cmake --install
# followed by find_package().
#
# The test helper installs LIBRA to a temporary prefix once (stamped), then
# each test configures its sample project with that prefix on CMAKE_PREFIX_PATH.
#
# Usage:
#   ./tests/suites/run_suite_installed_package.sh [bats options]
#
set -euo pipefail

SUITE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTS_DIR="$(cd "${SUITE_DIR}/.." && pwd)"

export LIBRA_CONSUME_MODE="installed_package"

exec bats -j $(nproc) "$@" \
    "${TESTS_DIR}/LIBRA_ANALYSIS.bats" \
    "${TESTS_DIR}/LIBRA_BUILD_PROF.bats" \
    "${TESTS_DIR}/LIBRA_CODE_COV.bats" \
    "${TESTS_DIR}/LIBRA_CXX_STANDARD.bats" \
    "${TESTS_DIR}/LIBRA_C_STANDARD.bats" \
    "${TESTS_DIR}/LIBRA_DOCS.bats" \
    "${TESTS_DIR}/LIBRA_ERL.bats" \
    "${TESTS_DIR}/LIBRA_FORTIFY.bats" \
    "${TESTS_DIR}/LIBRA_FPC.bats" \
    "${TESTS_DIR}/LIBRA_FPC_EXPORT.bats" \
    "${TESTS_DIR}/LIBRA_LTO.bats" \
    "${TESTS_DIR}/LIBRA_NATIVE_OPT.bats" \
    "${TESTS_DIR}/LIBRA_OPT_REPORT.bats" \
    "${TESTS_DIR}/LIBRA_PGO.bats" \
    "${TESTS_DIR}/LIBRA_SAN.bats" \
    "${TESTS_DIR}/LIBRA_STDLIB.bats" \
    "${TESTS_DIR}/LIBRA_TESTS.bats" \
    "${TESTS_DIR}/LIBRA_VALGRIND_COMPAT.bats"
