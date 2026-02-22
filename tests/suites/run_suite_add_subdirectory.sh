#!/usr/bin/env bash
#
# Copyright 2025 John Harwell, All rights reserved.
#
# SPDX-License-Identifier: MIT
#
# run_suite_add_subdirectory.sh
#
# Runs the full LIBRA BATS test suite with LIBRA consumed via add_subdirectory().
#
# Usage:
#   ./tests/suites/run_suite_add_subdirectory.sh [bats options]
#
# Any extra arguments are forwarded verbatim to bats, e.g.:
#   ./tests/suites/run_suite_add_subdirectory.sh --filter "ANALYSIS"
#   ./tests/suites/run_suite_add_subdirectory.sh --jobs 4
#
set -euo pipefail

SUITE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTS_DIR="$(cd "${SUITE_DIR}/.." && pwd)"

export LIBRA_CONSUME_MODE="add_subdirectory"

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
    "${TESTS_DIR}/LIBRA_VALGRIND_COMPAT.bats"
