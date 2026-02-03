#!/bin/bash
#
# Unit tests for LIBRA_BUILD_PROF variable across all supported compilers
#
# Usage: ./LIBRA_BUILD_PROF-utest.sh [COMPILER_TYPE] [LANGUAGE]
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
BUILDDIR=$SCRIPTDIR/build/LIBRA_BUILD_PROF_tests/${COMPILER_TYPE}

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

# Expected flags for each compiler/build profiling combination
# Note: Flags are the same for C and C++ (defined in LIBRA_{C,CXX}_BUILD_PROF_OPTIONS)

# GNU build profiling flags
declare -a GNU_ON_FLAGS=(
    "-ftime-report"
)

# Clang build profiling flags
declare -a CLANG_ON_FLAGS=(
    "-ftime-trace"
)

# Intel build profiling flags
declare -a INTEL_ON_FLAGS=(
)

################################################################################
# Helper Functions
################################################################################
source $SCRIPTDIR/utils.sh

# Run a test for build profiling ON/OFF and language
# Usage: run_build_prof_test LANGUAGE PROF_MODE LIBRA_BUILD_PROF_VALUE
run_build_prof_test() {
    local lang="$1"
    local prof_mode="$2"
    local libra_build_prof_value="$3"
    local test_dir="$BUILDDIR/${lang}/${prof_mode,,}"

    local lang_upper=$(echo "$lang" | tr '[:lower:]' '[:upper:]')
    local compiler_var="${lang_upper}_COMPILER_EXEC[$COMPILER_TYPE]"
    local compiler="${!compiler_var}"

    echo "[TEST $COMPILER_TYPE/$lang] LIBRA_BUILD_PROF=$libra_build_prof_value..."

    rm -rf "$test_dir"
    mkdir -p "$test_dir" && cd "$test_dir"

    if [ "$lang" = "c" ]; then
        cmake "$SCRIPTDIR/sample_build_info" \
              -DCMAKE_INSTALL_PREFIX=/tmp/libra_build_prof_test \
              -DCMAKE_C_COMPILER="$compiler" \
              -DCMAKE_BUILD_TYPE=Release \
              -DLIBRA_BUILD_PROF="$libra_build_prof_value" \
              -DLIBRA_TEST_LANGUAGE=C \
              --log-level=$LOGLEVEL
    else
        cmake "$SCRIPTDIR/sample_build_info" \
              -DCMAKE_INSTALL_PREFIX=/tmp/libra_build_prof_test \
              -DCMAKE_CXX_COMPILER="$compiler" \
              -DCMAKE_BUILD_TYPE=Release \
              -DLIBRA_BUILD_PROF="$libra_build_prof_value" \
              -DLIBRA_TEST_LANGUAGE=CXX \
              --log-level=$LOGLEVEL
    fi

    make

    # Get expected flags for this compiler/profiling mode combination
    local expected_flags=($(get_expected_flags "$COMPILER_TYPE" "$prof_mode"))

    if [ ${#expected_flags[@]} -eq 0 ]; then
        echo "WARNING: No expected flags defined for $COMPILER_TYPE/$prof_mode, skipping verification"
        return 0
    fi

    verify_compile_flags_present "$test_dir" "${expected_flags[@]}"
}

# Run all build profiling tests for a specific language
# Usage: run_all_tests LANGUAGE
run_all_tests() {
    local lang="$1"
    local lang_upper=$(echo "$lang" | tr '[:lower:]' '[:upper:]')
    local compiler_var="${lang_upper}_COMPILER_EXEC[$COMPILER_TYPE]"
    local compiler="${!compiler_var}"

    echo "========================================================================"
    echo "Testing LIBRA_BUILD_PROF with $COMPILER_TYPE/$lang ($compiler)"
    echo "========================================================================"

    # Test 1: OFF - no build profiling flags should be present
    echo "[TEST $COMPILER_TYPE/$lang] LIBRA_BUILD_PROF=OFF..."
    test_dir="$BUILDDIR/${lang}/off"
    rm -rf "$test_dir"
    mkdir -p "$test_dir" && cd "$test_dir"

    if [ "$lang" = "c" ]; then
        cmake "$SCRIPTDIR/sample_build_info" \
              -DCMAKE_INSTALL_PREFIX=/tmp/libra_build_prof_test \
              -DCMAKE_C_COMPILER="$compiler" \
              -DCMAKE_BUILD_TYPE=Release \
              -DLIBRA_BUILD_PROF=OFF \
              -DLIBRA_TEST_LANGUAGE=C \
              --log-level=$LOGLEVEL
    else
        cmake "$SCRIPTDIR/sample_build_info" \
              -DCMAKE_INSTALL_PREFIX=/tmp/libra_build_prof_test \
              -DCMAKE_CXX_COMPILER="$compiler" \
              -DCMAKE_BUILD_TYPE=Release \
              -DLIBRA_BUILD_PROF=OFF \
              -DLIBRA_TEST_LANGUAGE=CXX \
              --log-level=$LOGLEVEL
    fi

    make

    # Get flags that should be absent for this compiler
    if [ "$COMPILER_TYPE" = "gnu" ] || [ "$COMPILER_TYPE" = "intel" ]; then
        verify_compile_flags_absent "$test_dir" "-ftime-report"
    elif [ "$COMPILER_TYPE" = "clang" ]; then
        verify_compile_flags_absent "$test_dir" "-ftime-trace"
    fi

    # Test 2: ON - build profiling flags should be present
    run_build_prof_test "$lang" "ON" "ON"

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
