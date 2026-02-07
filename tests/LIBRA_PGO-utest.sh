#!/bin/bash
#
# Unit tests for LIBRA_PGO variable across all supported compilers
#
# Usage: ./08_LIBRA_PGO-utest.sh [COMPILER_TYPE] [LANGUAGE]
#   COMPILER_TYPE: gnu, clang, or intel (default: gnu)
#   LANGUAGE: c, cxx, or both (default: both)
#

set -x
set -e
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPT_NAME=$(basename "$0")
SCRIPT_NAME_NO_EXT="${SCRIPT_NAME%.*}"
# Parse command line arguments
COMPILER_TYPE="${1:-gnu}"
LANGUAGE="${2:-both}"
BUILDDIR=$SCRIPTDIR/build/LIBRA_PGO_tests/${COMPILER_TYPE}

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

# Expected flags for each compiler/PGO mode combination
# Note: Flags are the same for C and C++ (defined in LIBRA_{C,CXX}_PGO_OPTIONS)

# GNU PGO flags
declare -a GNU_GEN_FLAGS=(
    "-fprofile-generate"
)

declare -a GNU_USE_FLAGS=(
    "-fprofile-use"
)

# Clang PGO flags
declare -a CLANG_GEN_FLAGS=(
    "-fprofile-generate"
)

declare -a CLANG_USE_FLAGS=(
    "-fprofile-use"
)

# Intel PGO flags
declare -a INTEL_GEN_FLAGS=(
    "-fprofile-generate"
)

declare -a INTEL_USE_FLAGS=(
    "-fprofile-use"
)

# Flags that should NOT be present for NONE
declare -a GNU_NONE_ABSENT_FLAGS=(
    "-fprofile-generate"
    "-fprofile-use"
)

declare -a CLANG_NONE_ABSENT_FLAGS=(
    "-fprofile-generate"
    "-fprofile-use"
)

declare -a INTEL_NONE_ABSENT_FLAGS=(
    "-fprofile-generate"
    "-fprofile-use"
)

################################################################################
# Helper Functions
################################################################################
source $SCRIPTDIR/utils.sh

# Run a test for a specific PGO mode and language
# Usage: run_pgo_test LANGUAGE PGO_MODE LIBRA_PGO_VALUE
run_pgo_test() {
    local lang="$1"
    local pgo_mode="$2"
    local libra_pgo_value="$3"
    local test_dir="$BUILDDIR/${lang}"

    local lang_upper=$(echo "$lang" | tr '[:lower:]' '[:upper:]')
    local compiler_var="${lang_upper}_COMPILER_EXEC[$COMPILER_TYPE]"
    local compiler="${!compiler_var}"

    echo "[TEST $COMPILER_TYPE/$lang] LIBRA_PGO=$libra_pgo_value..."

    rm -rf "$test_dir/build_info*"
    mkdir -p "$test_dir" && cd "$test_dir"

    if [ "$lang" = "c" ]; then
        cmake "$SCRIPTDIR/sample_build_info" \
              -DCMAKE_INSTALL_PREFIX=/tmp/libra_pgo_test \
              -DCMAKE_C_COMPILER="$compiler" \
              -DCMAKE_BUILD_TYPE=Release \
              -DLIBRA_PGO="$libra_pgo_value" \
              -DLIBRA_TEST_LANGUAGE=C \
              --log-level=$LOGLEVEL
    else
        cmake "$SCRIPTDIR/sample_build_info" \
              -DCMAKE_INSTALL_PREFIX=/tmp/libra_pgo_test \
              -DCMAKE_CXX_COMPILER="$compiler" \
              -DCMAKE_BUILD_TYPE=Release \
              -DLIBRA_PGO="$libra_pgo_value" \
              -DLIBRA_TEST_LANGUAGE=CXX \
              --log-level=$LOGLEVEL
    fi

    if [ "$libra_pgo_value" = "USE" ]; then
        if [ "$COMPILER_TYPE" = "clang" ]; then
            llvm-profdata-17 merge -o default.profdata default*.profraw
        fi
    else
        make
        $test_dir/bin/sample_build_info
    fi

    # Get expected flags for this compiler/PGO mode combination
    local expected_flags=($(get_expected_flags "$COMPILER_TYPE" "$pgo_mode"))

    if [ ${#expected_flags[@]} -eq 0 ]; then
        echo "WARNING: No expected flags defined for $COMPILER_TYPE/$pgo_mode, skipping verification"
        return 0
    fi

    verify_compile_flags_present "$test_dir" "${expected_flags[@]}"
    verify_link_flags_present "$test_dir" "${expected_flags[@]}"
}

# Run all PGO tests for a specific language
# Usage: run_all_tests LANGUAGE
run_all_tests() {
    local lang="$1"
    local lang_upper=$(echo "$lang" | tr '[:lower:]' '[:upper:]')
    local compiler_var="${lang_upper}_COMPILER_EXEC[$COMPILER_TYPE]"
    local compiler="${!compiler_var}"

    echo "========================================================================"
    echo "Testing LIBRA_PGO with $COMPILER_TYPE/$lang ($compiler)"
    echo "========================================================================"

    # Test 1: Default (NONE) - no PGO flags should be present
    echo "[TEST $COMPILER_TYPE/$lang] Default LIBRA_PGO=NONE..."
    test_dir="$BUILDDIR/${lang}/none"
    rm -rf "$test_dir"
    mkdir -p "$test_dir" && cd "$test_dir"

    if [ "$lang" = "c" ]; then
        cmake "$SCRIPTDIR/sample_build_info" \
              -DCMAKE_INSTALL_PREFIX=/tmp/libra_pgo_test \
              -DCMAKE_C_COMPILER="$compiler" \
              -DCMAKE_BUILD_TYPE=Release \
              -DLIBRA_TEST_LANGUAGE=C \
              --log-level=$LOGLEVEL
    else
        cmake "$SCRIPTDIR/sample_build_info" \
              -DCMAKE_INSTALL_PREFIX=/tmp/libra_pgo_test \
              -DCMAKE_CXX_COMPILER="$compiler" \
              -DCMAKE_BUILD_TYPE=Release \
              -DLIBRA_TEST_LANGUAGE=CXX \
              --log-level=$LOGLEVEL
    fi

    make

    # Get flags that should be absent for this compiler
    absent_flags_var="${COMPILER_TYPE^^}_NONE_ABSENT_FLAGS[@]"
    absent_flags=("${!absent_flags_var}")
    verify_compile_flags_absent "$test_dir" "${absent_flags[@]}"

    # Test individual PGO modes
    run_pgo_test "$lang" "GEN" "GEN"
    run_pgo_test "$lang" "USE" "USE"

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
