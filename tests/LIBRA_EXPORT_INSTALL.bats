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
