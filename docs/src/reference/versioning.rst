.. SPDX-License-Identifier: MIT

.. _reference/versioning:

====================
Versioning reference
====================

Exact resolution rules, version string formats, and variables for LIBRA's
versioning. For the model behind them -- why tags, why two versions, and a
recommended release workflow -- see :ref:`concepts/versioning`.

.. _reference/versioning/tags:

Tag grammar
===========

A version tag is an optional ``v`` followed by a SemVer core and optional
prerelease::

  v?MAJOR.MINOR.PATCH(-PRERELEASE)?

where ``PRERELEASE`` starts with an alphanumeric and contains only
alphanumerics, ``.``, ``_``, and ``-``. Build metadata (``+...``) is not
allowed in tags; LIBRA adds its own for untagged commits.

.. list-table::
   :header-rows: 1
   :widths: 30 25 25

   * - Tag
     - Numeric
     - Prerelease
   * - ``v1.5.0``
     - ``1.5.0``
     - (empty)
   * - ``v1.5.0-dev.3``
     - ``1.5.0``
     - ``dev.3``
   * - ``v1.5.0-rc.1``
     - ``1.5.0``
     - ``rc.1``
   * - ``v1.5.0-rc-1``
     - ``1.5.0``
     - ``rc-1``

.. NOTE:: The CMake resolver accepts tags with or without the leading ``v``,
   but ``clibra version --bump`` only considers ``v``-prefixed tags. Use the
   ``v`` prefix everywhere.

.. WARNING:: ``git describe`` returns the nearest tag of *any* name. If the
   nearest tag to an untagged commit doesn't match this grammar (e.g.
   ``nightly``), resolution fails with an ``unrecognized git describe format``
   warning and falls through to ``0.0.0``, even if an older valid tag exists.
   Don't mix non-version tags into a branch whose version LIBRA resolves.

.. _reference/versioning/formats:

Version string formats
======================

The full version (:cmake:variable:`LIBRA_PROJECT_VERSION`,
:cmake:variable:`LIBRA_VERSION`) is a valid SemVer 2.0 string with no leading
``v``. On an untagged commit, the distance from the nearest tag and the
abbreviated commit hash are appended as build metadata, ``+<distance>.g<sha>``:

.. list-table::
   :header-rows: 1
   :widths: 40 30 30

   * - Git state
     - Full version
     - Numeric version
   * - ``HEAD`` tagged ``v1.5.0``
     - ``1.5.0``
     - ``1.5.0``
   * - ``HEAD`` tagged ``v1.5.0-dev.3``
     - ``1.5.0-dev.3``
     - ``1.5.0``
   * - 5 commits past ``v1.5.0``
     - ``1.5.0+5.g230f029``
     - ``1.5.0``
   * - 5 commits past ``v1.5.0-dev.3``
     - ``1.5.0-dev.3+5.g230f029``
     - ``1.5.0``
   * - Nothing resolvable
     - ``0.0.0``
     - ``0.0.0``

Per SemVer, build metadata does not affect precedence: ``1.5.0+5.g230f029``
sorts equal to ``1.5.0``.

.. _reference/versioning/project-version:

Project version resolution
==========================

:cmake:command:`libra_extract_version` resolves the calling project's version
by trying each tier in order and stopping at the first that succeeds. Git is
run in ``CMAKE_CURRENT_SOURCE_DIR`` of the caller, and is allowed to find a
repository in any parent directory.

.. list-table::
   :header-rows: 1
   :widths: 5 30 35 30

   * - #
     - Tier
     - Source
     - Diagnostics
   * - 1
     - Exact tag on ``HEAD``
     - ``git describe --exact-match --tags``
     - ``STATUS`` message
   * - 2
     - Untagged commit
     - ``git describe --tags --long``
     - ``WARNING``: not releasable
   * - 3
     - Baked version (**LIBRA only**)
     - ``cmake/libra/self.cmake``; only when the calling project *is* LIBRA
     - ``STATUS`` message
   * - 4
     - Nothing available
     - ``0.0.0``
     - ``WARNING``

