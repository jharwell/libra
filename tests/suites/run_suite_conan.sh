#!/usr/bin/env bash
#
# Copyright 2025 John Harwell, All rights reserved.
#
# SPDX-License-Identifier: MIT
#
# run_suite_conan.sh
#
# Runs the full LIBRA BATS test suite with LIBRA consumed via Conan.
#
# Prerequisites:
#   - conan must be on PATH
#   - LIBRA's conanfile.py must be at the repository root
#
# The test helper runs `conan create` once per bats invocation (stamped) to
# populate the local Conan package cache, then runs `conan install` in each
# test's build directory to generate conan_toolchain.cmake before cmake runs.
#
# Usage:
#   ./tests/suites/run_suite_conan.sh [bats options]
#
set -euo pipefail

SUITE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTS_DIR="$(cd "${SUITE_DIR}/.." && pwd)"

if ! command -v conan &>/dev/null; then
    echo "ERROR: conan not found on PATH. Install conan to run this suite." >&2
    echo "  pip install conan" >&2
    exit 1
fi


# Determine version
LIBRA_SOURCE_ROOT="$(cd "${TESTS_DIR}/.." && pwd)"
LIBRA_CONAN_VERSION=$(
    grep LIBRA_VERSION "${LIBRA_SOURCE_ROOT}/cmake/libra/self.cmake" \
        | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' \
        | head -1
                   )
# Write version to a file so bats workers can read it regardless of
# how the parallel job pool handles environment inheritance
export LIBRA_CONAN_VERSION
echo "$LIBRA_CONAN_VERSION" > "${TMPDIR:-/tmp}/libra_conan_version"

# Create once before any parallel bats workers start
conan profile detect --force || true

# Patch detected intel compiler version--this is a known limitation of
# conan's detection logic
sed -i 's/compiler.version=2025$/compiler.version=2025.0/' ~/.conan2/profiles/default

conan create "$LIBRA_SOURCE_ROOT" \
      --version "$LIBRA_CONAN_VERSION" \
      -s build_type=Debug \
      --build=missing \
      -tf "" \
    || { echo "ERROR: conan create failed" >&2; exit 1; }

export LIBRA_CONSUME_MODE="conan"

# 2026-02-22 [JRH]: We don't test LIBRA_{C,CXX}_STANDARD because the value of
# -std is set by conan, and LIBRA doesn't interfere with that. Similarly for
# LIBRA_{CPACK,ERL_EXPORT,FPC_EXPORT,EXPORT_INSTALL,DEP_ISOLATION,
# COMPILER_VERSION}: that's packaging-y things which conan handles.

exec bats -j $(nproc) "$@" \
  "${TESTS_DIR}/LIBRA_ANALYSIS.bats" \
  "${TESTS_DIR}/LIBRA_BUILD_PROF.bats" \
  "${TESTS_DIR}/LIBRA_COVERAGE.bats" \
  "${TESTS_DIR}/LIBRA_COMPILER_VERSION.bats" \
  "${TESTS_DIR}/LIBRA_DOCS.bats" \
  "${TESTS_DIR}/LIBRA_ERL.bats" \
  "${TESTS_DIR}/LIBRA_FORMAT.bats" \
  "${TESTS_DIR}/LIBRA_FORTIFY.bats" \
  "${TESTS_DIR}/LIBRA_FPC.bats" \
  "${TESTS_DIR}/LIBRA_LTO.bats" \
  "${TESTS_DIR}/LIBRA_NATIVE_OPT.bats" \
  "${TESTS_DIR}/LIBRA_NO_CCACHE.bats" \
  "${TESTS_DIR}/LIBRA_OPT_REPORT.bats" \
  "${TESTS_DIR}/LIBRA_PGO.bats" \
  "${TESTS_DIR}/LIBRA_SAN.bats" \
  "${TESTS_DIR}/LIBRA_STDLIB.bats" \
  "${TESTS_DIR}/LIBRA_TESTS.bats" \
  "${TESTS_DIR}/LIBRA_VALGRIND_COMPAT.bats"
