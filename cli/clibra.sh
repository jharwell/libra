#!/usr/bin/env bash
# libra - LIBRA build system CLI, Phase 1
# Usage: libra <command> [options] [-- <passthrough-args>]
set -euo pipefail

# ##############################################################################
# Constants
# ##############################################################################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LIBRA_VERSION=$(grep -r LIBRA_VERSION $SCRIPT_DIR/../cmake/libra/version.cmake | grep -Eo [0-9]+.[0-9]+.[0-9]+)
readonly LIBRA_DEFAULT_JOBS=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)

# ##############################################################################
# Utilities
# ##############################################################################

# Print to stderr
err() { printf '%s: error: %s\n' "libra" "$*" >&2; }

# Print to stderr and exit
die() { err "$@"; exit 1; }

# Print only when not --quiet
log() {
    [[ "${OPT_QUIET:-0}" == "1" ]] && return
    printf '%s\n' "$*"
}

# Print the command before running it (--verbose), then run it.
# Stdout/stderr pass through unchanged -- we never intercept them.
run() {
    if [[ "${OPT_VERBOSE:-0}" == "1" ]]; then
        printf '+ %s\n' "$*" >&2
    fi
    "$@"
}

usage() {
    cat <<'EOF'
Usage: libra <command> [global-options] [command-options] [-- <passthrough-args>]

Commands:
  build       Configure (if needed) and build
  test        Build (if needed) and run tests
  ci          Run the full CI workflow preset
  analyze     Run static analysis targets
  coverage    Generate a coverage report
  docs        Build documentation
  clean       Clean build artifacts
  info        Show resolved preset configuration
  doctor      Check tool availability and versions

Global options:
  --preset=<n>    CMake preset name (resolved from CMakePresets.json if absent)
  --verbose, -v   Print cmake/ctest commands before executing them
  --quiet, -q     Suppress cmake/ctest stdout; stderr always passes through
  --help, -h      Show this help
  --version       Show libra version

Run 'libra <command> --help' for command-specific options.
EOF
}

usage_build() {
    cat <<'EOF'
Usage: libra build [options] [-DVAR=VALUE ...]

Configure (if the build directory is absent) and build the project.

Options:
  --preset=<n>       CMake preset name (global default applies if absent)
  --jobs=N, -jN      Parallel job count (default: nproc)
  --target=<t>, -t   Build a specific CMake target instead of the default
  --clean            Pass --clean-first to cmake --build
  --reconfigure      Force the configure step even if the build directory exists
  --keep-going, -k   Continue building after errors (cmake --keep-going)
  --verbose, -v      Print the cmake commands before executing them
  --quiet, -q        Suppress cmake stdout; stderr always passes through

-DVAR=VALUE arguments are forwarded to the cmake configure step. They have
no effect unless --reconfigure is also given (or the build directory is absent).

Examples:
  libra build
  libra build --preset release -j8
  libra build --preset debug --target my_lib
  libra build --reconfigure -DLIBRA_TESTS=ON
EOF
}

usage_test() {
    cat <<'EOF'
Usage: libra test [options] [-DVAR=VALUE ...]

Build (if --no-build is not given) and run tests via ctest.

Options:
  --preset=<n>       CMake preset name (global default applies if absent)
  --type=<type>      Filter by test type: unit, integration, regression, all (default: all)
  --filter=<regex>   Run only tests whose name matches <regex> (ctest --tests-regex)
  --stop-on-failure  Stop at first test failure
  --parallel=N       Run N tests in parallel (default: nproc)
  --no-build         Skip the build step. Runs stale binaries if sources have
                     changed since the last build.
  --verbose, -v      Print the ctest command before executing it
  --quiet, -q        Suppress ctest stdout; stderr always passes through

-DVAR=VALUE arguments are forwarded to the cmake configure step when building.

Examples:
  libra test
  libra test --preset debug --type=unit
  libra test --filter=".*network.*" --stop-on-failure
  libra test --no-build --type=unit
  libra test -DLIBRA_TESTS=ON
EOF
}

