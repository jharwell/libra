#!/usr/bin/env bats
#
# BATS smoke tests for LIBRA's CMake versioning interface:
#
#   - libra_extract_version()  -> LIBRA_PROJECT_VERSION{,_NUMERIC,_PRERELEASE}
#   - libra_resolve_self_version() (via include(libra/project)) -> LIBRA_VERSION
#
# Unlike most LIBRA_*.bats tests, these can't configure sample_build_info in
# place: its version would come from LIBRA's own git history, which changes with
# every commit. Instead each test copies sample_version/ into its temp dir and
# builds exactly the git history it needs around it. GIT_CEILING_DIRECTORIES
# stops git from walking up out of the temp dir, so "no repository" really
# means no repository.
#
# LIBRA_VERSION is checked against what the active LIBRA_CONSUME_MODE should
# produce, so this file is meaningful under every suite in suites/.
#

load test_helpers

setup() {
    setup_libra_test

    export VERSION_SRC="$BATS_TEST_TMPDIR/sample_version"
    export VERSION_BUILD="$BATS_TEST_TMPDIR/version_build"
    export GIT_CEILING_DIRECTORIES="$BATS_TEST_TMPDIR"

    cp -r "$LIBRA_TESTS_DIR/sample_version" "$VERSION_SRC"
}

################################################################################
# Local helpers
################################################################################

# git with a fixed identity, so tests don't depend on the runner's git config.
# Usage: _git DIR ARGS...
_git() {
    local dir="$1"
    shift
    git -C "$dir" \
        -c user.name="LIBRA tests" \
        -c user.email="libra-tests@example.com" \
        -c init.defaultBranch=main \
        -c tag.gpgSign=false \
        -c commit.gpgSign=false \
        "$@"
}

# Turn DIR into a git repository with a single commit of its current contents.
# Usage: _git_init DIR
_git_init() {
    _git "$1" init -q
    _git "$1" add -A
    _git "$1" commit -q -m "initial"
}

# Add N empty commits on top of HEAD.
# Usage: _git_advance DIR N
_git_advance() {
    local i
    for ((i = 0; i < $2; i++)); do
        _git "$1" commit -q --allow-empty -m "commit $i"
    done
}

# Abbreviated SHA of HEAD, as git describe would print it.
# Usage: _git_short_sha DIR
_git_short_sha() {
    _git "$1" rev-parse --short HEAD
}

# Configure sample_version from $VERSION_SRC into $VERSION_BUILD (or $2, for
# tests that move the source), wiring LIBRA up for the active consume mode.
# Configure only: everything these tests check is decided at configure time.
# Sets $status/$output from cmake.
# Usage: configure_version [CMAKE_OPTIONS...]
configure_version() {
    local src="${VERSION_SRC_OVERRIDE:-$VERSION_SRC}"
    local cmake_args=(
        -S "$src"
        -B "$VERSION_BUILD"
        -DLIBRA_TESTS_DIR="$LIBRA_TESTS_DIR"
        -DCMAKE_C_COMPILER="$(get_compiler "$COMPILER_TYPE" c)"
        -DCMAKE_CXX_COMPILER="$(get_compiler "$COMPILER_TYPE" cxx)"
        --log-level=STATUS
    )

    local _flag
    while IFS= read -r _flag; do
        [[ -n "$_flag" ]] && cmake_args+=("$_flag")
    done < <(_consume_mode_cmake_args)

    if [[ "$LIBRA_CONSUME_MODE" == "conan" ]]; then
        mkdir -p "$VERSION_BUILD/conan"
        printf '[requires]\nlibra/%s\n\n[generators]\nCMakeToolchain\n' \
               "$LIBRA_CONAN_VERSION" > "$VERSION_BUILD/conanfile.txt"
        conan install "$VERSION_BUILD/conanfile.txt" \
              --output-folder="$VERSION_BUILD/conan" \
              -s build_type=Debug \
              --build=missing > /dev/null
        cmake_args+=("-DCMAKE_TOOLCHAIN_FILE=$VERSION_BUILD/conan/conan_toolchain.cmake")
    fi

    run cmake "${cmake_args[@]}" "$@"
    [ -n "$GITHUB_ACTIONS" ] && echo "$output" >&3
    true
}

# Assert the last configure_version printed a message containing STRING. CMake
# wraps warning text at arbitrary word boundaries, so whitespace (including
# newlines) is collapsed on both sides before matching.
# Usage: assert_message_contains STRING
assert_message_contains() {
    local flat needle
    flat=$(echo "$output" | tr -s '[:space:]' ' ')
    needle=$(printf '%s' "$1" | tr -s '[:space:]' ' ')
    grep -qF -- "$needle" <<< "$flat" && return 0
    libra_fail "configure output does not contain message" \
        expected "$1" output "$output"
}

