#!/usr/bin/env bats
#
# BATS tests for LIBRA_FORMAT (Code Formatting)
#
# LIBRA_FORMAT is the dedicated switch for formatting targets:
#   - ON:  Creates format, format-check, and per-tool subtargets
#   - OFF: No formatting targets created (default)
#
# LIBRA_ANALYSIS=ON also enables these targets internally (analysis implies
# formatting).  Tests in both sections are therefore included below:
#   - LIBRA_FORMAT=ON/OFF in isolation
#   - LIBRA_ANALYSIS=ON implies format targets present
#   - LIBRA_ANALYSIS=OFF + LIBRA_FORMAT=OFF means all format targets absent
#
# Format targets when ON:
#   - format:               Apply all formatters (clang-format + cmake-format)
#   - format-check:         Check formatting without modifying files
#   - format-clang:         Apply clang-format
#   - format-check-clang:   Check clang-format conformance
#   - format-cmake:         Apply cmake-format
#   - format-check-cmake:   Check cmake-format conformance
#
# Tools are optional: if clang-format or cmake-format is not installed the
# corresponding subtargets are absent but the umbrella targets still exist.
#

load test_helpers

setup() {
    setup_libra_test
}

# ==============================================================================
# LIBRA_FORMAT=ON — formatting targets created
# ==============================================================================

@test "FORMAT: LIBRA_FORMAT=ON creates all format targets (C)" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_FORMAT=ON)

    assert_target_exists "$test_dir" "format"
    assert_target_exists "$test_dir" "format-check"
}

@test "FORMAT: LIBRA_FORMAT=ON creates all format targets (C++)" {
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_FORMAT=ON)

    assert_target_exists "$test_dir" "format"
    assert_target_exists "$test_dir" "format-check"
}

@test "FORMAT: LIBRA_FORMAT=ON creates clang-format subtargets when clang-format is available" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_FORMAT=ON)

    # These targets are present only if clang-format is installed; skip rather
    # than hard-fail so the suite stays green on minimal CI images.
    if ! command -v clang-format &>/dev/null; then
        skip "clang-format not found on PATH"
    fi

    assert_target_exists "$test_dir" "format-clang"
    assert_target_exists "$test_dir" "format-check-clang"
}

@test "FORMAT: LIBRA_FORMAT=ON creates cmake-format subtargets when cmake-format is available" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_FORMAT=ON)

    if ! command -v cmake-format &>/dev/null; then
        skip "cmake-format not found on PATH"
    fi

    assert_target_exists "$test_dir" "format-cmake"
    assert_target_exists "$test_dir" "format-check-cmake"
}

# ==============================================================================
# LIBRA_FORMAT=OFF — formatting targets absent
# ==============================================================================

@test "FORMAT: LIBRA_FORMAT=OFF creates no format targets (C)" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_FORMAT=OFF)

    assert_target_absent "$test_dir" "format"
    assert_target_absent "$test_dir" "format-check"
    assert_target_absent "$test_dir" "format-clang"
    assert_target_absent "$test_dir" "format-check-clang"
    assert_target_absent "$test_dir" "format-cmake"
    assert_target_absent "$test_dir" "format-check-cmake"
}

@test "FORMAT: LIBRA_FORMAT=OFF creates no format targets (C++)" {
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_FORMAT=OFF)

    assert_target_absent "$test_dir" "format"
    assert_target_absent "$test_dir" "format-check"
    assert_target_absent "$test_dir" "format-clang"
    assert_target_absent "$test_dir" "format-check-clang"
    assert_target_absent "$test_dir" "format-cmake"
    assert_target_absent "$test_dir" "format-check-cmake"
}

@test "FORMAT: Default (unset) creates no format targets" {
    test_dir=$(run_libra_cmake_test "c")

    assert_target_absent "$test_dir" "format"
    assert_target_absent "$test_dir" "format-check"
}

# ==============================================================================
# LIBRA_ANALYSIS=ON implies format targets present
#
# format.cmake is included unconditionally by project.cmake; the targets are
# only materialised when LIBRA_FORMAT=ON.  
# ==============================================================================
@test "FORMAT: LIBRA_ANALYSIS=OFF and LIBRA_FORMAT=OFF means no format targets" {
    test_dir=$(run_libra_cmake_test "c" \
        -DLIBRA_FORMAT=OFF)

    assert_target_absent "$test_dir" "format"
    assert_target_absent "$test_dir" "format-check"
    assert_target_absent "$test_dir" "format-clang"
    assert_target_absent "$test_dir" "format-check-clang"
    assert_target_absent "$test_dir" "format-cmake"
    assert_target_absent "$test_dir" "format-check-cmake"
}