usage_ci() {
    cat <<'EOF'
Usage: libra ci [options]

Run the CI pipeline. Uses 'cmake --workflow --preset <n>' when a matching
workflow preset exists in CMakePresets.json or CMakeUserPresets.json.
Falls back to sequencing configure, build, and test individually if not.

Options:
  --preset=<n>    CMake preset name (default: ci)
  --verbose, -v   Print the cmake command before executing it
  --quiet, -q     Suppress cmake stdout; stderr always passes through

Examples:
  libra ci
  libra ci --preset ci
EOF
}

usage_analyze() {
    cat <<'EOF'
Usage: libra analyze [options] [-DVAR=VALUE ...]

Configure (if needed) and run static analysis via the 'analyze' cmake target.
Uses the 'analyze' preset by default (which sets LIBRA_ANALYSIS=ON and
LIBRA_USE_COMPDB=YES). Override with --preset if needed.

Options:
  --preset=<n>       CMake preset name (default: analyze)
  --jobs=N, -jN      Parallel job count (default: nproc)
  --keep-going, -k   Continue after errors to see all analysis output
  --verbose, -v      Print the cmake command before executing it
  --quiet, -q        Suppress cmake stdout; stderr always passes through

-DVAR=VALUE arguments are forwarded to the cmake configure step.

Examples:
  libra analyze
  libra analyze -j4 -k
  libra analyze -DLIBRA_CPPCHECK_EXTRA_ARGS="--library=googletest"
EOF
}

usage_coverage() {
    cat <<'EOF'
Usage: libra coverage [options] [-DVAR=VALUE ...]

Configure (if needed) and generate a coverage report. Requires
LIBRA_CODE_COV=ON in the preset cache (use the 'coverage' preset).
Detects the appropriate coverage target registered by LIBRA for the
active compiler (gcovr, lcov, or llvm-cov).

Options:
  --preset=<n>    CMake preset name (global default applies if absent)
  --open          Open the HTML report in the system browser after generation
  --verbose, -v   Print the cmake command before executing it
  --quiet, -q     Suppress cmake stdout; stderr always passes through

-DVAR=VALUE arguments are forwarded to the cmake configure step.

Examples:
  libra coverage --preset coverage
  libra coverage --preset coverage --open
EOF
}

usage_docs() {
    cat <<'EOF'
Usage: libra docs [options] [-DVAR=VALUE ...]

Configure (if needed) and build documentation via the 'docs' cmake target.
Uses the 'docs' preset by default (which sets LIBRA_DOCS=ON).

Options:
  --preset=<n>    CMake preset name (default: docs)
  --verbose, -v   Print the cmake command before executing it
  --quiet, -q     Suppress cmake stdout; stderr always passes through

-DVAR=VALUE arguments are forwarded to the cmake configure step.

Examples:
  libra docs
  libra docs --preset docs
EOF
}

usage_clean() {
    cat <<'EOF'
Usage: libra clean [options]

Clean build artifacts for the active preset.

  Default: runs cmake --build --preset <n> --target clean
  --all:   removes the preset's entire build directory (rm -rf binaryDir)

Options:
  --preset=<n>    CMake preset name (global default applies if absent)
  --all           Remove the entire build directory instead of running clean target
  --verbose, -v   Print the cmake/rm command before executing it
  --quiet, -q     Suppress output

Examples:
  libra clean
  libra clean --all
  libra clean --preset release --all
EOF
}

usage_info() {
    cat <<'EOF'
Usage: libra info [options]

Show the resolved configuration for the active preset. Runs cmake in
no-op mode (-N) to read and display the cache without regenerating.

Options:
  --preset=<n>    CMake preset name (global default applies if absent)
  --verbose, -v   Print the cmake command before executing it

Examples:
  libra info
  libra info --preset release
EOF
}

usage_doctor() {
    cat <<'EOF'
Usage: libra doctor

Check tool availability for all LIBRA-supported tools. Reports required
tools and optional tools. Also validates project structure and
CMakeLists.txt and preset files exist in the current directory.

Run from the project root. Takes no options.

Examples:
  libra doctor
EOF
}

