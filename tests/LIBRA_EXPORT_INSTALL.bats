#!/usr/bin/env bats
#
# BATS tests for the LIBRA export and install API:
#   libra_configure_exports()        -- generates <target>-config.cmake
#   libra_register_target_for_install()  -- registers a target with install()
#   libra_register_headers_for_install() -- registers headers with install()
#   libra_register_extra_configs_for_install() -- registers extra cmake files
#   libra_configure_cpack()          -- configures CPack generators
#
# sample_consumer exercises configure_exports + register_target_for_install.
# sample_keywords exercises the full install API including headers, extra
# configs, and cpack.
# sample_export exercises the same API as sample_keywords using the same
# keyword calling conventions.
#
# All assertions here are configure-time: cmake exits 0 only if the
# cmake-level assert_file_exists() and assert_target_exists() calls in
# project-local.cmake pass.
#

load test_helpers

setup() {
    setup_libra_test
    INSTALL_LIBDIR=$(get_install_libdir)
}

# ==============================================================================
# libra_configure_exports + libra_register_target_for_install (sample_consumer)
# ==============================================================================

@test "EXPORT: configure_exports generates <target>-config.cmake" {
    # sample_consumer's project-local.cmake calls assert_file_exists on the
    # generated config file, so cmake failure == file not generated.
    test_dir=$(run_libra_cmake_sample_test "sample_consumer")
    [ -n "$test_dir" ]
}

@test "EXPORT: configure_exports produces an includable config file" {
    # project-local.cmake includes the generated config file at configure time;
    # cmake failure == the file is malformed.
    test_dir=$(run_libra_cmake_sample_test "sample_consumer")
    [ -f "$test_dir/producer-config.cmake" ]
}

@test "EXPORT: target remains valid after configure_exports" {
    # project-local.cmake calls assert_target_exists(producer) after export setup.
    test_dir=$(run_libra_cmake_sample_test "sample_consumer")
    assert_target_exists "$test_dir" "producer"
}

@test "EXPORT: register_target_for_install creates install target" {
    test_dir=$(run_libra_cmake_sample_test "sample_consumer")
    assert_target_exists "$test_dir" "install"
}

# ==============================================================================
# Full install API — keyword form (sample_keywords)
# ==============================================================================

@test "INSTALL_API: sample_keywords configures without error" {
    test_dir=$(run_libra_cmake_sample_test "sample_keywords")
    [ -n "$test_dir" ]
}

@test "INSTALL_API: sample_keywords library target exists" {
    test_dir=$(run_libra_cmake_sample_test "sample_keywords")
    assert_target_exists "$test_dir" "mylib"
}

@test "INSTALL_API: sample_keywords executable target exists" {
    test_dir=$(run_libra_cmake_sample_test "sample_keywords")
    assert_target_exists "$test_dir" "myexe"
}

@test "INSTALL_API: sample_keywords creates install target" {
    test_dir=$(run_libra_cmake_sample_test "sample_keywords")
    assert_target_exists "$test_dir" "install"
}

# ==============================================================================
# Full install API — sample_export (same API, verify parity)
# ==============================================================================

@test "INSTALL_API: sample_export configures without error" {
    test_dir=$(run_libra_cmake_sample_test "sample_export")
    [ -n "$test_dir" ]
}

@test "INSTALL_API: sample_export library target exists" {
    test_dir=$(run_libra_cmake_sample_test "sample_export")
    assert_target_exists "$test_dir" "mylib"
}

@test "INSTALL_API: sample_export executable target exists" {
    test_dir=$(run_libra_cmake_sample_test "sample_export")
    assert_target_exists "$test_dir" "myexe"
}

@test "INSTALL_API: sample_export creates install target" {
    test_dir=$(run_libra_cmake_sample_test "sample_export")
    assert_target_exists "$test_dir" "install"
}

# ==============================================================================
# Reconfiguration
# ==============================================================================

@test "EXPORT: sample_consumer reconfigures cleanly" {
    test_dir=$(run_libra_cmake_sample_test "sample_consumer")

    pushd "$test_dir" > /dev/null
    run cmake "$BATS_TEST_DIRNAME/sample_consumer" --log-level=ERROR
    popd > /dev/null
    [ "$status" -eq 0 ]
}