# Negation of assert_message_contains.
# Usage: assert_message_not_contains STRING
assert_message_not_contains() {
    local flat needle
    flat=$(echo "$output" | tr -s '[:space:]' ' ')
    needle=$(printf '%s' "$1" | tr -s '[:space:]' ' ')
    grep -qF -- "$needle" <<< "$flat" || return 0
    libra_fail "configure output contains unexpected message" \
        unexpected "$1" output "$output"
}

# Value of one of the fixture's "[VERSION-TEST] NAME=value" markers from the
# last configure_version.
# Usage: marker NAME
marker() {
    echo "$output" | sed -n "s/^-- \[VERSION-TEST\] $1=//p" | tail -n 1
}

# Assert the three project version cache variables in one go.
# Usage: assert_project_version FULL NUMERIC PRERELEASE
assert_project_version() {
    local full numeric pre
    full=$(get_cache_value "$VERSION_BUILD" LIBRA_PROJECT_VERSION)
    numeric=$(get_cache_value "$VERSION_BUILD" LIBRA_PROJECT_VERSION_NUMERIC)
    pre=$(get_cache_value "$VERSION_BUILD" LIBRA_PROJECT_VERSION_PRERELEASE)

    [[ "$full" == "$1" && "$numeric" == "$2" && "$pre" == "$3" ]] && return 0
    libra_fail "project version differs" \
        'expected full' "$1" \
        'actual full' "$full" \
        'expected numeric' "$2" \
        'actual numeric' "$numeric" \
        'expected prerelease' "$3" \
        'actual prerelease' "$pre"
}

# What LIBRA_VERSION should be under the active consume mode. Mirrors
# libra_resolve_self_version() (see reference/versioning in the docs): a baked
# self.cmake wins, then git in LIBRA's own checkout (only if the repo is rooted
# exactly there), then 0.0.0.
# Usage: expected_libra_version
expected_libra_version() {
    case "$LIBRA_CONSUME_MODE" in
        installed_package)
            # Installed trees carry neither .git nor a baked self.cmake.
            echo "0.0.0"
            return
            ;;
        conan)
            # Baked at package time. LIBRA_CONAN_VERSION is the numeric
            # version; the bake is the full one, so callers prefix-match.
            echo "$LIBRA_CONAN_VERSION"
            return
            ;;
    esac

    # in_situ, add_subdirectory, cpm: all use LIBRA_SOURCE_ROOT directly.
    local root baked top tag described
    root=$(realpath "$LIBRA_SOURCE_ROOT")

    baked="$root/cmake/libra/self.cmake"
    if [[ -f "$baked" ]] && ! grep -q '\$Format' "$baked"; then
        sed -n 's/^set(LIBRA_VERSION "\(.*\)")/\1/p' "$baked"
        return
    fi

    top=$(git -C "$root" rev-parse --show-toplevel 2>/dev/null) || top=""
    [[ -n "$top" ]] && top=$(realpath "$top")
    if [[ "$top" != "$root" ]]; then
        echo "0.0.0"
        return
    fi

    if tag=$(git -C "$root" describe --exact-match --tags 2>/dev/null); then
        echo "${tag#v}"
        return
    fi
    if described=$(git -C "$root" describe --tags --long 2>/dev/null) &&
       [[ "$described" =~ ^v?(.+)-([0-9]+)-g([0-9a-f]+)$ ]]; then
        echo "${BASH_REMATCH[1]}+${BASH_REMATCH[2]}.g${BASH_REMATCH[3]}"
        return
    fi
    echo "0.0.0"
}

# ==============================================================================
# Tagged commits
# ==============================================================================

@test "VERSION: stable tag on HEAD" {
    _git_init "$VERSION_SRC"
    _git "$VERSION_SRC" tag v1.2.3

    configure_version
    assert_success

    assert_project_version "1.2.3" "1.2.3" ""

    # Matched on our version specifically: in add_subdirectory mode, LIBRA's
    # own CMakeLists.txt legitimately warns about LIBRA's untagged commits.
    assert_message_not_contains "1.2.3 is not releasable"
}

@test "VERSION: prerelease tag on HEAD" {
    _git_init "$VERSION_SRC"
    _git "$VERSION_SRC" tag v1.2.3-dev.4

    configure_version
    assert_success

    assert_project_version "1.2.3-dev.4" "1.2.3" "dev.4"
}

