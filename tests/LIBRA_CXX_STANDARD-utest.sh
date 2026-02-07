#!/bin/bash
#
# Unit tests for LIBRA_CXX_STANDARD variable across all supported compilers
#
# Usage: ./LIBRA_CXX_STANDARD-utest.sh
#

set -e
# set -x
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPT_NAME=$(basename "$0")
SCRIPT_NAME_NO_EXT="${SCRIPT_NAME%.*}"

# Parse command line arguments
BUILDDIR=$SCRIPTDIR/build/LIBRA_CXX_STANDARD_tests

LOGLEVEL=ERROR

################################################################################
# Helpers
################################################################################
source $SCRIPTDIR/utils.sh
declare -a CXX_STANDARDS=(23 20 17 14 11)

################################################################################
# Helper Functions
################################################################################
source $SCRIPTDIR/utils.sh


# Run a basic test with optional LIBRA_CXX_STANDARD override
# Usage: run_cxx_standard_test TEST_NAME [LIBRA_CXX_STANDARD] [CMAKE_CXX_STANDARD]
run_cxx_standard_test() {
    local test_name="$1"
    local libra_std="${2:-}"
    local cmake_std="${3:-}"
    local test_dir="$BUILDDIR/${test_name}"


    rm -rf "$test_dir"
    mkdir -p "$test_dir" && cd "$test_dir"

    local cmake_args=(
        "$SCRIPTDIR/sample_build_info"
        -DCMAKE_INSTALL_PREFIX=/tmp/libra_cxx_standard_test
        -DCMAKE_BUILD_TYPE=Debug
        -DLIBRA_TEST_LANGUAGE=CXX
        --log-level=$LOGLEVEL
    )

    if [ -n "$libra_std" ]; then
        cmake_args+=(-DLIBRA_CXX_STANDARD="$libra_std")
    fi

    if [ -n "$cmake_std" ]; then
        cmake_args+=(-DCMAKE_CXX_STANDARD="$cmake_std")
    fi

    cmake "${cmake_args[@]}"
    make
}

################################################################################
# Test Suite
################################################################################

echo "========================================================================"
echo "Testing LIBRA_CXX_STANDARD"
echo "========================================================================"

# Test 1: Default behavior (no LIBRA_CXX_STANDARD or CMAKE_CXX_STANDARD)
echo ""
echo "--- Test 1: Default C++ Standard ---"
run_cxx_standard_test "default"
default_std=$(get_cxx_standard "$BUILDDIR/default")
echo "Default C++ standard: $default_std"

# Test 2: Respect CMAKE_CXX_STANDARD when set
echo ""
echo "--- Test 2: Respect CMAKE_CXX_STANDARD ---"
for std in "${CXX_STANDARDS[@]}"; do
    run_cxx_standard_test "cmake_std_${std}" "" "$std"
    verify_cxx_standard "$BUILDDIR/cmake_std_${std}" "c++$std"
done

# Test 3: LIBRA_CXX_STANDARD sets the standard when CMAKE_CXX_STANDARD not set
echo ""
echo "--- Test 3: LIBRA_CXX_STANDARD Sets Standard ---"
for std in "${CXX_STANDARDS[@]}"; do
    run_cxx_standard_test "libra_std_${std}" "c++$std" ""
    verify_cxx_standard "$BUILDDIR/libra_std_${std}" "c++$std"
done

# Test 4: CMAKE_CXX_STANDARD takes precedence over LIBRA_CXX_STANDARD
echo ""
echo "--- Test 4: CMAKE_CXX_STANDARD Overrides LIBRA_CXX_STANDARD ---"
run_cxx_standard_test "precedence_test" "11" "17"
verify_cxx_standard "$BUILDDIR/precedence_test" "c++17"
echo "SUCCESS: CMAKE_CXX_STANDARD correctly overrides LIBRA_CXX_STANDARD"

echo ""
echo "========================================================================"
echo "ALL TESTS PASSED!"
echo "========================================================================"
echo ""
echo "Summary of tests:"
echo "  ✓ Default standard behavior"
echo "  ✓ CMAKE_CXX_STANDARD respected"
echo "  ✓ LIBRA_CXX_STANDARD sets standard"
echo "  ✓ CMAKE_CXX_STANDARD takes precedence"
echo ""
