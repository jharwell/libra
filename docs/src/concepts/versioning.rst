.. SPDX-License-Identifier: MIT

.. _concepts/versioning:

==========
Versioning
==========

Two different versions are in play whenever you build with LIBRA:

- **Your project's version** -- the version of the thing you are building. You
  opt into LIBRA managing this by calling :cmake:command:`libra_extract_version`,
  and it is exposed as :cmake:variable:`LIBRA_PROJECT_VERSION` and friends.

- **LIBRA's own version** -- the version of the build framework doing the
  building. LIBRA always resolves this itself, and it is exposed as
  :cmake:variable:`LIBRA_VERSION`.

Both are derived from git tags, but they answer different questions and so are
resolved differently. This page explains the model behind each; the exact
resolution rules, string formats, and variables are in
:ref:`reference/versioning`.

.. _concepts/versioning/source-of-truth:

Git tags as the single source of truth
======================================

LIBRA treats git tags as the *only* place a version is recorded. There is no
``VERSION`` file and no version string in ``CMakeLists.txt``. This:

- Eliminates version-bump commits from history, and with them the whole class
  of "the file says 1.4.2 but the tag says 1.4.3" bugs.

- Makes the tag the single, unambiguous artifact of a release. Releasing *is*
  tagging a commit that CI has already tested.

- Makes versions effectively immutable, since most projects (and most hosting
  platforms) treat pushed tags as immutable.

- Lets CI bump versions automatically according to whatever scheme you want.

Tags follow semantic versioning with a leading ``v``: ``v1.5.0`` for a stable
release, and ``v1.5.0-dev.3``, ``v1.5.0-rc.1``, etc. for prereleases. See
:ref:`reference/versioning/tags` for the exact grammar.

.. _concepts/versioning/two-questions:

"What version is this?" vs. "What version is next?"
---------------------------------------------------

LIBRA answers these two questions from deliberately different information:

- **What version is this build?** is answered from the version *baked into the
  build*. At configure time, the version is resolved once and written into the
  CMake cache; from there it flows into ``project()``, generated build-info
  files, binaries, and packages. ``clibra version`` reads it back from the
  cache and never consults git. For LIBRA itself, a version baked into
  ``self.cmake`` by packaging takes priority even over git (see
  :ref:`concepts/versioning/libra-self`).

- **What version comes next?** is answered from the *set of all tags* in the
  repository, regardless of whether they are reachable from ``HEAD``. This is
  what ``clibra version --bump`` computes. It reads git directly and never
  consults the cache.

Tags still determine what gets baked: when git is available, configure time
derives the version from the tag on ``HEAD``, or the nearest reachable tag plus
how far past it you are. But once baked, the build's version is fixed. Creating
a tag on a commit you have already configured does not change that build's
version until you reconfigure (``clibra version --reconfigure``, or re-run
``cmake``). This is also what lets a build keep a meaningful version after
leaving the repository, e.g. as a package or a tarball with no ``.git``.

The next-version question uses the whole tag set because the model assumes one
release line with immutable tags, but allows integration branches to be
force-pushed. After a force push, a tag like ``v1.5.0-dev.4`` can point at a
commit no branch contains anymore. The nearest *reachable* tag is then stale
(say ``v1.5.0-dev.3``), and bumping from it would try to create
``v1.5.0-dev.4`` again. Since the tag set is the release history, bumping from
the highest tag ever created is always correct.

.. _concepts/versioning/project:

Your project's version
======================

Calling :cmake:command:`libra_extract_version` before ``project()`` gives your
project a version derived from its git state:

.. code-block:: cmake

   cmake_minimum_required(VERSION 3.31)

   # LIBRA's cmake/ directory must already be on CMAKE_MODULE_PATH, however
   # you consume LIBRA.
   include(libra/version)
   libra_extract_version()

   project(
     myproject
     LANGUAGES CXX C
     VERSION ${LIBRA_PROJECT_VERSION_NUMERIC})

   message(STATUS "Configuring myproject ${LIBRA_PROJECT_VERSION}")

   include(libra/project)

This is opt-in. If you don't call it, LIBRA leaves your project's version
entirely to you; the only thing you lose is ``clibra version``, which reads
the result back out of the CMake cache.

What you get depends on the state of your checkout:

- **Tagged commit** (``HEAD`` is exactly ``v1.5.0``): the version is the tag,
  ``1.5.0``. This is the normal state for anything you release or let others
  consume.

- **Untagged commit** (a feature branch, or ``main`` a few commits past a
  release): the version is the nearest tag plus build metadata recording the
  distance and commit, e.g. ``1.5.0+5.g230f029``. It sorts as the tagged version
  it came from, but is clearly distinguishable from it, and LIBRA warns that it
  is not releasable.

- **No git or no tags** (source tarball, a fresh repo): the version is
  ``0.0.0``, with a warning.

Three variables carry the result, because CMake's own version machinery can
only represent the numeric ``MAJOR.MINOR.PATCH`` part:

- :cmake:variable:`LIBRA_PROJECT_VERSION` -- everything, e.g.
  ``1.5.0-dev.3+5.g230f029``. Use it for display, logs, and build info.

- :cmake:variable:`LIBRA_PROJECT_VERSION_NUMERIC` -- ``1.5.0``. Use it anywhere
  CMake needs a version: ``project(VERSION)``, package config compatibility
  checks, ``CPMAddPackage(VERSION)``.

- :cmake:variable:`LIBRA_PROJECT_VERSION_PRERELEASE` -- ``dev.3``, or empty for
  stable releases.

After ``project()``, CMake's standard :cmake:variable:`PROJECT_VERSION` and
its ``_MAJOR``/``_MINOR``/``_PATCH`` components are set from the numeric part
as usual.

