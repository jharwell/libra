#!/bin/bash
#
# Unit tests for LIBRA_FORTIFY variable across supported compilers
#
# Usage: ./LIBRA_FORTIFY-utest.sh [COMPILER_TYPE] [LANGUAGE]
#   COMPILER_TYPE: gnu or clang (default: gnu)
#   LANGUAGE: c, cxx, or both (default: both)
#   Note: Intel compiler does not support LIBRA_FORTIFY
#   Note: GOT mode uses linker flags (LIBRA_TARGET_FLAGS_LINK) which are not
#         currently written to the build_info files, so cannot be tested
#

# set -x
set -e
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPT_NAME=$(basename "$0")
SCRIPT_NAME_NO_EXT="${SCRIPT_NAME%.*}"
# Parse command line arguments
COMPILER_TYPE="${1:-gnu}"
LANGUAGE="${2:-both}"
BUILDDIR=$SCRIPTDIR/build/LIBRA_FORTIFY_tests/${COMPILER_TYPE}

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

# Expected flags for each compiler/fortify mode combination
# Note: Flags are the same for C and C++ (defined in LIBRA_{C,CXX}_FORTIFY_OPTIONS)

# GNU fortify flags
declare -a GNU_STACK_FLAGS=(
    "-fstack-protector"
)

declare -a GNU_SOURCE_FLAGS=(
    "-D_FORTIFY_SOURCE=2"
)

declare -a GNU_ALL_FLAGS=(
    "-D_FORTIFY_SOURCE=2"
    "-fstack-protector"
)

# Clang fortify flags
declare -a CLANG_STACK_FLAGS=(
    "-fstack-protector"
)

declare -a CLANG_SOURCE_FLAGS=(
    "-D_FORTIFY_SOURCE=2"
)

declare -a CLANG_ALL_FLAGS=(
    "-D_FORTIFY_SOURCE=2"
    "-fstack-protector"
)

# Flags that should NOT be present for NONE
declare -a GNU_NONE_ABSENT_FLAGS=(
    "-fstack-protector"
    "-D_FORTIFY_SOURCE"
)

declare -a CLANG_NONE_ABSENT_FLAGS=(
    "-fstack-protector"
    "-D_FORTIFY_SOURCE"
)

################################################################################
# Helper Functions
################################################################################
source $SCRIPTDIR/utils.sh

# Run a test for a specific fortify mode and language
# Usage: run_fortify_test LANGUAGE FORTIFY_MODE LIBRA_FORTIFY_VALUE
run_fortify_test() {
    local lang="$1"
    local fortify_mode="$2"
    local libra_fortify_value="$3"
    local test_dir="$BUILDDIR/${lang}/${fortify_mode,,}"

    local lang_upper=$(echo "$lang" | tr '[:lower:]' '[:upper:]')
    local compiler_var="${lang_upper}_COMPILER_EXEC[$COMPILER_TYPE]"
    local compiler="${!compiler_var}"

    echo "[TEST $COMPILER_TYPE/$lang] LIBRA_FORTIFY=$libra_fortify_value..."

    rm -rf "$test_dir"
    mkdir -p "$test_dir" && cd "$test_dir"

    if [ "$lang" = "c" ]; then
        cmake "$SCRIPTDIR/sample_build_info" \
              -DCMAKE_INSTALL_PREFIX=/tmp/libra_fortify_test \
              -DCMAKE_C_COMPILER="$compiler" \
              -DCMAKE_BUILD_TYPE=Release \
              -DLIBRA_FORTIFY="$libra_fortify_value" \
              -DLIBRA_TEST_LANGUAGE=C \
              --log-level=$LOGLEVEL
    else
        cmake "$SCRIPTDIR/sample_build_info" \
              -DCMAKE_INSTALL_PREFIX=/tmp/libra_fortify_test \
              -DCMAKE_CXX_COMPILER="$compiler" \
              -DCMAKE_BUILD_TYPE=Release \
              -DLIBRA_FORTIFY="$libra_fortify_value" \
              -DLIBRA_TEST_LANGUAGE=CXX \
              --log-level=$LOGLEVEL
    fi

    make

    # Get expected flags for this compiler/fortify mode combination
    local expected_flags=($(get_expected_flags "$COMPILER_TYPE" "$fortify_mode"))

    if [ ${#expected_flags[@]} -eq 0 ]; then
        echo "WARNING: No expected flags defined for $COMPILER_TYPE/$fortify_mode, skipping verification"
        return 0
    fi

    verify_compile_flags_present "$test_dir" "${expected_flags[@]}"
}

# Run all fortify tests for a specific language
# Usage: run_all_tests LANGUAGE
run_all_tests() {
    local lang="$1"
    local lang_upper=$(echo "$lang" | tr '[:lower:]' '[:upper:]')
    local compiler_var="${lang_upper}_COMPILER_EXEC[$COMPILER_TYPE]"
    local compiler="${!compiler_var}"

    echo "========================================================================"
    echo "Testing LIBRA_FORTIFY with $COMPILER_TYPE/$lang ($compiler)"
    echo "========================================================================"

    # Test 1: NONE - no fortify flags should be present
    echo "[TEST $COMPILER_TYPE/$lang] LIBRA_FORTIFY=NONE..."
    test_dir="$BUILDDIR/${lang}/none"
    rm -rf "$test_dir"
    mkdir -p "$test_dir" && cd "$test_dir"

    if [ "$lang" = "c" ]; then
        cmake "$SCRIPTDIR/sample_build_info" \
              -DCMAKE_INSTALL_PREFIX=/tmp/libra_fortify_test \
              -DCMAKE_C_COMPILER="$compiler" \
              -DCMAKE_BUILD_TYPE=Release \
              -DLIBRA_FORTIFY=NONE \
              -DLIBRA_TEST_LANGUAGE=C \
              --log-level=$LOGLEVEL
    else
        cmake "$SCRIPTDIR/sample_build_info" \
              -DCMAKE_INSTALL_PREFIX=/tmp/libra_fortify_test \
              -DCMAKE_CXX_COMPILER="$compiler" \
              -DCMAKE_BUILD_TYPE=Release \
              -DLIBRA_FORTIFY=NONE \
              -DLIBRA_TEST_LANGUAGE=CXX \
              --log-level=$LOGLEVEL
    fi

    make

    # Get flags that should be absent for this compiler
    absent_flags_var="${COMPILER_TYPE^^}_NONE_ABSENT_FLAGS[@]"
    absent_flags=("${!absent_flags_var}")
    verify_compile_flags_absent "$test_dir" "${absent_flags[@]}"

    # Test individual fortify modes
    run_fortify_test "$lang" "STACK" "STACK"
    run_fortify_test "$lang" "SOURCE" "SOURCE"
    run_fortify_test "$lang" "ALL" "ALL"

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
    echo "Note: Intel compiler does not support LIBRA_FORTIFY"
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
