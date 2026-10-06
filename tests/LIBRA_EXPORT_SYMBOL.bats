#!/usr/bin/env bats
#
# BATS tests for LIBRA_EXPORT_SYMBOL
#
# libra_add_library() defines LIBRA_EXPORT_SYMBOL (default
# <PROJECT_NAME>_EXPORTS, uppercased) when compiling SHARED or MODULE
# libraries, so one export macro works across a project's main library and its
# components.
#
# sample_export_symbol builds a main library and a component library with
# hidden visibility (LIBRA_OPT_INLINE=ON), each with one function marked with
# an export macro that tests for the symbol. A library exports its function
# only if the symbol was defined when it was compiled.
#

load test_helpers

setup() {
    setup_libra_test
}

# build_sample [CMAKE_OPTIONS...]
#
# Configure and build sample_export_symbol with LIBRA_OPT_INLINE=ON. Prints the
# build directory.
build_sample() {
    local test_dir
    test_dir=$(run_libra_cmake_sample_test "sample_export_symbol" \
        -DLIBRA_OPT_INLINE=ON "$@") || return 1
    if ! cmake --build "$test_dir" > "$test_dir/build.log" 2>&1; then
        cat "$test_dir/build.log" >&3
        return 1
    fi
    echo "$test_dir"
}

# exported TEST_DIR LIBRARY_GLOB
#
# Print the symbols the shared library matching LIBRARY_GLOB exports.
exported() {
    local lib
    lib=$(find "$1" -name "$2" -type f | head -n 1)
    [ -n "$lib" ] || { echo "no library matching $2 in $1" >&2; return 1; }
    nm -D --defined-only "$lib" | awk '{print $3}'
}

@test "EXPORT_SYMBOL: SHARED main library exports its API" {
    test_dir=$(build_sample)
    run exported "$test_dir" "libsample_export_symbol.so*"
    [ "$status" -eq 0 ]
    [[ "$output" == *sample_core_api* ]]
}

@test "EXPORT_SYMBOL: SHARED component library exports its API" {
    test_dir=$(build_sample)
    run exported "$test_dir" "libsample_export_symbol_net.so*"
    [ "$status" -eq 0 ]
    [[ "$output" == *sample_net_api* ]]
}

@test "EXPORT_SYMBOL: CMake's <target>_EXPORTS is still defined" {
    # core.cpp fails to compile if sample_export_symbol_EXPORTS is missing.
    test_dir=$(build_sample)
    [ -n "$test_dir" ]
}

@test "EXPORT_SYMBOL: not defined for STATIC libraries" {
    # core.cpp fails to compile if the symbol is defined.
    test_dir=$(build_sample -DLIBRA_TEST_LIBTYPE=STATIC)
    [ -n "$test_dir" ]
}

@test "EXPORT_SYMBOL: can be renamed" {
    test_dir=$(build_sample -DLIBRA_TEST_EXPORT_SYMBOL=MY_API_EXPORTS \
        -DLIBRA_TEST_API_SYMBOL=MY_API_EXPORTS)
    run exported "$test_dir" "libsample_export_symbol_net.so*"
    [ "$status" -eq 0 ]
    [[ "$output" == *sample_net_api* ]]
}

@test "EXPORT_SYMBOL: set to empty defines nothing" {
    # Without the symbol, hidden visibility hides every function.
    test_dir=$(build_sample "-DLIBRA_TEST_EXPORT_SYMBOL=")
    run exported "$test_dir" "libsample_export_symbol.so*"
    [ "$status" -eq 0 ]
    [[ "$output" != *sample_core_api* ]]
}
