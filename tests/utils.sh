#!/bin/bash
#


# Function to check if a Makefile target exists
# Usage: target_exists BUILD_DIR TARGET_NAME
mk_target_exists() {
    local build_dir="$1"
    local target_name="$2"

    if [ ! -f "$build_dir/Makefile" ]; then
        echo "ERROR: Makefile not found in $build_dir"
        return 1
    fi

    # Use make to list all targets and check if our target is there
    # This works better than grepping the Makefile directly
    cd "$build_dir"
    if make -qp 2>/dev/null | grep -q "^${target_name}:"; then
        return 0
    else
        return 1
    fi
}

# Verify that expected targets exist
# Usage: verify_targets_present BUILD_DIR
verify_mk_targets_present() {
    local build_dir="$1"
    local all_found=true

    echo "  Verifying expected targets are present..."

    for target in "${EXPECTED_MK_TARGETS[@]}"; do
        if mk_target_exists "$build_dir" "$target"; then
            echo "    ✓ Target '$target' found"
        else
            echo "    ✗ ERROR: Expected target '$target' not found"
            all_found=false
        fi
    done

    if [ "$all_found" = false ]; then
        echo "ERROR: Not all expected targets were found"
        exit 1
    fi

    echo "SUCCESS: All expected targets are present"
}

# Verify that targets do NOT exist
# Usage: verify_targets_absent BUILD_DIR
verify_mk_targets_absent() {
    local build_dir="$1"
    local none_found=true

    echo "  Verifying targets are absent..."

    for target in "${EXPECTED_MK_TARGETS[@]}"; do
        if mk_target_exists "$build_dir" "$target"; then
            echo "    ✗ ERROR: Target '$target' found but should be absent"
            none_found=false
        else
            echo "    ✓ Target '$target' correctly absent"
        fi
    done

    if [ "$none_found" = false ]; then
        echo "ERROR: Targets found"
        exit 1
    fi

    echo "SUCCESS: All targets are correctly absent"
}

# Get the expected flags for a compiler/variable combination
# Usage: get_expected_compile_flags COMPILER_TYPE THING
get_expected_compile_flags() {
    local compiler_upper=$(echo "$1" | tr '[:lower:]' '[:upper:]')
    local thing="$2"
    local var_name="${compiler_upper}_${thing}_COMPILE_FLAGS[@]"

    if [[ -n "${!var_name}" ]]; then
        echo "${!var_name}"
    else
        echo ""
    fi
}

get_expected_link_flags() {
    local compiler_upper=$(echo "$1" | tr '[:lower:]' '[:upper:]')
    local thing="$2"
    local var_name="${compiler_upper}_${thing}_LINK_FLAGS[@]"

    if [[ -n "${!var_name}" ]]; then
        echo "${!var_name}"
    else
        echo ""
    fi
}

get_expected_flags() {
    local compiler_upper=$(echo "$1" | tr '[:lower:]' '[:upper:]')
    local thing="$2"
    local var_name="${compiler_upper}_${thing}_FLAGS[@]"

    if [[ -n "${!var_name}" ]]; then
        echo "${!var_name}"
    else
        echo ""
    fi
}

# Function to test that expected flags are present in compile flags
# Usage: verify_compile_flags_present "build_dir" "flag1" "flag2" ...
verify_compile_flags_present() {
    local build_dir="$1"
    shift
    local expected_flags=("$@")

    local build_info_file="$build_dir/build_info.cpp"

    if [ ! -f "$build_info_file" ]; then
        # Try .c extension for C projects
        build_info_file="$build_dir/build_info.c"
        if [ ! -f "$build_info_file" ]; then
            echo "ERROR: Build info file not found: $build_dir/build_info.{cpp,c}"
            exit 1
        fi
    fi

    # Extract the COMPILE_FLAGS line from the generated C/C++ file
    local build_flags=$(grep 'COMPILE_FLAGS = ' "$build_info_file" | sed 's/.*COMPILE_FLAGS = "\(.*\)";/\1/')

    if [ -z "$build_flags" ]; then
        echo "ERROR: Could not extract build flags from $build_info_file"
        exit 1
    fi

    for flag in "${expected_flags[@]}"; do
        if ! echo "$build_flags" | grep -q -- "$flag"; then
            echo "ERROR: Expected flag '$flag' not found in compile flags:"
            echo "Build flags: $build_flags"
            exit 1
        fi
    done

    echo "SUCCESS: All expected flags found in build flags"
}

