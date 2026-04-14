#!/usr/bin/env bash
#
# LIBRA Test Common Library for BATS
# Provides shared infrastructure for all LIBRA BATS tests
#
# Usage: load test_helpers
#

################################################################################
# Stable path anchor
#
# LIBRA_TESTS_DIR always points to the tests/ directory regardless of where
# the currently-running .bats file lives (top-level tests/ or suites/).
# It is derived from the location of this file itself (BASH_SOURCE[0]).
################################################################################
LIBRA_TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export LIBRA_TESTS_DIR

# LIBRA repository root: one level above tests/
LIBRA_SOURCE_ROOT_DEFAULT="$(cd "${LIBRA_TESTS_DIR}/.." && pwd)"

export CLI_CMAKE_DEFINES="-DLIBRA_TESTS_DIR=$LIBRA_TESTS_DIR -DLIBRA_SOURCE_ROOT=$LIBRA_SOURCE_ROOT_DEFAULT"

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

    # Consumption mode: one of in_situ | add_subdirectory | installed_package | cpm | conan
    export LIBRA_CONSUME_MODE="${LIBRA_CONSUME_MODE:-in_situ}"

    # Allow callers to override the repo root; default to auto-detected value
    export LIBRA_SOURCE_ROOT="${LIBRA_SOURCE_ROOT:-$LIBRA_SOURCE_ROOT_DEFAULT}"

    # Create unique test directory in BATS temp space
    export TEST_BUILD_DIR="$BATS_TEST_TMPDIR/build"
    mkdir -p "$TEST_BUILD_DIR"

    # Run mode-specific one-time setup
    case "$LIBRA_CONSUME_MODE" in
        in_situ)           ;;  # nothing extra needed
        add_subdirectory)  ;;  # nothing extra needed - source root already set
        installed_package) _libra_setup_installed_package ;;
        cpm)               _libra_setup_cpm ;;
        conan)             _libra_setup_conan ;;
        *)
            echo "ERROR: Unknown LIBRA_CONSUME_MODE: $LIBRA_CONSUME_MODE" >&2
            return 1
            ;;
    esac
}

################################################################################
# Consumption Mode: One-time setup helpers
#
# Each function is called from setup_libra_test() for the matching mode.
# They use BATS_RUN_TMPDIR (shared across all tests in a single `bats` run)
# so expensive operations (cmake install, conan create) happen at most once.
################################################################################

# installed_package mode: build and install LIBRA into a shared prefix once.
# Sets LIBRA_INSTALL_PREFIX.
_libra_setup_installed_package() {
    export LIBRA_INSTALL_PREFIX="${BATS_RUN_TMPDIR}/libra_install"
    local stamp="${LIBRA_INSTALL_PREFIX}/.installed"
    local build_dir="${BATS_RUN_TMPDIR}/libra_install_build"
    local lockfile="${BATS_RUN_TMPDIR}/libra_install.lock"

    # Use a file lock to prevent parallel workers from racing
    (
        flock -x 200

        # Re-check stamp inside the lock in case another worker just finished
        [[ -f "$stamp" ]] && exit 0

        mkdir -p "$build_dir"
        cmake -S "$LIBRA_SOURCE_ROOT" \
              -B "$build_dir" \
              -DCMAKE_INSTALL_PREFIX="$LIBRA_INSTALL_PREFIX" \
              --log-level=ERROR \
            || { echo "ERROR: cmake configure failed for installed_package setup" >&2; exit 1; }

        cmake --install "$build_dir" \
            || { echo "ERROR: cmake install failed for installed_package setup" >&2; exit 1; }

        touch "$stamp"
    ) 200>"$lockfile"

    # Propagate subshell failure
    return $?
}

# cpm mode: resolve the path to the vendored CPM.cmake.
# Sets LIBRA_CPM_CMAKE.
_libra_setup_cpm() {
    export LIBRA_CPM_CMAKE="${LIBRA_TESTS_DIR}/consume/cpm/CPM.cmake"
    if [[ ! -f "$LIBRA_CPM_CMAKE" ]]; then
        echo "ERROR: CPM.cmake not found at $LIBRA_CPM_CMAKE" >&2
        return 1
    fi
}

