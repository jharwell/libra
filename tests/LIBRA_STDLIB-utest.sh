#!/bin/bash
#
# Unit tests for LIBRA_STDLIB variable across all supported compilers
#
# Usage: ./LIBRA_STDLIB-utest.sh [COMPILER_TYPE] [LANGUAGE]
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
BUILDDIR=$SCRIPTDIR/build/LIBRA_STDLIB_tests/${COMPILER_TYPE}

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

# Expected flags for each compiler/stdlib combination
# Note: Flags are the same for C and C++ (defined in LIBRA_STDLIB_OPTIONS)

# GNU stdlib flags (only supports NONE)
declare -a GNU_NONE_FLAGS=(
    "-nostdlib"
)

# Clang stdlib flags
declare -a CLANG_NONE_FLAGS=(
    "-nostdlib"
)

declare -a CLANG_STDCXX_FLAGS=(
    "-stdlib=libstdc++"
)

declare -a CLANG_CXX_FLAGS=(
    "-stdlib=libc++"
)

# Intel stdlib flags
declare -a INTEL_NONE_FLAGS=(
    "-nostdlib"
)

declare -a INTEL_STDCXX_FLAGS=(
    "-stdlib=libstdc++"
)

declare -a INTEL_CXX_FLAGS=(
    "-stdlib=libc++"
)

################################################################################
# Helper Functions
################################################################################
source $SCRIPTDIR/utils.sh

# Run a test for a specific stdlib mode and language
# Usage: run_stdlib_test LANGUAGE STDLIB_MODE LIBRA_STDLIB_VALUE
run_stdlib_test() {
    local lang="$1"
    local stdlib_mode="$2"
    local libra_stdlib_value="$3"
    local test_dir="$BUILDDIR/${lang}/${stdlib_mode,,}"

    local lang_upper=$(echo "$lang" | tr '[:lower:]' '[:upper:]')
    local compiler_var="${lang_upper}_COMPILER_EXEC[$COMPILER_TYPE]"
    local compiler="${!compiler_var}"

    echo "[TEST $COMPILER_TYPE/$lang] LIBRA_STDLIB=$libra_stdlib_value..."

    rm -rf "$test_dir"
    mkdir -p "$test_dir" && cd "$test_dir"

    if [ "$lang" = "c" ]; then
        cmake "$SCRIPTDIR/sample_build_info" \
              -DCMAKE_INSTALL_PREFIX=/tmp/libra_stdlib_test \
              -DCMAKE_C_COMPILER="$compiler" \
              -DCMAKE_BUILD_TYPE=Release \
              -DLIBRA_STDLIB="$libra_stdlib_value" \
              -DLIBRA_TEST_LANGUAGE=C \
              --log-level=$LOGLEVEL
    else
        cmake "$SCRIPTDIR/sample_build_info" \
              -DCMAKE_INSTALL_PREFIX=/tmp/libra_stdlib_test \
              -DCMAKE_CXX_COMPILER="$compiler" \
              -DCMAKE_BUILD_TYPE=Release \
              -DLIBRA_STDLIB="$libra_stdlib_value" \
              -DLIBRA_TEST_LANGUAGE=CXX \
              --log-level=$LOGLEVEL
    fi

    make

    # Get expected flags for this compiler/stdlib mode combination
    local expected_flags=($(get_expected_flags "$COMPILER_TYPE" "$stdlib_mode"))

    if [ ${#expected_flags[@]} -eq 0 ]; then
        echo "WARNING: No expected flags defined for $COMPILER_TYPE/$stdlib_mode, skipping verification"
        return 0
    fi

    verify_link_flags_present "$test_dir" "${expected_flags[@]}"
}

# Run all stdlib tests for a specific language
# Usage: run_all_tests LANGUAGE
run_all_tests() {
    local lang="$1"
    local lang_upper=$(echo "$lang" | tr '[:lower:]' '[:upper:]')
    local compiler_var="${lang_upper}_COMPILER_EXEC[$COMPILER_TYPE]"
    local compiler="${!compiler_var}"

    echo "========================================================================"
    echo "Testing LIBRA_STDLIB with $COMPILER_TYPE/$lang ($compiler)"
    echo "========================================================================"

    # Test NONE mode for both C and C++ (all compilers support this)
    run_stdlib_test "$lang" "NONE" "NONE"

    # Test STDCXX and CXX modes only for C++ with Clang and Intel
    if [ "$lang" = "cxx" ]; then
        if [ "$COMPILER_TYPE" = "clang" ] || [ "$COMPILER_TYPE" = "intel" ]; then
            run_stdlib_test "$lang" "STDCXX" "STDCXX"
            run_stdlib_test "$lang" "CXX" "CXX"
        else
            echo "[INFO] GNU compiler only supports default stdlib for C++, skipping STDCXX and CXX tests"
        fi
    fi

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
