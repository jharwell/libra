#!/bin/bash
#
# Unit tests for LIBRA_OPT_REPORT variable for Clang and Intel compilers
#
# Usage: ./LIBRA_OPT_REPORT-utest.sh [COMPILER_TYPE] [LANGUAGE]
#   COMPILER_TYPE: clang or intel (default: clang)
#   LANGUAGE: c, cxx, or both (default: both)
#

# set -x
set -e
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPT_NAME=$(basename "$0")
SCRIPT_NAME_NO_EXT="${SCRIPT_NAME%.*}"
# Parse command line arguments
COMPILER_TYPE="${1:-clang}"
LANGUAGE="${2:-both}"
BUILDDIR=$SCRIPTDIR/build/LIBRA_OPT_REPORT_tests/${COMPILER_TYPE}

LOGLEVEL=ERROR

################################################################################
# Compiler Configuration Maps
################################################################################

# Map compiler types to actual compiler executables
declare -A C_COMPILER_EXEC=(
    ["clang"]="clang"
    ["intel"]="icx"
    ["gnu"]="gcc"
)

declare -A CXX_COMPILER_EXEC=(
    ["clang"]="clang++"
    ["intel"]="icpx"
    ["gnu"]="g++"
)

# Expected flags for each compiler/optimization report combination
# Note: Flags are the same for C and C++ (defined in LIBRA_{C,CXX}_REPORT_OPTIONS)

# Clang optimization report flags (LLVM-based)
declare -a CLANG_ON_FLAGS=(
    "-Rpass=.*"
    "-Rpass-missed=.*"
    "-Rpass-analysis=.*"
    "-fsave-optimization-record"
)

# Clang optimization report flags (LLVM-based)
declare -a GNU_ON_FLAGS=(
    "-fopt-info-all"
)

# Intel LLVM optimization report flags (new icx/icpx)
# Using LLVM-based flags instead of old -qopt-report flags
declare -a INTEL_ON_FLAGS=(
    "-qopt-report=3"
    "-qopt-report-phase=all"
)

# Flags that should NOT be present for OFF
declare -a GNU_OFF_ABSENT_FLAGS=(
    "-fopt-info-all"
)
declare -a CLANG_OFF_ABSENT_FLAGS=(
    "-Rpass"
    "-fsave-optimization-record"
)

declare -a INTEL_OFF_ABSENT_FLAGS=(
    "-qopt-report=3"
    "-qopt-report-phase=all"
)

################################################################################
# Helper Functions
################################################################################
source $SCRIPTDIR/utils.sh