# conan mode: run `conan create` once to populate the local cache.
# Sets LIBRA_CONAN_VERSION.
_libra_setup_conan() {
    skip_if_conan_missing

    # Read version from the file written by run_suite_conan.sh.
    # Fall back to environment variable for cases where the suite runner
    # set it directly (e.g. single-file invocation without -j).
    local version_file="${TMPDIR:-/tmp}/libra_conan_version"
    if [[ -z "${LIBRA_CONAN_VERSION:-}" ]]; then
        if [[ -f "$version_file" ]]; then
            LIBRA_CONAN_VERSION="$(cat "$version_file")"
            export LIBRA_CONAN_VERSION
        else
            echo "ERROR: LIBRA_CONAN_VERSION not set and $version_file not found" \
                 "- was run_suite_conan.sh used?" >&2
            return 1
        fi
    fi
}

################################################################################
# Consumption Mode: cmake argument injection
#
# Returns (via echo) the list of -D flags that run_libra_cmake_test() and
# reconfigure_libra_test() must pass to cmake for the active mode.
################################################################################
_consume_mode_cmake_args() {
    case "$LIBRA_CONSUME_MODE" in
        in_situ)
            # Pass source root so libra_consume.cmake can use it even in in_situ
            echo "-DLIBRA_SOURCE_ROOT=${LIBRA_SOURCE_ROOT}"
            ;;
        add_subdirectory)
            echo "-DLIBRA_CONSUME_MODE=add_subdirectory"
            echo "-DLIBRA_SOURCE_ROOT=${LIBRA_SOURCE_ROOT}"
            ;;
        installed_package)
            echo "-DLIBRA_CONSUME_MODE=installed_package"
            echo "-DCMAKE_PREFIX_PATH=${LIBRA_INSTALL_PREFIX}"
            ;;
        cpm)
            echo "-DLIBRA_CONSUME_MODE=cpm"
            echo "-DLIBRA_CPM_CMAKE=${LIBRA_CPM_CMAKE}"
            echo "-DLIBRA_SOURCE_ROOT=${LIBRA_SOURCE_ROOT}"
            ;;
        conan)
            # Signal the mode; the toolchain path is injected separately in
            # run_libra_cmake_test/reconfigure_libra_test where test_dir is
            # in scope, since CMAKE_TOOLCHAIN_FILE must include the per-test
            # build directory path.
            echo "-DLIBRA_CONSUME_MODE=conan"
            echo "-DLIBRA_CONAN_VERSION=${LIBRA_CONAN_VERSION}"
            ;;
        # Unknown modes are caught in setup_libra_test; nothing to do here
    esac
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

# Skip test if clang version too old (inclusive)
# Usage: skip_if_clang_older_than VERSION
skip_if_clang_older_than() {
    local version="$1"
    CLANG_VERSION=$(${CXX_COMPILER_EXEC["clang"]} -dumpversion | cut -d. -f1)
    if [ "$CLANG_VERSION" -le "$version" ]; then
        skip "clang version $CLANG_VERSION <= $version"
    fi
}
# Skip test if g++ version too old (inclusive)
# Usage: skip_if_gcc_older_than VERSION
skip_if_gcc_older_than() {
    local version="$1"
    GCC_VERSION=$(${CXX_COMPILER_EXEC["gnu"]} -dumpversion | cut -d. -f1)
    if [ "$GCC_VERSION" -le "$version" ]; then
        skip "g++ version $GCC_VERSION <= $version"
    fi
}

# Skip test if conan is not installed or not on PATH
# Usage: skip_if_conan_missing
skip_if_conan_missing() {
    if ! command -v conan &>/dev/null; then
        skip "conan not found on PATH - install conan to run conan consumption tests"
    fi
}

