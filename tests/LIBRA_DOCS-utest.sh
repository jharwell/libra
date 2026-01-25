#!/bin/bash
#
# Unit tests for LIBRA_DOCS variable
#
# Usage: ./LIBRA_DOCS-utest.sh
#   Note: This test is independent of compiler type
#

# set -x
set -e
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPT_NAME=$(basename "$0")
SCRIPT_NAME_NO_EXT="${SCRIPT_NAME%.*}"
BUILDDIR=$SCRIPTDIR/build/LIBRA_DOCS_tests

LOGLEVEL=ERROR

# Expected Makefile targets when LIBRA_DOCS=ON
# Based on libra/apidoc.cmake:
# - apidoc: Generate API documentation with Doxygen
# - apidoc-check: Parent target for documentation checks
# - apidoc-check-doxygen: Check documentation with Doxygen warnings as errors
# - apidoc-check-clang: Check doxygen markup with clang
EXPECTED_MK_TARGETS=(
    "apidoc"
    "apidoc-check"
    "apidoc-check-doxygen"
    "apidoc-check-clang"
)


################################################################################
# Helper Functions
################################################################################
source $SCRIPTDIR/utils.sh

################################################################################
# Test Cases
################################################################################

echo "========================================================================"
echo "Testing LIBRA_DOCS"
echo "========================================================================"

# Test 1: LIBRA_DOCS=ON - targets should exist
echo ""
echo "[TEST 1] LIBRA_DOCS=ON - Documentation targets should be created"
echo "------------------------------------------------------------------------"

test_dir="$BUILDDIR/on"
rm -rf "$test_dir"
mkdir -p "$test_dir" && cd "$test_dir"

# Note: We need to use a project that has docs/Doxyfile.in
# The sample_build_info project may not have this, so we'll check for it
source_dir="$SCRIPTDIR/sample_build_info"

# Configure with LIBRA_DOCS=ON
cmake "$source_dir" \
      -DCMAKE_BUILD_TYPE=Release \
      -DLIBRA_DOCS=ON \
      --log-level=$LOGLEVEL

# Verify targets exist
verify_mk_targets_present "$test_dir"

echo ""
echo "------------------------------------------------------------------------"

# Test 2: LIBRA_DOCS=OFF - targets should NOT exist
echo ""
echo "[TEST 2] LIBRA_DOCS=OFF - Documentation targets should NOT be created"
echo "------------------------------------------------------------------------"

test_dir="$BUILDDIR/off"
rm -rf "$test_dir"
mkdir -p "$test_dir" && cd "$test_dir"

cmake "$source_dir" \
      -DCMAKE_BUILD_TYPE=Release \
      -DLIBRA_DOCS=OFF \
      --log-level=$LOGLEVEL

# Verify targets do NOT exist
verify_mk_targets_absent "$test_dir"

echo ""
echo "------------------------------------------------------------------------"

echo ""
echo "========================================================================"
echo "ALL TESTS PASSED!"
echo "========================================================================"
echo ""
echo "Summary:"
echo "  ✓ LIBRA_DOCS=ON creates documentation targets"
echo "  ✓ LIBRA_DOCS=OFF does not create documentation targets"
echo ""
