#!/usr/bin/env bash
#
# LIBRA Test Common Library for BATS
# Provides shared infrastructure for all LIBRA BATS tests
#
# Usage: load test_helpers
#

################################################################################
# Compiler Configuration
################################################################################

# Map compiler types to actual compiler executables
declare -gA C_COMPILER_EXEC=(
    ["gnu"]="gcc"
    ["clang"]="clang"
    ["intel"]="icx"
)

declare -gA CXX_COMPILER_EXEC=(
    ["gnu"]="g++"
    ["clang"]="clang++"
    ["intel"]="icpx"
)

# Compiler family names (for display)
declare -gA COMPILER_NAMES=(
    ["gnu"]="GCC/G++"
    ["clang"]="Clang/Clang++"
    ["intel"]="Intel oneAPI"
)

################################################################################
# Environment Setup
################################################################################

# Setup function called before each test
# Creates isolated test directory and sets up environment
setup_libra_test() {
    # Set default compiler and language if not already set
    export COMPILER_TYPE="${COMPILER_TYPE:-gnu}"
    export LANGUAGE="${LANGUAGE:-both}"
    export LOGLEVEL="${LOGLEVEL:-STATUS}"

    # Create unique test directory in BATS temp space
    export TEST_BUILD_DIR="$BATS_TEST_TMPDIR/build"
    mkdir -p "$TEST_BUILD_DIR"
}

# Teardown function (optional, BATS handles cleanup)
teardown_libra_test() {
    # BATS automatically cleans up BATS_TEST_TMPDIR
    # Add custom cleanup here if needed
    :
}

################################################################################
# Compiler Utilities
################################################################################

# Get compiler executable for a language
# Usage: get_compiler COMPILER_TYPE LANGUAGE
get_compiler() {
    local compiler_type="$1"
    local lang="$2"

    local lang_upper=$(echo "$lang" | tr '[:lower:]' '[:upper:]')
    local compiler_var="${lang_upper}_COMPILER_EXEC[$compiler_type]"

    echo "${!compiler_var}"
}

# Check if compiler exists
# Usage: compiler_exists COMPILER_TYPE LANGUAGE
compiler_exists() {
    local compiler_type="$1"
    local lang="$2"

    local compiler=$(get_compiler "$compiler_type" "$lang")
    command -v "$compiler" &> /dev/null
}

# Skip test if compiler is missing
# Usage: skip_if_compiler_missing COMPILER_TYPE LANGUAGE
skip_if_compiler_missing() {
    local compiler_type="${1:-$COMPILER_TYPE}"
    local lang="${2:-cxx}"

    if ! compiler_exists "$compiler_type" "$lang"; then
        local compiler=$(get_compiler "$compiler_type" "$lang")
        skip "Compiler not found: $compiler"
    fi
}

# Validate compiler type
# Usage: validate_compiler_type COMPILER_TYPE
validate_compiler_type() {
    local compiler_type="$1"

    if [[ ! -v C_COMPILER_EXEC[$compiler_type] ]]; then
        echo "ERROR: Unknown compiler type: $compiler_type"
        echo "Valid options: ${!C_COMPILER_EXEC[@]}"
        return 1
    fi
    return 0
}

################################################################################
# CMake Test Runner
################################################################################
# Run a CMake test with LIBRA
# Usage: run_libra_cmake_test LANG [CMAKE_OPTIONS...]
# Returns: Path to build directory
run_libra_cmake_test() {
    local lang="$1"
    shift
    local cmake_options=("$@")
    local lang_upper=$(echo "$lang" | tr '[:lower:]' '[:upper:]')
    local compiler=$(get_compiler "$COMPILER_TYPE" "$lang")

    # Create unique test directory for this invocation
    local test_dir="$TEST_BUILD_DIR/${lang}_${RANDOM}"
    mkdir -p "$test_dir"

    # Build cmake arguments
    local cmake_args=(
        "$BATS_TEST_DIRNAME/sample_build_info"
        -DCMAKE_INSTALL_PREFIX="$test_dir/install"
        -DCMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE:-Debug}"
        -DLIBRA_TEST_LANGUAGE="$lang_upper"
        --log-level="$LOGLEVEL"
    )

    # Add compiler argument
    if [ "$lang" = "c" ]; then
        cmake_args+=(-DCMAKE_C_COMPILER="$compiler")
    else
        cmake_args+=(-DCMAKE_CXX_COMPILER="$compiler")
    fi

    # Add user-provided cmake options
    cmake_args+=("${cmake_options[@]}")

    # Run cmake
    cd "$test_dir"

    run cmake "${cmake_args[@]}" # &> /dev/null
    [ "$status" -eq 0 ] || return 1

    # Run make
    run make # &> /dev/null
    [ "$status" -eq 0 ] || return 1

    # Return to original directory and output test dir path
    cd - > /dev/null
    echo "$test_dir"
}

################################################################################
# File Verification Utilities
################################################################################

