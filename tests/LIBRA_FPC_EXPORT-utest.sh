#!/bin/bash
#
# Unit tests for LIBRA_FPC_EXPORT variable
#
# Usage: ./LIBRA_FPC_EXPORT-utest.sh
#   Note: This test is independent of compiler type
#
# What is being tested
# --------------------
# LIBRA_FPC_EXPORT controls whether the LIBRA_FPC compile definition is PUBLIC
# or PRIVATE on the LIBRA-managed target.
#
#   LIBRA_FPC_EXPORT=ON  -> define is PUBLIC  -> propagates to downstream consumers
#   LIBRA_FPC_EXPORT=OFF -> define is PRIVATE -> invisible to downstream consumers
#
# How we test it
# --------------
# sample_build_info is built as a STATIC library (triggered by
# -DLIBRA_TEST_FPC_EXPORT=ON).  A consumer/ subdirectory adds a plain
# (non-LIBRA) executable that links against it.  At configure time the consumer
# queries INTERFACE_COMPILE_DEFINITIONS off the library — that property holds
# exactly the PUBLIC definitions — and writes the result into a generated
# consumer_build_info.c file.  We grep that file for the expected define.
#

# set -x
set -e
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPT_NAME=$(basename "$0")
SCRIPT_NAME_NO_EXT="${SCRIPT_NAME%.*}"
BUILDDIR=$SCRIPTDIR/build/LIBRA_FPC_EXPORT_tests

LOGLEVEL=ERROR

# We pick one concrete FPC level for the export tests.  The mapping from
# FPC value -> define is already covered by LIBRA_FPC-utest.sh; here we only
# care about PUBLIC vs PRIVATE propagation.
TEST_FPC_VALUE="ABORT"
TEST_FPC_DEFINE="LIBRA_FPC_ABORT"

################################################################################
# Helper Functions
################################################################################
source $SCRIPTDIR/utils.sh

################################################################################
# Test Cases
################################################################################

echo "========================================================================"
echo "Testing LIBRA_FPC_EXPORT"
echo "========================================================================"

if [ ! -d "$SCRIPTDIR/sample_build_info" ]; then
    echo "ERROR: sample_build_info not found"
    exit 1
fi

# ----------------------------------------------------------------------
# TEST 1: LIBRA_FPC_EXPORT=ON — define must propagate to consumer
# ----------------------------------------------------------------------
echo ""
echo "[TEST 1] LIBRA_FPC_EXPORT=ON  (define should propagate)"
echo "------------------------------------------------------------------------"

test_dir="$BUILDDIR/export_on"
rm -rf "$test_dir"
mkdir -p "$test_dir" && cd "$test_dir"

cmake "$SCRIPTDIR/sample_build_info" \
      -DCMAKE_BUILD_TYPE=Release \
      -DLIBRA_TEST_LANGUAGE=C \
      -DLIBRA_TEST_FPC_EXPORT=ON \
      -DLIBRA_FPC_EXPORT=ON \
      -DLIBRA_FPC="$TEST_FPC_VALUE" \
      -DLIBRA_FPC_EXPORT=ON \
      --log-level=$LOGLEVEL

make

consumer_verify_define_present "$test_dir" "LIBRA_FPC=$TEST_FPC_DEFINE"
echo "------------------------------------------------------------------------"

# ----------------------------------------------------------------------
# TEST 2: LIBRA_FPC_EXPORT=OFF — define must NOT propagate to consumer
# ----------------------------------------------------------------------
echo ""
echo "[TEST 2] LIBRA_FPC_EXPORT=OFF (define should NOT propagate)"
echo "------------------------------------------------------------------------"

test_dir="$BUILDDIR/export_off"
rm -rf "$test_dir"
mkdir -p "$test_dir" && cd "$test_dir"

cmake "$SCRIPTDIR/sample_build_info" \
      -DCMAKE_BUILD_TYPE=Release \
      -DLIBRA_TEST_LANGUAGE=C \
      -DLIBRA_TEST_FPC_EXPORT=ON \
      -DLIBRA_FPC_EXPORT=OFF \
      --log-level=$LOGLEVEL

make

consumer_verify_define_absent "$test_dir" "LIBRA_FPC="

echo "------------------------------------------------------------------------"

echo ""
echo "========================================================================"
echo "ALL TESTS PASSED!"
echo "========================================================================"
echo ""
echo "Summary:"
echo "  ✓ LIBRA_FPC_EXPORT=ON  -> LIBRA_FPC define propagates to consumer"
echo "  ✓ LIBRA_FPC_EXPORT=OFF -> LIBRA_FPC define does NOT propagate"
echo ""
