#!/usr/bin/env bats
#
# BATS tests for `clibra preset`.
#
# Subcommands: list, show, default.
#   list    -> shells out to `cmake --list-presets=all`
#   show    -> resolves a preset and prints its cache variables
#   default -> writes vendor/libra/defaultConfigurePreset into
#              CMakeUserPresets.json (per-developer setting), creating a
#              stub file if none exists.
#
# `default` is pure JSON manipulation and needs no compiler. `list`/`show`
# invoke cmake but not a compiler, so they run without skip guards.
#

load test_helpers

setup() {
    setup_cli_test
}

# Skip a test unless jq is available (used for JSON assertions).
require_jq() {
    command -v jq >/dev/null 2>&1 || skip "jq not installed"
}

# Read vendor/libra/defaultConfigurePreset out of CMakeUserPresets.json.
default_preset_value() {
    jq -r '.vendor.libra.defaultConfigurePreset' CMakeUserPresets.json
}

# ==============================================================================
# list
# ==============================================================================

@test "PRESET: list succeeds" {
    run_clibra preset list
    assert_clibra_success
}

@test "PRESET: list enumerates known presets" {
    run_clibra preset list
    assert_clibra_success
    assert_output_contains "debug"
    assert_output_contains "release"
}

# ==============================================================================
# show
# ==============================================================================

@test "PRESET: show succeeds for an explicit preset" {
    run_clibra --preset debug preset show
    assert_clibra_success
}

@test "PRESET: show prints the resolved preset banner" {
    run_clibra --preset debug preset show
    assert_clibra_success
    assert_output_contains "Resolved preset"
    assert_output_contains "debug"
}

@test "PRESET: show fails for a non-existent preset" {
    run_clibra --preset no_such_preset_xyzzy preset show
    assert_clibra_failure
}

# ==============================================================================
# default: argument handling
# ==============================================================================

@test "PRESET: default without --preset fails" {
    run_clibra preset default
    assert_clibra_failure
}

@test "PRESET: default without --preset reports --preset is required" {
    run_clibra preset default
    assert_clibra_failure
    assert_output_contains "--preset is required"
}

@test "PRESET: default reports the preset it set" {
    run_clibra --preset debug preset default
    assert_clibra_success
    assert_output_contains "debug"
}

# ==============================================================================
# default: stub creation when CMakeUserPresets.json is absent
# ==============================================================================

@test "PRESET: default creates CMakeUserPresets.json when absent" {
    rm -f CMakeUserPresets.json
    run_clibra --preset debug preset default
    assert_clibra_success
    [ -f CMakeUserPresets.json ]
}

@test "PRESET: default warns when creating the stub file" {
    rm -f CMakeUserPresets.json
    run_clibra --preset debug preset default
    assert_clibra_success
    assert_output_contains "creating stub"
}

@test "PRESET: created stub carries a version field" {
    require_jq
    rm -f CMakeUserPresets.json
    run_clibra --preset debug preset default
    assert_clibra_success
    run jq -e 'has("version")' CMakeUserPresets.json
    [ "$status" -eq 0 ]
}

# ==============================================================================
# default: JSON contents
# ==============================================================================

@test "PRESET: default writes vendor/libra/defaultConfigurePreset" {
    require_jq
    rm -f CMakeUserPresets.json
    run_clibra --preset release preset default
    assert_clibra_success
    [ "$(default_preset_value)" = "release" ]
}

@test "PRESET: default produces valid JSON" {
    require_jq
    rm -f CMakeUserPresets.json
    run_clibra --preset debug preset default
    assert_clibra_success
    run jq -e . CMakeUserPresets.json
    [ "$status" -eq 0 ]
}

# ==============================================================================
# default: idempotency / overwrite
# ==============================================================================

@test "PRESET: default overwrites a prior default on rerun" {
    require_jq
    rm -f CMakeUserPresets.json

    run_clibra --preset debug preset default
    assert_clibra_success
    [ "$(default_preset_value)" = "debug" ]

    run_clibra --preset release preset default
    assert_clibra_success
    [ "$(default_preset_value)" = "release" ]
}

# ==============================================================================
# default: preservation of existing file content
# ==============================================================================

@test "PRESET: default preserves unrelated top-level keys" {
    require_jq
    cat > CMakeUserPresets.json << 'EOF'
{
    "version": 6,
    "configurePresets": [
        { "name": "custom", "binaryDir": "build/custom" }
    ]
}
EOF
    run_clibra --preset debug preset default
    assert_clibra_success

    # Unrelated key survives...
    run jq -e '.configurePresets[0].name == "custom"' CMakeUserPresets.json
    [ "$status" -eq 0 ]
    # ...and the default was still written.
    [ "$(default_preset_value)" = "debug" ]
}

@test "PRESET: default preserves existing sibling keys under vendor" {
    require_jq
    cat > CMakeUserPresets.json << 'EOF'
{
    "version": 6,
    "vendor": {
        "other-tool": { "setting": true },
        "libra": { "someOtherKey": "keep-me" }
    }
}
EOF
    run_clibra --preset debug preset default
    assert_clibra_success

    run jq -e '.vendor["other-tool"].setting == true' CMakeUserPresets.json
    [ "$status" -eq 0 ]
    run jq -e '.vendor.libra.someOtherKey == "keep-me"' CMakeUserPresets.json
    [ "$status" -eq 0 ]
    [ "$(default_preset_value)" = "debug" ]
}

# ==============================================================================
# default: malformed input
# ==============================================================================

@test "PRESET: default fails on invalid JSON" {
    echo "{ this is not json" > CMakeUserPresets.json
    run_clibra --preset debug preset default
    assert_clibra_failure
    assert_output_contains "invalid JSON"
}

@test "PRESET: default fails when root is not a JSON object" {
    echo '[1, 2, 3]' > CMakeUserPresets.json
    run_clibra --preset debug preset default
    assert_clibra_failure
    assert_output_contains "root is not a JSON object"
}

@test "PRESET: default fails when vendor is not an object" {
    cat > CMakeUserPresets.json << 'EOF'
{ "version": 6, "vendor": "not-an-object" }
EOF
    run_clibra --preset debug preset default
    assert_clibra_failure
    assert_output_contains "'vendor' is not an object"
}

@test "PRESET: default fails when vendor.libra is not an object" {
    cat > CMakeUserPresets.json << 'EOF'
{ "version": 6, "vendor": { "libra": "not-an-object" } }
EOF
    run_clibra --preset debug preset default
    assert_clibra_failure
    assert_output_contains "'vendor.libra' is not an object"
}