Any git failure (git not installed, not a repository, no tags, shallow clone
with no reachable tag) is treated as "unavailable" and falls through to the next
tier.

**Scope.** When called from the top-level ``CMakeLists.txt``, the results are
written as ``INTERNAL`` cache variables, which is where ``clibra version`` reads
them. When called from a subproject (e.g. a dependency brought in with
``add_subdirectory()`` that also calls it), the results are set as normal
variables in that subproject's directory scope only, so each project sees its
own version and the cache keeps the top-level project's.

.. _reference/versioning/libra-version:

LIBRA version resolution
========================

:cmake:variable:`LIBRA_VERSION` is resolved by
:cmake:command:`libra_resolve_self_version`, which ``include(libra/project)``
calls automatically. It never emits warnings.

.. list-table::
   :header-rows: 1
   :widths: 5 40 55

   * - #
     - Tier
     - Notes
   * - 1
     - Baked version in ``cmake/libra/self.cmake``
     - Used if the file exists and contains a real version. An unexpanded
       ``$Format:...$`` placeholder counts as absent.
   * - 2
     - Git in LIBRA's own directory
     - Same exact-tag / describe logic as the project version, but only if
       ``git rev-parse --show-toplevel`` is *exactly* LIBRA's root, so an
       enclosing repository is never consulted.
   * - 3
     - ``0.0.0``
     -

What that means for each way of consuming LIBRA:

.. list-table::
   :header-rows: 1
   :widths: 35 20 45

   * - Consumption mode
     - Tier used
     - Example ``LIBRA_VERSION``
   * - Conan package
     - 1 (baked)
     - ``0.13.13-dev.2``, frozen at ``conan export`` time
   * - CPM git fetch, git submodule, development clone
     - 2 (git)
     - ``0.13.13-dev.2``, or ``0.13.13-dev.2+3.g5f7115c`` past a tag
   * - ``git archive`` tarball
     - 1 if ``self.cmake`` was expanded via ``export-subst``, else 3
     - ``0.13.13-dev.2``, or ``0.0.0``
   * - ``cmake --install`` of LIBRA
     - 3
     - ``0.0.0`` (installed trees carry neither ``.git`` nor a baked
       ``self.cmake``)
   * - Copy of LIBRA without its own ``.git``
     - 3
     - ``0.0.0``

.. _reference/versioning/bump:

Bump rules
==========

``clibra version --bump`` prints the next development version; it does not
create or push tags. It takes the highest ``v``-prefixed SemVer tag in the
local repository by SemVer precedence -- *not* the nearest reachable one, see
:ref:`concepts/versioning/two-questions` -- and applies:

.. list-table::
   :header-rows: 1
   :widths: 30 30 40

   * - Highest tag
     - Next version
     - Why
   * - ``v1.2.3``
     - ``1.2.4-dev.1``
     - Stable: start a dev stream toward the next patch.
   * - ``v1.2.4-dev.4``
     - ``1.2.4-dev.5``
     - Continue the dev stream.
   * - ``v1.2.4-alpha.1``, ``v1.2.4-beta.2``
     - ``1.2.4-dev.1``
     - ``alpha``/``beta`` sort below ``dev``, so a dev stream on the same
       numeric still moves forward.
   * - ``v1.2.4-rc.1``
     - ``1.2.5-dev.1``
     - ``rc`` sorts above ``dev``; ``1.2.4-dev.1`` would go backwards.
   * - (no tags)
     - ``0.0.1-dev.1``
     - Bootstrap.

The result always has strictly higher SemVer precedence than its input. Because
only local tags are considered, run ``git fetch --tags`` first (or use
``fetch-depth: 0`` on shallow CI checkouts); a tag that exists only on the
remote is invisible, and the collision surfaces when ``git push`` rejects the
duplicate tag.

To move to a new minor or major version, create the first tag of the new
series by hand (e.g. ``v1.3.0-dev.1`` or ``v2.0.0``); subsequent bumps continue
from it.


.. _reference/versioning/functions:

API
===

.. cmake-module:: ../../../cmake/libra/version.cmake
