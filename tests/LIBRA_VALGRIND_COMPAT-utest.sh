#!/bin/bash
#
# Unit tests for LIBRA_VALGRIND_COMPAT variable across supported compilers
#
# Usage: ./LIBRA_VALGRIND_COMPAT-utest.sh [COMPILER_TYPE] [LANGUAGE]
#   COMPILER_TYPE: gnu or clang (default: gnu)
#   LANGUAGE: c, cxx, or both (default: both)
#   Note: Intel compiler does not support LIBRA_VALGRIND_COMPAT
#

# set -x
set -e
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPT_NAME=$(basename "$0")
SCRIPT_NAME_NO_EXT="${SCRIPT_NAME%.*}"
# Parse command line arguments
COMPILER_TYPE="${1:-gnu}"
LANGUAGE="${2:-both}"
BUILDDIR=$SCRIPTDIR/build/LIBRA_VALGRIND_COMPAT_tests/${COMPILER_TYPE}

LOGLEVEL=ERROR

################################################################################
# Compiler Configuration Maps
################################################################################

# Map compiler types to actual compiler executables
declare -A C_COMPILER_EXEC=(
    ["gnu"]="gcc"
    ["clang"]="clang"
)

declare -A CXX_COMPILER_EXEC=(
    ["gnu"]="g++"
    ["clang"]="clang++"
)

# Expected flags for each compiler/valgrind compatibility combination
# Note: Flags are the same for C and C++ (defined in LIBRA_VALGRIND_COMPAT_OPTIONS)

# GNU valgrind compatibility flags
declare -a GNU_ON_COMPILE_FLAGS=(
    "-mno-sse3"
)

# Clang valgrind compatibility flags
declare -a CLANG_ON_COMPILE_FLAGS=(
    "-mno-sse3"
)

# Flags that should NOT be present for OFF
declare -a GNU_OFF_ABSENT_COMPILE_FLAGS=(
    "-mno-sse3"
)

declare -a CLANG_OFF_ABSENT_COMPILE_FLAGS=(
    "-mno-sse3"
)

################################################################################
# Helper Functions
################################################################################
source $SCRIPTDIR/utils.sh

# Run a test for valgrind compatibility ON/OFF and language
# Usage: run_valgrind_compat_test LANGUAGE COMPAT_MODE LIBRA_VALGRIND_COMPAT_VALUE
run_valgrind_compat_test() {
    local lang="$1"
    local compat_mode="$2"
    local libra_valgrind_compat_value="$3"
    local test_dir="$BUILDDIR/${lang}/${compat_mode,,}"

    local lang_upper=$(echo "$lang" | tr '[:lower:]' '[:upper:]')
    local compiler_var="${lang_upper}_COMPILER_EXEC[$COMPILER_TYPE]"
    local compiler="${!compiler_var}"

    echo "[TEST $COMPILER_TYPE/$lang] LIBRA_VALGRIND_COMPAT=$libra_valgrind_compat_value..."

    rm -rf "$test_dir"
    mkdir -p "$test_dir" && cd "$test_dir"

    if [ "$lang" = "c" ]; then
        cmake "$SCRIPTDIR/sample_build_info" \
              -DCMAKE_INSTALL_PREFIX=/tmp/libra_valgrind_compat_test \
              -DCMAKE_C_COMPILER="$compiler" \
              -DCMAKE_BUILD_TYPE=Debug \
              -DLIBRA_VALGRIND_COMPAT="$libra_valgrind_compat_value" \
              -DLIBRA_TEST_LANGUAGE=C \
              --log-level=$LOGLEVEL
    else
        cmake "$SCRIPTDIR/sample_build_info" \
              -DCMAKE_INSTALL_PREFIX=/tmp/libra_valgrind_compat_test \
              -DCMAKE_CXX_COMPILER="$compiler" \
              -DCMAKE_BUILD_TYPE=Debug \
              -DLIBRA_VALGRIND_COMPAT="$libra_valgrind_compat_value" \
              -DLIBRA_TEST_LANGUAGE=CXX \
              --log-level=$LOGLEVEL
    fi

    make

    # Get expected flags for this compiler/compatibility mode combination
    local expected_compile_flags=($(get_expected_compile_flags "$COMPILER_TYPE" "$compat_mode"))

    if [ ${#expected_compile_flags[@]} -eq 0 ]; then
        echo "WARNING: No expected compile flags defined for $COMPILER_TYPE/$compat_mode, skipping verification"
        return 0
    fi

    verify_compile_flags_present "$test_dir" "${expected_compile_flags[@]}"
}

# Run all valgrind compatibility tests for a specific language
# Usage: run_all_tests LANGUAGE
run_all_tests() {
    local lang="$1"
    local lang_upper=$(echo "$lang" | tr '[:lower:]' '[:upper:]')
    local compiler_var="${lang_upper}_COMPILER_EXEC[$COMPILER_TYPE]"
    local compiler="${!compiler_var}"

    echo "========================================================================"
    echo "Testing LIBRA_VALGRIND_COMPAT with $COMPILER_TYPE/$lang ($compiler)"
    echo "========================================================================"

    # Test 1: OFF - no valgrind compatibility flags should be present
    echo "[TEST $COMPILER_TYPE/$lang] LIBRA_VALGRIND_COMPAT=OFF..."
    test_dir="$BUILDDIR/${lang}/off"
    rm -rf "$test_dir"
    mkdir -p "$test_dir" && cd "$test_dir"

    if [ "$lang" = "c" ]; then
        cmake "$SCRIPTDIR/sample_build_info" \
              -DCMAKE_INSTALL_PREFIX=/tmp/libra_valgrind_compat_test \
              -DCMAKE_C_COMPILER="$compiler" \
              -DCMAKE_BUILD_TYPE=Debug \
              -DLIBRA_VALGRIND_COMPAT=OFF \
              -DLIBRA_TEST_LANGUAGE=C \
              --log-level=$LOGLEVEL
    else
        cmake "$SCRIPTDIR/sample_build_info" \
              -DCMAKE_INSTALL_PREFIX=/tmp/libra_valgrind_compat_test \
              -DCMAKE_CXX_COMPILER="$compiler" \
              -DCMAKE_BUILD_TYPE=Debug \
              -DLIBRA_VALGRIND_COMPAT=OFF \
              -DLIBRA_TEST_LANGUAGE=CXX \
              --log-level=$LOGLEVEL
    fi

    make

    # Get flags that should be absent for this compiler
    absent_flags_var="${COMPILER_TYPE^^}_OFF_ABSENT_COMPILE_FLAGS[@]"
    absent_flags=("${!absent_flags_var}")
    verify_compile_flags_absent "$test_dir" "${absent_flags[@]}"

    # Test 2: ON - valgrind compatibility flags should be present
    run_valgrind_compat_test "$lang" "ON" "ON"

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
    echo "Valid options: gnu, clang"
    echo "Note: Intel compiler does not support LIBRA_VALGRIND_COMPAT"
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