# Skip test if conan is the LIBRA driver
# Usage: skip_if_conan_driver
skip_if_conan_driver () {
    if [ "$LIBRA_CONSUME_MODE" = "conan" ]; then
        skip "Test not applicable when conan is the driver"
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
        "$LIBRA_TESTS_DIR/sample_build_info"
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

    # Inject consumption-mode wiring (-D flags for the active LIBRA_CONSUME_MODE)
    local _mode_args
    while IFS= read -r _flag; do
        [[ -n "$_flag" ]] && cmake_args+=("$_flag")
    done < <(_consume_mode_cmake_args)

    # For conan mode: run `conan install` to generate conan_toolchain.cmake
    # in the build dir before cmake runs.
    # We use --requires rather than pointing at the source tree -- the latter
    # treats LIBRA's conanfile.py as a consumer recipe and tries to install
    # *its* dependencies (including tool_requires like cmake) rather than
    # installing libra itself.
    if [[ "${LIBRA_CONSUME_MODE:-in_situ}" == "conan" ]]; then
        mkdir -p "$test_dir/conan"

        # Write a throwaway consumer conanfile into the per-test dir so conan
        # has no reason to touch the source tree. CMakeUserPresets.json will
        # be written here alongside it, isolated per test.
        cat > "$test_dir/conanfile.txt" << EOF
[requires]
libra/${LIBRA_CONAN_VERSION}

[generators]
CMakeToolchain
EOF

        conan install "$test_dir/conanfile.txt" \
              --output-folder="$test_dir/conan" \
              -s build_type="${CMAKE_BUILD_TYPE:-Debug}" \
              --build=missing
        cmake_args+=("-DCMAKE_TOOLCHAIN_FILE=$test_dir/conan/conan_toolchain.cmake")
        cmake_args+=("-DCMAKE_RUNTIME_OUTPUT_DIRECTORY=$test_dir/bin")
    fi

    # Add user-provided cmake options
    cmake_args+=("${cmake_options[@]}")

    # Run cmake
    cd "$test_dir"

    run cmake "${cmake_args[@]}"
    if [ "$status" -ne 0 ]; then
        echo "DEBUG: cmake failed with status $status" >&3
        echo "$output" >&3
        return 1
    fi
    # Echo unconditionally on success to make debugging odd things in
    # CI quicker.
    [ -n "$GITHUB_ACTIONS" ] && echo "$output" >&3

    run make
    if [ "$status" -ne 0 ]; then
        echo "DEBUG: make failed with status $status" >&3
        echo "$output" >&3
        return 1
    fi
    # Echo unconditionally on success to make debugging odd things in
    # CI quicker.
    [ -n "$GITHUB_ACTIONS" ] && echo "$output" >&3

    # Return to original directory and output test dir path
    cd - > /dev/null
    echo "$test_dir"
}


# Reconfigure an existing build dir without --fresh
# Usage: reconfigure_libra_test TEST_DIR LANG [CMAKE_OPTIONS...]
# Returns: 0 on success, 1 on failure
reconfigure_libra_test() {
    local test_dir="$1"
    local lang="$2"
    shift 2
    local cmake_options=("$@")
    local lang_upper=$(echo "$lang" | tr '[:lower:]' '[:upper:]')
    local compiler=$(get_compiler "$COMPILER_TYPE" "$lang")

    local cmake_args=(
        "$LIBRA_TESTS_DIR/sample_build_info"
        -DLIBRA_TEST_LANGUAGE="$lang_upper"
        --log-level="$LOGLEVEL"
    )

    if [ "$lang" = "c" ]; then
        cmake_args+=(-DCMAKE_C_COMPILER="$compiler")
    else
        cmake_args+=(-DCMAKE_CXX_COMPILER="$compiler")
    fi

    # Inject consumption-mode wiring so reconfiguration stays consistent
    local _mode_args
    while IFS= read -r _flag; do
        [[ -n "$_flag" ]] && cmake_args+=("$_flag")
    done < <(_consume_mode_cmake_args)

    # conan install is idempotent; re-run to refresh the toolchain if needed
    if [[ "${LIBRA_CONSUME_MODE:-in_situ}" == "conan" ]]; then
        mkdir -p "$test_dir/conan"
        conan install \
              --requires="libra/${LIBRA_CONAN_VERSION}" \
              --output-folder="$test_dir/conan" \
              --generator=CMakeToolchain \
              -s build_type="${CMAKE_BUILD_TYPE:-Debug}" \
              --build=missing \
            &>/dev/null
        cmake_args+=("-DCMAKE_TOOLCHAIN_FILE=$test_dir/conan/conan_toolchain.cmake")
    fi

    cmake_args+=("${cmake_options[@]}")

    cd "$test_dir"
    cmake "${cmake_args[@]}" &> /dev/null
}

