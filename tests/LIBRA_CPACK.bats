#!/usr/bin/env bats
#
# BATS tests for libra_configure_cpack() (package/deploy.cmake)
#
# libra_configure_cpack() configures CPack to generate packages.
# Signature:
#
#   libra_configure_cpack(
#       GENERATORS    # semicolon-separated: DEB, RPM, TGZ, ZIP, STGZ, TBZ2, TXZ
#       SUMMARY       # one-line description
#       DESCRIPTION   # full description
#       VENDOR        # maintainer organization
#       HOMEPAGE      # project URL
#       CONTACT       # email (DEB) or name (RPM)
#   )
#
# All CPACK_* variables are set with plain cmake set() (no CACHE), so they do
# not appear in CMakeCache.txt.  The observable artefact after a successful
# configure is CPackConfig.cmake, written to CMAKE_BINARY_DIR by
# include(CPack).  That file contains every CPACK_* variable as a cmake
# set() call and is the primary assertion target here.
#
# Secondary observables:
#   - cmake configure exit status (0 = success, non-0 = FATAL_ERROR)
#   - the "package" Makefile target (created by include(CPack))
#   - cmake STATUS output messages (via run_libra_cmake_cpack_test, which
#     returns both test_dir and the captured configure output)
#
# Strategy: sample_keywords calls libra_configure_cpack() when
# LIBRA_TEST_CPACK_GENERATORS is set.  Additional -D flags control
# which generator, license fixture, and error-injection paths are used.
#

load test_helpers

setup() {
    setup_libra_test
}

# ==============================================================================
# Helper: run cmake configure and expose both the build dir AND cmake output.
#
# run_libra_cmake_sample_test swallows $output; this wrapper re-runs cmake
# in a fresh directory so the caller can inspect $output directly.
#
# Usage: run_libra_cmake_cpack_test SAMPLE_DIR [CMAKE_OPTIONS...]
# Sets:  $status  — cmake exit status
#        $output  — full cmake configure output
#        $CPACK_TEST_DIR — build directory path (set in env for subsequent checks)
# ==============================================================================
run_libra_cmake_cpack_test() {
    local sample_dir="$1"
    shift
    local cmake_options=("$@")

    local compiler
    compiler=$(get_compiler "${COMPILER_TYPE:-gnu}" "cxx")

    CPACK_TEST_DIR="$(mktemp -d "$TEST_BUILD_DIR/cpack_XXXXXX")"

    local cmake_args=(
        "$LIBRA_TESTS_DIR/${sample_dir}"
        -DCMAKE_INSTALL_PREFIX="$CPACK_TEST_DIR/install"
        -DCMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE:-Debug}"
        -DCMAKE_CXX_COMPILER="$compiler"
        --log-level=STATUS
    )

    while IFS= read -r _flag; do
        [[ -n "$_flag" ]] && cmake_args+=("$_flag")
    done < <(_consume_mode_cmake_args)

    cmake_args+=("${cmake_options[@]}")

    pushd "$CPACK_TEST_DIR" > /dev/null
    run cmake "${cmake_args[@]}"
    popd > /dev/null
}

# Read a variable from CPackConfig.cmake.
# Usage: cpack_config_value TEST_DIR VARNAME
# Prints the value, returns 0 if found, 1 if not.
cpack_config_value() {
    local test_dir="$1"
    local varname="$2"
    local cpack_file="$test_dir/CPackConfig.cmake"

    if [[ ! -f "$cpack_file" ]]; then
        echo "ERROR: $cpack_file not found" >&2
        return 1
    fi

    # Lines have the form: set(VARNAME "value") or set(VARNAME value)
    local line
    line=$(grep "^set(${varname} " "$cpack_file" | head -1)
    if [[ -z "$line" ]]; then
        return 1
    fi
    # Extract the value — strip leading 'set(VAR ' and trailing ')'
    # Handles both quoted and unquoted values
    echo "$line" | sed 's/^set([^ ]* //; s/)$//' | tr -d '"'
}

