#!/bin/bash
#
# Unit tests for LIBRA_ERL variable
#
# Usage: ./LIBRA_ERL-utest.sh
#   Note: This test is independent of compiler type
#   Note: LIBRA_ERL is a cache variable, not a boolean option
#

# set -x
set -e
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPT_NAME=$(basename "$0")
SCRIPT_NAME_NO_EXT="${SCRIPT_NAME%.*}"
BUILDDIR=$SCRIPTDIR/build/LIBRA_ERL_tests

LOGLEVEL=ERROR

# Valid LIBRA_ERL values
# Based on libra/project.cmake:
# Event Reporting Level (logging level)
# - NONE: No logging
# - ERROR: Error level only
# - WARN: Warning and above
# - INFO: Info and above
# - DEBUG: Debug and above
# - TRACE: Trace and above
# - ALL: All logging
# - INHERIT: Inherit from parent project
VALID_ERL_VALUES=(
    "NONE"
    "ERROR"
    "WARN"
    "INFO"
    "DEBUG"
    "TRACE"
    "ALL"
    "INHERIT"
)

################################################################################
# Helper Functions
################################################################################

# Function to get a CMake cache variable value
# Usage: get_cache_value BUILD_DIR VARIABLE_NAME
get_cache_value() {
    local build_dir="$1"
    local var_name="$2"
    
    if [ ! -f "$build_dir/CMakeCache.txt" ]; then
        echo "ERROR: CMakeCache.txt not found in $build_dir"
        return 1
    fi
    
    # Extract the value from CMakeCache.txt
    # Format: VARIABLE_NAME:TYPE=value
    local value=$(grep "^${var_name}:" "$build_dir/CMakeCache.txt" | cut -d'=' -f2)
    echo "$value"
}

# Verify that LIBRA_ERL is set to expected value
# Usage: verify_erl_value BUILD_DIR EXPECTED_VALUE
verify_erl_value() {
    local build_dir="$1"
    local expected="$2"
    
    echo "  Verifying LIBRA_ERL is set to '$expected'..."
    
    local actual=$(get_cache_value "$build_dir" "LIBRA_ERL")
    
    if [ "$actual" = "$expected" ]; then
        echo "    ✓ LIBRA_ERL = '$actual' (correct)"
        echo "SUCCESS: LIBRA_ERL correctly set to '$expected'"
        return 0
    else
        echo "    ✗ ERROR: LIBRA_ERL = '$actual' (expected '$expected')"
        exit 1
    fi
}

################################################################################
# Test Cases
################################################################################

echo "========================================================================"
echo "Testing LIBRA_ERL (Event Reporting Level / Logging Level)"
echo "========================================================================"

# Determine source directory
if [ -d "$SCRIPTDIR/sample_build_info" ]; then
    source_dir="$SCRIPTDIR/sample_build_info"
else
    echo "ERROR: sample_build_info not found"
    exit 1
fi

# Test each valid ERL value
test_num=1
for erl_value in "${VALID_ERL_VALUES[@]}"; do
    echo ""
    echo "[TEST $test_num] LIBRA_ERL=$erl_value"
    echo "------------------------------------------------------------------------"
    
    test_dir="$BUILDDIR/${erl_value,,}"
    rm -rf "$test_dir"
    mkdir -p "$test_dir" && cd "$test_dir"
    
    cmake "$source_dir" \
          -DCMAKE_BUILD_TYPE=Release \
          -DLIBRA_ERL="$erl_value" \
          --log-level=$LOGLEVEL
    
    verify_erl_value "$test_dir" "$erl_value"
    
    echo "------------------------------------------------------------------------"
    ((test_num++))
done

# Test default value (should be INHERIT)
echo ""
echo "[TEST $test_num] Default LIBRA_ERL value (no explicit setting)"
echo "------------------------------------------------------------------------"

test_dir="$BUILDDIR/default"
rm -rf "$test_dir"
mkdir -p "$test_dir" && cd "$test_dir"

cmake "$source_dir" \
      -DCMAKE_BUILD_TYPE=Release \
      --log-level=$LOGLEVEL

verify_erl_value "$test_dir" "INHERIT"

echo "------------------------------------------------------------------------"

echo ""
echo "========================================================================"
echo "ALL TESTS PASSED!"
echo "========================================================================"
echo ""
echo "Summary:"
echo "  ✓ LIBRA_ERL=NONE: No logging"
echo "  ✓ LIBRA_ERL=ERROR: Error level logging only"
echo "  ✓ LIBRA_ERL=WARN: Warning and above"
echo "  ✓ LIBRA_ERL=INFO: Info and above"
echo "  ✓ LIBRA_ERL=DEBUG: Debug and above"
echo "  ✓ LIBRA_ERL=TRACE: Trace and above"
echo "  ✓ LIBRA_ERL=ALL: All logging levels"
echo "  ✓ LIBRA_ERL=INHERIT: Inherit from parent project"
echo "  ✓ Default value is INHERIT"
echo ""