################################################################################
# CMake Test Runner: Root + Dependency
#
################################################################################
# CMake Test Runner: generic named sample
#
# Like run_libra_cmake_test but configures a named sample directory instead of
# sample_build_info.  Used for samples that are always C++ and do not require
# the LIBRA_TEST_LANGUAGE variable (e.g. sample_consumer, sample_export,
# sample_keywords).
#
# Usage: run_libra_cmake_sample_test SAMPLE_DIR [CMAKE_OPTIONS...]
# Returns: Path to build directory
################################################################################
run_libra_cmake_sample_test() {
    local sample_dir="$1"
    shift
    local cmake_options=("$@")

    local compiler
    compiler=$(get_compiler "${COMPILER_TYPE:-gnu}" "cxx")

    local test_dir
    test_dir="$(mktemp -d "$TEST_BUILD_DIR/sample_XXXXXX")"

    local cmake_args=(
        "$LIBRA_TESTS_DIR/${sample_dir}"
        -DCMAKE_INSTALL_PREFIX="$test_dir/install"
        -DCMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE:-Debug}"
        -DCMAKE_CXX_COMPILER="$compiler"
        --log-level="$LOGLEVEL"
    )

    while IFS= read -r _flag; do
        [[ -n "$_flag" ]] && cmake_args+=("$_flag")
    done < <(_consume_mode_cmake_args)

    if [[ "${LIBRA_CONSUME_MODE:-in_situ}" == "conan" ]]; then
        mkdir -p "$test_dir/conan"
        cat > "$test_dir/conanfile.txt" << EOF
[requires]
libra/${LIBRA_CONAN_VERSION}

[generators]
CMakeToolchain
EOF
        conan install "$test_dir/conanfile.txt" \
              --output-folder="$test_dir/conan" \
              -s build_type="${CMAKE_BUILD_TYPE:-Debug}" \
              --build=missing
        cmake_args+=("-DCMAKE_TOOLCHAIN_FILE=$test_dir/conan/conan_toolchain.cmake")
    fi

    cmake_args+=("${cmake_options[@]}")

    pushd "$test_dir" > /dev/null

    run cmake "${cmake_args[@]}"
    if [ "$status" -ne 0 ]; then
        echo "DEBUG: cmake failed with status $status" >&3
        echo "$output" >&3
        popd > /dev/null
        return 1
    fi
    [ -n "$GITHUB_ACTIONS" ] && echo "$output" >&3

    popd > /dev/null
    echo "$test_dir"
}

# Like run_libra_cmake_test but configures sample_dep_isolation/root instead
# of sample_build_info.  The root project pulls in sample_dep_isolation/dep
# via add_subdirectory, giving a two-level LIBRA project tree.
#
# Usage: run_libra_cmake_dep_test LANG [CMAKE_OPTIONS...]
# Returns: Path to build directory (the root build dir)
################################################################################
run_libra_cmake_dep_test() {
    local lang="$1"
    shift
    local cmake_options=("$@")
    local lang_upper=$(echo "$lang" | tr '[:lower:]' '[:upper:]')
    local compiler=$(get_compiler "$COMPILER_TYPE" "$lang")

    local test_dir
    test_dir="$(mktemp -d "$TEST_BUILD_DIR/${lang}_XXXXXX")"

    local cmake_args=(
        "$LIBRA_TESTS_DIR/sample_dep_isolation/root"
        -DCMAKE_INSTALL_PREFIX="$test_dir/install"
        -DCMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE:-Debug}"
        -DLIBRA_TEST_LANGUAGE="$lang_upper"
        --log-level="$LOGLEVEL"
    )

    if [ "$lang" = "c" ]; then
        cmake_args+=(-DCMAKE_C_COMPILER="$compiler")
    else
        cmake_args+=(-DCMAKE_CXX_COMPILER="$compiler")
    fi

    while IFS= read -r _flag; do
        [[ -n "$_flag" ]] && cmake_args+=("$_flag")
    done < <(_consume_mode_cmake_args)

    if [[ "${LIBRA_CONSUME_MODE:-in_situ}" == "conan" ]]; then
        mkdir -p "$test_dir/conan"
        cat > "$test_dir/conanfile.txt" << EOF
[requires]
libra/${LIBRA_CONAN_VERSION}

