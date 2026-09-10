#!/usr/bin/env python3
#
# Copyright 2026 John Harwell, All rights reserved.
#
# SPDX-License-Identifier: MIT
#
# Note: This is vendored from the forge repo (https://github.com/jharwell/forge).
#
# Usage:
#   version.py                  # prints full version
#   version.py --numeric        # prints X.Y.Z only
#   version.py --prerelease     # prints prerelease suffix only
#
# Version resolution priority:
#   1. Exact git tag on HEAD.
#   2. Nearest ancestor tag + commit distance (git describe --long).
#   3. Baked LIBRA_VERSION in self.cmake -- the git-less fallback for
#      CPM consumers / source tarballs / shallow clones, where the whole
#      point is to still report a meaningful version in diagnostics.
#   4. 0.0.0 (nothing available).

# Core packages
import subprocess
import argparse
import pathlib
import re

# 3rd party packages

# Project packages


def git(*args):
    try:
        result = subprocess.run(
            ["git", *args],
            capture_output=True,
            text=True,
            check=True,
        )
        return result.stdout.strip() or None
    except (subprocess.CalledProcessError, FileNotFoundError):
        # CalledProcessError: git ran but failed (not a repo, no tags, ...).
        # FileNotFoundError: git is not installed at all.
        return None


# Matches the output of `git describe --tags --long`, e.g.:
#   v1.2.3
#   v1.2.3-dev.4
#   v1.2.3-dev.4-2-gabcdef1
#
# The prerelease group is greedy but the trailing `-<distance>-g<sha>` suffix
# is anchored, so a prerelease containing hyphens (e.g. rc-1) is parsed into
# `prerelease` rather than being mistaken for the distance/sha suffix. This
# keeps version.py consistent with version.cmake's _libra_parse_semver_tag,
# whose character class already permits hyphens in the prerelease.
SEMVER_GIT_RE = re.compile(
    r"""
    ^v?
    (?P<version>\d+\.\d+\.\d+)
    (?:-(?P<prerelease>.+?))?          # greedy-minimal; hyphens allowed
    (?:-(?P<distance>\d+)-g(?P<sha>[0-9a-f]+))?
    $
    """,
    re.VERBOSE,
)


def from_self_cmake():
    """Git-less fallback: read the baked LIBRA_VERSION from self.cmake.

    self.cmake lives beside this script in cmake/libra/ and contains a single
    `set(LIBRA_VERSION "X.Y.Z")` line, baked in at release time. This is what
    a CPM consumer checked out at a tag with no git metadata sees, so its
    diagnostic output still reports the real version instead of 0.0.0.

    The stored value has no leading 'v' (CI strips it before baking), but
    parse() tolerates either convention.
    """
    p = pathlib.Path(__file__).with_name("self.cmake")
    try:
        text = p.read_text()
    except OSError:
        return None
    m = re.search(r'set\(\s*LIBRA_VERSION\s+"([^"]+)"\s*\)', text)
    return m.group(1) if m else None


def extract():
    # 1. exact tag
    tag = git("describe", "--exact-match", "--tags")
    if tag:
        return parse(tag)

    # 2. nearest tag + distance
    described = git("describe", "--tags", "--long")
    if described:
        m = SEMVER_GIT_RE.match(described)
        if not m:
            raise ValueError(f"Unrecognized git describe format: {described}")

        version = m.group("version")
        prerelease = m.group("prerelease")
        distance = m.group("distance")
        sha = m.group("sha")

        # exact tag match (no commits ahead)
        if distance is None:
            return (
                version,
                f"{version}" + (f"-{prerelease}" if prerelease else ""),
                prerelease or "",
            )

        # build metadata per SemVer 2.0
        build = f"{distance}.g{sha}"

        full = version
        if prerelease:
            full += f"-{prerelease}"
        full += f"+{build}"

        prerelease_str = prerelease or ""

        return version, full, prerelease_str

    # 3. git-less fallback: baked value in self.cmake (CPM / tarball consumers)
    baked = from_self_cmake()
    if baked:
        return parse(baked)

    # 4. nothing available
    return "0.0.0", "0.0.0", ""


def parse(tag):
    tag = tag.removeprefix("v")

    # Split into semver + prerelease only (NO git parsing here)
    if "-" in tag:
        numeric, prerelease = tag.split("-", 1)
    else:
        numeric, prerelease = tag, ""

    full = numeric + (f"-{prerelease}" if prerelease else "")
    return numeric, full, prerelease


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--numeric", action="store_true")
    parser.add_argument("--prerelease", action="store_true")
    args = parser.parse_args()

    numeric, full, prerelease = extract()

    if args.numeric:
        print(numeric)
    elif args.prerelease:
        print(prerelease)
    else:
        print(full)
