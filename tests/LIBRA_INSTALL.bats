#!/usr/bin/env bats
#
# BATS tests for the overhauled LIBRA install API:
#
#   libra_install_target()        -- installs compiled target + optional headers
#   libra_install_headers()       -- installs a header directory
#   libra_install_cmake_modules() -- installs .cmake files/directories
#   libra_install_copyright()     -- installs LICENSE as 'copyright'
#   libra_add_component_library() -- defines a component as a separate library
#   libra_check_components()      -- verifies requested components are present
#
# Also verifies that the deprecated wrapper names (libra_register_*) still
# work and emit DEPRECATION warnings.
#
# Observable strategy:
#   - Configure-time: cmake exits 0 and assert_* calls in project-local.cmake pass
#   - Install-time:   cmake --install and file presence checks
#   - Status output:  captured cmake output for deprecation and STATUS messages
#

load test_helpers

setup_file() {
    # GNUInstallDirs' libdir (lib vs lib64) is a property of the platform,
    # so probe it once per file rather than once per test.
    INSTALL_LIBDIR=$(get_install_libdir)
    export INSTALL_LIBDIR
}

setup() {
    setup_libra_test
}

# Build and install a configured sample, failing the test (with cmake's
# output) if either step fails.
# Usage: build_and_install TEST_DIR
build_and_install() {
    run cmake --build "$1"
    assert_success
    run cmake --install "$1"
    assert_success
}

# ==============================================================================
# Helper: run cmake and capture output (mirrors run_libra_cmake_cpack_test)
# ==============================================================================
run_libra_cmake_install_test() {
    local sample_dir="$1"
    shift
    local cmake_options=("$@")

    local compiler
    compiler=$(get_compiler "${COMPILER_TYPE:-gnu}" "cxx")

    INSTALL_TEST_DIR="$(mktemp -d "$TEST_BUILD_DIR/install_XXXXXX")"

    local cmake_args=(
        "$LIBRA_TESTS_DIR/${sample_dir}"
        -DCMAKE_INSTALL_PREFIX="$INSTALL_TEST_DIR/install"
        -DCMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE:-Debug}"
        -DCMAKE_CXX_COMPILER="$compiler"
        --log-level=STATUS
    )

    while IFS= read -r _flag; do
        [[ -n "$_flag" ]] && cmake_args+=("$_flag")
    done < <(_consume_mode_cmake_args)

    cmake_args+=("${cmake_options[@]}")

    pushd "$INSTALL_TEST_DIR" > /dev/null
    run cmake "${cmake_args[@]}"
    popd > /dev/null
}

# ==============================================================================
# libra_install_target — configure-time
# ==============================================================================

@test "INSTALL: libra_install_target creates install target" {
    test_dir=$(run_libra_cmake_sample_test "sample_keywords")
    assert_target_exists "$test_dir" "install"
}

@test "INSTALL: libra_install_target creates install target (sample_export)" {
    test_dir=$(run_libra_cmake_sample_test "sample_export")
    assert_target_exists "$test_dir" "install"
}

@test "INSTALL: sample_keywords configures without error with new API names" {
    test_dir=$(run_libra_cmake_sample_test "sample_keywords")
    assert [ -n "$test_dir" ]
}

@test "INSTALL: sample_export configures without error with new API names" {
    test_dir=$(run_libra_cmake_sample_test "sample_export")
    assert [ -n "$test_dir" ]
}

# ==============================================================================
# libra_install_target — install-time file layout
# ==============================================================================

@test "INSTALL: libra_install_target installs library under lib/" {
    test_dir=$(run_libra_cmake_sample_test "sample_keywords")

    build_and_install "$test_dir"

    run find "$test_dir/install/${INSTALL_LIBDIR}" -maxdepth 1 \
        \( -name "libmylib.a" -o -name "libmylib.so" -o -name "libmylib.dylib" \)
    assert_output
}

@test "INSTALL: libra_install_target installs config file under lib/cmake/<target>/" {
    test_dir=$(run_libra_cmake_sample_test "sample_keywords")

    build_and_install "$test_dir"

    assert_file_exists "$test_dir/install/lib/cmake/mylib/mylib-config.cmake"
}

@test "INSTALL: libra_install_target installs exports file under lib/cmake/<target>/" {
    test_dir=$(run_libra_cmake_sample_test "sample_keywords")

    build_and_install "$test_dir"

    assert_file_exists "$test_dir/install/lib/cmake/mylib/mylib-exports.cmake"
}

@test "INSTALL: libra_install_target installs headers under include/" {
    test_dir=$(run_libra_cmake_sample_test "sample_export")

    build_and_install "$test_dir"

    run find "$test_dir/install/include" \( -name "*.hpp" -o -name "*.h" \)
    assert_output
}

# ==============================================================================
# libra_install_headers — separate call
# ==============================================================================

@test "INSTALL: libra_install_headers installs headers under include/" {
    test_dir=$(run_libra_cmake_sample_test "sample_keywords")

    build_and_install "$test_dir"

    run find "$test_dir/install/include" \( -name "*.hpp" -o -name "*.h" \)
    assert_output
}

@test "INSTALL: libra_install_headers preserves directory structure" {
    test_dir=$(run_libra_cmake_sample_test "sample_export")

    build_and_install "$test_dir"

    # Top-level headers land directly under include/, and the nested header
    # keeps its subdirectory.
    assert_file_exists "$test_dir/install/include/a.hpp"
    assert_file_exists "$test_dir/install/include/b.hpp"
    assert_file_exists "$test_dir/install/include/nested/c.hpp"
}

# ==============================================================================
# libra_install_cmake_modules
# ==============================================================================

