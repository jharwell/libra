#!/bin/bash
#
# Unit tests for LIBRA_SAN variable across all supported compilers
#
# Usage: ./LIBRA_SAN-utest.sh [COMPILER_TYPE] [LANGUAGE]
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
BUILDDIR=$SCRIPTDIR/build/LIBRA_SAN_tests/${COMPILER_TYPE}

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

# Expected flags for each compiler/sanitizer combination
# Note: Flags are the same for C and C++ (defined in LIBRA_{C,CXX}_SAN_OPTIONS)

# GNU flags
declare -a GNU_MSAN_FLAGS=(
    "-fno-omit-frame-pointer"
    "-fno-optimize-sibling-calls"
    "-fsanitize=leak"
    "-fsanitize-recover=all"
)

declare -a GNU_ASAN_FLAGS=(
    "-fno-omit-frame-pointer"
    "-fno-optimize-sibling-calls"
    "-fsanitize=address"
    "-fsanitize-address-use-after-scope"
    "-fsanitize=pointer-compare"
    "-fsanitize=pointer-subtract"
    "-fsanitize-recover=all"
)

declare -a GNU_SSAN_FLAGS=(
    "-fno-omit-frame-pointer"
    "-fstack-protector-all"
    "-fstack-protector-strong"
    "-fsanitize-recover=all"
)

declare -a GNU_UBSAN_FLAGS=(
    "-fno-omit-frame-pointer"
    "-fsanitize=undefined"
    "-fsanitize=float-divide-by-zero"
    "-fsanitize=float-cast-overflow"
    "-fsanitize=null"
    "-fsanitize=signed-integer-overflow"
    "-fsanitize=bool"
    "-fsanitize=enum"
    "-fsanitize=builtin"
    "-fsanitize=bounds"
    "-fsanitize=vptr"
    "-fsanitize=pointer-overflow"
    "-fsanitize-recover=all"
)

declare -a GNU_TSAN_FLAGS=(
    "-fno-omit-frame-pointer"
    "-fsanitize=thread"
    "-fsanitize-recover=all"
)
# Clang flags
declare -a CLANG_MSAN_FLAGS=(
    "-fno-omit-frame-pointer"
    "-fno-optimize-sibling-calls"
    "-fsanitize=memory"
    "-fsanitize-memory-track-origins"
)

declare -a CLANG_ASAN_FLAGS=(
    "-fno-omit-frame-pointer"
    "-fno-optimize-sibling-calls"
    "-fsanitize=address"
)

declare -a CLANG_SSAN_FLAGS=(
    "-fno-omit-frame-pointer"
    "-fstack-protector-all"
    "-fstack-protector-strong"
)

declare -a CLANG_UBSAN_FLAGS=(
    "-fno-omit-frame-pointer"
    "-fsanitize=undefined"
    "-fsanitize=float-divide-by-zero"
    "-fsanitize=unsigned-integer-overflow"
    "-fsanitize=local-bounds"
    "-fsanitize=nullability"
)

declare -a CLANG_TSAN_FLAGS=(
    "-fno-omit-frame-pointer"
    "-fsanitize=thread"
)

# Intel flags
declare -a INTEL_MSAN_FLAGS=(
    "-fno-omit-frame-pointer"
    "-fno-optimize-sibling-calls"
    "-fsanitize=memory"
    "-fsanitize-memory-track-origins"
)

declare -a INTEL_ASAN_FLAGS=(
    "-fno-omit-frame-pointer"
    "-fno-optimize-sibling-calls"
    "-fsanitize=address")

declare -a INTEL_SSAN_FLAGS=(
    "-fno-omit-frame-pointer"
    "-fstack-protector-all"
    "-fstack-protector-strong"
)

declare -a INTEL_UBSAN_FLAGS=(
    "-fno-omit-frame-pointer"
    "-fsanitize=undefined"
)

declare -a INTEL_TSAN_FLAGS=("-fsanitize=thread")


# Flags that should NOT be present for NONE
declare -a GNU_NONE_ABSENT_FLAGS=(
    "-fsanitize=leak"
    "-fsanitize=address"
    "-fsanitize=thread"
    "-fstack-protector-all"
)

declare -a CLANG_NONE_ABSENT_FLAGS=(
    "-fsanitize=memory"
    "-fsanitize=address"
    "-fsanitize=thread"
    "-fstack-protector-all"
)

declare -a INTEL_NONE_ABSENT_FLAGS=(
    "-fsanitize=memory"
    "-fsanitize=address"
    "-fsanitize=thread"
    "-fstack-protector-all"
)

################################################################################
# Helper Functions
################################################################################
source $SCRIPTDIR/utils.sh