[generators]
CMakeToolchain
EOF
        conan install "$test_dir/conanfile.txt" \
              --output-folder="$test_dir/conan" \
              -s build_type="${CMAKE_BUILD_TYPE:-Debug}" \
              --build=missing
        cmake_args+=("-DCMAKE_TOOLCHAIN_FILE=$test_dir/conan/conan_toolchain.cmake")
        cmake_args+=("-DCMAKE_RUNTIME_OUTPUT_DIRECTORY=$test_dir/bin")
    fi

    cmake_args+=("${cmake_options[@]}")

    pushd "$test_dir" > /dev/null

    run cmake "${cmake_args[@]}"
    if [ "$status" -ne 0 ]; then
        echo "DEBUG: cmake failed with status $status" >&3
        echo "$output" >&3
        popd > /dev/null
        return 1
    fi
    # Echo unconditionally on success to make debugging odd things in
    # CI quicker.
    [ -n "$GITHUB_ACTIONS" ] && echo "$output" >&3

    run make
    popd > /dev/null
    if [ "$status" -ne 0 ]; then
        echo "DEBUG: make failed with status $status" >&3
        echo "$output" >&3
        return 1
    fi
    # Echo unconditionally on success to make debugging odd things in
    # CI quicker.
    [ -n "$GITHUB_ACTIONS" ] && echo "$output" >&3
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

    grep 'COMPILE_FLAGS' "$build_info" | sed 's/.*COMPILE_FLAGS[[:space:]]*=[[:space:]]*"\(.*\)";/\1/'
}