# Function to test that expected flags are present in link flags
# Usage: verify_link_flags_present "build_dir" "flag1" "flag2" ...
verify_link_flags_present() {
    local build_dir="$1"
    shift
    local expected_flags=("$@")

    local build_info_file="$build_dir/build_info.cpp"

    if [ ! -f "$build_info_file" ]; then
        # Try .c extension for C projects
        build_info_file="$build_dir/build_info.c"
        if [ ! -f "$build_info_file" ]; then
            echo "ERROR: Build info file not found: $build_dir/build_info.{cpp,c}"
            exit 1
        fi
    fi

    # Extract the LINK_FLAGS line from the generated C/C++ file
    local build_flags=$(grep 'LINK_FLAGS = ' "$build_info_file" | sed 's/.*LINK_FLAGS = "\(.*\)";/\1/')

    if [ -z "$build_flags" ]; then
        echo "ERROR: Could not extract link flags from $build_info_file"
        exit 1
    fi

    for flag in "${expected_flags[@]}"; do
        if ! echo "$build_flags" | grep -q -- "$flag"; then
            echo "ERROR: Expected flag '$flag' not found in link flags:"
            echo "Link flags: $build_flags"
            exit 1
        fi
    done

    echo "SUCCESS: All expected flags found in link flags"
}

# Function to verify that flags are NOT present
verify_compile_flags_absent() {
    local build_dir="$1"
    shift
    local unexpected_flags=("$@")

    local build_info_file="$build_dir/build_info.cpp"

    if [ ! -f "$build_info_file" ]; then
        # Try .c extension for C projects
        build_info_file="$build_dir/build_info.c"
        if [ ! -f "$build_info_file" ]; then
            echo "ERROR: Build info file not found: $build_dir/build_info.{cpp,c}"
            exit 1
        fi
    fi

    # Extract the COMPILE_FLAGS line from the generated C/C++ file
    local build_flags=$(grep 'COMPILE_FLAGS = ' "$build_info_file" | sed 's/.*COMPILE_FLAGS = "\(.*\)";/\1/')

    if [ -z "$build_flags" ]; then
        echo "ERROR: Could not extract build flags from $build_info_file"
        exit 1
    fi

    for flag in "${unexpected_flags[@]}"; do
        if echo "$build_flags" | grep -q -- "$flag"; then
            echo "ERROR: Unexpected flag '$flag' found in build flags:"
            echo "Build flags: $build_flags"
            exit 1
        fi
    done

    echo "SUCCESS: No unexpected flags found in build flags"
}
# Function to verify that flags are NOT present
verify_link_flags_absent() {
    local build_dir="$1"
    shift
    local unexpected_flags=("$@")

    local build_info_file="$build_dir/build_info.cpp"

    if [ ! -f "$build_info_file" ]; then
        # Try .c extension for C projects
        build_info_file="$build_dir/build_info.c"
        if [ ! -f "$build_info_file" ]; then
            echo "ERROR: Build info file not found: $build_dir/build_info.{cpp,c}"
            exit 1
        fi
    fi

    # Extract the LINK_FLAGS line from the generated C/C++ file
    local build_flags=$(grep 'LINK_FLAGS = ' "$build_info_file" | sed 's/.*LINK_FLAGS = "\(.*\)";/\1/')

    if [ -z "$build_flags" ]; then
        echo "ERROR: Could not extract link flags from $build_info_file"
        exit 1
    fi

    for flag in "${unexpected_flags[@]}"; do
        if echo "$build_flags" | grep -q -- "$flag"; then
            echo "ERROR: Unexpected flag '$flag' found in build flags:"
            echo "Link flags: $build_flags"
            exit 1
        fi
    done

    echo "SUCCESS: No unexpected flags found in Link flags"
}