# Run a test for a specific sanitizer and language
# Usage: run_sanitizer_test LANGUAGE SANITIZER_NAME LIBRA_SAN_VALUE
run_sanitizer_test() {
    local lang="$1"
    local sanitizer_name="$2"
    local libra_san_value="$3"
    local test_dir="$BUILDDIR/${lang}/${sanitizer_name,,}"

    local lang_upper=$(echo "$lang" | tr '[:lower:]' '[:upper:]')
    local compiler_var="${lang_upper}_COMPILER_EXEC[$COMPILER_TYPE]"
    local compiler="${!compiler_var}"

    echo "[TEST $COMPILER_TYPE/$lang] LIBRA_SAN=$libra_san_value..."

    rm -rf "$test_dir"
    mkdir -p "$test_dir" && cd "$test_dir"

    if [ "$lang" = "c" ]; then
        cmake "$SCRIPTDIR/sample_build_info" \
              -DCMAKE_INSTALL_PREFIX=/tmp/libra_san_test \
              -DCMAKE_C_COMPILER="$compiler" \
              -DCMAKE_BUILD_TYPE=Debug \
              -DLIBRA_SAN="$libra_san_value" \
              -DLIBRA_TEST_LANGUAGE=C \
              --log-level=$LOGLEVEL
    else
        cmake "$SCRIPTDIR/sample_build_info" \
              -DCMAKE_INSTALL_PREFIX=/tmp/libra_san_test \
              -DCMAKE_CXX_COMPILER="$compiler" \
              -DCMAKE_BUILD_TYPE=Debug \
              -DLIBRA_SAN="$libra_san_value" \
              -DLIBRA_TEST_LANGUAGE=CXX \
              --log-level=$LOGLEVEL
    fi

    make

    # Get expected flags for this compiler/sanitizer combination
    local expected_flags=($(get_expected_flags "$COMPILER_TYPE" "$sanitizer_name"))

    if [ ${#expected_flags[@]} -eq 0 ]; then
        echo "WARNING: No expected flags defined for $COMPILER_TYPE/$sanitizer_name, skipping verification"
        return 0
    fi

    verify_compile_flags_present "$test_dir" "${expected_flags[@]}"
    verify_link_flags_present "$test_dir" "${expected_flags[@]}"
}

# Run all sanitizer tests for a specific language
# Usage: run_all_tests LANGUAGE
run_all_tests() {
    local lang="$1"
    local lang_upper=$(echo "$lang" | tr '[:lower:]' '[:upper:]')
    local compiler_var="${lang_upper}_COMPILER_EXEC[$COMPILER_TYPE]"
    local compiler="${!compiler_var}"

    echo "========================================================================"
    echo "Testing LIBRA_SAN with $COMPILER_TYPE/$lang ($compiler)"
    echo "========================================================================"

    # Test 1: Default (NONE) - no sanitizer flags should be present
    echo "[TEST $COMPILER_TYPE/$lang] Default LIBRA_SAN=NONE..."
    test_dir="$BUILDDIR/${lang}/none"
    rm -rf "$test_dir"
    mkdir -p "$test_dir" && cd "$test_dir"

    if [ "$lang" = "c" ]; then
        cmake "$SCRIPTDIR/sample_build_info" \
              -DCMAKE_INSTALL_PREFIX=/tmp/libra_san_test \
              -DCMAKE_C_COMPILER="$compiler" \
              -DCMAKE_BUILD_TYPE=Debug \
              -DLIBRA_TEST_LANGUAGE=C \
              --log-level=$LOGLEVEL
    else
        cmake "$SCRIPTDIR/sample_build_info" \
              -DCMAKE_INSTALL_PREFIX=/tmp/libra_san_test \
              -DCMAKE_CXX_COMPILER="$compiler" \
              -DCMAKE_BUILD_TYPE=Debug \
              -DLIBRA_TEST_LANGUAGE=CXX \
              --log-level=$LOGLEVEL
    fi

    make

    # Get flags that should be absent for this compiler
    absent_compile_flags_var="${COMPILER_TYPE^^}_NONE_ABSENT_COMPILE_FLAGS[@]"
    absent_compile_flags=("${!absent_compile_flags_var}")
    absent_link_flags_var="${COMPILER_TYPE^^}_NONE_ABSENT_LINK_FLAGS[@]"
    absent_link_flags=("${!absent_link_flags_var}")
    verify_compile_flags_absent "$test_dir" "${absent_compile_flags[@]}"
    verify_link_flags_absent "$test_dir" "${absent_link_flags[@]}"

    # Test individual sanitizers
    run_sanitizer_test "$lang" "MSAN" "MSAN"
    run_sanitizer_test "$lang" "ASAN" "ASAN"
    run_sanitizer_test "$lang" "SSAN" "SSAN"
    run_sanitizer_test "$lang" "UBSAN" "UBSAN"
    run_sanitizer_test "$lang" "TSAN" "TSAN"

    # Test combined sanitizers (ASAN+UBSAN)
    echo "[TEST $COMPILER_TYPE/$lang] LIBRA_SAN=ASAN+UBSAN+SSAN..."
    test_dir="$BUILDDIR/${lang}/asan_ubsan_ssan"
    rm -rf "$test_dir"
    mkdir -p "$test_dir" && cd "$test_dir"

    if [ "$lang" = "c" ]; then
        cmake "$SCRIPTDIR/sample_build_info" \
              -DCMAKE_INSTALL_PREFIX=/tmp/libra_san_test \
              -DCMAKE_C_COMPILER="$compiler" \
              -DCMAKE_BUILD_TYPE=Debug \
              -DLIBRA_SAN="ASAN+UBSAN" \
              -DLIBRA_TEST_LANGUAGE=C \
              --log-level=$LOGLEVEL
    else
        cmake "$SCRIPTDIR/sample_build_info" \
              -DCMAKE_INSTALL_PREFIX=/tmp/libra_san_test \
              -DCMAKE_CXX_COMPILER="$compiler" \
              -DCMAKE_BUILD_TYPE=Debug \
              -DLIBRA_SAN="ASAN+UBSAN" \
              -DLIBRA_TEST_LANGUAGE=CXX \
              --log-level=$LOGLEVEL
    fi

    make

    # For combined sanitizers, just check that both are present
    verify_compile_flags_present "$test_dir" "-fsanitize=address" "-fsanitize=undefined"
    verify_link_flags_present "$test_dir" "-fsanitize=address" "-fsanitize=undefined"

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