# Get link flags from build info
# Usage: get_link_flags TEST_DIR LANG
get_link_flags() {
    local test_dir="$1"
    local lang="$2"
    local build_info=$(get_build_info_file "$test_dir" "$lang")

    grep 'LINK_FLAGS' "$build_info" | sed 's/.*LINK_FLAGS[[:space:]]*=[[:space:]]*"\(.*\)";/\1/'
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


# Check if a flag is present in compile_commands.json
# Usage: has_compile_command_flag TEST_DIR FLAG
has_compile_command_flag() {
    local test_dir="$1"
    local flag="$2"

    if [ ! -f "$test_dir/compile_commands.json" ]; then
        echo "ERROR: compile_commands.json not found in $test_dir" >&2
        return 1
    fi

    grep -q -- "$flag" "$test_dir/compile_commands.json"
}

# Assert that a flag appears in compile_commands.json
# Usage: assert_compile_command_flag_present TEST_DIR FLAG
assert_compile_command_flag_present() {
    run has_compile_command_flag "$1" "$2"
    [ "$status" -eq 0 ]
}

# Assert that a flag does NOT appear in compile_commands.json
# Usage: assert_compile_command_flag_absent TEST_DIR FLAG
assert_compile_command_flag_absent() {
    run has_compile_command_flag "$1" "$2"
    [ "$status" -ne 0 ]
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
# CMake Test Runner: sample_testing
#
# Like run_libra_cmake_test but configures sample_testing instead of
# sample_build_info.  sample_testing is a project that contains real test stub
# sources under its tests/ subdirectory, allowing LIBRA_TESTS.bats to verify
# that testing.cmake actually discovers, registers, and labels tests rather
# than just checking cache values.
#
# The project is always C++; LIBRA_TEST_LANGUAGE is not injected.
#
# Usage: run_libra_testing_cmake_test [CMAKE_OPTIONS...]
# Returns: Path to build directory
################################################################################
run_libra_testing_cmake_test() {
    local cmake_options=("$@")
    local compiler
    compiler=$(get_compiler "${COMPILER_TYPE:-gnu}" "cxx")

    local test_dir="$TEST_BUILD_DIR/testing_${RANDOM}"
    mkdir -p "$test_dir"

    local cmake_args=(
        "$LIBRA_TESTS_DIR/sample_testing"
        -DCMAKE_INSTALL_PREFIX="$test_dir/install"
        -DCMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE:-Debug}"
        -DCMAKE_CXX_COMPILER="$compiler"
        --log-level="$LOGLEVEL"
    )

    local _mode_args
    while IFS= read -r _flag; do
        [[ -n "$_flag" ]] && cmake_args+=("$_flag")
    done < <(_consume_mode_cmake_args)

    if [[ "${LIBRA_CONSUME_MODE:-in_situ}" == "conan" ]]; then
        mkdir -p "$test_dir/conan"
        cat > "$test_dir/conanfile.txt" << EOF
[requires]
libra/${LIBRA_CONAN_VERSION}

[generators]
CMakeToolchain
EOF
        conan install "$test_dir/conanfile.txt" \
              --output-folder="$test_dir/conan" \
              -s build_type="${CMAKE_BUILD_TYPE:-Debug}" \
              --build=missing
        cmake_args+=("-DCMAKE_TOOLCHAIN_FILE=$test_dir/conan/conan_toolchain.cmake")
        cmake_args+=("-DCMAKE_RUNTIME_OUTPUT_DIRECTORY=$test_dir/bin")
    fi

    cmake_args+=("${cmake_options[@]}")

    cd "$test_dir"

    run cmake "${cmake_args[@]}"
    if [ "$status" -ne 0 ]; then
        echo "DEBUG: cmake failed with status $status" >&3
        echo "$output" >&3
        cd - > /dev/null
        return 1
    fi

    run make
    if [ "$status" -ne 0 ]; then
        echo "DEBUG: make failed with status $status" >&3
        echo "$output" >&3
        cd - > /dev/null
        return 1
    fi

    cd - > /dev/null
    echo "$test_dir"
}

################################################################################
# Reconfigure helper for sample_testing builds
#
# Like reconfigure_libra_test but points at sample_testing instead of
# sample_build_info.  Must be used when the build directory was originally
# configured by run_libra_testing_cmake_test, because cmake enforces that the
# source directory passed on reconfiguration matches the one in the cache.
#
# Usage: reconfigure_libra_testing_test TEST_DIR [CMAKE_OPTIONS...]
# Returns: 0 on success, 1 on failure
################################################################################
reconfigure_libra_testing_test() {
    local test_dir="$1"
    shift
    local cmake_options=("$@")
    local compiler
    compiler=$(get_compiler "${COMPILER_TYPE:-gnu}" "cxx")

    local cmake_args=(
        "$LIBRA_TESTS_DIR/sample_testing"
        --log-level="$LOGLEVEL"
        -DCMAKE_CXX_COMPILER="$compiler"
    )

    local _mode_args
    while IFS= read -r _flag; do
        [[ -n "$_flag" ]] && cmake_args+=("$_flag")
    done < <(_consume_mode_cmake_args)

    if [[ "${LIBRA_CONSUME_MODE:-in_situ}" == "conan" ]]; then
        mkdir -p "$test_dir/conan"
        conan install \
              --requires="libra/${LIBRA_CONAN_VERSION}" \
              --output-folder="$test_dir/conan" \
              --generator=CMakeToolchain \
              -s build_type="${CMAKE_BUILD_TYPE:-Debug}" \
              --build=missing \
            &>/dev/null
        cmake_args+=("-DCMAKE_TOOLCHAIN_FILE=$test_dir/conan/conan_toolchain.cmake")
    fi

    cmake_args+=("${cmake_options[@]}")

    cd "$test_dir"
    cmake "${cmake_args[@]}" &> /dev/null
    local rc=$?
    cd - > /dev/null
    return $rc
}

################################################################################
# CTest Registration Utilities
#
# Parse CTestTestfile.cmake (written by cmake during configuration) to verify
# which tests were registered with CTest and what labels they received.
#
# CTestTestfile.cmake format (relevant lines):
#   add_test(TEST_NAME "/path/to/binary")
#   set_tests_properties(TEST_NAME PROPERTIES ... LABELS "label" ...)
################################################################################

# Check whether a test name appears in CTestTestfile.cmake.
# The file uses the form: add_test(TEST_NAME ...)
# Usage: ctest_test_registered TEST_DIR TEST_NAME
# Returns: 0 if registered, 1 if absent
ctest_test_registered() {
    local test_dir="$1"
    local test_name="$2"
    local ctestfile="$test_dir/CTestTestfile.cmake"

    if [ ! -f "$ctestfile" ]; then
        return 1
    fi

    # Match the exact test name — must be followed by a space or closing paren
    # to avoid partial-name false positives.
    escaped=$(echo "$test_name" | sed 's/\./\\./g')
    grep -F "add_test(${test_name} " "$ctestfile"
}

# Check that a test has a given CTest LABELS value.
# Usage: ctest_test_has_label TEST_DIR TEST_NAME LABEL
# Returns: 0 if the label is present, 1 otherwise
ctest_test_has_label() {
    local test_dir="$1"
    local test_name="$2"
    local label="$3"
    local ctestfile="$test_dir/CTestTestfile.cmake"

    if [ ! -f "$ctestfile" ]; then
        return 1
    fi

    # set_tests_properties lines contain both the test name and LABELS "label"
    grep -F "set_tests_properties(${test_name} " "$ctestfile" \
        | grep -qF "${label}"
}

# Assert that a test is registered with CTest.
# Usage: assert_ctest_test_registered TEST_DIR TEST_NAME
assert_ctest_test_registered() {
    local test_dir="$1"
    local test_name="$2"

    run ctest_test_registered "$test_dir" "$test_name"
    [ "$status" -eq 0 ]
}

# Assert that a test is NOT registered with CTest.
# Usage: assert_ctest_test_absent TEST_DIR TEST_NAME
assert_ctest_test_absent() {
    local test_dir="$1"
    local test_name="$2"

    run ctest_test_registered "$test_dir" "$test_name"
    [ "$status" -ne 0 ]
}

# Assert that a test has a given CTest label.
# Usage: assert_ctest_test_label TEST_DIR TEST_NAME LABEL
assert_ctest_test_label() {
    local test_dir="$1"
    local test_name="$2"
    local label="$3"

    run ctest_test_has_label "$test_dir" "$test_name" "$label"
    [ "$status" -eq 0 ]
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

################################################################################
# CLI Test Helpers
#
# Helpers for testing the clibra CLI binary.
# CLI tests use sample_cli/ as their project fixture.
################################################################################

# Path to the sample_cli project fixture
CLI_PROJECT_DIR="${LIBRA_TESTS_DIR}/sample_cli"

# Setup function for CLI tests.
# Changes into a temporary copy of sample_cli so each test gets an isolated
# project directory with no pre-existing build artifacts.
setup_cli_test() {
    export CLIBRA_BIN="${LIBRA_TESTS_DIR}/../target/debug/clibra"

    if [[ ! -x "$CLIBRA_BIN" ]]; then
        echo "ERROR: clibra binary not found at $CLIBRA_BIN" >&2
        echo "Build with: cargo build" >&2
        return 1
    fi

    # Copy the fixture into a fresh temp directory so each test is isolated
    export CLI_TEST_DIR="${BATS_TEST_TMPDIR}/project"
    cp -r "$CLI_PROJECT_DIR" "$CLI_TEST_DIR"
    cd "$CLI_TEST_DIR"
}

# Run clibra with the given arguments.
# Sets $status and $output (standard BATS run semantics).
# Usage: run_clibra [ARGS...]
run_clibra() {
    # echo "$CLIBRA_BIN" "$@" >& 3
    run "$CLIBRA_BIN" "$@"
}

# Assert the last run_clibra succeeded.
assert_clibra_success() {
    if [ "$status" -ne 0 ]; then
        echo "Expected success but got exit code $status" >&3
        echo "Output: $output" >&3
        false
    fi
}

# Assert the last run_clibra failed.
assert_clibra_failure() {
    if [ "$status" -eq 0 ]; then
        echo "Expected failure but got exit code 0" >&3
        echo "Output: $output" >&3
        false
    fi
}

# Assert that the last run output contains a string.
# Usage: assert_output_contains STRING
assert_output_contains() {
    if ! echo "$output" | grep -qF -- "$1"; then
        echo "Expected output to contain: $1" >&3
        echo "Actual output: $output" >&3
        false
    fi
}

# Assert that the last run output does NOT contain a string.
# Usage: assert_output_not_contains STRING
assert_output_not_contains() {
    if echo "$output" | grep -qF -- "$1"; then
        echo "Expected output NOT to contain: $1" >&3
        echo "Actual output: $output" >&3
        false
    fi
}

# Run clibra with --dry-run and assert the printed command contains a string.
# Useful for verifying flag forwarding without needing a real build.
# Usage: assert_dry_run_contains EXPECTED_FRAGMENT [ARGS...]
assert_dry_run_contains() {
    local expected="$1"
    shift
    run_clibra --dry-run "$@"
    assert_clibra_success
    assert_output_contains "$expected"
}

# Assert the build directory for a preset exists.
# Usage: assert_build_dir_exists PRESET
assert_build_dir_exists() {
    local preset="$1"
    if [ ! -d "build/${preset}" ]; then
        echo "Expected build directory build/${preset} to exist" >&3
        false
    fi
}

# Assert the build directory for a preset does NOT exist.
# Usage: assert_build_dir_absent PRESET
assert_build_dir_absent() {
    local preset="$1"
    if [ -d "build/${preset}" ]; then
        echo "Expected build directory build/${preset} to be absent" >&3
        false
    fi
}
