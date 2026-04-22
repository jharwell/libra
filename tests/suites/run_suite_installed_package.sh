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

exec bats -j $(nproc) "$@" ${TESTS_DIR}/LIBRA*.bats
