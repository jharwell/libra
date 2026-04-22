#!/usr/bin/env bash
#
# Copyright 2025 John Harwell, All rights reserved.
#
# SPDX-License-Identifier: MIT
#
# run_suite_cpm.sh
#
# Runs the full LIBRA BATS test suite with LIBRA consumed via CPM.cmake
# (vendored at tests/consume/cpm/CPM.cmake) using a local SOURCE_DIR.
# No network access is required.
#
# Usage:
#   ./tests/suites/run_suite_cpm.sh [bats options]
#
set -euo pipefail

SUITE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTS_DIR="$(cd "${SUITE_DIR}/.." && pwd)"

export LIBRA_CONSUME_MODE="cpm"

exec bats -j $(nproc) "$@" ${TESTS_DIR}/LIBRA_*.bats