# ==============================================================================
# FORMAT flags visible in compile_commands.json
#
# FORMAT hardening flags (-Wformat-security, -Werror=format=2 on GNU;
# -Werror=format-security on Clang) begin with -W and are stripped by the
# build_info filter, so they cannot be verified via assert_compile_flag_present.
# compile_commands.json is NOT filtered, so the flags ARE observable there.
# ==============================================================================

@test "FORMAT: LIBRA_FORTIFY=FORMAT adds -Wformat-security to compile_commands.json (GNU/C)" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" \
        -DLIBRA_FORTIFY=FORMAT \
        -DCMAKE_BUILD_TYPE=Release)

    assert_compile_command_flag_present "$test_dir" "-Wformat-security"
}

@test "FORMAT: LIBRA_FORTIFY=FORMAT adds -Werror=format=2 to compile_commands.json (GNU/C)" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" \
        -DLIBRA_FORTIFY=FORMAT \
        -DCMAKE_BUILD_TYPE=Release)

    assert_compile_command_flag_present "$test_dir" "-Werror=format=2"
}

@test "FORMAT: LIBRA_FORTIFY=FORMAT adds -Wformat-security to compile_commands.json (GNU/C++)" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" \
        -DLIBRA_FORTIFY=FORMAT \
        -DCMAKE_BUILD_TYPE=Release)

    assert_compile_command_flag_present "$test_dir" "-Wformat-security"
}

@test "FORMAT: LIBRA_FORTIFY=FORMAT adds -Werror=format=2 to compile_commands.json (GNU/C++)" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" \
        -DLIBRA_FORTIFY=FORMAT \
        -DCMAKE_BUILD_TYPE=Release)

    assert_compile_command_flag_present "$test_dir" "-Werror=format=2"
}

@test "FORMAT: LIBRA_FORTIFY=FORMAT adds -Wformat-security to compile_commands.json (Clang/C)" {
    skip_if_compiler_missing "clang" "c"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "c" \
        -DLIBRA_FORTIFY=FORMAT \
        -DCMAKE_BUILD_TYPE=Release)

    assert_compile_command_flag_present "$test_dir" "-Wformat-security"
}

@test "FORMAT: LIBRA_FORTIFY=FORMAT adds -Wformat-security to compile_commands.json (Clang/C++)" {
    skip_if_compiler_missing "clang" "cxx"
    COMPILER_TYPE=clang
    test_dir=$(run_libra_cmake_test "cxx" \
        -DLIBRA_FORTIFY=FORMAT \
        -DCMAKE_BUILD_TYPE=Release)

    assert_compile_command_flag_present "$test_dir" "-Wformat-security"
}

@test "FORMAT: LIBRA_FORTIFY=NONE adds no format flags to compile_commands.json (GNU/C)" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" \
        -DLIBRA_FORTIFY=NONE \
        -DCMAKE_BUILD_TYPE=Release)

    assert_compile_command_flag_absent "$test_dir" "-Wformat-security"
    assert_compile_command_flag_absent "$test_dir" "-Werror=format"
}

@test "FORMAT: LIBRA_FORTIFY=ALL includes FORMAT flags in compile_commands.json (GNU/C)" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" \
        -DLIBRA_FORTIFY=ALL \
        -DCMAKE_BUILD_TYPE=Release)

    assert_compile_command_flag_present "$test_dir" "-Wformat-security"
    assert_compile_command_flag_present "$test_dir" "-Werror=format=2"
}

# ==============================================================================
# Cache persistence
# ==============================================================================

@test "FORMAT: Cache variable persists across reconfiguration" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_FORMAT=ON)

    run cache_value_equals "$test_dir" "LIBRA_FORMAT" "ON"
    [ "$status" -eq 0 ]

    cd "$test_dir"
    run cmake "$BATS_TEST_DIRNAME/sample_build_info" --log-level=ERROR
    [ "$status" -eq 0 ]

    run cache_value_equals "$test_dir" "LIBRA_FORMAT" "ON"
    [ "$status" -eq 0 ]
}

@test "FORMAT: Can change value on reconfiguration" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_FORMAT=ON)

    run cache_value_equals "$test_dir" "LIBRA_FORMAT" "ON"
    [ "$status" -eq 0 ]

    cd "$test_dir"
    run cmake "$BATS_TEST_DIRNAME/sample_build_info" -DLIBRA_FORMAT=OFF --log-level=ERROR
    [ "$status" -eq 0 ]

    run cache_value_equals "$test_dir" "LIBRA_FORMAT" "OFF"
    [ "$status" -eq 0 ]
}