# ==============================================================================
# Actual install verification — cmake --install
#
# The configure-only tests above verify cmake exits 0 and targets exist, but
# they do not prove that files land in the right places after installation.
# These tests run `cmake --install` and check the output directory layout.
#
# Expected layout after install:
#   ${prefix}/lib/              — libproducer.a / libproducer.so
#   ${prefix}/lib/cmake/producer/producer-config.cmake
#   ${prefix}/lib/cmake/producer/producer-exports.cmake
#   ${prefix}/include/          — public headers (if any)
# ==============================================================================

@test "EXPORT: cmake --install succeeds for sample_consumer" {
    test_dir=$(run_libra_cmake_sample_test "sample_consumer")

    pushd "$test_dir" > /dev/null
    run cmake --build .
    run cmake --install .
    popd > /dev/null

    [ "$status" -eq 0 ]
}

@test "EXPORT: installed producer-config.cmake exists under lib/cmake/producer/" {
    test_dir=$(run_libra_cmake_sample_test "sample_consumer")

    pushd "$test_dir" > /dev/null
    run cmake --build .
    cmake --install . > /dev/null 2>&1
    popd > /dev/null

    [ -f "$test_dir/install/${INSTALL_LIBDIR}/cmake/producer/producer-config.cmake" ]
}

@test "EXPORT: installed producer-exports.cmake exists under lib/cmake/producer/" {
    test_dir=$(run_libra_cmake_sample_test "sample_consumer")

    pushd "$test_dir" > /dev/null
    run cmake --build .
    cmake --install . > /dev/null 2>&1
    popd > /dev/null
    [ -f "$test_dir/install/${INSTALL_LIBDIR}/cmake/producer/producer-exports.cmake" ]


}

@test "EXPORT: installed library file exists under lib/" {
    test_dir=$(run_libra_cmake_sample_test "sample_consumer")

    pushd "$test_dir" > /dev/null
    run cmake --build .
    cmake --install . > /dev/null 2>&1
    popd > /dev/null

    # Either a static or shared library must be present
    run find "$test_dir/install/${INSTALL_LIBDIR}" -maxdepth 1 \
        \( -name "libproducer.a" -o -name "libproducer.so" -o -name "libproducer.dylib" \)
    [ -n "$output" ]
}

@test "INSTALL_API: cmake --install succeeds for sample_keywords" {
    test_dir=$(run_libra_cmake_sample_test "sample_keywords")

    pushd "$test_dir" > /dev/null
    run cmake --build .
    run cmake --install .
    popd > /dev/null

    [ "$status" -eq 0 ]
}

@test "INSTALL_API: sample_keywords installs mylib-config.cmake under lib/cmake/mylib/" {
    test_dir=$(run_libra_cmake_sample_test "sample_keywords")

    pushd "$test_dir" > /dev/null
    run cmake --build .
    cmake --install . > /dev/null 2>&1
    popd > /dev/null

    [ -f "$test_dir/install/${INSTALL_LIBDIR}/cmake/mylib/mylib-config.cmake" ]
}

@test "INSTALL_API: sample_keywords installs mylib-exports.cmake under lib/cmake/mylib/" {
    test_dir=$(run_libra_cmake_sample_test "sample_keywords")

    pushd "$test_dir" > /dev/null
    run cmake --build .
    cmake --install . > /dev/null 2>&1
    popd > /dev/null

    [ -f "$test_dir/install/${INSTALL_LIBDIR}/cmake/mylib/mylib-exports.cmake" ]
}

@test "INSTALL_API: sample_keywords installs headers under include/" {
    test_dir=$(run_libra_cmake_sample_test "sample_keywords")

    pushd "$test_dir" > /dev/null
    run cmake --build .
    cmake --install . > /dev/null 2>&1
    popd > /dev/null

    # At least one header must have been installed
    run find "$test_dir/install/include" -name "*.hpp" -o -name "*.h"
    [ -n "$output" ]
}

@test "INSTALL_API: cmake --install succeeds for sample_export" {
    test_dir=$(run_libra_cmake_sample_test "sample_export")

    pushd "$test_dir" > /dev/null
    run cmake --build .
    run cmake --install .
    popd > /dev/null

    [ "$status" -eq 0 ]
}

@test "INSTALL_API: sample_export installs mylib-config.cmake under lib/cmake/mylib/" {
    test_dir=$(run_libra_cmake_sample_test "sample_export")

    pushd "$test_dir" > /dev/null
    run cmake --build .
    cmake --install . > /dev/null 2>&1
    popd > /dev/null

    [ -f "$test_dir/install/${INSTALL_LIBDIR}/cmake/mylib/mylib-config.cmake" ]
}
