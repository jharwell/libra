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

exec bats -j $(nproc) "$@" ${TESTS_DIR}/LIBRA_*.bats
