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

# Core packages
import subprocess
import argparse
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
    except subprocess.CalledProcessError:
        return None


# Matches:
# v1.2.3
# v1.2.3-dev.4
# v1.2.3-dev.4-2-gabcdef
SEMVER_GIT_RE = re.compile(
    r"""
    ^v?
    (?P<version>\d+\.\d+\.\d+)
    (?:-(?P<prerelease>[^-]+))?
    (?:-(?P<distance>\d+)-g(?P<sha>[0-9a-f]+))?
    $
    """,
    re.VERBOSE,
)


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

    return "0.0.0", "0.0.0", ""


def parse(tag):
    tag = tag.lstrip("v")

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