# Assert a variable in CPackConfig.cmake equals an expected value.
# Usage: assert_cpack_value TEST_DIR VARNAME EXPECTED
assert_cpack_value() {
    local test_dir="$1"
    local varname="$2"
    local expected="$3"

    local actual
    actual=$(cpack_config_value "$test_dir" "$varname")
    if [[ "$actual" != "$expected" ]]; then
        echo "CPACK: $varname: expected '$expected', got '$actual'" >&3
        return 1
    fi
}

# Assert a variable is present (non-empty) in CPackConfig.cmake.
# Usage: assert_cpack_var_set TEST_DIR VARNAME
assert_cpack_var_set() {
    local test_dir="$1"
    local varname="$2"

    local actual
    actual=$(cpack_config_value "$test_dir" "$varname")
    if [[ -z "$actual" ]]; then
        echo "CPACK: $varname not set in CPackConfig.cmake" >&3
        return 1
    fi
}

# ==============================================================================
# CPackConfig.cmake is generated
# ==============================================================================

@test "CPACK: TGZ generator produces CPackConfig.cmake" {
    test_dir=$(run_libra_cmake_sample_test "sample_keywords" \
        -DLIBRA_TEST_CPACK_GENERATORS=TGZ)

    [ -f "$test_dir/CPackConfig.cmake" ]
}

@test "CPACK: ZIP generator produces CPackConfig.cmake" {
    test_dir=$(run_libra_cmake_sample_test "sample_keywords" \
        -DLIBRA_TEST_CPACK_GENERATORS=ZIP)

    [ -f "$test_dir/CPackConfig.cmake" ]
}

@test "CPACK: DEB generator produces CPackConfig.cmake" {
    test_dir=$(run_libra_cmake_sample_test "sample_keywords" \
        -DLIBRA_TEST_CPACK_GENERATORS=DEB)

    [ -f "$test_dir/CPackConfig.cmake" ]
}

@test "CPACK: RPM generator produces CPackConfig.cmake" {
    test_dir=$(run_libra_cmake_sample_test "sample_keywords" \
        -DLIBRA_TEST_CPACK_GENERATORS=RPM)

    [ -f "$test_dir/CPackConfig.cmake" ]
}

@test "CPACK: multiple generators (TGZ;ZIP) produce CPackConfig.cmake" {
    test_dir=$(run_libra_cmake_sample_test "sample_keywords" \
        "-DLIBRA_TEST_CPACK_GENERATORS=TGZ;ZIP")

    [ -f "$test_dir/CPackConfig.cmake" ]
}

# ==============================================================================
# package Makefile target
# ==============================================================================

@test "CPACK: TGZ generator creates package Makefile target" {
    test_dir=$(run_libra_cmake_sample_test "sample_keywords" \
        -DLIBRA_TEST_CPACK_GENERATORS=TGZ)

    assert_target_exists "$test_dir" "package"
}

@test "CPACK: DEB generator creates package Makefile target" {
    test_dir=$(run_libra_cmake_sample_test "sample_keywords" \
        -DLIBRA_TEST_CPACK_GENERATORS=DEB)

    assert_target_exists "$test_dir" "package"
}

# ==============================================================================
# Common CPACK_* variables in CPackConfig.cmake
# ==============================================================================

@test "CPACK: CPACK_GENERATOR set correctly in CPackConfig.cmake" {
    test_dir=$(run_libra_cmake_sample_test "sample_keywords" \
        -DLIBRA_TEST_CPACK_GENERATORS=TGZ)

    assert_cpack_value "$test_dir" "CPACK_GENERATOR" "TGZ"
}