# ##############################################################################
# Project root and preset resolution
# ##############################################################################

# Die with an actionable message if the project structure is not usable.
# Called at the top of every command that invokes cmake. Not called by doctor,
# which is specifically designed to diagnose missing setup.
check_project_root() {
    if [[ ! -f CMakeLists.txt ]]; then
        die "no CMakeLists.txt found. Run libra from the project root."
    fi

    if [[ ! -f CMakePresets.json ]] && [[ ! -f CMakeUserPresets.json ]]; then
        die "no CMakePresets.json or CMakeUserPresets.json found.
       libra requires CMake presets to function. Options:
         - Create CMakePresets.json manually
         - Use 'libra init' to scaffold a full preset hierarchy  [Phase 3]"
    fi
}

# Search for a preset name without failing. Writes result to stdout or empty.
# Priority: --preset flag > CMakeUserPresets.json default > CMakePresets.json default
find_preset() {
    local preset="${OPT_PRESET:-}"
    [[ -n "$preset" ]] && { printf '%s' "$preset"; return; }

    local presets_files=("CMakeUserPresets.json" "CMakePresets.json")
    for f in "${presets_files[@]}"; do
        if [[ -f "$f" ]]; then
            local default
            default=$(grep -o '"defaultConfigurePreset"\s*:\s*"[^"]*"' "$f" \
                      | sed 's/.*:\s*"\([^"]*\)"/\1/' \
                      | head -1)
            if [[ -n "$default" ]]; then
                printf '%s' "$default"
                return
            fi
        fi
    done
    # Return empty — caller decides what to do
}

# Resolve a preset or die with an actionable error.
resolve_preset() {
    local preset
    preset=$(find_preset)
    if [[ -z "$preset" ]]; then
        die "no preset specified and no defaultConfigurePreset found.
       Options:
         - Pass --preset=<n> explicitly
         - Add defaultConfigurePreset to CMakeUserPresets.json
         - Use 'libra preset default <n>'  [Phase 3]"
    fi
    printf '%s' "$preset"
}

# Return the binaryDir for a preset by asking cmake.
# Falls back to ./build if cmake can't be queried.
preset_binary_dir() {
    local preset="$1"
    cmake --preset "$preset" -N 2>/dev/null \
        | grep -i 'Build directory' \
        | sed 's/.*: *//' \
        || printf './build'
}

# Return 0 if the preset's build directory contains a CMake cache, 1 otherwise.
build_dir_exists() {
    local preset="$1"
    local bdir
    bdir=$(preset_binary_dir "$preset")
    [[ -f "${bdir}/CMakeCache.txt" ]]
}

# ##############################################################################
# Global option parsing
# ##############################################################################
# Parsed into OPT_* variables consumed by subcommands.

OPT_PRESET=""
OPT_VERBOSE=0
OPT_QUIET=0

# Parse global flags from the front of "$@", leaving the remainder in ARGV.
# Sets COMMAND to the first non-flag argument.
parse_global_opts() {
    COMMAND=""
    ARGV=()
    PASSTHROUGH=()   # everything after --, kept separate

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --preset=*)    OPT_PRESET="${1#--preset=}" ;;
            --preset)      OPT_PRESET="${2:?--preset requires an argument}"; shift ;;
            --verbose|-v)  OPT_VERBOSE=1 ;;
            --quiet|-q)    OPT_QUIET=1 ;;
            --version)     printf 'libra %s\n' "$LIBRA_VERSION"; exit 0 ;;
            --dump-help)
                usage
                for cmd in build test ci analyze coverage docs clean info doctor; do
                    printf '\n'
                    usage_${cmd}
                done
                exit 0
                ;;
            --)
                shift
                while [[ $# -gt 0 ]]; do
                    PASSTHROUGH+=("$1")
                    shift
                done
                break
                ;;
            --help|-h)
                if [[ -z "$COMMAND" ]]; then
                    usage; exit 0
                else
                    ARGV+=("$1")
                fi
                ;;
            -*)
                if [[ -n "$COMMAND" ]]; then
                    ARGV+=("$1")
                else
                    die "unknown option '$1'. Run 'libra --help' for usage."
                fi
                ;;
            *)
                if [[ -z "$COMMAND" ]]; then
                    COMMAND="$1"
                else
                    ARGV+=("$1")
                fi
                ;;
        esac
        shift
    done
}

