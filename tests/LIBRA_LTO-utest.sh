#!/bin/bash
#
# Unit tests for LIBRA_LTO variable across all supported compilers
#
# Usage: ./LIBRA_LTO-utest.sh [COMPILER_TYPE] [LANGUAGE]
#   COMPILER_TYPE: gnu, clang, or intel (default: gnu)
#   LANGUAGE: c, cxx, or both (default: both)
#

# set -x
set -e
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPT_NAME=$(basename "$0")
SCRIPT_NAME_NO_EXT="${SCRIPT_NAME%.*}"
# Parse command line arguments
COMPILER_TYPE="${1:-gnu}"
LANGUAGE="${2:-both}"
BUILDDIR=$SCRIPTDIR/build/LIBRA_LTO_tests/${COMPILER_TYPE}

LOGLEVEL=ERROR

################################################################################
# Compiler Configuration Maps
################################################################################

# Map compiler types to actual compiler executables
declare -A C_COMPILER_EXEC=(
    ["gnu"]="gcc"
    ["clang"]="clang"
    ["intel"]="icx"
)

declare -A CXX_COMPILER_EXEC=(
    ["gnu"]="g++"
    ["clang"]="clang++"
    ["intel"]="icpx"
)

################################################################################
# Helper Functions
################################################################################

# Function to verify that INTERPROCEDURAL_OPTIMIZATION property is set correctly
# Usage: verify_ipo_property "build_dir" "expected_value"
verify_ipo_property() {
    local build_dir="$1"
    local expected_value="$2"

    # Read the CMakeCache.txt to find the project name
    local cmake_cache="$build_dir/CMakeCache.txt"

    if [ ! -f "$cmake_cache" ]; then
        echo "ERROR: CMakeCache.txt not found in $build_dir"
        exit 1
    fi

    # Look for the project name from CMakeCache
    local project_name=$(grep "CMAKE_PROJECT_NAME:" "$cmake_cache" | cut -d'=' -f2)

    if [ -z "$project_name" ]; then
        echo "ERROR: Could not determine project name from CMakeCache.txt"
        exit 1
    fi

    echo "  Checking target '$project_name' for INTERPROCEDURAL_OPTIMIZATION via flags.make"

    # Check the flags.make file for LTO/IPO flags
    local target_dir="$build_dir/CMakeFiles/${project_name}.dir"

    if [ ! -d "$target_dir" ]; then
        echo "ERROR: Target directory not found: $target_dir"
        exit 1
    fi

    local flags_file="$target_dir/flags.make"
    if [ ! -f "$flags_file" ]; then
        echo "ERROR: flags.make not found: $flags_file"
        exit 1
    fi

    if [ "$expected_value" = "TRUE" ]; then
        # Look for -flto or -ipo flags
        if grep -q -- "-flto\|-ipo" "$flags_file"; then
            echo "SUCCESS: Found LTO/IPO flags in flags.make (INTERPROCEDURAL_OPTIMIZATION is enabled)"
        else
            echo "ERROR: Expected IPO to be enabled but no LTO/IPO flags found in flags.make"
            echo "Contents of flags.make:"
            cat "$flags_file"
            exit 1
        fi
    else
        # Verify no -flto or -ipo flags present
        if grep -q -- "-flto\|-ipo" "$flags_file"; then
            echo "ERROR: Expected IPO to be disabled but found LTO/IPO flags in flags.make"
            echo "Contents of flags.make:"
            cat "$flags_file"
            exit 1
        else
            echo "SUCCESS: No LTO/IPO flags found in flags.make (INTERPROCEDURAL_OPTIMIZATION is disabled)"
        fi
    fi
}

# Run a test for LTO ON/OFF and language
# Usage: run_lto_test LANGUAGE LTO_MODE LIBRA_LTO_VALUE EXPECTED_IPO
run_lto_test() {
    local lang="$1"
    local lto_mode="$2"
    local libra_lto_value="$3"
    local expected_ipo="$4"
    local test_dir="$BUILDDIR/${lang}/${lto_mode,,}"

    local lang_upper=$(echo "$lang" | tr '[:lower:]' '[:upper:]')
    local compiler_var="${lang_upper}_COMPILER_EXEC[$COMPILER_TYPE]"
    local compiler="${!compiler_var}"

    echo "[TEST $COMPILER_TYPE/$lang] LIBRA_LTO=$libra_lto_value..."

    rm -rf "$test_dir"
    mkdir -p "$test_dir" && cd "$test_dir"

    if [ "$lang" = "c" ]; then
        cmake "$SCRIPTDIR/sample_build_info" \
              -DCMAKE_INSTALL_PREFIX=/tmp/libra_lto_test \
              -DCMAKE_C_COMPILER="$compiler" \
              -DCMAKE_BUILD_TYPE=Release \
              -DLIBRA_LTO="$libra_lto_value" \
              -DLIBRA_TEST_LANGUAGE=C \
              --log-level=$LOGLEVEL
    else
        cmake "$SCRIPTDIR/sample_build_info" \
              -DCMAKE_INSTALL_PREFIX=/tmp/libra_lto_test \
              -DCMAKE_CXX_COMPILER="$compiler" \
              -DCMAKE_BUILD_TYPE=Release \
              -DLIBRA_LTO="$libra_lto_value" \
              -DLIBRA_TEST_LANGUAGE=CXX \
              --log-level=$LOGLEVEL
    fi

    verify_ipo_property "$test_dir" "$expected_ipo"
}

# Run all LTO tests for a specific language
# Usage: run_all_tests LANGUAGE
run_all_tests() {
    local lang="$1"
    local lang_upper=$(echo "$lang" | tr '[:lower:]' '[:upper:]')
    local compiler_var="${lang_upper}_COMPILER_EXEC[$COMPILER_TYPE]"
    local compiler="${!compiler_var}"

    echo "========================================================================"
    echo "Testing LIBRA_LTO with $COMPILER_TYPE/$lang ($compiler)"
    echo "========================================================================"

    # Test 1: OFF - INTERPROCEDURAL_OPTIMIZATION should be FALSE
    run_lto_test "$lang" "OFF" "OFF" "FALSE"

    # Test 2: ON - INTERPROCEDURAL_OPTIMIZATION should be TRUE
    run_lto_test "$lang" "ON" "ON" "TRUE"

    echo "========================================================================"
    echo "ALL TESTS PASSED for $COMPILER_TYPE/$lang!"
    echo "========================================================================"
    echo ""
}

################################################################################
# Validation
################################################################################

# Validate compiler type
if [[ ! -v C_COMPILER_EXEC[$COMPILER_TYPE] ]]; then
    echo "ERROR: Unknown compiler type: $COMPILER_TYPE"
    echo "Valid options: gnu, clang, intel"
    exit 1
fi

################################################################################
# Test Execution
################################################################################

# Run tests based on language selection
if [[ "$LANGUAGE" == "both" || "$LANGUAGE" == "cxx" ]]; then
    run_all_tests "cxx"
fi

if [[ "$LANGUAGE" == "both" || "$LANGUAGE" == "c" ]]; then
    run_all_tests "c"
fi

echo "========================================================================"
echo "ALL TESTS COMPLETED SUCCESSFULLY!"
echo "========================================================================"
