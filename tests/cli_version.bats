#!/usr/bin/env bats
#
# BATS tests for `clibra version`.
#
# `clibra version` answers two different questions from two different sources
# (see concepts/versioning in the docs):
#
#   - version / --full / --check: "what version is this build?" Read back from
#     the CMake cache, where libra_extract_version() baked it at configure time.
#     Never runs git.
#
#   - --bump: "what version comes next?" Computed from the set of all v* tags in
#     the repository. Never reads the cache.
#
# Every test turns the copied sample_cli fixture into its own git repository
# with exactly the tags it needs, so expected versions are exact rather than
# "something semver-shaped". GIT_CEILING_DIRECTORIES stops git from walking up
# out of the temp dir into whatever repository the tests are run from.
#

load test_helpers

setup() {
    setup_cli_test
    skip_if_compiler_missing gnu c

    export GIT_CEILING_DIRECTORIES="$BATS_TEST_TMPDIR"

    # Build output must not count as repository content.
    printf 'build/\n' > .gitignore
}

################################################################################
# Local helpers
################################################################################

# git in the test project, with a fixed identity.
# Usage: _git ARGS...
_git() {
    git -c user.name="LIBRA tests" \
        -c user.email="libra-tests@example.com" \
        -c init.defaultBranch=main \
        -c tag.gpgSign=false \
        -c commit.gpgSign=false \
        "$@"
}

# Make the test project a git repository with one commit, optionally tagged.
# Usage: repo_init [TAG...]
repo_init() {
    _git init -q
    _git add -A
    _git commit -q -m "initial"
    local t
    for t in "$@"; do
        _git tag "$t"
    done
}

# Add an empty commit, optionally tagged.
# Usage: repo_commit [TAG]
repo_commit() {
    _git commit -q --allow-empty -m "commit"
    [[ -n "${1:-}" ]] && _git tag "$1"
    true
}

# Configure (and build) the debug preset, which is what bakes the version into
# the cache.
configure() {
    run "$CLIBRA_BIN" build --preset debug $CLI_CMAKE_DEFINES
    assert_success
}

# Assert the last command's output, ignoring log lines, is exactly EXPECTED.
# Usage: assert_version_output EXPECTED
assert_version_output() {
    local got
    got=$(echo "$output" | grep -v '^\[' | sed '/^\s*$/d' | tail -n 1)

    [[ "$got" == "$1" ]] && return 0
    libra_fail "version output differs" \
        expected "$1" actual "$got" output "$output"
}

# ==============================================================================
# Reading the baked version: default (numeric) and --full
# ==============================================================================

@test "VERSION: stable tag prints the same numeric and full version" {
    repo_init v1.2.3
    configure

    run_clibra version --preset debug
    assert_success
    assert_version_output "1.2.3"

    run_clibra version --preset debug --full
    assert_success
    assert_version_output "1.2.3"
}

@test "VERSION: prerelease tag prints numeric by default, prerelease with --full" {
    repo_init v1.2.3-dev.4
    configure

    run_clibra version --preset debug
    assert_success
    assert_version_output "1.2.3"

    run_clibra version --preset debug --full
    assert_success
    assert_version_output "1.2.3-dev.4"
}

@test "VERSION: untagged commit --full carries distance and sha" {
    repo_init v1.2.3-dev.4
    repo_commit
    repo_commit
    local sha
    sha=$(_git rev-parse --short HEAD)
    configure

    run_clibra version --preset debug --full
    assert_success
    assert_version_output "1.2.3-dev.4+2.g${sha}"

    run_clibra version --preset debug
    assert_success
    assert_version_output "1.2.3"
}

@test "VERSION: repository without tags reports 0.0.0" {
    repo_init
    configure

    run_clibra version --preset debug --full
    assert_success
    assert_version_output "0.0.0"
}

@test "VERSION: not a git repository reports 0.0.0" {
    configure

    run_clibra version --preset debug --full
    assert_success
    assert_version_output "0.0.0"
}

# ==============================================================================
# The version is what was baked at configure time
# ==============================================================================

@test "VERSION: tagging after configure is not seen until reconfigure" {
    repo_init v1.2.3
    configure

    repo_commit v1.3.0

    # Still what the cache holds.
    run_clibra version --preset debug --full
    assert_success
    assert_version_output "1.2.3"

    # --reconfigure re-runs libra_extract_version().
    run_clibra version --preset debug --full --reconfigure
    assert_success
    assert_version_output "1.3.0"

    # And the new value sticks.
    run_clibra version --preset debug --full
    assert_success
    assert_version_output "1.3.0"
}

@test "VERSION: -r is accepted as short form of --reconfigure" {
    repo_init v1.2.3
    configure
    repo_commit v1.3.0

    run_clibra version --preset debug -r
    assert_success
    assert_version_output "1.3.0"
}

@test "VERSION: reads the cache, not git" {
    repo_init v1.2.3
    configure

    # With the repository gone, only the cache can answer.
    rm -rf .git

    run_clibra version --preset debug --full
    assert_success
    assert_version_output "1.2.3"
}

# ==============================================================================
# --check (CI gating)
# ==============================================================================

@test "VERSION: --check passes on an exact match" {
    repo_init v1.2.3
    configure

    run_clibra version --preset debug --check 1.2.3
    assert_success
}