# Internal: configure if needed, then build. Reads OPT_PRESET.
_do_build() {
    local reconfigure="${1:-0}"; shift
    local jobs="${1:-$LIBRA_DEFAULT_JOBS}"; shift
    local clean="${1:-0}"; shift
    local target="${1:-}"; shift
    local keep_going="${1:-0}"; shift
    local configure_passthrough=("$@")

    local preset
    preset=$(resolve_preset)

    if [[ "$reconfigure" == "1" ]] || ! build_dir_exists "$preset"; then
        log "Configuring preset '$preset'..."
        run cmake --preset "$preset" "${configure_passthrough[@]}"
    fi

    local build_args=(cmake --build --preset "$preset" --parallel "$jobs")
    [[ "$clean"      == "1" ]] && build_args+=(--clean-first)
    [[ -n "$target"  ]]        && build_args+=(--target "$target")
    [[ "$keep_going" == "1" ]] && build_args+=(--keep-going)
    run "${build_args[@]}"
}

# ##############################################################################
# Commands
# ##############################################################################
cmd_build() {
    local jobs="$LIBRA_DEFAULT_JOBS"
    local clean=0
    local reconfigure=0
    local target=""
    local keep_going=0
    local configure_passthrough=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)     usage_build; exit 0 ;;
            --jobs=*)      jobs="${1#--jobs=}" ;;
            --jobs|-j)     jobs="${2:?--jobs requires an argument}"; shift ;;
            -j[0-9]*)      jobs="${1#-j}" ;;
            --clean)       clean=1 ;;
            --reconfigure) reconfigure=1 ;;
            --target=*|-t=*)  target="${1#--target=}" ;;
            --target|-t)      target="${2:?--target requires an argument}"; shift ;;
            --keep-going|-k) keep_going=1 ;;
            -D*)           configure_passthrough+=("$1") ;;
            -*)            die "build: unknown option: $1. Run 'libra build --help'." ;;
            *)             die "build: unexpected argument: $1. Use -DVAR=VALUE to pass cache variables." ;;
        esac
        shift
    done

    check_project_root
    _do_build "$reconfigure" "$jobs" "$clean" "$target" "$keep_going" "${configure_passthrough[@]}"
}

cmd_test() {
    local type="all"
    local filter=""
    local stop_on_failure=0
    local parallel="$LIBRA_DEFAULT_JOBS"
    local no_build=0
    local configure_passthrough=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)         usage_test; exit 0 ;;
            --type=*)          type="${1#--type=}" ;;
            --type)            type="${2:?--type requires an argument}"; shift ;;
            --filter=*)        filter="${1#--filter=}" ;;
            --filter)          filter="${2:?--filter requires an argument}"; shift ;;
            --stop-on-failure) stop_on_failure=1 ;;
            --parallel=*)      parallel="${1#--parallel=}" ;;
            --parallel)        parallel="${2:?--parallel requires an argument}"; shift ;;
            --no-build)        no_build=1 ;;
            -D*)               configure_passthrough+=("$1") ;;
            -*)                die "test: unknown option: $1. Run 'libra test --help'." ;;
        esac
        shift
    done

    check_project_root

    local preset
    preset=$(resolve_preset)

    if [[ "$no_build" == "0" ]]; then
        _do_build 0 "$LIBRA_DEFAULT_JOBS" 0 "all-tests" 0 "${configure_passthrough[@]}"
    fi

    # Map --type to a ctest -L label
    local label_args=()
    case "$type" in
        unit)        label_args+=(-L unit) ;;
        integration) label_args+=(-L integration) ;;
        regression)  label_args+=(-L regression) ;;
        all)         ;;
        *)           die "test: unknown type '$type': must be unit|integration|regression|all" ;;
    esac

    local ctest_args=(ctest --preset "$preset" --parallel "$parallel")
    ctest_args+=("${label_args[@]}")
    [[ -n "$filter" ]]              && ctest_args+=(--tests-regex "$filter")
    [[ "$stop_on_failure" == "1" ]] && ctest_args+=(--stop-on-failure)
    ctest_args+=("${passthrough[@]}")

    log "Testing preset '$preset'..."
    run "${ctest_args[@]}"
}

