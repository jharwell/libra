#!/bin/bash
#
# Unit tests for LIBRA_DEBUG_INFO variable across all supported compilers
#
# Usage: ./LIBRA_DEBUG_INFO-utest.sh [COMPILER_TYPE] [LANGUAGE]
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
BUILDDIR=$SCRIPTDIR/build/LIBRA_DEBUG_INFO_tests/${COMPILER_TYPE}

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

# Expected flags for each compiler/debug info combination
# Note: Flags are the same for C and C++ (defined in LIBRA_{C,CXX}_DEBUG_INFO_OPTIONS)

# GNU debug info flags
declare -a GNU_ON_FLAGS=(
    "-g2"
)

declare -a GNU_OFF_FLAGS=(
    "-g0"
)

# Clang debug info flags
declare -a CLANG_ON_FLAGS=(
    "-g2"
)

declare -a CLANG_OFF_FLAGS=(
    "-g0"
)

# Intel debug info flags
declare -a INTEL_ON_FLAGS=(
    "-g2"
)

declare -a INTEL_OFF_FLAGS=(
    "-g0"
)


################################################################################
# Helper Functions
################################################################################
source $SCRIPTDIR/utils.sh

# Run a test for debug info ON/OFF and language
# Usage: run_debug_info_test LANGUAGE DEBUG_MODE LIBRA_DEBUG_INFO_VALUE
run_debug_info_test() {
    local lang="$1"
    local debug_mode="$2"
    local libra_debug_info_value="$3"
    local test_dir="$BUILDDIR/${lang}/${debug_mode,,}"

    local lang_upper=$(echo "$lang" | tr '[:lower:]' '[:upper:]')
    local compiler_var="${lang_upper}_COMPILER_EXEC[$COMPILER_TYPE]"
    local compiler="${!compiler_var}"

    echo "[TEST $COMPILER_TYPE/$lang] LIBRA_DEBUG_INFO=$libra_debug_info_value..."

    rm -rf "$test_dir"
    mkdir -p "$test_dir" && cd "$test_dir"

    if [ "$lang" = "c" ]; then
        cmake "$SCRIPTDIR/sample_build_info" \
              -DCMAKE_INSTALL_PREFIX=/tmp/libra_debug_info_test \
              -DCMAKE_C_COMPILER="$compiler" \
              -DCMAKE_BUILD_TYPE=Release \
              -DLIBRA_DEBUG_INFO="$libra_debug_info_value" \
              -DLIBRA_TEST_LANGUAGE=C \
              --log-level=$LOGLEVEL
    else
        cmake "$SCRIPTDIR/sample_build_info" \
              -DCMAKE_INSTALL_PREFIX=/tmp/libra_debug_info_test \
              -DCMAKE_CXX_COMPILER="$compiler" \
              -DCMAKE_BUILD_TYPE=Release \
              -DLIBRA_DEBUG_INFO="$libra_debug_info_value" \
              -DLIBRA_TEST_LANGUAGE=CXX \
              --log-level=$LOGLEVEL
    fi

    make

    # Get expected flags for this compiler/debug mode combination
    local expected_flags=($(get_expected_flags "$COMPILER_TYPE" "$debug_mode"))

    if [ ${#expected_flags[@]} -eq 0 ]; then
        echo "WARNING: No expected flags defined for $COMPILER_TYPE/$debug_mode, skipping verification"
        return 0
    fi

    verify_compile_flags_present "$test_dir" "${expected_flags[@]}"
}

# Run all debug info tests for a specific language
# Usage: run_all_tests LANGUAGE
run_all_tests() {
    local lang="$1"
    local lang_upper=$(echo "$lang" | tr '[:lower:]' '[:upper:]')
    local compiler_var="${lang_upper}_COMPILER_EXEC[$COMPILER_TYPE]"
    local compiler="${!compiler_var}"

    echo "========================================================================"
    echo "Testing LIBRA_DEBUG_INFO with $COMPILER_TYPE/$lang ($compiler)"
    echo "========================================================================"

    # Test 1: OFF - should have -g0 flag
    run_debug_info_test "$lang" "OFF" "OFF"

    # Test 2: ON - should have -g2 flag
    run_debug_info_test "$lang" "ON" "ON"

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
