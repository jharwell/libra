#!/usr/bin/env bats
#
# BATS tests for global clibra flags and preset resolution.
#
# Coverage:
#   - Basic sanity (--help, --version)
#   - Project root and preset file validation
#   - Preset resolution priority order including per-command defaults
#   - --dry-run: prints commands, no side effects, works for all subcommands
#   - --log: annotates cmake commands at debug level
#   - --color: ANSI code suppression and forcing
#

load test_helpers

setup() {
    setup_cli_test
}

# ==============================================================================
# Sanity
# ==============================================================================

@test "GLOBAL: clibra --help exits 0" {
    run_clibra --help
    assert_clibra_success
}

@test "GLOBAL: clibra --version exits 0" {
    run_clibra --version
    assert_clibra_success
}

@test "GLOBAL: clibra --version prints a version string" {
    run_clibra --version
    assert_clibra_success
    assert_output_contains "clibra"
}

@test "GLOBAL: bare clibra with no subcommand prints help and exits non-zero" {
    run_clibra
    assert_clibra_failure
}

# ==============================================================================
# Error handling — missing project structure
# ==============================================================================

@test "GLOBAL: fails with error when run outside a project root" {
    cd /tmp
    run_clibra --dry-run build --preset debug
    assert_clibra_failure
    assert_output_contains "CMakeLists.txt"
}

@test "GLOBAL: error message when outside project root mentions project root" {
    cd /tmp
    run_clibra --dry-run build --preset debug
    assert_clibra_failure
    assert_output_contains "project root"
}

@test "GLOBAL: fails with error when no preset files exist and no --preset given" {
    rm -f CMakePresets.json CMakeUserPresets.json
    run_clibra build --dry-run
    assert_clibra_failure
    assert_output_contains "CMakePresets.json"
}

@test "GLOBAL: succeeds with --preset even when no preset files exist" {
    rm -f CMakePresets.json CMakeUserPresets.json
    run_clibra --dry-run build --preset debug
    assert_clibra_success
}

# ==============================================================================
# Preset resolution — priority order
# ==============================================================================

@test "PRESET: --preset flag takes priority over all other sources" {
    assert_dry_run_contains "--preset release" build --preset release
}

@test "PRESET: vendor field in CMakeUserPresets.json used when --preset absent" {
    cat > CMakeUserPresets.json << 'EOF2'
{
  "version": 6,
  "vendor": { "libra": { "defaultConfigurePreset": "release" } }
}
EOF2
    assert_dry_run_contains "--preset release" build
}

@test "PRESET: CMakeUserPresets.json vendor preset takes priority over CMakePresets.json" {
    cat > CMakeUserPresets.json << 'EOF2'
{
  "version": 6,
  "vendor": { "libra": { "defaultConfigurePreset": "release" } }
}
EOF2
    assert_dry_run_contains "--preset release" build
}

@test "PRESET: CMakePresets.json vendor field used when CMakeUserPresets.json has no vendor entry" {
    cat > CMakeUserPresets.json << 'EOF2'
{ "version": 6 }
EOF2
    python3 -c "
import json
with open('CMakePresets.json') as f: d = json.load(f)
d['vendor'] = {'libra': {'defaultConfigurePreset': 'debug'}}
print(json.dumps(d))
" > CMakePresets.json.tmp && mv CMakePresets.json.tmp CMakePresets.json
    assert_dry_run_contains "--preset debug" build
}

@test "PRESET: fails with actionable error when no preset can be resolved for build" {
    python3 -c "
import json
with open('CMakePresets.json') as f: d = json.load(f)
d.pop('vendor', None)
print(json.dumps(d))
" > CMakePresets.json.tmp && mv CMakePresets.json.tmp CMakePresets.json
    rm -f CMakeUserPresets.json
    run_clibra build --dry-run
    assert_clibra_failure
    assert_output_contains "no preset"
}

@test "PRESET: error message suggests --preset as fix option" {
    python3 -c "
import json
with open('CMakePresets.json') as f: d = json.load(f)
d.pop('vendor', None)
print(json.dumps(d))
" > CMakePresets.json.tmp && mv CMakePresets.json.tmp CMakePresets.json
    rm -f CMakeUserPresets.json
    run_clibra build --dry-run
    assert_clibra_failure
    assert_output_contains "--preset"
}

@test "PRESET: error message suggests CMakeUserPresets.json as fix option" {
    python3 -c "
import json
with open('CMakePresets.json') as f: d = json.load(f)
d.pop('vendor', None)
print(json.dumps(d))
" > CMakePresets.json.tmp && mv CMakePresets.json.tmp CMakePresets.json
    rm -f CMakeUserPresets.json
    run_clibra build --dry-run
    assert_clibra_failure
    assert_output_contains "CMakeUserPresets.json"
}

@test "PRESET: ci uses per-command default 'ci' when no vendor field" {
    python3 -c "
import json
with open('CMakePresets.json') as f: d = json.load(f)
d.pop('vendor', None)
print(json.dumps(d))
" > CMakePresets.json.tmp && mv CMakePresets.json.tmp CMakePresets.json
    rm -f CMakeUserPresets.json
    assert_dry_run_contains "--preset ci" ci
}