# Run a test for optimization report ON/OFF and language
# Usage: run_opt_report_test LANGUAGE REPORT_MODE LIBRA_OPT_REPORT_VALUE
run_opt_report_test() {
    local lang="$1"
    local report_mode="$2"
    local libra_opt_report_value="$3"
    local test_dir="$BUILDDIR/${lang}/${report_mode,,}"

    local lang_upper=$(echo "$lang" | tr '[:lower:]' '[:upper:]')
    local compiler_var="${lang_upper}_COMPILER_EXEC[$COMPILER_TYPE]"
    local compiler="${!compiler_var}"

    echo "[TEST $COMPILER_TYPE/$lang] LIBRA_OPT_REPORT=$libra_opt_report_value..."

    rm -rf "$test_dir"
    mkdir -p "$test_dir" && cd "$test_dir"

    if [ "$lang" = "c" ]; then
        cmake "$SCRIPTDIR/sample_build_info" \
              -DCMAKE_INSTALL_PREFIX=/tmp/libra_opt_report_test \
              -DCMAKE_C_COMPILER="$compiler" \
              -DCMAKE_BUILD_TYPE=Release \
              -DLIBRA_OPT_REPORT="$libra_opt_report_value" \
              -DLIBRA_TEST_LANGUAGE=C \
              --log-level=$LOGLEVEL
    else
        cmake "$SCRIPTDIR/sample_build_info" \
              -DCMAKE_INSTALL_PREFIX=/tmp/libra_opt_report_test \
              -DCMAKE_CXX_COMPILER="$compiler" \
              -DCMAKE_BUILD_TYPE=Release \
              -DLIBRA_OPT_REPORT="$libra_opt_report_value" \
              -DLIBRA_TEST_LANGUAGE=CXX \
              --log-level=$LOGLEVEL
    fi

    make

    # Get expected flags for this compiler/report mode combination
    local expected_flags=($(get_expected_flags "$COMPILER_TYPE" "$report_mode"))

    if [ ${#expected_flags[@]} -eq 0 ]; then
        echo "WARNING: No expected flags defined for $COMPILER_TYPE/$report_mode, skipping verification"
        return 0
    fi

    verify_compile_flags_present "$test_dir" "${expected_flags[@]}"
}

# Run all optimization report tests for a specific language
# Usage: run_all_tests LANGUAGE
run_all_tests() {
    local lang="$1"
    local lang_upper=$(echo "$lang" | tr '[:lower:]' '[:upper:]')
    local compiler_var="${lang_upper}_COMPILER_EXEC[$COMPILER_TYPE]"
    local compiler="${!compiler_var}"

    echo "========================================================================"
    echo "Testing LIBRA_OPT_REPORT with $COMPILER_TYPE/$lang ($compiler)"
    echo "========================================================================"

    # Test 1: OFF - no optimization report flags should be present
    echo "[TEST $COMPILER_TYPE/$lang] LIBRA_OPT_REPORT=OFF..."
    test_dir="$BUILDDIR/${lang}/off"
    rm -rf "$test_dir"
    mkdir -p "$test_dir" && cd "$test_dir"

    if [ "$lang" = "c" ]; then
        cmake "$SCRIPTDIR/sample_build_info" \
              -DCMAKE_INSTALL_PREFIX=/tmp/libra_opt_report_test \
              -DCMAKE_C_COMPILER="$compiler" \
              -DCMAKE_BUILD_TYPE=Release \
              -DLIBRA_OPT_REPORT=OFF \
              -DLIBRA_TEST_LANGUAGE=C \
              --log-level=$LOGLEVEL
    else
        cmake "$SCRIPTDIR/sample_build_info" \
              -DCMAKE_INSTALL_PREFIX=/tmp/libra_opt_report_test \
              -DCMAKE_CXX_COMPILER="$compiler" \
              -DCMAKE_BUILD_TYPE=Release \
              -DLIBRA_OPT_REPORT=OFF \
              -DLIBRA_TEST_LANGUAGE=CXX \
              --log-level=$LOGLEVEL
    fi

    make

    # Get flags that should be absent for this compiler
    absent_flags_var="${COMPILER_TYPE^^}_OFF_ABSENT_FLAGS[@]"
    absent_flags=("${!absent_flags_var}")
    verify_compile_flags_absent "$test_dir" "${absent_flags[@]}"

    # Test 2: ON - optimization report flags should be present
    run_opt_report_test "$lang" "ON" "ON"

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
    echo "Valid options: clang, intel, gnu"
    exit 1
fi

# Validate language
if [[ "$LANGUAGE" != "c" && "$LANGUAGE" != "cxx" && "$LANGUAGE" != "both" ]]; then
    echo "ERROR: Unknown language: $LANGUAGE"
    echo "Valid options: c, cxx, both"
    exit 1
fi

################################################################################
# Test Execution
################################################################################

# Run tests based on language selection
if [[ "$LANGUAGE" == "both" || "$LANGUAGE" == "cxx" ]]; then
    # Check if C++ compiler is available
    if ! command -v "${CXX_COMPILER_EXEC[$COMPILER_TYPE]}" &> /dev/null; then
        echo "ERROR: C++ compiler ${CXX_COMPILER_EXEC[$COMPILER_TYPE]} not found in PATH"
        exit 1
    fi
    run_all_tests "cxx"
fi

if [[ "$LANGUAGE" == "both" || "$LANGUAGE" == "c" ]]; then
    # Check if C compiler is available
    if ! command -v "${C_COMPILER_EXEC[$COMPILER_TYPE]}" &> /dev/null; then
        echo "ERROR: C compiler ${C_COMPILER_EXEC[$COMPILER_TYPE]} not found in PATH"
        exit 1
    fi
    run_all_tests "c"
fi

echo "========================================================================"
echo "ALL TESTS COMPLETED SUCCESSFULLY!"
echo "========================================================================"