@test "CPACK: CPACK_PACKAGE_VERSION set from PROJECT_VERSION in CPackConfig.cmake" {
    test_dir=$(run_libra_cmake_sample_test "sample_keywords" \
        -DLIBRA_TEST_CPACK_GENERATORS=TGZ)

    # Value must be non-empty and in x.y.z form
    local ver
    ver=$(cpack_config_value "$test_dir" "CPACK_PACKAGE_VERSION")
    [ -n "$ver" ]
    [[ "$ver" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "CPACK: CPACK_PACKAGE_NAME set in CPackConfig.cmake" {
    test_dir=$(run_libra_cmake_sample_test "sample_keywords" \
        -DLIBRA_TEST_CPACK_GENERATORS=TGZ)

    assert_cpack_var_set "$test_dir" "CPACK_PACKAGE_NAME"
}

@test "CPACK: CPACK_PACKAGE_VENDOR set in CPackConfig.cmake" {
    test_dir=$(run_libra_cmake_sample_test "sample_keywords" \
        -DLIBRA_TEST_CPACK_GENERATORS=TGZ)

    assert_cpack_var_set "$test_dir" "CPACK_PACKAGE_VENDOR"
}

# ==============================================================================
# DEB-specific variables in CPackConfig.cmake
# ==============================================================================

@test "CPACK: DEB sets CPACK_DEBIAN_FILE_NAME to DEB-DEFAULT in CPackConfig.cmake" {
    test_dir=$(run_libra_cmake_sample_test "sample_keywords" \
        -DLIBRA_TEST_CPACK_GENERATORS=DEB)

    assert_cpack_value "$test_dir" "CPACK_DEBIAN_FILE_NAME" "DEB-DEFAULT"
}

@test "CPACK: DEB sets CPACK_DEBIAN_PACKAGE_SHLIBDEPS to ON in CPackConfig.cmake" {
    test_dir=$(run_libra_cmake_sample_test "sample_keywords" \
        -DLIBRA_TEST_CPACK_GENERATORS=DEB)

    assert_cpack_value "$test_dir" "CPACK_DEBIAN_PACKAGE_SHLIBDEPS" "ON"
}

@test "CPACK: DEB sets CPACK_DEBIAN_PACKAGE_SECTION to devel in CPackConfig.cmake" {
    test_dir=$(run_libra_cmake_sample_test "sample_keywords" \
        -DLIBRA_TEST_CPACK_GENERATORS=DEB)

    assert_cpack_value "$test_dir" "CPACK_DEBIAN_PACKAGE_SECTION" "devel"
}

@test "CPACK: DEB sets CPACK_DEBIAN_PACKAGE_PRIORITY to optional in CPackConfig.cmake" {
    test_dir=$(run_libra_cmake_sample_test "sample_keywords" \
        -DLIBRA_TEST_CPACK_GENERATORS=DEB)

    assert_cpack_value "$test_dir" "CPACK_DEBIAN_PACKAGE_PRIORITY" "optional"
}

# ==============================================================================
# RPM-specific variables in CPackConfig.cmake
# ==============================================================================

@test "CPACK: RPM sets CPACK_RPM_FILE_NAME to RPM-DEFAULT in CPackConfig.cmake" {
    test_dir=$(run_libra_cmake_sample_test "sample_keywords" \
        -DLIBRA_TEST_CPACK_GENERATORS=RPM)

    assert_cpack_value "$test_dir" "CPACK_RPM_FILE_NAME" "RPM-DEFAULT"
}

@test "CPACK: RPM sets CPACK_RPM_PACKAGE_AUTOREQ to ON in CPackConfig.cmake" {
    test_dir=$(run_libra_cmake_sample_test "sample_keywords" \
        -DLIBRA_TEST_CPACK_GENERATORS=RPM)

    assert_cpack_value "$test_dir" "CPACK_RPM_PACKAGE_AUTOREQ" "ON"
}

@test "CPACK: RPM sets CPACK_RPM_PACKAGE_GROUP to Development/Libraries in CPackConfig.cmake" {
    test_dir=$(run_libra_cmake_sample_test "sample_keywords" \
        -DLIBRA_TEST_CPACK_GENERATORS=RPM)

    assert_cpack_value "$test_dir" "CPACK_RPM_PACKAGE_GROUP" "Development/Libraries"
}

@test "CPACK: RPM sets CPACK_RPM_PACKAGE_RELEASE to 1 in CPackConfig.cmake" {
    test_dir=$(run_libra_cmake_sample_test "sample_keywords" \
        -DLIBRA_TEST_CPACK_GENERATORS=RPM)

    assert_cpack_value "$test_dir" "CPACK_RPM_PACKAGE_RELEASE" "1"
}

@test "CPACK: RPM sets CPACK_RPM_PACKAGE_RELOCATABLE to ON in CPackConfig.cmake" {
    test_dir=$(run_libra_cmake_sample_test "sample_keywords" \
        -DLIBRA_TEST_CPACK_GENERATORS=RPM)

    assert_cpack_value "$test_dir" "CPACK_RPM_PACKAGE_RELOCATABLE" "ON"
}

# ==============================================================================
# License auto-detection (RPM) — verified via STATUS output
#
# The macro emits: "RPM: Group=..., License=..., Release=..."
# This is the only observable that doesn't require a fixture LICENSE file
# with controlled content; the sample_keywords fixture controls which
# license text is injected via LIBRA_TEST_CPACK_LICENSE_TYPE.
# ==============================================================================

@test "CPACK: RPM MIT license auto-detected — CPACK_RPM_PACKAGE_LICENSE=MIT in CPackConfig.cmake" {
    test_dir=$(run_libra_cmake_sample_test "sample_keywords" \
        -DLIBRA_TEST_CPACK_GENERATORS=RPM \
        -DLIBRA_TEST_CPACK_LICENSE_TYPE=MIT)

    assert_cpack_value "$test_dir" "CPACK_RPM_PACKAGE_LICENSE" "MIT"
}

@test "CPACK: RPM unrecognised license falls back to Unknown in CPackConfig.cmake" {
    test_dir=$(run_libra_cmake_sample_test "sample_keywords" \
        -DLIBRA_TEST_CPACK_GENERATORS=RPM \
        -DLIBRA_TEST_CPACK_LICENSE_TYPE=Unknown)

    assert_cpack_value "$test_dir" "CPACK_RPM_PACKAGE_LICENSE" "Unknown"
}

@test "CPACK: missing LICENSE file warns but configures without error" {
    test_dir=$(run_libra_cmake_sample_test "sample_keywords" \
        -DLIBRA_TEST_CPACK_GENERATORS=TGZ \
        -DLIBRA_TEST_CPACK_OMIT_LICENSE=ON)

    [ -n "$test_dir" ]
    [ -f "$test_dir/CPackConfig.cmake" ]
}

# ==============================================================================
# Error cases — cmake must exit non-zero
# ==============================================================================

@test "CPACK: invalid generator causes cmake FATAL_ERROR" {
    run_libra_cmake_cpack_test "sample_keywords" \
        -DLIBRA_TEST_CPACK_GENERATORS=INVALID_GENERATOR

    [ "$status" -ne 0 ]
}

@test "CPACK: missing PROJECT_VERSION causes cmake FATAL_ERROR" {
    run_libra_cmake_cpack_test "sample_keywords" \
        -DLIBRA_TEST_CPACK_GENERATORS=TGZ \
        -DLIBRA_TEST_CPACK_OMIT_VERSION=ON

    [ "$status" -ne 0 ]
}

# ==============================================================================
# STATUS message observable
#
# The macro logs "Configured CPack for <name> <version>" at STATUS level.
# This is the lightest-weight check that the macro ran at all without needing
# to inspect CPackConfig.cmake.
# ==============================================================================

@test "CPACK: configure emits 'Configured CPack' STATUS message" {
    run_libra_cmake_cpack_test "sample_keywords" \
        -DLIBRA_TEST_CPACK_GENERATORS=TGZ

    [ "$status" -eq 0 ]
    assert_output_contains "Configured CPack"
}

@test "CPACK: DEB configure emits DEB-specific STATUS message" {
    run_libra_cmake_cpack_test "sample_keywords" \
        -DLIBRA_TEST_CPACK_GENERATORS=DEB

    [ "$status" -eq 0 ]
    assert_output_contains "Configuring DEB package generator"
}

@test "CPACK: RPM configure emits RPM-specific STATUS message" {
    run_libra_cmake_cpack_test "sample_keywords" \
        -DLIBRA_TEST_CPACK_GENERATORS=RPM

    [ "$status" -eq 0 ]
    assert_output_contains "Configuring RPM package generator"
}
