#!/bin/bash
#
# Unit tests for LIBRA_C_STANDARD variable across all supported compilers
#
# Usage: ./LIBRA_C_STANDARD-utest.sh
#

set -e
# set -x
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPT_NAME=$(basename "$0")
SCRIPT_NAME_NO_EXT="${SCRIPT_NAME%.*}"

# Parse command line arguments
COMPILER_TYPE="${1:-gnu}"
BUILDDIR=$SCRIPTDIR/build/LIBRA_C_STANDARD_tests/${COMPILER_TYPE}

LOGLEVEL=ERROR

################################################################################
# Compiler Configuration Maps
################################################################################

# Valid C standards to test
declare -a C_STANDARDS=(99 11 17 23)

################################################################################
# Helper Functions
################################################################################
source $SCRIPTDIR/utils.sh

# Extract C standard from build_info.c
# Usage: get_c_standard BUILD_DIR
get_c_standard() {
    local build_dir="$1"
    local build_info_file="$build_dir/build_info.c"

    if [ ! -f "$build_info_file" ]; then
        echo "ERROR: Build info file not found: $build_info_file"
        exit 1
    fi

    # Look for lines like: const char* C_STANDARD = "11";
    local std=$(grep 'C_STANDARD = ' "$build_info_file" | sed 's/.*C_STANDARD = "\(.*\)";/\1/')

    if [ -z "$std" ]; then
        echo "ERROR: Could not extract C standard from $build_info_file"
        exit 1
    fi

    echo "$std"
}

# Verify C standard matches expected value
# Usage: verify_c_standard BUILD_DIR EXPECTED_STD
verify_c_standard() {
    local build_dir="$1"
    local expected="$2"

    local actual=$(get_c_standard "$build_dir")

    if [ "$actual" != "$expected" ]; then
        echo "ERROR: C standard mismatch!"
        echo "  Expected: $expected"
        echo "  Actual:   $actual"
        exit 1
    fi

    echo "SUCCESS: C standard is $actual"
}

# Run a basic test with optional LIBRA_C_STANDARD override
# Usage: run_c_standard_test TEST_NAME [LIBRA_C_STANDARD] [CMAKE_C_STANDARD]
run_c_standard_test() {
    local test_name="$1"
    local libra_std="${2:-}"
    local cmake_std="${3:-}"
    local test_dir="$BUILDDIR/${test_name}"


    rm -rf "$test_dir"
    mkdir -p "$test_dir" && cd "$test_dir"

    local cmake_args=(
        "$SCRIPTDIR/sample_build_info"
        -DCMAKE_INSTALL_PREFIX=/tmp/libra_c_standard_test
        -DCMAKE_BUILD_TYPE=Debug
        -DLIBRA_TEST_LANGUAGE=C
        --log-level=$LOGLEVEL
    )

    if [ -n "$libra_std" ]; then
        cmake_args+=(-DLIBRA_C_STANDARD="$libra_std")
    fi

    if [ -n "$cmake_std" ]; then
        cmake_args+=(-DCMAKE_C_STANDARD="$cmake_std")
    fi

    cmake "${cmake_args[@]}"
    make
}

################################################################################
# Test Suite
################################################################################

echo "========================================================================"
echo "Testing LIBRA_C_STANDARD"
echo "========================================================================"

# Test 1: Default behavior (no LIBRA_C_STANDARD or CMAKE_C_STANDARD)
echo ""
echo "--- Test 1: Default C Standard ---"
run_c_standard_test "default"
default_std=$(get_c_standard "$BUILDDIR/default")
echo "Default C standard: $default_std"

# Test 2: Respect CMAKE_C_STANDARD when set
echo ""
echo "--- Test 2: Respect CMAKE_C_STANDARD ---"
for std in "${C_STANDARDS[@]}"; do
    run_c_standard_test "cmake_std_${std}" "" "$std"
    verify_c_standard "$BUILDDIR/cmake_std_${std}" "c$std"
done

# Test 3: LIBRA_C_STANDARD sets the standard when CMAKE_C_STANDARD not set
echo ""
echo "--- Test 3: LIBRA_C_STANDARD Sets Standard ---"
for std in "${C_STANDARDS[@]}"; do
    run_c_standard_test "libra_std_${std}" "c$std" ""
    verify_c_standard "$BUILDDIR/libra_std_${std}" "c$std"
done

# Test 4: CMAKE_C_STANDARD takes precedence over LIBRA_C_STANDARD
echo ""
echo "--- Test 4: CMAKE_C_STANDARD Overrides LIBRA_C_STANDARD ---"
run_c_standard_test "precedence_test" "11" "17"
verify_c_standard "$BUILDDIR/precedence_test" "c17"
echo "SUCCESS: CMAKE_C_STANDARD correctly overrides LIBRA_C_STANDARD"

echo ""
echo "========================================================================"
echo "ALL TESTS PASSED!"
echo "========================================================================"
echo ""
echo "Summary of tests:"
echo "  ✓ Default standard behavior"
echo "  ✓ CMAKE_C_STANDARD respected"
echo "  ✓ LIBRA_C_STANDARD sets standard"
echo "  ✓ CMAKE_C_STANDARD takes precedence"
echo ""