@test "VERSION: hyphenated prerelease is kept intact" {
    _git_init "$VERSION_SRC"
    _git "$VERSION_SRC" tag v1.2.3-rc-1

    configure_version
    assert_success

    assert_project_version "1.2.3-rc-1" "1.2.3" "rc-1"
}

@test "VERSION: tag without leading v is accepted" {
    _git_init "$VERSION_SRC"
    _git "$VERSION_SRC" tag 1.2.3

    configure_version
    assert_success

    assert_project_version "1.2.3" "1.2.3" ""
}

@test "VERSION: PROJECT_VERSION follows the numeric version" {
    _git_init "$VERSION_SRC"
    _git "$VERSION_SRC" tag v1.2.3-dev.4

    configure_version
    assert_success

    assert_equal "$(marker PROJECT_VERSION)" "1.2.3"
    assert_cache_value "$VERSION_BUILD" CMAKE_PROJECT_VERSION "1.2.3"
}

# ==============================================================================
# Untagged commits
# ==============================================================================

@test "VERSION: untagged commit past a stable tag gets build metadata" {
    _git_init "$VERSION_SRC"
    _git "$VERSION_SRC" tag v1.2.3
    _git_advance "$VERSION_SRC" 2
    local sha
    sha=$(_git_short_sha "$VERSION_SRC")

    configure_version
    assert_success

    assert_project_version "1.2.3+2.g${sha}" "1.2.3" ""
}

@test "VERSION: untagged commit past a prerelease tag keeps the prerelease" {
    _git_init "$VERSION_SRC"
    _git "$VERSION_SRC" tag v1.2.3-dev.4
    _git_advance "$VERSION_SRC" 3
    local sha
    sha=$(_git_short_sha "$VERSION_SRC")

    configure_version
    assert_success

    assert_project_version "1.2.3-dev.4+3.g${sha}" "1.2.3" "dev.4"
}

@test "VERSION: untagged commit warns that it is not releasable" {
    _git_init "$VERSION_SRC"
    _git "$VERSION_SRC" tag v1.2.3
    _git_advance "$VERSION_SRC" 1
    local sha
    sha=$(_git_short_sha "$VERSION_SRC")

    configure_version
    assert_success

    assert_message_contains "version 1.2.3+1.g${sha} is not releasable"
}

@test "VERSION: nearest tag wins over older tags" {
    _git_init "$VERSION_SRC"
    _git "$VERSION_SRC" tag v1.0.0
    _git_advance "$VERSION_SRC" 1
    _git "$VERSION_SRC" tag v1.1.0-dev.1
    _git_advance "$VERSION_SRC" 1
    local sha
    sha=$(_git_short_sha "$VERSION_SRC")

    configure_version
    assert_success

    assert_project_version "1.1.0-dev.1+1.g${sha}" "1.1.0" "dev.1"
}

# ==============================================================================
# Nothing to resolve from
# ==============================================================================

@test "VERSION: no git repository falls back to 0.0.0 with a warning" {
    configure_version
    assert_success

    assert_project_version "0.0.0" "0.0.0" ""
    assert_equal "$(marker PROJECT_VERSION)" "0.0.0"
    assert_message_contains "Falling back to 0.0.0"
}

@test "VERSION: repository without tags falls back to 0.0.0" {
    _git_init "$VERSION_SRC"

    configure_version
    assert_success

    assert_project_version "0.0.0" "0.0.0" ""
    assert_message_contains "Falling back to 0.0.0"
}

@test "VERSION: non-version nearest tag falls back to 0.0.0" {
    # git describe returns the nearest tag of any name, so a non-version tag
    # shadows the older valid one.
    _git_init "$VERSION_SRC"
    _git "$VERSION_SRC" tag v1.2.3
    _git_advance "$VERSION_SRC" 1
    _git "$VERSION_SRC" tag nightly
    _git_advance "$VERSION_SRC" 1

    configure_version
    assert_success

    assert_project_version "0.0.0" "0.0.0" ""
    assert_message_contains "unrecognized git describe format"
}

@test "VERSION: vendored project without its own .git reports the enclosing repo" {
    # Documented caveat: git searches upward from the calling project.
    local outer="$BATS_TEST_TMPDIR/outer"
    mkdir -p "$outer"
    mv "$VERSION_SRC" "$outer/sample_version"
    _git_init "$outer"
    _git "$outer" tag v9.8.7

    VERSION_SRC_OVERRIDE="$outer/sample_version" configure_version
    assert_success

    assert_project_version "9.8.7" "9.8.7" ""
}

# ==============================================================================
# Where the version goes, and when it is resolved
# ==============================================================================