@test "VERSION: --check fails on a mismatch and reports both versions" {
    repo_init v1.2.3
    configure

    run_clibra version --preset debug --check 1.2.4
    assert_failure
    assert_output --partial "1.2.3"
    assert_output --partial "1.2.4"
}

@test "VERSION: --check compares against the numeric version" {
    # A dev build of 1.2.3 passes a gate for 1.2.3.
    repo_init v1.2.3-dev.4
    configure

    run_clibra version --preset debug --check 1.2.3
    assert_success
}

@test "VERSION: --check uses the baked version, not newer tags" {
    repo_init v1.2.3
    configure
    repo_commit v1.3.0

    run_clibra version --preset debug --check 1.3.0
    assert_failure

    run_clibra version --preset debug --check 1.3.0 --reconfigure
    assert_success
}

@test "VERSION: --check fails on a non-semver argument" {
    repo_init v1.2.3
    configure

    run_clibra version --preset debug --check not-a-version
    assert_failure
}

@test "VERSION: -c is accepted as short form of --check" {
    repo_init v1.2.3
    configure

    run_clibra version --preset debug -c 1.2.3
    assert_success

    run_clibra version --preset debug -c 1.2.4
    assert_failure
}

# ==============================================================================
# --bump (next dev version, from tags)
# ==============================================================================

@test "VERSION: --bump after a stable tag starts a dev stream on the next patch" {
    repo_init v1.2.3

    run_clibra version --bump
    assert_success
    assert_version_output "1.2.4-dev.1"
}

@test "VERSION: --bump continues an existing dev stream" {
    repo_init v1.2.4-dev.4

    run_clibra version --bump
    assert_success
    assert_version_output "1.2.4-dev.5"
}

@test "VERSION: --bump dev counter is numeric, not lexical" {
    repo_init v1.2.4-dev.9

    run_clibra version --bump
    assert_success
    assert_version_output "1.2.4-dev.10"
}

@test "VERSION: --bump after an rc advances the patch" {
    # 1.2.4-dev.1 would sort below 1.2.4-rc.1.
    repo_init v1.2.4-rc.1

    run_clibra version --bump
    assert_success
    assert_version_output "1.2.5-dev.1"
}

@test "VERSION: --bump after alpha/beta starts dev on the same numeric" {
    repo_init v1.2.4-beta.2

    run_clibra version --bump
    assert_success
    assert_version_output "1.2.4-dev.1"
}

@test "VERSION: --bump with no tags bootstraps" {
    repo_init

    run_clibra version --bump
    assert_success
    assert_version_output "0.0.1-dev.1"
}

@test "VERSION: --bump picks the highest tag by precedence, not lexically" {
    repo_init v1.9.0
    repo_commit v1.10.0
    repo_commit v1.2.0

    run_clibra version --bump
    assert_success
    assert_version_output "1.10.1-dev.1"
}

@test "VERSION: --bump prefers a stable release over its own dev tags" {
    repo_init v1.2.4-dev.3
    repo_commit v1.2.4

    run_clibra version --bump
    assert_success
    assert_version_output "1.2.5-dev.1"
}

@test "VERSION: --bump counts tags unreachable from HEAD" {
    # Simulate a force-pushed branch: the newest dev tag points at a commit no
    # branch contains, and HEAD's nearest tag is older.
    repo_init v1.2.4-dev.3
    repo_commit v1.2.4-dev.4
    _git reset -q --hard HEAD~1

    run_clibra version --bump
    assert_success
    assert_version_output "1.2.4-dev.5"
}

@test "VERSION: --bump ignores tags that are not v + semver" {
    repo_init v1.2.3
    repo_commit 9.9.9
    repo_commit v-nightly
    repo_commit release-2.0.0

    run_clibra version --bump
    assert_success
    assert_version_output "1.2.4-dev.1"
}

@test "VERSION: --bump does not need a configured build" {
    repo_init v1.2.3
    assert_dir_not_exists build

    run_clibra version --bump
    assert_success
    assert_version_output "1.2.4-dev.1"
}

@test "VERSION: --bump reads tags, not the cache" {
    repo_init v1.2.3
    configure
    repo_commit v2.0.0

    # The build is still 1.2.3...
    run_clibra version --preset debug
    assert_success
    assert_version_output "1.2.3"

    # ...but the next version is computed from all tags.
    run_clibra version --bump
    assert_success
    assert_version_output "2.0.1-dev.1"
}

@test "VERSION: --bump only prints; it does not create a tag" {
    repo_init v1.2.3
    local before
    before=$(_git tag -l | sort)

    run_clibra version --bump
    assert_success

    assert_equal "$(_git tag -l | sort)" "$before"
}

@test "VERSION: -b is accepted as short form of --bump" {
    repo_init v1.2.3

    run_clibra version -b
    assert_success
    assert_version_output "1.2.4-dev.1"
}

@test "VERSION: --bump with --full is rejected" {
    repo_init v1.2.3

    run_clibra version --bump --full
    assert_failure
    assert_output --partial "--full not valid with --bump"
}

# ==============================================================================
# Failure
# ==============================================================================

@test "VERSION: fails when build directory does not exist" {
    run_clibra version --preset release
    assert_failure
    assert_output --partial "Build directory"
}

@test "VERSION: fails when no preset files exist" {
    rm -f CMakePresets.json CMakeUserPresets.json
    run_clibra version --preset debug
    assert_failure
}

@test "VERSION: rejects an invalid --output value" {
    run_clibra version --preset debug --output yaml
    assert_failure
}
