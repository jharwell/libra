#!/usr/bin/env bats
#
# BATS tests for LIBRA_C_STANDARD
#
# LIBRA_C_STANDARD controls the C language standard:
#   - Can be set to 99, 11, 17, 23, etc.
#   - CMAKE_C_STANDARD takes precedence over LIBRA_C_STANDARD
#

load test_helpers

setup() {
    setup_libra_test
}

@test "C_STANDARD: LIBRA_C_STANDARD=99 sets C99" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_C_STANDARD=99)

    assert_standard_equals "$test_dir" "c" "99"
}

@test "C_STANDARD: LIBRA_C_STANDARD=11 sets C11" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_C_STANDARD=11)

    assert_standard_equals "$test_dir" "c" "11"
}

@test "C_STANDARD: LIBRA_C_STANDARD=17 sets C17" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_C_STANDARD=17)

    assert_standard_equals "$test_dir" "c" "17"
}

@test "C_STANDARD: LIBRA_C_STANDARD=23 sets C23" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_C_STANDARD=23)

    assert_standard_equals "$test_dir" "c" "23"
}

@test "C_STANDARD: CMAKE_C_STANDARD overrides LIBRA_C_STANDARD" {
    test_dir=$(run_libra_cmake_test "c" \
        -DLIBRA_C_STANDARD=11 \
        -DCMAKE_C_STANDARD=17)

    # CMAKE_C_STANDARD should win
    assert_standard_equals "$test_dir" "c" "17"
}

@test "C_STANDARD: Default standard is set" {
    # When neither CMAKE_C_STANDARD nor LIBRA_C_STANDARD is specified,
    # LIBRA should set a default
    test_dir=$(run_libra_cmake_test "c")

    # Get whatever standard was set (should be something)
    std=$(get_standard "$test_dir" "c")

    # Should have SOME standard set
    [ -n "$std" ]
}

@test "C_STANDARD: Works with GNU compiler" {
    COMPILER_TYPE=gnu
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_C_STANDARD=11)

    assert_standard_equals "$test_dir" "c" "11"
}

@test "C_STANDARD: Works with Clang compiler" {
    COMPILER_TYPE=clang
    skip_if_compiler_missing "clang" "c"
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_C_STANDARD=17)

    assert_standard_equals "$test_dir" "c" "17"
}

@test "C_STANDARD: Works with Intel compiler" {
    COMPILER_TYPE=intel
    skip_if_compiler_missing "intel" "c"

    test_dir=$(run_libra_cmake_test "c" -DLIBRA_C_STANDARD=11)

    assert_standard_equals "$test_dir" "c" "11"
}

@test "C_STANDARD: Cache variable persists across reconfiguration" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_C_STANDARD=11)

    run cache_value_equals "$test_dir" "LIBRA_C_STANDARD" "11"
    [ "$status" -eq 0 ]

    cd "$test_dir"
    run cmake "$BATS_TEST_DIRNAME/sample_build_info" --log-level=ERROR
    [ "$status" -eq 0 ]

    run cache_value_equals "$test_dir" "LIBRA_C_STANDARD" "11"
    [ "$status" -eq 0 ]
}

@test "C_STANDARD: Can change value on reconfiguration" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_C_STANDARD=11)

    run cache_value_equals "$test_dir" "LIBRA_C_STANDARD" "11"
    [ "$status" -eq 0 ]

    cd "$test_dir"
    run cmake "$BATS_TEST_DIRNAME/sample_build_info" -DLIBRA_C_STANDARD=99 --log-level=ERROR
    [ "$status" -eq 0 ]

    run cache_value_equals "$test_dir" "LIBRA_C_STANDARD" "99"
    [ "$status" -eq 0 ]
}

@test "C_STANDARD: -std= flag present in compile_commands.json" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_C_STANDARD=11)

    [ -f "$test_dir/compile_commands.json" ]
    grep -q -- '-std=gnu11' "$test_dir/compile_commands.json"
}

@test "C_STANDARD: -std= flag present after reconfiguration (no --fresh)" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_C_STANDARD=11)

    grep -q -- '-std=gnu11' "$test_dir/compile_commands.json"

    # Reconfigure WITHOUT --fresh
    run reconfigure_libra_test "$test_dir" "c"
    [ "$status" -eq 0 ]

    # Flag must still be present
    grep -q -- '-std=gnu11' "$test_dir/compile_commands.json"
}

@test "C_STANDARD: -std= flag updates after changing standard on reconfigure" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_C_STANDARD=11)

    grep -q -- '-std=gnu11' "$test_dir/compile_commands.json"

    # Reconfigure with a different standard
    run reconfigure_libra_test "$test_dir" "c" -DLIBRA_C_STANDARD=17
    [ "$status" -eq 0 ]

    # Old flag must be gone, new flag must be present
    ! grep -q -- '-std=gnu11' "$test_dir/compile_commands.json"
    grep -q -- '-std=gnu17' "$test_dir/compile_commands.json"
}

@test "C_STANDARD: build succeeds after reconfiguration (no --fresh)" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_C_STANDARD=11)

    # Reconfigure without --fresh
    run reconfigure_libra_test "$test_dir" "c"
    [ "$status" -eq 0 ]

    # Build must succeed
    cd "$test_dir"
    run make
    [ "$status" -eq 0 ]
}

@test "C_STANDARD: build succeeds after changing standard on reconfigure" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_C_STANDARD=11)

    # Reconfigure with a different standard
    run reconfigure_libra_test "$test_dir" "c" -DLIBRA_C_STANDARD=17
    [ "$status" -eq 0 ]

    # Build must succeed with new standard
    cd "$test_dir"
    run make
    [ "$status" -eq 0 ]
}

@test "C_STANDARD: multiple reconfigures preserve -std= flag" {
    test_dir=$(run_libra_cmake_test "c" -DLIBRA_C_STANDARD=11)

    grep -q -- '-std=gnu11' "$test_dir/compile_commands.json"

    # Reconfigure 3 times without --fresh
    for i in 1 2 3; do
        run reconfigure_libra_test "$test_dir" "c"
        [ "$status" -eq 0 ]
    done

    # Flag must still be present after repeated reconfigures
    grep -q -- '-std=gnu11' "$test_dir/compile_commands.json"
}

@test "C_STANDARD: CMAKE_C_STANDARD override persists in compile_commands after reconfigure" {
    test_dir=$(run_libra_cmake_test "c" \
        -DLIBRA_C_STANDARD=99 \
        -DCMAKE_C_STANDARD=17)

    grep -q -- '-std=gnu17' "$test_dir/compile_commands.json"

    # Reconfigure without --fresh (CMAKE_C_STANDARD stays in cache)
    run reconfigure_libra_test "$test_dir" "c"
    [ "$status" -eq 0 ]

    # The override standard should still be in compile commands
    grep -q -- '-std=gnu17' "$test_dir/compile_commands.json"
}