@test "VERSION: resolved version is baked into configured source files" {
    _git_init "$VERSION_SRC"
    _git "$VERSION_SRC" tag v1.2.3-dev.4

    configure_version
    assert_success

    local info="$VERSION_BUILD/version_info.c"
    assert_file_exists "$info"
    assert_file_contains "$info" 'PROJECT_VERSION_FULL = "1\.2\.3-dev\.4"'
    assert_file_contains "$info" 'PROJECT_VERSION_NUMERIC = "1\.2\.3"'
}

@test "VERSION: tagging after configure changes nothing until reconfigure" {
    _git_init "$VERSION_SRC"
    _git "$VERSION_SRC" tag v1.2.3

    configure_version
    assert_success
    assert_project_version "1.2.3" "1.2.3" ""

    _git_advance "$VERSION_SRC" 1
    _git "$VERSION_SRC" tag v1.2.4

    # A build does not re-run configure just because tags changed.
    run cmake --build "$VERSION_BUILD"
    assert_success
    assert_project_version "1.2.3" "1.2.3" ""
    assert_file_contains "$VERSION_BUILD/version_info.c" 'PROJECT_VERSION_FULL = "1\.2\.3"'

    configure_version
    assert_success
    assert_project_version "1.2.4" "1.2.4" ""
    assert_file_contains "$VERSION_BUILD/version_info.c" 'PROJECT_VERSION_FULL = "1\.2\.4"'
}

# ==============================================================================
# Calling patterns and scoping
# ==============================================================================

@test "VERSION: include(libra/project) without project() resolves automatically" {
    _git_init "$VERSION_SRC"
    _git "$VERSION_SRC" tag v1.2.3-dev.4

    configure_version -DLIBRA_TEST_VERSION_AUTO=ON
    assert_success

    assert_project_version "1.2.3-dev.4" "1.2.3" "dev.4"
    assert_equal "$(marker PROJECT_VERSION)" "1.2.3"
}

@test "VERSION: nested project sees its own version, cache keeps the top-level one" {
    _git_init "$VERSION_SRC"
    _git "$VERSION_SRC" tag v1.2.3

    # A nested project with its own repository and tag.
    local nested="$BATS_TEST_TMPDIR/nested"
    mkdir -p "$nested"
    cat > "$nested/CMakeLists.txt" << 'EOF'
include(libra/version)
libra_extract_version()
message(STATUS "[VERSION-TEST] NESTED LIBRA_PROJECT_VERSION=${LIBRA_PROJECT_VERSION}")
EOF
    _git_init "$nested"
    _git "$nested" tag v7.0.0

    configure_version -DLIBRA_TEST_VERSION_SUBDIR="$nested"
    assert_success

    assert_equal "$(marker 'NESTED LIBRA_PROJECT_VERSION')" "7.0.0"
    assert_equal "$(marker 'AFTER_NESTED LIBRA_PROJECT_VERSION')" "1.2.3"
    assert_project_version "1.2.3" "1.2.3" ""
}

# ==============================================================================
# LIBRA's own version
# ==============================================================================

@test "VERSION: LIBRA_VERSION matches what the consume mode should resolve" {
    _git_init "$VERSION_SRC"
    _git "$VERSION_SRC" tag v1.2.3

    configure_version
    assert_success

    local expected actual
    expected=$(expected_libra_version)
    actual=$(get_cache_value "$VERSION_BUILD" LIBRA_VERSION)

    # Under conan the expected value is only the numeric prefix of the baked
    # full version.
    if [[ "$LIBRA_CONSUME_MODE" == "conan" && "$actual" == "$expected"* ]] ||
       [[ "$actual" == "$expected" ]]; then
        return 0
    fi
    libra_fail "LIBRA_VERSION differs" \
        expected "$expected" actual "$actual" mode "$LIBRA_CONSUME_MODE"
}

@test "VERSION: LIBRA_VERSION is independent of the project's version" {
    # LIBRA_VERSION comes from LIBRA's own checkout/package, never from the
    # consuming project's tags.
    _git_init "$VERSION_SRC"
    _git "$VERSION_SRC" tag v42.0.0

    configure_version
    assert_success

    assert_project_version "42.0.0" "42.0.0" ""
    assert_not_equal "$(get_cache_value "$VERSION_BUILD" LIBRA_VERSION)" "42.0.0"
}

@test "VERSION: configure reports LIBRA_VERSION" {
    configure_version
    assert_success

    local v
    v=$(get_cache_value "$VERSION_BUILD" LIBRA_VERSION)
    assert [ -n "$v" ]
    assert_message_contains "This is LIBRA v${v}"
    assert_file_contains "$VERSION_BUILD/version_info.c" \
        "LIBRA_FRAMEWORK_VERSION = \"${v//./\\.}\""
}
