.. SPDX-License-Identifier: MIT

.. _concepts/versioning:

==========
Versioning
==========

LIBRA directly supports git tags as the single source of truth for version
numbers. By doing so:

- Versions can be easily be automatically bumped in CI according to whatever
  scheme you want in a repo which uses LIBRA.

- Versions are generally immutable for a repo, because tags are considered
  immutable by most projects.

This page explains how LIBRA's versioning works, and how it can be used by
downstream projects.

.. _concepts/versioning/source-of-truth:

Git tags as the single source of truth
======================================

Keeping the version in git tags rather than a file eliminates
version-bump commits from the history, avoids the file-tag sync problem,
and makes the tag the unambiguous single artifact of a release action.

The resolution chain, in priority order:

1. **Exact tag on HEAD** — the normal state for every consumable build.
   The tag is parsed as ``vMAJOR.MINOR.PATCH`` or
   ``vMAJOR.MINOR.PATCH-PRERELEASE`` per semantic versioning.

2. **Untagged commit** — HEAD is not directly tagged (e.g., a WIP package from a
   feature branch). The nearest ancestor tag is located via ``git
   describe --tags --long`` and the commit distance and SHA are appended as
   build metadata, producing a string like
   ``1.5.0-dev.3.untagged.5+g230f029``. A warning is emitted. Untagged builds
   are not considered releasable in most projects.

3. **No git / no tags** — no repository or no reachable tags (source
   tarball, shallow clone predating any tag). Version is set to
   ``0.0.0`` with an empty prerelease component and a warning is
   emitted.


.. _concepts/versioning/variables:

Version variables
=================

:cmake:command:`libra_extract_version` sets three variables in the calling
scope:

- :cmake:variable:`LIBRA_PROJECT_VERSION`
- :cmake:variable:`LIBRA_PROJECT_VERSION_NUMERIC`
- :cmake:variable:`LIBRA_PROJECT_VERSION_PRERELEASE`

These variables are available before the ``project()`` call in your root
``CMakeLists.txt``:

.. code-block:: cmake

   include(libra/version)
   libra_extract_version()

   project(
     myproject
     LANGUAGES CXX C
     VERSION ${LIBRA_PROJECT_VERSION_NUMERIC})
   message(
     STATUS "Configuring myproject v${PROJECT_VERSION} (${LIBRA_PROJECT_VERSION})")

   include(libra/project)


.. IMPORTANT:: ``project(VERSION xxxx)`` does not support anything other than
   numeric identifiers, so :cmake:variable:`LIBRA_PROJECT_VERSION_NUMERIC` is
   the safest choice to use.

After the ``project()`` call, CMake's standard :cmake:variable:`PROJECT_VERSION`
equals :cmake:variable:`LIBRA_PROJECT_VERSION_NUMERIC`, and
:cmake:variable:`PROJECT_VERSION_MAJOR`,
:cmake:variable:`PROJECT_VERSION_MINOR`, and
:cmake:variable:`PROJECT_VERSION_PATCH` are set accordingly.
:cmake:variable:`LIBRA_PROJECT_VERSION` and
:cmake:variable:`LIBRA_PROJECT_VERSION_PRERELEASE` carry the information that
CMake's own version machinery cannot represent.

.. note::

   :cmake:variable:`LIBRA_VERSION` is a distinct variable that holds
   the version of the LIBRA framework itself, not your project's
   version. After ``include(libra/project)``, both variables are in
   scope, so the distinction matters.


.. _concepts/versioning/consuming:

Consuming versions in CPM
==========================

CPM's ``GIT_TAG`` and ``VERSION`` parameters serve different purposes
and must both be supplied:

.. code-block:: cmake

   CPMAddPackage(
     NAME    mydep
     GIT_TAG v${LIBRA_PROJECT_VERSION}         # fetch ref: full semver tag
     VERSION   ${LIBRA_PROJECT_VERSION_NUMERIC} # deduplication key: X.Y.Z only
   )

``GIT_TAG`` is the actual git fetch reference and accepts the full
semver string including any prerelease suffix. ``VERSION`` is CMake's
package deduplication key and requires integer-only version strings —
passing a prerelease string here produces a parse warning and may cause
incorrect deduplication when multiple packages request the same
dependency.

For stable builds, prefer stable tags:

.. code-block:: cmake

   CPMAddPackage(NAME mydep GIT_TAG v1.5.0 VERSION 1.5.0)

For active co-development, pin to an integration tag explicitly:

.. code-block:: cmake

   CPMAddPackage(NAME mydep GIT_TAG v1.5.0-dev.3 VERSION 1.5.0)

To use a locally installed package in preference to fetching:

.. code-block:: bash

   cmake -DCPM_USE_LOCAL_PACKAGES=ON \
         -DCMAKE_PREFIX_PATH=/path/to/install \
         ...

With ``CPM_USE_LOCAL_PACKAGES=ON``, CPM attempts ``find_package()``
before fetching from git. ``GIT_TAG`` and ``VERSION`` become the
fallback only if the local package is not found.