cmd_analyze() {
    local jobs="$LIBRA_DEFAULT_JOBS"
    local keep_going=0
    local configure_passthrough=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)   usage_analyze; exit 0 ;;
            --jobs=*)    jobs="${1#--jobs=}" ;;
            --jobs|-j)   jobs="${2:?--jobs requires an argument}"; shift ;;
            -j[0-9]*)    jobs="${1#-j}" ;;
            --keep-going|-k) keep_going=1 ;;
            -D*)         configure_passthrough+=("$1") ;;
            -*)          die "analyze: unknown option: $1. Run 'libra analyze --help'." ;;
            *)           die "analyze: unexpected argument: $1." ;;
        esac
        shift
    done

    check_project_root
    OPT_PRESET="${OPT_PRESET:-analyze}"

    _do_build 0 "$jobs" 0 "analyze" "$keep_going" "${configure_passthrough[@]}"
}

cmd_ci() {
    local passthrough=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h) usage_ci; exit 0 ;;
            --)        shift; passthrough+=("$@"); break ;;
            -*)        die "ci: unknown option: $1. Run 'libra ci --help'." ;;
            *)         passthrough+=("$1") ;;
        esac
        shift
    done

    check_project_root

    local preset
    preset=$(resolve_preset)

    # Prefer cmake --workflow if a workflow preset with this name exists.
    # We detect this by checking whether cmake --workflow --preset <n> --list-presets
    # (or equivalent) knows about it. The simplest proxy: grep the presets files.
    local has_workflow=0
    for f in CMakeUserPresets.json CMakePresets.json; do
        if [[ -f "$f" ]] && grep -q '"workflowPresets"' "$f" 2>/dev/null; then
            if grep -q "\"name\"[[:space:]]*:[[:space:]]*\"${preset}\"" "$f" 2>/dev/null; then
                has_workflow=1
                break
            fi
        fi
    done

    if [[ "$has_workflow" == "1" ]]; then
        log "Running workflow preset '$preset'..."
        run cmake --workflow --preset "$preset" "${passthrough[@]}"
    else
        log "No workflow preset '$preset' found; sequencing steps manually..." >&2
        log "(Consider adding a workflowPreset named '$preset' to CMakePresets.json)"
        run cmake --preset "$preset"
        run cmake --build --preset "$preset" --parallel "$LIBRA_DEFAULT_JOBS"
        run ctest --preset "$preset" "${passthrough[@]}"
    fi
}

cmd_coverage() {
    local open_report=0
    local passthrough=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h) usage_coverage; exit 0 ;;
            --open)    open_report=1 ;;
            --)        shift; passthrough+=("$@"); break ;;
            -*)        die "coverage: unknown option: $1. Run 'libra coverage --help'." ;;
            *)         passthrough+=("$1") ;;
        esac
        shift
    done

    check_project_root

    local preset
    preset=$(resolve_preset)

    # Detect which coverage target LIBRA registered for the active compiler.
    # We try targets in preference order; cmake --build will error clearly if
    # none exist, which is the right failure mode.
    local coverage_target=""
    local bdir
    bdir=$(preset_binary_dir "$preset")
    for t in gcovr-html lcov-report llvm-cov-report; do
        if cmake --build --preset "$preset" --target help 2>/dev/null \
                | grep -q "^\.\.\. ${t}$"; then
            coverage_target="$t"
            break
        fi
    done

    local build_args=(cmake --build --preset "$preset")
    [[ -n "$coverage_target" ]] && build_args+=(--target "$coverage_target")
    build_args+=("${passthrough[@]}")

    log "Generating coverage report for preset '$preset'..."
    run "${build_args[@]}"

    if [[ "$open_report" == "1" ]]; then
        local report="${bdir}/coverage/index.html"
        if [[ -f "$report" ]]; then
            case "$(uname -s)" in
                Darwin) open "$report" ;;
                Linux)  xdg-open "$report" ;;
                *)      log "Coverage report: $report" ;;
            esac
        else
            log "Coverage report not found at expected path: $report"
        fi
    fi
}

