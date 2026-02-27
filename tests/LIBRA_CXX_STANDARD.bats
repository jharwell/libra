#!/usr/bin/env bats
#
# BATS tests for LIBRA_CXX_STANDARD
#
# LIBRA_CXX_STANDARD controls the C++ language standard:
#   - Can be set to 11, 14, 17, 20, 23, etc.
#   - CMAKE_CXX_STANDARD takes precedence over LIBRA_CXX_STANDARD
#   - LIBRA_GLOBAL_CXX_STANDARD=YES prevents per-target override
#

load test_helpers

setup() {
    setup_libra_test
}


@test "CXX_STANDARD: LIBRA_CXX_STANDARD=11 sets C++11" {
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_CXX_STANDARD=11)

    assert_standard_equals "$test_dir" "cxx" "11"
}

@test "CXX_STANDARD: LIBRA_CXX_STANDARD=14 sets C++14" {
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_CXX_STANDARD=14)

    assert_standard_equals "$test_dir" "cxx" "14"
}

@test "CXX_STANDARD: LIBRA_CXX_STANDARD=17 sets C++17" {
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_CXX_STANDARD=17)

    assert_standard_equals "$test_dir" "cxx" "17"
}

@test "CXX_STANDARD: LIBRA_CXX_STANDARD=20 sets C++20" {
    # GCC <= 9 doesn't know c++20
    skip_if_gcc_older_than 9
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_CXX_STANDARD=20)

    assert_standard_equals "$test_dir" "cxx" "20"
}

@test "CXX_STANDARD: LIBRA_CXX_STANDARD=23 sets C++23" {
    # GCC <= 9 doesn't know c++23
    skip_if_gcc_older_than 9
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_CXX_STANDARD=23)

    assert_standard_equals "$test_dir" "cxx" "23"
}

@test "CXX_STANDARD: CMAKE_CXX_STANDARD overrides LIBRA_CXX_STANDARD" {
    test_dir=$(run_libra_cmake_test "cxx" \
        -DLIBRA_CXX_STANDARD=14 \
        -DCMAKE_CXX_STANDARD=20)

    # CMAKE_CXX_STANDARD should win
    assert_standard_equals "$test_dir" "cxx" "20"
}


@test "CXX_STANDARD: Default standard is set" {
    # When neither CMAKE_CXX_STANDARD nor LIBRA_CXX_STANDARD is specified,
    # LIBRA should set a default
    test_dir=$(run_libra_cmake_test "cxx")

    # Get whatever standard was set (should be something)
    std=$(get_standard "$test_dir" "cxx")

    # Should have SOME standard set
    [ -n "$std" ]
}

@test "CXX_STANDARD: Works with GNU compiler" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_CXX_STANDARD=17)

    assert_standard_equals "$test_dir" "cxx" "17"
}

@test "CXX_STANDARD: Works with Clang compiler" {
    COMPILER_TYPE=clang
    skip_if_compiler_missing "clang" "cxx"

    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_CXX_STANDARD=20)

    assert_standard_equals "$test_dir" "cxx" "20"
}

@test "CXX_STANDARD: Works with Intel compiler" {
    COMPILER_TYPE=intel
    skip_if_compiler_missing "intel" "cxx"

    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_CXX_STANDARD=17)

    assert_standard_equals "$test_dir" "cxx" "17"
}

@test "CXX_STANDARD: Cache variable persists across reconfiguration" {
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_CXX_STANDARD=17)

    run cache_value_equals "$test_dir" "LIBRA_CXX_STANDARD" "17"
    [ "$status" -eq 0 ]

    cd "$test_dir"
    run cmake "$BATS_TEST_DIRNAME/sample_build_info" --log-level=ERROR
    [ "$status" -eq 0 ]

    run cache_value_equals "$test_dir" "LIBRA_CXX_STANDARD" "17"
    [ "$status" -eq 0 ]
}

