#!/bin/bash
#
# Unit tests for LIBRA_CODE_COV variable across all supported compilers
#
# Usage: ./09_LIBRA_CODE_COV-utest.sh [COMPILER_TYPE] [LANGUAGE]
#   COMPILER_TYPE: gnu or clang (default: gnu)
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
BUILDDIR=$SCRIPTDIR/build/LIBRA_CODE_COV_tests/${COMPILER_TYPE}

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

# Expected flags for each compiler/code coverage combination
# Note: Flags are the same for C and C++ (defined in LIBRA_{C,CXX}_CODE_COV_OPTIONS)

# GNU code coverage flags
declare -a GNU_YES_COMPILE_FLAGS=(
    "-fprofile-arcs"
    "-ftest-coverage"
    "-fno-inline"
    "-fprofile-update=atomic"
)
declare -a GNU_YES_LINK_FLAGS=(
    "-fprofile-arcs"
)

# Clang code coverage flags
declare -a CLANG_YES_COMPILE_FLAGS=(
    "-coverage"
    "-fno-inline"
)

declare -a CLANG_YES_LINK_FLAGS=(
    "--coverage"
)
# Flags that should NOT be present for NO
declare -a GNU_NO_ABSENT_FLAGS=(
    "-fprofile-arcs"
    "-ftest-coverage"
    "-fno-inline"
    "-fprofile-update=atomic"
)

declare -a CLANG_NO_ABSENT_FLAGS=(
    "--coverage"
    "-fno-inline"
)

declare -a EXPECTED_MK_TARGETS=(
    "lcov-preinfo"
    "lcov-report"
    "gcovr-report"
    "gcovr-check"
)
################################################################################
# Helper Functions
################################################################################
source $SCRIPTDIR/utils.sh

# Run a test for a specific code coverage mode and language
# Usage: run_code_cov_test LANGUAGE COV_MODE LIBRA_CODE_COV_VALUE
run_code_cov_test() {
    local lang="$1"
    local cov_mode="$2"
    local test_dir="$BUILDDIR/${lang}/${cov_mode,,}"

    local lang_upper=$(echo "$lang" | tr '[:lower:]' '[:upper:]')
    local compiler_var="${lang_upper}_COMPILER_EXEC[$COMPILER_TYPE]"
    local compiler="${!compiler_var}"

    echo "[TEST $COMPILER_TYPE/$lang] LIBRA_CODE_COV=$cov_mode..."

    rm -rf "$test_dir"
    mkdir -p "$test_dir" && cd "$test_dir"

    if [ "$lang" = "c" ]; then
        cmake "$SCRIPTDIR/sample_build_info" \
              -DCMAKE_INSTALL_PREFIX=/tmp/libra_code_cov_test \
              -DCMAKE_C_COMPILER="$compiler" \
              -DCMAKE_BUILD_TYPE=Debug \
              -DLIBRA_CODE_COV="$cov_mode" \
              -DLIBRA_TEST_LANGUAGE=C \
              --log-level=$LOGLEVEL
    else
        cmake "$SCRIPTDIR/sample_build_info" \
              -DCMAKE_INSTALL_PREFIX=/tmp/libra_code_cov_test \
              -DCMAKE_CXX_COMPILER="$compiler" \
              -DCMAKE_BUILD_TYPE=Debug \
              -DLIBRA_CODE_COV="$cov_mode" \
              -DLIBRA_TEST_LANGUAGE=CXX \
              --log-level=$LOGLEVEL
    fi

    make
    $test_dir/bin/sample_build_info
    verify_mk_targets_present "$test_dir"

    # Run all targets
    for target in "${EXPECTED_MK_TARGETS[@]}"; do
        make $target
        $test_dir/bin/sample_build_info
    done

    # Get expected flags for this compiler/code coverage mode combination
    local expected_compile_flags=($(get_expected_compile_flags "$COMPILER_TYPE" "$cov_mode"))
    local expected_link_flags=($(get_expected_link_flags "$COMPILER_TYPE" "$cov_mode"))

    if [ ${#expected_link_flags[@]} -eq 0 ]; then
        echo "WARNING: No expected link flags defined for $COMPILER_TYPE/$cov_mode, skipping verification"
        return 0
    fi
    if [ ${#expected_compile_flags[@]} -eq 0 ]; then
        echo "WARNING: No expected compile flags defined for $COMPILER_TYPE/$cov_mode, skipping verification"
        return 0
    fi

    verify_compile_flags_present "$test_dir" "${expected_compile_flags[@]}"
    verify_link_flags_present "$test_dir" "${expected_link_flags[@]}"
}

# Run all code coverage tests for a specific language
# Usage: run_all_tests LANGUAGE
run_all_tests() {
    local lang="$1"
    local lang_upper=$(echo "$lang" | tr '[:lower:]' '[:upper:]')
    local compiler_var="${lang_upper}_COMPILER_EXEC[$COMPILER_TYPE]"
    local compiler="${!compiler_var}"

    echo "========================================================================"
    echo "Testing LIBRA_CODE_COV with $COMPILER_TYPE/$lang ($compiler)"
    echo "========================================================================"

    # Test 1: Default (no) - no code coverage flags should be present
    echo "[TEST $COMPILER_TYPE/$lang] Default LIBRA_CODE_COV=NONE..."
    test_dir="$BUILDDIR/${lang}/no"
    rm -rf "$test_dir"
    mkdir -p "$test_dir" && cd "$test_dir"

    if [ "$lang" = "c" ]; then
        cmake "$SCRIPTDIR/sample_build_info" \
              -DCMAKE_INSTALL_PREFIX=/tmp/libra_code_cov_test \
              -DCMAKE_C_COMPILER="$compiler" \
              -DCMAKE_BUILD_TYPE=Debug \
              -DLIBRA_TEST_LANGUAGE=C \
              --log-level=$LOGLEVEL
    else
        cmake "$SCRIPTDIR/sample_build_info" \
              -DCMAKE_INSTALL_PREFIX=/tmp/libra_code_cov_test \
              -DCMAKE_CXX_COMPILER="$compiler" \
              -DCMAKE_BUILD_TYPE=Debug \
              -DLIBRA_TEST_LANGUAGE=CXX \
              --log-level=$LOGLEVEL
    fi

    make
    verify_mk_targets_absent "$test_dir"

    # Get flags that should be absent for this compiler
    absent_flags_var="${COMPILER_TYPE^^}_NO_ABSENT_FLAGS[@]"
    absent_flags=("${!absent_flags_var}")
    verify_compile_flags_absent "$test_dir" "${absent_flags[@]}"
    verify_link_flags_absent "$test_dir" "${absent_flags[@]}"

    run_code_cov_test "$lang" "YES"

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
    echo "Note: Intel compiler does not support LIBRA_CODE_COV"
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
