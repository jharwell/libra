#!/bin/bash
#
# Unit tests for LIBRA_NATIVE_OPT variable across all supported compilers
#
# Usage: ./LIBRA_NATIVE_OPT-utest.sh [COMPILER_TYPE] [LANGUAGE]
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
BUILDDIR=$SCRIPTDIR/build/LIBRA_NATIVE_OPT_tests/${COMPILER_TYPE}

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

# Expected flags for each compiler/native optimization combination
# Note: Flags are the same for C and C++ (defined in LIBRA_{C,CXX}_OPT_OPTIONS)

# GNU native optimization flags
declare -a GNU_ON_FLAGS=(
    "-march=native"
    "-mtune=native"
)

# Clang native optimization flags
declare -a CLANG_ON_FLAGS=(
    "-march=native"
    "-mtune=native"
)

# Intel native optimization flags
declare -a INTEL_ON_FLAGS=(
    "-xHost"
)

# Flags that should NOT be present for OFF
declare -a GNU_OFF_ABSENT_FLAGS=(
    "-march=native"
    "-mtune=native"
)

declare -a CLANG_OFF_ABSENT_FLAGS=(
    "-march=native"
    "-mtune=native"
)

declare -a INTEL_OFF_ABSENT_FLAGS=(
    "-xHost"
)

################################################################################
# Helper Functions
################################################################################
source $SCRIPTDIR/utils.sh

# Run a test for native optimization ON/OFF and language
# Usage: run_native_opt_test LANGUAGE OPT_MODE LIBRA_NATIVE_OPT_VALUE
run_native_opt_test() {
    local lang="$1"
    local opt_mode="$2"
    local libra_native_opt_value="$3"
    local test_dir="$BUILDDIR/${lang}/${opt_mode,,}"

    local lang_upper=$(echo "$lang" | tr '[:lower:]' '[:upper:]')
    local compiler_var="${lang_upper}_COMPILER_EXEC[$COMPILER_TYPE]"
    local compiler="${!compiler_var}"

    echo "[TEST $COMPILER_TYPE/$lang] LIBRA_NATIVE_OPT=$libra_native_opt_value..."

    rm -rf "$test_dir"
    mkdir -p "$test_dir" && cd "$test_dir"

    if [ "$lang" = "c" ]; then
        cmake "$SCRIPTDIR/sample_build_info" \
              -DCMAKE_INSTALL_PREFIX=/tmp/libra_native_opt_test \
              -DCMAKE_C_COMPILER="$compiler" \
              -DCMAKE_BUILD_TYPE=Release \
              -DLIBRA_NATIVE_OPT="$libra_native_opt_value" \
              -DLIBRA_TEST_LANGUAGE=C \
              --log-level=$LOGLEVEL
    else
        cmake "$SCRIPTDIR/sample_build_info" \
              -DCMAKE_INSTALL_PREFIX=/tmp/libra_native_opt_test \
              -DCMAKE_CXX_COMPILER="$compiler" \
              -DCMAKE_BUILD_TYPE=Release \
              -DLIBRA_NATIVE_OPT="$libra_native_opt_value" \
              -DLIBRA_TEST_LANGUAGE=CXX \
              --log-level=$LOGLEVEL
    fi

    make

    # Get expected flags for this compiler/optimization mode combination
    local expected_flags=($(get_expected_flags "$COMPILER_TYPE" "$opt_mode"))

    if [ ${#expected_flags[@]} -eq 0 ]; then
        echo "WARNING: No expected compile flags defined for $COMPILER_TYPE/$opt_mode, skipping verification"
        return 0
    fi

    verify_compile_flags_present "$test_dir" "${expected_flags[@]}"
}

# Run all native optimization tests for a specific language
# Usage: run_all_tests LANGUAGE
run_all_tests() {
    local lang="$1"
    local lang_upper=$(echo "$lang" | tr '[:lower:]' '[:upper:]')
    local compiler_var="${lang_upper}_COMPILER_EXEC[$COMPILER_TYPE]"
    local compiler="${!compiler_var}"

    echo "========================================================================"
    echo "Testing LIBRA_NATIVE_OPT with $COMPILER_TYPE/$lang ($compiler)"
    echo "========================================================================"

    # Test 1: OFF - no native optimization flags should be present
    echo "[TEST $COMPILER_TYPE/$lang] LIBRA_NATIVE_OPT=OFF..."
    test_dir="$BUILDDIR/${lang}/off"
    rm -rf "$test_dir"
    mkdir -p "$test_dir" && cd "$test_dir"

    if [ "$lang" = "c" ]; then
        cmake "$SCRIPTDIR/sample_build_info" \
              -DCMAKE_INSTALL_PREFIX=/tmp/libra_native_opt_test \
              -DCMAKE_C_COMPILER="$compiler" \
              -DCMAKE_BUILD_TYPE=Release \
              -DLIBRA_NATIVE_OPT=OFF \
              -DLIBRA_TEST_LANGUAGE=C \
              --log-level=$LOGLEVEL
    else
        cmake "$SCRIPTDIR/sample_build_info" \
              -DCMAKE_INSTALL_PREFIX=/tmp/libra_native_opt_test \
              -DCMAKE_CXX_COMPILER="$compiler" \
              -DCMAKE_BUILD_TYPE=Release \
              -DLIBRA_NATIVE_OPT=OFF \
              -DLIBRA_TEST_LANGUAGE=CXX \
              --log-level=$LOGLEVEL
    fi

    make

    # Get flags that should be absent for this compiler
    absent_flags_var="${COMPILER_TYPE^^}_OFF_ABSENT_FLAGS[@]"
    absent_flags=("${!absent_flags_var}")
    verify_compile_flags_absent "$test_dir" "${absent_flags[@]}"

    # Test 2: ON - native optimization flags should be present
    run_native_opt_test "$lang" "ON" "ON"

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