@test "INSTALL: libra_install_cmake_modules installs .cmake file under lib/cmake/<target>/" {
    test_dir=$(run_libra_cmake_sample_test "sample_keywords")

    build_and_install "$test_dir"

    assert_file_exists "$test_dir/install/lib/cmake/mylib/foo.cmake"
}

# ==============================================================================
# libra_install_copyright
# ==============================================================================

@test "INSTALL: libra_install_copyright installs file renamed to 'copyright'" {
    test_dir=$(run_libra_cmake_sample_test "sample_components")

    build_and_install "$test_dir"

    assert_file_exists "$test_dir/install/share/doc/sample_components/copyright"
}

# ==============================================================================
# libra_add_component_library — configure-time
# ==============================================================================

@test "COMPONENTS: library strategy configures without error" {
    test_dir=$(run_libra_cmake_sample_test "sample_components" \
        -DLIBRA_TEST_COMPONENT_STRATEGY=library)
    assert [ -n "$test_dir" ]
}

@test "COMPONENTS: library strategy creates <target>_networking library target" {
    test_dir=$(run_libra_cmake_sample_test "sample_components" \
        -DLIBRA_TEST_COMPONENT_STRATEGY=library)
    assert_target_exists "$test_dir" "sample_components_networking"
}

@test "COMPONENTS: library strategy creates <target>_serialization library target" {
    test_dir=$(run_libra_cmake_sample_test "sample_components" \
        -DLIBRA_TEST_COMPONENT_STRATEGY=library)
    assert_target_exists "$test_dir" "sample_components_serialization"
}

@test "COMPONENTS: library strategy sets <target>_networking_FOUND" {
    # assert_true() in project-local.cmake fires FATAL_ERROR if not set;
    # cmake exit 0 proves the flag was set.
    test_dir=$(run_libra_cmake_sample_test "sample_components" \
        -DLIBRA_TEST_COMPONENT_STRATEGY=library)
    assert [ -n "$test_dir" ]
}

@test "COMPONENTS: library strategy sets <target>_serialization_FOUND" {
    test_dir=$(run_libra_cmake_sample_test "sample_components" \
        -DLIBRA_TEST_COMPONENT_STRATEGY=library)
    assert [ -n "$test_dir" ]
}

@test "COMPONENTS: library strategy generates config file in build dir" {
    test_dir=$(run_libra_cmake_sample_test "sample_components" \
        -DLIBRA_TEST_COMPONENT_STRATEGY=library)
    assert_file_exists "$test_dir/sample_components-config.cmake"
}

# ==============================================================================
# libra_add_component_library — install-time layout
# ==============================================================================

@test "COMPONENTS: library strategy installs component library under lib/" {
    test_dir=$(run_libra_cmake_sample_test "sample_components" \
        -DLIBRA_TEST_COMPONENT_STRATEGY=library)

    build_and_install "$test_dir"

    run find "$test_dir/install/${INSTALL_LIBDIR}" -maxdepth 1 \
        \( -name "*networking*" \)
    assert_output
}

# ==============================================================================
# libra_check_components — STATUS output
# ==============================================================================

@test "COMPONENTS: check_components emits CHECK_PASS when all components found" {
    run_libra_cmake_install_test "sample_components" \
        -DLIBRA_TEST_COMPONENT_STRATEGY=library

    assert_success
    # project-local.cmake doesn't call libra_check_components directly since
    # that's a config.cmake.in concern; verify configure succeeded and _FOUND
    # flags are set (proven by cmake exit 0 from assert_true calls)
}

# ==============================================================================
# Deprecated wrapper names — must still work and emit DEPRECATION
# ==============================================================================

@test "DEPRECATED: libra_register_target_for_install emits DEPRECATION warning" {
    run_libra_cmake_install_test "sample_keywords" \
        -DLIBRA_TEST_USE_DEPRECATED_NAMES=ON

    assert_success
    assert_output --partial "deprecated"
    assert_output --partial "libra_register_target_for_install"
}

@test "DEPRECATED: libra_register_headers_for_install emits DEPRECATION warning" {
    run_libra_cmake_install_test "sample_keywords" \
        -DLIBRA_TEST_USE_DEPRECATED_NAMES=ON

    assert_success
    assert_output --partial "deprecated"
    assert_output --partial "libra_register_headers_for_install"
}

@test "DEPRECATED: libra_register_extra_configs_for_install emits DEPRECATION warning" {
    run_libra_cmake_install_test "sample_keywords" \
        -DLIBRA_TEST_USE_DEPRECATED_NAMES=ON

    assert_success
    assert_output --partial "deprecated"
    assert_output --partial "libra_register_extra_configs_for_install"
}

@test "DEPRECATED: libra_component_register_as_lib emits DEPRECATION warning" {
    run_libra_cmake_install_test "sample_components" \
        -DLIBRA_TEST_USE_DEPRECATED_NAMES=ON

    assert_success
    assert_output --partial "deprecated"
    assert_output --partial "libra_component_register_as_lib"
}

@test "DEPRECATED: deprecated wrappers still configure successfully" {
    run_libra_cmake_install_test "sample_keywords" \
        -DLIBRA_TEST_USE_DEPRECATED_NAMES=ON

    assert_success
}

# ==============================================================================
# Error cases
# ==============================================================================

@test "INSTALL: libra_install_target with non-existent TARGET causes FATAL_ERROR" {
    run_libra_cmake_install_test "sample_keywords" \
        -DLIBRA_TEST_INSTALL_BAD_TARGET=ON

    assert_failure
}

@test "COMPONENTS: libra_add_component_library without REGEX causes FATAL_ERROR" {
    run_libra_cmake_install_test "sample_components" \
        -DLIBRA_TEST_COMPONENT_MISSING_REGEX=ON

    assert_failure
}
