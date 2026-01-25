#!/bin/bash
#
# Unit tests for LIBRA_OPT_LEVEL variable across all supported compilers
#
# Usage: ./LIBRA_OPT_LEVEL-utest.sh [COMPILER_TYPE] [LANGUAGE]
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
BUILDDIR=$SCRIPTDIR/build/LIBRA_OPT_LEVEL_tests/${COMPILER_TYPE}

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

# Expected flags for each compiler/optimization level combination
# Note: Flags are the same for C and C++ (defined in LIBRA_OPT_LEVEL)

# All compilers support the same optimization levels
declare -a GNU_O0_FLAGS=("-O0")
declare -a GNU_O1_FLAGS=("-O1")
declare -a GNU_O2_FLAGS=("-O2")
declare -a GNU_O3_FLAGS=("-O3")
declare -a GNU_Os_FLAGS=("-Os")

declare -a CLANG_O0_FLAGS=("-O0")
declare -a CLANG_O1_FLAGS=("-O1")
declare -a CLANG_O2_FLAGS=("-O2")
declare -a CLANG_O3_FLAGS=("-O3")
declare -a CLANG_Os_FLAGS=("-Os")

declare -a INTEL_O0_FLAGS=("-O0")
declare -a INTEL_O1_FLAGS=("-O1")
declare -a INTEL_O2_FLAGS=("-O2")
declare -a INTEL_O3_FLAGS=("-O3")
declare -a INTEL_Os_FLAGS=("-Os")

################################################################################
# Helper Functions
################################################################################
source $SCRIPTDIR/utils.sh

# Run a test for a specific optimization level and language
# Usage: run_opt_level_test LANGUAGE OPT_LEVEL LIBRA_OPT_LEVEL_VALUE BUILD_TYPE
run_opt_level_test() {
    local lang="$1"
    local opt_level="$2"
    local libra_opt_level_value="$3"
    local build_type="$4"
    local test_dir="$BUILDDIR/${lang}/${opt_level,,}_${build_type,,}"

    local lang_upper=$(echo "$lang" | tr '[:lower:]' '[:upper:]')
    local compiler_var="${lang_upper}_COMPILER_EXEC[$COMPILER_TYPE]"
    local compiler="${!compiler_var}"

    echo "[TEST $COMPILER_TYPE/$lang/$build_type] LIBRA_OPT_LEVEL=$libra_opt_level_value..."

    rm -rf "$test_dir"
    mkdir -p "$test_dir" && cd "$test_dir"

    if [ "$lang" = "c" ]; then
        cmake "$SCRIPTDIR/sample_build_info" \
              -DCMAKE_INSTALL_PREFIX=/tmp/libra_opt_level_test \
              -DCMAKE_C_COMPILER="$compiler" \
              -DCMAKE_BUILD_TYPE="$build_type" \
              -DLIBRA_OPT_LEVEL="$libra_opt_level_value" \
              -DLIBRA_TEST_LANGUAGE=C \
              --log-level=$LOGLEVEL
    else
        cmake "$SCRIPTDIR/sample_build_info" \
              -DCMAKE_INSTALL_PREFIX=/tmp/libra_opt_level_test \
              -DCMAKE_CXX_COMPILER="$compiler" \
              -DCMAKE_BUILD_TYPE="$build_type" \
              -DLIBRA_OPT_LEVEL="$libra_opt_level_value" \
              -DLIBRA_TEST_LANGUAGE=CXX \
              --log-level=$LOGLEVEL
    fi

    make

    # Get expected flags for this compiler/optimization level combination
    local expected_flags=($(get_expected_flags "$COMPILER_TYPE" "$opt_level"))

    if [ ${#expected_flags[@]} -eq 0 ]; then
        echo "WARNING: No expected flags defined for $COMPILER_TYPE/$opt_level, skipping verification"
        return 0
    fi

    verify_compile_flags_present "$test_dir" "${expected_flags[@]}"
    verify_link_flags_present "$test_dir" "${expected_flags[@]}"
}

# Run all optimization level tests for a specific language
# Usage: run_all_tests LANGUAGE
run_all_tests() {
    local lang="$1"
    local lang_upper=$(echo "$lang" | tr '[:lower:]' '[:upper:]')
    local compiler_var="${lang_upper}_COMPILER_EXEC[$COMPILER_TYPE]"
    local compiler="${!compiler_var}"

    echo "========================================================================"
    echo "Testing LIBRA_OPT_LEVEL with $COMPILER_TYPE/$lang ($compiler)"
    echo "========================================================================"

    # Test default optimization levels for Debug and Release builds
    echo "--- Testing Default Optimization Levels ---"

    # Debug build should default to -O0
    run_opt_level_test "$lang" "O0" "-O0" "Debug"

    # Release build should default to -O3
    run_opt_level_test "$lang" "O3" "-O3" "Release"

    # Test overriding optimization levels
    echo "--- Testing Override Optimization Levels ---"

    # Override Debug build to use -O2
    run_opt_level_test "$lang" "O2" "-O2" "Debug"

    # Override Release build to use -O1
    run_opt_level_test "$lang" "O1" "-O1" "Release"

    # Override Release build to use -Os
    run_opt_level_test "$lang" "Os" "-Os" "Release"

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