cmd_docs() {
    local configure_passthrough=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h) usage_docs; exit 0 ;;
            -D*)       configure_passthrough+=("$1") ;;
            -*)        die "docs: unknown option: $1. Run 'libra docs --help'." ;;
            *)         die "docs: unexpected argument: $1." ;;
        esac
        shift
    done

    check_project_root
    OPT_PRESET="${OPT_PRESET:-docs}"

    log "Building docs..."
    _do_build 0 "$LIBRA_DEFAULT_JOBS" 0 "docs" 0 "${configure_passthrough[@]}"
}

cmd_clean() {
    local clean_all=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h) usage_clean; exit 0 ;;
            --all)     clean_all=1 ;;
            --)        shift; break ;;
            -*)        die "clean: unknown option: $1. Run 'libra clean --help'." ;;
            *)         die "clean: unexpected argument: $1" ;;
        esac
        shift
    done

    check_project_root

    local preset
    preset=$(resolve_preset)

    if [[ "$clean_all" == "1" ]]; then
        local bdir
        bdir=$(preset_binary_dir "$preset")
        log "Removing build directory: $bdir"
        run rm -rf "$bdir"
    else
        log "Cleaning preset '$preset'..."
        run cmake --build --preset "$preset" --target clean
    fi
}

cmd_info() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h) usage_info; exit 0 ;;
            --)        shift; break ;;
            -*)        die "info: unknown option: $1. Run 'libra info --help'." ;;
            *)         die "info: unexpected argument: $1" ;;
        esac
        shift
    done

    check_project_root

    local preset
    preset=$(resolve_preset)

    log "Preset: $preset"
    # -N = no-op (list cache variables without generating)
    run cmake --preset "$preset" -N
}

