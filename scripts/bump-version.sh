#!/usr/bin/env bash
#
# Copyright 2026 John Harwell, All rights reserved.
#
# SPDX-License-Identifier: MIT
#
# Note: This is vendored from the forge repo (https://github.com/jharwell/forge).
#
# Determine the next development prerelease tag.
#
# Policy:
#   - Development occurs on a single monotonically increasing dev stream:
#
#       vX.Y.Z-dev.N
#
#   - Once vX.Y.Z is released, the next dev tag becomes:
#
#       vX.Y.(Z+1)-dev.1
#
#   - Only one active development line is assumed.
#   - Stable tags are never rewritten or deleted.
#
# Usage:
#   NEW_TAG=$(./bump-version.sh)
#

set -euo pipefail

SEMVER_DEV_RE='^v[0-9]+\.[0-9]+\.[0-9]+-dev\.[0-9]+$'
SEMVER_STABLE_RE='^v[0-9]+\.[0-9]+\.[0-9]+$'


latest_matching_tag() {
    local regex="$1"

    git tag --list --sort=-v:refname \
        | grep -m1 -E "${regex}" || true
}

# Return the highest stable tag that is >= the given base version (MAJ.MIN.PAT),
# or empty string if none exists.
superseding_stable_tag() {
    local base="$1"
    local bmaj bmin bpat

    IFS='.' read -r bmaj bmin bpat <<< "${base}"

    git tag --list \
        | grep -E "${SEMVER_STABLE_RE}" \
        | sed 's/^v//' \
        | sort -V \
        | awk -F. \
            -v bmaj="${bmaj}" \
            -v bmin="${bmin}" \
            -v bpat="${bpat}" \
            '
            ($1+0 > bmaj+0) ||
            ($1+0 == bmaj+0 && $2+0 > bmin+0) ||
            ($1+0 == bmaj+0 && $2+0 == bmin+0 && $3+0 >= bpat+0)
            ' \
        | tail -1
}


LATEST_DEV=$(latest_matching_tag "${SEMVER_DEV_RE}")

if [[ -n "${LATEST_DEV}" ]]; then
    echo "Latest dev tag: ${LATEST_DEV}" >&2

    BASE=$(
        echo "${LATEST_DEV}" \
            | sed -E 's/^v//; s/-dev\..*//'
    )

    N=$(
        echo "${LATEST_DEV}" \
            | sed -E 's/.*-dev\.([0-9]+)/\1/'
    )

    #
    # If any stable release >= this base exists, the dev series has been
    # promoted (possibly to a higher version on another branch). Start the
    # next patch development series from the highest such stable release.
    #
    SUPERSEDING=$(superseding_stable_tag "${BASE}")

    if [[ -n "${SUPERSEDING}" ]]; then
        echo "Stable release v${SUPERSEDING} supersedes ${BASE}; advancing patch series" >&2

        IFS='.' read -r MAJ MIN PAT <<< "${SUPERSEDING}"

        NEW_TAG="v${MAJ}.${MIN}.$((PAT + 1))-dev.1"
    else
        echo "Continuing existing development series" >&2

        NEW_TAG="v${BASE}-dev.$((N + 1))"
    fi

else
    #
    # No development tags exist yet. Bootstrap from the latest
    # stable release if available.
    #
    LATEST_STABLE=$(latest_matching_tag "${SEMVER_STABLE_RE}")

    if [[ -n "${LATEST_STABLE}" ]]; then
        echo "No development tags found; bootstrapping from ${LATEST_STABLE}" >&2

        BASE=$(echo "${LATEST_STABLE}" | sed 's/^v//')

        IFS='.' read -r MAJ MIN PAT <<< "${BASE}"

        NEW_TAG="v${MAJ}.${MIN}.$((PAT + 1))-dev.1"

    else
        #
        # Completely unversioned repository bootstrap.
        #
        echo "No stable or development tags found; initializing version stream" >&2

        NEW_TAG="v0.0.1-dev.1"
    fi
fi

printf '%s\n' "${NEW_TAG}"
