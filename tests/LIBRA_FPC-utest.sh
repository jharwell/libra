#!/bin/bash
#
# Unit tests for LIBRA_FPC variable
#
# Usage: ./LIBRA_FPC-utest.sh
#   Note: This test is independent of compiler type
#   Note: LIBRA_FPC is a cache variable that sets compile definitions
#

# set -x
set -e
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPT_NAME=$(basename "$0")
SCRIPT_NAME_NO_EXT="${SCRIPT_NAME%.*}"
BUILDDIR=$SCRIPTDIR/build/LIBRA_FPC_tests

LOGLEVEL=ERROR

# Valid LIBRA_FPC values and their corresponding defines
# Based on libra/compile/compiler.cmake:
# - RETURN: -DLIBRA_FPC=LIBRA_FPC_RETURN (default)
# - ABORT: -DLIBRA_FPC=LIBRA_FPC_ABORT
# - NONE: -DLIBRA_FPC=LIBRA_FPC_NONE
# - INHERIT: Uses parent's value (not tested standalone)

# Map FPC values to expected defines
declare -A FPC_TO_DEFINE=(
    ["RETURN"]="LIBRA_FPC_RETURN"
    ["ABORT"]="LIBRA_FPC_ABORT"
    ["NONE"]="LIBRA_FPC_NONE"
)

################################################################################
# Helper Functions
################################################################################

# Function to verify LIBRA_FPC define in build_info file
# Usage: verify_fpc_define BUILD_DIR EXPECTED_DEFINE
verify_fpc_define() {
    local build_dir="$1"
    local expected_define="$2"

    echo "  Verifying LIBRA_FPC define is set to '$expected_define' in build_info..."

    # Check C build_info file
    local build_info_file="$build_dir/build_info.c"

    if [ ! -f "$build_info_file" ]; then
        echo "    ✗ ERROR: build_info file not found: $build_info_file"
        exit 1
    fi

    # Check if the expected define is in the LIBRA_FLAGS constant
    if grep -q "LIBRA_FPC=$expected_define" "$build_info_file"; then
        echo "    ✓ Found LIBRA_FPC=$expected_define in $build_info_file"
        echo "SUCCESS: LIBRA_FPC correctly set to '$expected_define'"
        return 0
    else
        echo "    ✗ ERROR: Expected LIBRA_FPC=$expected_define not found in $build_info_file"
        echo "    Contents of LIBRA_FLAGS:"
        grep "LIBRA_FLAGS" "$build_info_file" || echo "    (LIBRA_FLAGS not found)"
        exit 1
    fi
}

# Run test for a specific FPC value
# Usage: run_fpc_test FPC_VALUE
run_fpc_test() {
    local fpc_value="$1"
    local expected_define="${FPC_TO_DEFINE[$fpc_value]}"
    local test_dir="$BUILDDIR/${fpc_value,,}"

    echo ""
    echo "[TEST] LIBRA_FPC=$fpc_value (should define $expected_define)"
    echo "------------------------------------------------------------------------"

    rm -rf "$test_dir"
    mkdir -p "$test_dir" && cd "$test_dir"

    cmake "$SCRIPTDIR/sample_build_info" \
          -DCMAKE_BUILD_TYPE=Release \
          -DLIBRA_FPC="$fpc_value" \
          -DLIBRA_TEST_LANGUAGE=C \
          --log-level=$LOGLEVEL

    make

    verify_fpc_define "$test_dir" "$expected_define"

    echo "------------------------------------------------------------------------"
}

################################################################################
# Test Cases
################################################################################

echo "========================================================================"
echo "Testing LIBRA_FPC (Function Precondition Checking)"
echo "========================================================================"

# Determine source directory
if [ -d "$SCRIPTDIR/sample_build_info" ]; then
    source_dir="$SCRIPTDIR/sample_build_info"
else
    echo "ERROR: sample_build_info not found"
    exit 1
fi

# Test each FPC value
for fpc_value in "${!FPC_TO_DEFINE[@]}"; do
    run_fpc_test "$fpc_value"
done

# Test default value (should be RETURN)
echo ""
echo "[TEST] Default LIBRA_FPC value (no explicit setting)"
echo "------------------------------------------------------------------------"

test_dir="$BUILDDIR/default"
rm -rf "$test_dir"
mkdir -p "$test_dir" && cd "$test_dir"

cmake "$SCRIPTDIR/sample_build_info" \
      -DCMAKE_BUILD_TYPE=Release \
      -DLIBRA_TEST_LANGUAGE=C \
      --log-level=$LOGLEVEL

make

verify_fpc_define "$test_dir" "LIBRA_FPC_RETURN"

echo "------------------------------------------------------------------------"

echo ""
echo "========================================================================"
echo "ALL TESTS PASSED!"
echo "========================================================================"
echo ""
echo "Summary:"
echo "  ✓ LIBRA_FPC=RETURN → LIBRA_FPC=LIBRA_FPC_RETURN (default)"
echo "  ✓ LIBRA_FPC=ABORT → LIBRA_FPC=LIBRA_FPC_ABORT"
echo "  ✓ LIBRA_FPC=NONE → LIBRA_FPC=LIBRA_FPC_NONE"
echo "  ✓ Default value creates LIBRA_FPC_RETURN"
echo ""
echo "These defines control function precondition checking behavior:"
echo "  - LIBRA_FPC_RETURN: Return from function on precondition failure"
echo "  - LIBRA_FPC_ABORT: Abort program on precondition failure"
echo "  - LIBRA_FPC_NONE: No precondition checking"
echo ""