cmd_doctor() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h) usage_doctor; exit 0 ;;
            -*)        die "doctor: unknown option: $1. Run 'libra doctor --help'." ;;
            *)         die "doctor: unexpected argument: $1" ;;
        esac
        shift
    done
    local ok=0
    local warn=0
    local fail=0

    check_tool() {
        local name="$1"
        local min_version="$2"   # informational only in Phase 1
        local optional="${3:-0}"

        if command -v "$name" &>/dev/null; then
            local ver
            ver=$("$name" --version 2>&1 | head -1)
            path=$(which "$name")
            printf '  ✓ %s -> %s (%s) \n' "$name" "$path" "$ver"
            (( ok++ )) || true
        else
            if [[ "$optional" == "1" ]]; then
                printf '  ⚠ %s not found (optional)\n' "$name"
                (( warn++ )) || true
            else
                printf '  ✗ %s not found\n' "$name"
                (( fail++ )) || true
            fi
        fi
    }

    printf 'Checking LIBRA environment...\n\n'

    printf 'Tools:\n'
    check_tool cmake        "3.25"
    check_tool ninja        ""     1
    check_tool make         ""     1
    check_tool gcc          "9"    1
    check_tool g++          "9"    1
    check_tool clang        "17"   1
    check_tool "clang++"    "17"   1
    check_tool icx          "2025.0"   1
    check_tool "icpx"    "2025.0"   1
    check_tool lcov         "1.14" 1
    check_tool gcovr        "5.0"  1
    check_tool cppcheck     ""     1
    check_tool clang-tidy   ""     1
    check_tool clang-format ""     1
    check_tool valgrind     ""     1
    check_tool ccache       ""     1

    printf '\nProject structure:\n'
    if [[ -f CMakeLists.txt ]]; then
        printf '  ✓ CMakeLists.txt\n'
        (( ok++ )) || true
    else
        printf '  ✗ CMakeLists.txt not found (are you in the project root?)\n'
        (( fail++ )) || true
    fi

    # CMakePresets.json is optional if CMakeUserPresets.json is present.
    # At least one must exist for any cmake command to work.
    if [[ -f CMakePresets.json ]]; then
        printf '  ✓ CMakePresets.json\n'
        (( ok++ )) || true
    elif [[ -f CMakeUserPresets.json ]]; then
        printf '  ⚠ CMakePresets.json not found (CMakeUserPresets.json present; OK for local use)\n'
        (( warn++ )) || true
    else
        printf '  ✗ CMakePresets.json not found\n'
        printf '    → create one manually or use libra init [Phase 3]\n'
        (( fail++ )) || true
    fi

    if [[ -f CMakeUserPresets.json ]]; then
        printf '  ✓ CMakeUserPresets.json\n'
        (( ok++ )) || true
    else
        printf '  ⚠ CMakeUserPresets.json not found (optional; holds local defaults)\n'
        (( warn++ )) || true
    fi


    if [[ -d src ]]; then
        printf '  ✓ src/\n'
        (( ok++ )) || true
    else
        printf '  ✗ src/ not found (are you in the project root?)\n'
        (( fail++ )) || true
    fi
    if [[ -d include/ ]]; then
        printf '  ✓ include/\n'
        (( ok++ )) || true
    else
        printf '  ✗ include/ not found (are you in the project root?)\n'
        (( fail++ )) || true
    fi
    if [[ -d tests/ ]]; then
        printf '  ✓ tests/\n'
        (( ok++ )) || true
    else
        printf '  ✗ tests/ not found (are you in the project root?)\n'
        (( fail++ )) || true
    fi
    if [[ -d docs/ ]]; then
        printf '  ✓ docs/\n'
        (( ok++ )) || true
    else
        printf '  ✗ docs/ not found (are you in the project root?)\n'
        (( fail++ )) || true
    fi
    if [[ -f docs/Doxyfile.in ]]; then
        printf '  ✓ docs/Doxyfile.in\n'
        (( ok++ )) || true
    else
        printf '  ✗ docs/Doxyfile.in not found (are you in the project root?)\n'
        (( fail++ )) || true
    fi

    printf '\n%d ok, %d warnings, %d errors\n' "$ok" "$warn" "$fail"
    [[ "$fail" -eq 0 ]]
}

# ##############################################################################
# Entry point
# ##############################################################################
main() {
    if [[ $# -eq 0 ]]; then
        usage
        exit 0
    fi

    parse_global_opts "$@"

    if [[ -z "$COMMAND" ]]; then
        usage
        exit 0
    fi

    # Rebuild $@ as: <subcommand-args> [-- <passthrough-args>]
    if [[ "${#PASSTHROUGH[@]}" -gt 0 ]]; then
        set -- "${ARGV[@]+"${ARGV[@]}"}" -- "${PASSTHROUGH[@]}"
    else
        set -- "${ARGV[@]+"${ARGV[@]}"}"
    fi

    case "$COMMAND" in
        build)    cmd_build    "$@" ;;
        test)     cmd_test     "$@" ;;
        ci)       cmd_ci       "$@" ;;
        analyze)  cmd_analyze  "$@" ;;
        coverage) cmd_coverage "$@" ;;
        docs)     cmd_docs     "$@" ;;
        clean)    cmd_clean    "$@" ;;
        info)     cmd_info     "$@" ;;
        doctor)   cmd_doctor   "$@" ;;
        *)        die "unknown command '$COMMAND'. Run 'libra --help' for usage." ;;
    esac
}

main "$@"