# Get build info file path
# Usage: get_build_info_file TEST_DIR LANG
get_build_info_file() {
    local test_dir="$1"
    local lang="$2"

    if [ "$lang" = "c" ]; then
        echo "$test_dir/build_info.c"
    else
        echo "$test_dir/build_info.cpp"
    fi
}

# Extract value from build info file
# Usage: extract_from_build_info TEST_DIR LANG PATTERN
extract_from_build_info() {
    local test_dir="$1"
    local lang="$2"
    local pattern="$3"

    local build_info=$(get_build_info_file "$test_dir" "$lang")

    if [ ! -f "$build_info" ]; then
        echo "ERROR: Build info file not found: $build_info" >&2
        return 1
    fi

    grep "$pattern" "$build_info" | head -1
}

# Get C/C++ standard from build info
# Usage: get_standard TEST_DIR LANG
get_standard() {
    local test_dir="$1"
    local lang="$2"

    # Debug: Show what we received
    if [ -n "$BATS_DEBUG" ]; then
        echo "DEBUG get_standard: test_dir='$test_dir'" >&3
        echo "DEBUG get_standard: lang='$lang'" >&3
    fi

    local build_info=$(get_build_info_file "$test_dir" "$lang")

    if [ "$lang" = "c" ]; then
        grep 'C_STANDARD = ' "$build_info" | sed 's/.*C_STANDARD = "\(.*\)";/\1/'
    else
        grep 'CXX_STANDARD = ' "$build_info" | sed 's/.*CXX_STANDARD = "\(.*\)";/\1/'
    fi
}

# Get compile flags from build info
# Usage: get_compile_flags TEST_DIR LANG
get_compile_flags() {
    local test_dir="$1"
    local lang="$2"
    local build_info=$(get_build_info_file "$test_dir" "$lang")

    grep 'COMPILE_FLAGS = ' "$build_info" | sed 's/.*COMPILE_FLAGS = "\(.*\)";/\1/'
}

# Get link flags from build info
# Usage: get_link_flags TEST_DIR LANG
get_link_flags() {
    local test_dir="$1"
    local lang="$2"
    local build_info=$(get_build_info_file "$test_dir" "$lang")

    grep 'LINK_FLAGS = ' "$build_info" | sed 's/.*LINK_FLAGS = "\(.*\)";/\1/'
}

# Check if a flag is present in compile flags
# Usage: has_compile_flag TEST_DIR LANG FLAG
has_compile_flag() {
    local test_dir="$1"
    local lang="$2"
    local flag="$3"

    local flags=$(get_compile_flags "$test_dir" "$lang")
    echo "$flags" | grep -q -- "$flag"
}

# Check if a flag is present in link flags
# Usage: has_link_flag TEST_DIR LANG FLAG
has_link_flag() {
    local test_dir="$1"
    local lang="$2"
    local flag="$3"

    local flags=$(get_link_flags "$test_dir" "$lang")
    echo "$flags" | grep -q -- "$flag"
}

# Check if a define is present in build info
# Usage: has_define TEST_DIR LANG DEFINE
has_define() {
    local test_dir="$1"
    local lang="$2"
    local define="$3"

    local build_info=$(get_build_info_file "$test_dir" "$lang")
    grep -q "$define" "$build_info"
}

# Return 0 if any LTO/IPO flag (-flto or -ipo) is present in flags.make for
# the sample_build_info target in the given build directory.
# Usage: has_lto_flag TEST_DIR
has_lto_flag() {
    local test_dir="$1"
    local flags_file="$test_dir/CMakeFiles/sample_build_info.dir/flags.make"

    if [ ! -f "$flags_file" ]; then
        return 1
    fi

    grep -qE -- '-flto|-ipo' "$flags_file"
}


################################################################################
# Makefile Target Utilities
################################################################################

# Check if a Makefile target exists
# Usage: makefile_target_exists TEST_DIR TARGET
makefile_target_exists() {
    local test_dir="$1"
    local target="$2"

    if [ ! -f "$test_dir/Makefile" ]; then
        return 1
    fi

    cd "$test_dir"
    make -qp 2>/dev/null | grep -q "^${target}:"
    local result=$?
    cd - > /dev/null
    return $result
}

################################################################################
# BATS Assertion Helpers
################################################################################

# Assert that a compile flag is present
# Usage: assert_compile_flag_present TEST_DIR LANG FLAG
assert_compile_flag_present() {
    local test_dir="$1"
    local lang="$2"
    local flag="$3"

    run has_compile_flag "$test_dir" "$lang" "$flag"
    [ "$status" -eq 0 ]
}

# Assert that a compile flag is absent
# Usage: assert_compile_flag_absent TEST_DIR LANG FLAG
assert_compile_flag_absent() {
    local test_dir="$1"
    local lang="$2"
    local flag="$3"

    run has_compile_flag "$test_dir" "$lang" "$flag"
    [ "$status" -ne 0 ]
}

