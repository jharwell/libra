#!/bin/bash
#
# Unit tests for LIBRA_ANALYSIS variable
#
# Usage: ./LIBRA_ANALYSIS-utest.sh
#   Note: This test is independent of compiler type
#

# set -x
set -e
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPT_NAME=$(basename "$0")
SCRIPT_NAME_NO_EXT="${SCRIPT_NAME%.*}"
BUILDDIR=$SCRIPTDIR/build/LIBRA_ANALYSIS_tests

LOGLEVEL=ERROR

# Expected Makefile targets when LIBRA_ANALYSIS=ON
EXPECTED_MK_TARGETS=(
    "analyze"
    "format"
    "fix"
    "analyze-clang-check"
    "analyze-clang-tidy"
    "analyze-cppcheck"
    "analyze-cmake-format"
    "format-clang-format"
    "format-cmake-format"
    "fix-clang-tidy"
    "fix-clang-check"
)

################################################################################
# Helper Functions
################################################################################
source $SCRIPTDIR/utils.sh

# Function to run LIBRA_ANALYSIS=ON test with specific settings
# Usage: run_analysis_on_test TEST_NAME COMPDB_SETTING
run_analysis_on_test() {
    local test_name="$1"
    local compdb_setting="$2"
    local test_dir="$BUILDDIR/${test_name}"

    echo ""
    echo "[TEST] LIBRA_ANALYSIS=ON - ${test_name}"
    echo "------------------------------------------------------------------------"

    rm -rf "$test_dir"
    mkdir -p "$test_dir" && cd "$test_dir"

    if [ "$compdb_setting" = "YES" ]; then
        cmake "$source_dir" \
              -DCMAKE_BUILD_TYPE=Release \
              -DLIBRA_ANALYSIS=ON \
              -DCMAKE_C_COMPILER=clang \
              -DCMAKE_CXX_COMPILER=clang++ \
              -DLIBRA_USE_COMPDB="$compdb_setting" \
              --log-level=$LOGLEVEL \
              --fresh
    else
        cmake "$source_dir" \
              -DCMAKE_BUILD_TYPE=Release \
              -DLIBRA_ANALYSIS=ON \
              -DLIBRA_USE_COMPDB="$compdb_setting" \
              --log-level=$LOGLEVEL
    fi

    # Verify targets exist
    verify_mk_targets_present "$test_dir"

    # Run each target
    echo "  Running analysis targets..."
    for target in "${EXPECTED_MK_TARGETS[@]}"; do
        echo "    Running: make $target"
        make -j $target
    done

    echo "------------------------------------------------------------------------"
}

################################################################################
# Test Cases
################################################################################

echo "========================================================================"
echo "Testing LIBRA_ANALYSIS"
echo "========================================================================"

# Determine source directory
if [ -d "$SCRIPTDIR/sample_build_info" ]; then
    source_dir="$SCRIPTDIR/sample_build_info"
else
    echo "ERROR: sample_build_info not found"
    exit 1
fi

# Test 1: LIBRA_ANALYSIS=ON without compilation database
run_analysis_on_test "on_no_compdb" "NO"

# Test 2: LIBRA_ANALYSIS=ON with compilation database
run_analysis_on_test "on_with_compdb" "YES"

# Test 3: LIBRA_ANALYSIS=OFF - targets should NOT exist
echo ""
echo "[TEST] LIBRA_ANALYSIS=OFF"
echo "------------------------------------------------------------------------"

test_dir="$BUILDDIR/off"
rm -rf "$test_dir"
mkdir -p "$test_dir" && cd "$test_dir"

cmake "$source_dir" \
      -DCMAKE_BUILD_TYPE=Release \
      -DLIBRA_ANALYSIS=OFF \
      --log-level=$LOGLEVEL

# Verify targets do NOT exist
verify_mk_targets_absent "$test_dir"

echo "------------------------------------------------------------------------"

echo ""
echo "========================================================================"
echo "ALL TESTS PASSED!"
echo "========================================================================"
echo ""
echo "Summary:"
echo "  ✓ LIBRA_ANALYSIS=ON creates static analysis targets (no compdb)"
echo "  ✓ LIBRA_ANALYSIS=ON creates static analysis targets (with compdb)"
echo "  ✓ LIBRA_ANALYSIS=OFF does not create static analysis targets"
echo ""
echo "Static analysis targets created when enabled:"
echo "  - analyze: Run all static analyzers"
echo "  - format: Run all code formatters"
echo "  - fix: Run all auto-fixers"
echo "  - analyze-clang-check: Clang static analyzer (if available)"
echo "  - analyze-clang-tidy: Clang-tidy checker (if available)"
echo "  - analyze-cppcheck: Cppcheck analyzer (if available)"
echo "  - analyze-cmake-format: CMake formatter checker (if available)"
echo "  - format-clang-format: Clang-format formatter (if available)"
echo "  - format-cmake-format: CMake formatter (if available)"
echo "  - fix-clang-tidy: Clang-tidy auto-fixer (if available)"
echo "  - fix-clang-check: Clang-check auto-fixer (if available)"
echo ""
