#!/usr/bin/env python3
#
# Copyright 2026 John Harwell, All rights reserved.
#
# SPDX-License-Identifier: MIT
#
# Single source of truth for git-based version extraction.
# Mirrors the logic in libra_extract_version() and build.rs.
#
# Usage:
#   version.py                  # prints full version
#   version.py --numeric        # prints X.Y.Z only
#   version.py --prerelease     # prints prerelease suffix only

# Core packages

# 3rd party packages

# Project packages


import subprocess
import argparse


def git(*args):
    try:
        result = subprocess.run(
            ["git", *args], capture_output=True, text=True, check=True
        )
        return result.stdout.strip() or None
    except subprocess.CalledProcessError:
        return None


def extract():
    # Priority 1: exact tag
    tag = git("describe", "--exact-match", "--tags")
    if tag:
        return parse(tag)

    # Priority 2: nearest ancestor tag + distance
    described = git("describe", "--tags", "--long")
    if described:
        # v1.5.0-dev.2-5-gabcdef1 -> base, distance, sha
        sha = described.rsplit("-g", 1)[1]
        rest = described.rsplit("-g", 1)[0]
        base, dist = rest.rsplit("-", 1)
        base = base.lstrip("v")
        dist = int(dist)
        if dist == 0:
            return parse("v" + base)
        sep = "." if "-" in base else "-"
        return base, f"{base}{sep}untagged.{dist}+g{sha}", f"untagged.{dist}+g{sha}"

    return "0.0.0", "0.0.0", ""


def parse(tag):
    tag = tag.lstrip("v")
    if "-" in tag:
        numeric, prerelease = tag.split("-", 1)
    else:
        numeric, prerelease = tag, ""
    full = f"{numeric}-{prerelease}" if prerelease else numeric
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