# Assert that a link flag is present
# Usage: assert_link_flag_present TEST_DIR LANG FLAG
assert_link_flag_present() {
    local test_dir="$1"
    local lang="$2"
    local flag="$3"

    run has_link_flag "$test_dir" "$lang" "$flag"
    [ "$status" -eq 0 ]
}
# Assert that a link flag is absent
# Usage: assert_link_flag_present TEST_DIR LANG FLAG
assert_link_flag_absent() {
    local test_dir="$1"
    local lang="$2"
    local flag="$3"

    run has_link_flag "$test_dir" "$lang" "$flag"
    [ "$status" -ne 0 ]
}

# Assert that a define is present
# Usage: assert_define_present TEST_DIR LANG DEFINE
assert_define_present() {
    local test_dir="$1"
    local lang="$2"
    local define="$3"

    run has_define "$test_dir" "$lang" "$define"
    [ "$status" -eq 0 ]
}

# Assert that a define is absent
# Usage: assert_define_absent TEST_DIR LANG DEFINE
assert_define_absert() {
    local test_dir="$1"
    local lang="$2"
    local define="$3"

    run has_define "$test_dir" "$lang" "$define"
    [ "$status" -ne 0 ]
}

# Assert that a makefile target exists
# Usage: assert_target_exists TEST_DIR TARGET
assert_target_exists() {
    local test_dir="$1"
    local target="$2"

    run makefile_target_exists "$test_dir" "$target"
    [ "$status" -eq 0 ]
}

# Assert that a makefile target does not exist
# Usage: assert_target_absent TEST_DIR TARGET
assert_target_absent() {
    local test_dir="$1"
    local target="$2"

    run makefile_target_exists "$test_dir" "$target"
    [ "$status" -ne 0 ]
}

# Assert standard equals expected value
# Usage: assert_standard_equals TEST_DIR LANG EXPECTED
assert_standard_equals() {
    local test_dir="$1"
    local lang="$2"
    local expected="$3"
    local actual=$(get_standard "$test_dir" "$lang")
    echo "$actual|$expected"
    [ "$actual" = "$expected" ]
}

################################################################################
# CMake Cache Utilities
################################################################################

# Get value from CMakeCache.txt
# Usage: get_cache_value TEST_DIR VARIABLE_NAME
get_cache_value() {
    local test_dir="$1"
    local var_name="$2"

    if [ ! -f "$test_dir/CMakeCache.txt" ]; then
        echo "ERROR: CMakeCache.txt not found in $test_dir" >&2
        return 1
    fi

    # Extract value from CMakeCache.txt
    # Format: VARIABLE_NAME:TYPE=value
    grep "^${var_name}:" "$test_dir/CMakeCache.txt" | cut -d'=' -f2
}

# Check if cache variable equals expected value
# Usage: cache_value_equals TEST_DIR VARIABLE_NAME EXPECTED
cache_value_equals() {
    local test_dir="$1"
    local var_name="$2"
    local expected="$3"

    local actual=$(get_cache_value "$test_dir" "$var_name")
    [ "$actual" = "$expected" ]
}

################################################################################
# Consumer Verification Utilities
################################################################################

# Check if define is present in consumer build info
# Usage: consumer_has_define TEST_DIR DEFINE
consumer_has_define() {
    local test_dir="$1"
    local define="$2"
    local lang="$3"
    local consumer_info=""

    if [ "$lang" = "c" ]; then
        consumer_info="$test_dir/consumer/consumer_build_info.c"
    else
        consumer_info="$test_dir/consumer/consumer_build_info.cpp"
    fi

    grep -q "$define" "$consumer_info"
}

# Check if define is absent in consumer build info
# Usage: consumer_define_absent TEST_DIR DEFINE
consumer_define_absent() {
    local test_dir="$1"
    local define="$2"
    local lang="$3"
    local consumer_info="$test_dir/consumer/consumer_build_info.c"

    run consumer_has_define "$test_dir" "$define" "$lang"
    [ "$status" -ne 0 ]
}

################################################################################
# Debugging Utilities
################################################################################

# Print build info for debugging
# Usage: debug_build_info TEST_DIR LANG
debug_build_info() {
    local test_dir="$1"
    local lang="$2"
    local build_info=$(get_build_info_file "$test_dir" "$lang")

    echo "=== Build Info: $build_info ===" >&3
    cat "$build_info" >&3
    echo "==============================" >&3
}

# Print compile flags for debugging
# Usage: debug_compile_flags TEST_DIR LANG
debug_compile_flags() {
    local test_dir="$1"
    local lang="$2"

    echo "Compile flags: $(get_compile_flags "$test_dir" "$lang")" >&3
}

# Print link flags for debugging
# Usage: debug_link_flags TEST_DIR LANG
debug_link_flags() {
    local test_dir="$1"
    local lang="$2"

    echo "Link flags: $(get_link_flags "$test_dir" "$lang")" >&3
}

# Print CMake cache value for debugging
# Usage: debug_cache_value TEST_DIR VAR_NAME
debug_cache_value() {
    local test_dir="$1"
    local var_name="$2"

    echo "$var_name = $(get_cache_value "$test_dir" "$var_name")" >&3
}