@test "CXX_STANDARD: Can change value on reconfiguration" {
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_CXX_STANDARD=17)

    run cache_value_equals "$test_dir" "LIBRA_CXX_STANDARD" "17"
    [ "$status" -eq 0 ]

    cd "$test_dir"
    run cmake "$BATS_TEST_DIRNAME/sample_build_info" -DLIBRA_CXX_STANDARD=14 --log-level=ERROR
    [ "$status" -eq 0 ]

    run cache_value_equals "$test_dir" "LIBRA_CXX_STANDARD" "14"
    [ "$status" -eq 0 ]
}

@test "CXX_STANDARD: -std= flag present in compile_commands.json" {
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_CXX_STANDARD=17)

    [ -f "$test_dir/compile_commands.json" ]
    grep -q -- '-std=gnu++17' "$test_dir/compile_commands.json"
}

@test "CXX_STANDARD: -std= flag present after reconfiguration (no --fresh)" {
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_CXX_STANDARD=17)

    grep -q -- '-std=gnu++17' "$test_dir/compile_commands.json"

    # Reconfigure WITHOUT --fresh
    run reconfigure_libra_test "$test_dir" "cxx"
    [ "$status" -eq 0 ]

    # Flag must still be present
    grep -q -- '-std=gnu++17' "$test_dir/compile_commands.json"
}

@test "CXX_STANDARD: -std= flag updates after changing standard on reconfigure" {
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_CXX_STANDARD=17)

    grep -q -- '-std=gnu++17' "$test_dir/compile_commands.json"

    # Reconfigure with a different standard
    run reconfigure_libra_test "$test_dir" "cxx" -DLIBRA_CXX_STANDARD=14
    [ "$status" -eq 0 ]

    # Old flag must be gone, new flag must be present
    ! grep -q -- '-std=gnu++17' "$test_dir/compile_commands.json"
    grep -q -- '-std=gnu++14' "$test_dir/compile_commands.json"
}

@test "CXX_STANDARD: build succeeds after reconfiguration (no --fresh)" {
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_CXX_STANDARD=17)

    # Reconfigure without --fresh
    run reconfigure_libra_test "$test_dir" "cxx"
    [ "$status" -eq 0 ]

    # Build must succeed
    cd "$test_dir"
    run make
    [ "$status" -eq 0 ]
}

@test "CXX_STANDARD: build succeeds after changing standard on reconfigure" {
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_CXX_STANDARD=17)

    # Reconfigure with a different standard
    run reconfigure_libra_test "$test_dir" "cxx" -DLIBRA_CXX_STANDARD=20
    [ "$status" -eq 0 ]

    # Build must succeed with new standard
    cd "$test_dir"
    run make
    [ "$status" -eq 0 ]
}

@test "CXX_STANDARD: multiple reconfigures preserve -std= flag" {
    test_dir=$(run_libra_cmake_test "cxx" -DLIBRA_CXX_STANDARD=17)

    grep -q -- '-std=gnu++17' "$test_dir/compile_commands.json"

    # Reconfigure 3 times without --fresh
    for i in 1 2 3; do
        run reconfigure_libra_test "$test_dir" "cxx"
        [ "$status" -eq 0 ]
    done

    # Flag must still be present after repeated reconfigures
    grep -q -- '-std=gnu++17' "$test_dir/compile_commands.json"
}

@test "CXX_STANDARD: CMAKE_CXX_STANDARD override persists in compile_commands after reconfigure" {
    test_dir=$(run_libra_cmake_test "cxx" \
        -DLIBRA_CXX_STANDARD=14 \
        -DCMAKE_CXX_STANDARD=17)

    grep -q -- '-std=gnu++17' "$test_dir/compile_commands.json"

    # Reconfigure without --fresh (CMAKE_CXX_STANDARD stays in cache)
    run reconfigure_libra_test "$test_dir" "cxx"
    [ "$status" -eq 0 ]

    # The override standard should still be in compile commands
    grep -q -- '-std=gnu++17' "$test_dir/compile_commands.json"
}
