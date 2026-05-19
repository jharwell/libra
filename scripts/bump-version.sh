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
    # If a stable release for this base already exists, the dev
    # series has been promoted. Start the next patch development
    # series.
    #
    if git tag --list | grep -qx "v${BASE}"; then
        echo "Stable release for ${BASE} exists; advancing patch series" >&2

        IFS='.' read -r MAJ MIN PAT <<< "${BASE}"

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