@test "PRESET: analyze uses per-command default 'analyze' when no vendor field" {
    python3 -c "
import json
with open('CMakePresets.json') as f: d = json.load(f)
d.pop('vendor', None)
print(json.dumps(d))
" > CMakePresets.json.tmp && mv CMakePresets.json.tmp CMakePresets.json
    rm -f CMakeUserPresets.json
    assert_dry_run_contains "--preset analyze" analyze
}

@test "PRESET: coverage uses per-command default 'coverage' when no vendor field" {
    python3 -c "
import json
with open('CMakePresets.json') as f: d = json.load(f)
d.pop('vendor', None)
print(json.dumps(d))
" > CMakePresets.json.tmp && mv CMakePresets.json.tmp CMakePresets.json
    rm -f CMakeUserPresets.json
    assert_dry_run_contains "--preset coverage" coverage --html
}

@test "PRESET: docs uses per-command default 'docs' when no vendor field" {
    python3 -c "
import json
with open('CMakePresets.json') as f: d = json.load(f)
d.pop('vendor', None)
print(json.dumps(d))
" > CMakePresets.json.tmp && mv CMakePresets.json.tmp CMakePresets.json
    rm -f CMakeUserPresets.json
    assert_dry_run_contains "--preset docs" docs
}

@test "PRESET: test has no per-command default — fails without --preset" {
    python3 -c "
import json
with open('CMakePresets.json') as f: d = json.load(f)
d.pop('vendor', None)
print(json.dumps(d))
" > CMakePresets.json.tmp && mv CMakePresets.json.tmp CMakePresets.json
    rm -f CMakeUserPresets.json
    run_clibra test --dry-run
    assert_clibra_failure
    assert_output_contains "no preset"
}

@test "PRESET: install has no per-command default — fails without --preset" {
    python3 -c "
import json
with open('CMakePresets.json') as f: d = json.load(f)
d.pop('vendor', None)
print(json.dumps(d))
" > CMakePresets.json.tmp && mv CMakePresets.json.tmp CMakePresets.json
    rm -f CMakeUserPresets.json
    run_clibra install --dry-run
    assert_clibra_failure
    assert_output_contains "no preset"
}

# ==============================================================================
# --dry-run
# ==============================================================================

@test "DRY_RUN: exits 0" {
    run_clibra --dry-run build --preset debug
    assert_clibra_success
}

@test "DRY_RUN: prints cmake command" {
    run_clibra --dry-run build --preset debug
    assert_output_contains "cmake"
}

@test "DRY_RUN: does not create build directory" {
    run_clibra --dry-run build --preset debug
    assert_clibra_success
    assert_build_dir_absent "debug"
}

@test "DRY_RUN: works with build subcommand" {
    run_clibra --dry-run --preset debug build
    assert_clibra_success
}

@test "DRY_RUN: works with clean subcommand" {
    run_clibra --dry-run --preset debug clean
    assert_clibra_success
}

@test "DRY_RUN: works with analyze subcommand" {
    run_clibra --dry-run --preset debug analyze
    assert_clibra_success
}

@test "DRY_RUN: works with docs subcommand" {
    run_clibra --dry-run --preset debug docs
    assert_clibra_success
}

@test "DRY_RUN: works with ci subcommand" {
    run_clibra --dry-run --preset debug ci
    assert_clibra_success
}

@test "DRY_RUN: works with coverage subcommand" {
    run_clibra --dry-run --preset debug coverage --html
    assert_clibra_success
}

@test "DRY_RUN: works with test subcommand" {
    run_clibra --dry-run --preset debug test
    assert_clibra_success
}

@test "DRY_RUN: works with info subcommand" {
    run_clibra --dry-run --preset debug info
    assert_clibra_success
}

# ==============================================================================
# --log
# ==============================================================================

@test "LOG: --log=debug prints cmake commands with + prefix" {
    run_clibra --log=debug --dry-run build --preset debug
    assert_clibra_success
    assert_output_contains "+ cmake"
}

@test "LOG: --log=debug prints preset resolution source" {
    run_clibra --log=debug --dry-run build --preset debug
    assert_clibra_success
    assert_output_contains "resolved"
}

# ==============================================================================
# --color
# ==============================================================================

@test "COLOR: --color=never produces no ANSI escape codes" {
    run_clibra --color=never --dry-run build --preset debug
    assert_clibra_success
    if echo "$output" | grep -qP '\x1b\['; then
        echo "Output contained ANSI codes with --color=never" >&3
        false
    fi
}

@test "COLOR: --color=always exits 0" {
    run_clibra --color=always --dry-run build --preset debug
    assert_clibra_success
}

@test "COLOR: --color=always produces ANSI escape codes in info output" {
    skip_if_compiler_missing gnu c
    run_clibra build --preset debug $CLI_CMAKE_DEFINES
    assert_clibra_success
    run "$CLIBRA_BIN" --color=always info --preset debug
    assert_clibra_success
    # info output uses colored crate for bold/green; verify ANSI codes present
    echo "$output" | grep -qP '\x1b\['
}