.. IMPORTANT:: Git is run in the directory of the ``CMakeLists.txt`` that calls
   :cmake:command:`libra_extract_version`, and git searches *upward* for a
   repository. If your project is a plain directory vendored inside some other
   repository, it will report *that* repository's tags. Give vendored projects
   their own ``.git`` (e.g. a submodule), or don't call
   :cmake:command:`libra_extract_version` for them.

.. _concepts/versioning/workflow:

A release workflow built on this model
--------------------------------------

LIBRA doesn't force a branching or release scheme on you, but the model is
designed around one that works well, and that LIBRA itself uses (see
:ref:`concepts/versioning/libra-self`):

#. **Every green build of your integration branch gets a dev tag.** CI runs
   ``clibra version --bump`` to compute the next dev prerelease, and tags the
   commit it just tested. Stable ``v1.4.2`` bumps to ``v1.4.3-dev.1``; each
   subsequent bump advances the counter: ``v1.4.3-dev.2``, ``v1.4.3-dev.3``, ...

   .. code-block:: bash

      git fetch --tags          # --bump only sees local tags
      NEXT="v$(clibra version --bump)"
      git tag -a "$NEXT" -m "dev release $NEXT" "$GITHUB_SHA"
      git push origin "refs/tags/$NEXT"

#. **Stable releases are tagged by hand.** When you decide ``v1.4.3`` is ready,
   tag the tested commit on your release branch as ``v1.4.3``. Nothing is
   committed; the next ``--bump`` then starts ``v1.4.4-dev.1``.

#. **Downstream projects pin dev tags for co-development and stable tags for
   everything else** (see :ref:`concepts/versioning/consuming`).

Because every dev tag has lower precedence than the stable tag it leads to,
anything that orders by SemVer (CPM, Conan, package managers) does the right
thing. ``clibra version --check`` is available as a CI gate to assert that a
build resolved to the version you expected. See :ref:`cli/reference/version`
for the command, and :ref:`reference/versioning/bump` for the exact bump rules,
including how ``-alpha``/``-rc`` style prereleases are handled.

.. _concepts/versioning/libra-self:

LIBRA's own version
===================

:cmake:variable:`LIBRA_VERSION` is the version of LIBRA itself. It is set
automatically by ``include(libra/project)``; you never need to call anything.
It appears in the ``This is LIBRA v...`` configure message, and is what to
quote in bug reports.

It is kept separate from your project's version because both are in scope at
once, and because LIBRA's version needs to be correct in situations where your
project's version doesn't matter -- in particular, when LIBRA is installed or
packaged and there is no git repository to ask.

That difference drives the resolution order. For your project, the live git
state is authoritative: you are building a checkout, and the checkout is what
you want described. For LIBRA, a *packaged artifact* is authoritative about what
it contains, so a version baked into the artifact wins over git:

#. **Baked version.** Artifacts that can't carry a ``.git`` directory have the
   version written into ``cmake/libra/self.cmake`` when they are produced. A
   Conan package gets this in its ``package()`` step.

#. **Git in LIBRA's own checkout.** A CPM fetch, a git submodule, or a
   development clone. Git is only trusted if the repository it finds is rooted
   exactly at LIBRA's directory, so a copy of LIBRA without its own ``.git``
   sitting inside your repository reports ``0.0.0`` rather than *your* tags.

#. ``0.0.0`` otherwise.

Unlike your project's version, an untagged LIBRA commit produces no warning:
that is the normal state when developing LIBRA and a project together via a
local source override. See :ref:`reference/versioning/libra-version` for what
each consumption mode resolves to.

LIBRA's own release process is the workflow in
:ref:`concepts/versioning/workflow`: every green push to ``devel`` is tagged
``vX.Y.Z-dev.N`` by CI, and stable ``vX.Y.Z`` tags are created on ``master`` by
a manually-dispatched release workflow. So ``devel`` builds report something
like ``0.13.13-dev.2``, and a commit past it reports
``0.13.13-dev.2+3.g5f7115c``.

.. _concepts/versioning/consuming:

Consuming versioned dependencies with CPM
=========================================

When one LIBRA-versioned project depends on another, CPM's ``GIT_TAG`` and
``VERSION`` parameters serve different purposes and should both be supplied:

.. code-block:: cmake

   CPMAddPackage(
     NAME    mydep
     GIT_TAG v1.5.0-dev.3   # what to fetch: the full tag
     VERSION 1.5.0          # deduplication key: numeric only
   )

``GIT_TAG`` is the git ref to fetch, and takes the full tag including any
prerelease suffix. ``VERSION`` is the key CPM uses to decide whether two
requests for the same dependency are compatible. It must be purely numeric:
a prerelease string produces a parse warning and can cause incorrect
deduplication when multiple packages request the same dependency. This is the
same numeric/full split as :cmake:variable:`LIBRA_PROJECT_VERSION_NUMERIC` and
:cmake:variable:`LIBRA_PROJECT_VERSION`.

For stable builds, pin stable tags:

.. code-block:: cmake

   CPMAddPackage(NAME mydep GIT_TAG v1.5.0 VERSION 1.5.0)

For active co-development, pin a dev tag explicitly, and move the pin forward as
the dependency's dev stream advances:

.. code-block:: cmake

   CPMAddPackage(NAME mydep GIT_TAG v1.5.0-dev.3 VERSION 1.5.0)

To use a locally installed package in preference to fetching:

.. code-block:: bash

   cmake -DCPM_USE_LOCAL_PACKAGES=ON \
         -DCMAKE_PREFIX_PATH=/path/to/install \
         ...

With ``CPM_USE_LOCAL_PACKAGES=ON``, CPM attempts ``find_package()`` before
fetching from git; ``GIT_TAG`` and ``VERSION`` are only used if the local
package is not found.
