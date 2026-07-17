.. SPDX-License-Identifier: MIT

.. _concepts/feature-flags:

=============
Feature flags
=============

LIBRA features are controlled by ``LIBRA_*`` CMake cache variables. This
page explains the mental model — what they are, how they interact with
presets, and the patterns that make them predictable. For the full
variable reference, see :ref:`reference/variables`.

What feature flags are
======================

Each ``LIBRA_*`` variable controls a specific capability. Setting
``LIBRA_TESTS=ON`` at configure time causes LIBRA to:

- discover test files under ``tests/``
- register them with CTest
- create the ``all-tests``, ``unit-tests``, ``integration-tests``,
  ``regression-tests``, and ``build-and-test`` targets

Setting it to ``OFF`` means none of those targets exist in the build.
This is the general pattern: flags gate both the behaviour and the
targets. A target that requires a disabled flag is not merely
non-functional — it does not exist, and attempting to build it produces
a clear error.

The same flag also serves as the guard that ``clibra`` checks before
running a subcommand. ``clibra test`` reads ``LIBRA_TESTS`` from the
CMake cache of the resolved build directory and fails early with an
actionable message if it is ``OFF``, rather than letting the build fail
mid-way with a cryptic "no rule to make target" error.

The explicit-off pattern
========================

The recommended preset hierarchy (see :ref:`concepts/project-setup/presets`)
uses a ``base`` hidden preset that sets every ``LIBRA_*`` flag to its
default/off state explicitly.  Every other preset inherits from ``base`` and
enables only what it needs. This matters because CMake preset inheritance is
additive — a child preset that does not mention a variable inherits its parent's
value. Without ``base`` setting everything off, a ``coverage`` preset inheriting
from ``debug`` might silently inherit ``LIBRA_ANALYSIS=ON`` from some ancestor
and run analysis on every coverage build.

The explicit-off pattern makes every preset self-describing: reading a
preset's ``cacheVariables`` tells you exactly what is enabled, with no
hidden inherited state.

How flags interact with presets
================================

Feature flags live in the CMake cache of a configured build directory.
They are set at configure time and do not change between builds unless
you reconfigure. This means:

- ``clibra build --preset debug`` and ``clibra test --preset debug``
  use the same cache — the flags are shared across all commands that
  resolve to the same preset.

- Changing a flag requires a reconfigure: ``clibra build --preset debug
  --reconfigure -DLIBRA_TESTS=ON``, or by updating the preset's
  ``cacheVariables`` and running a fresh configure.

- Different presets have independent caches in independent build
  directories (when using ``${presetName}`` in ``binaryDir``). Switching
  from ``debug`` to ``coverage`` means switching to a different build
  directory, not reconfiguring the same one.

Checking flag state
===================

To see which flags are active in the current build:

.. code-block:: bash

   clibra info               # shows LIBRA feature flags section
   clibra info --build       # build configuration only

Or directly from the CMake cache:

.. code-block:: bash

   cmake -LA -N build/<preset>/CMakeCache.txt | grep LIBRA_  # variable values
   grep LIBRA_ build/<preset>/CMakeCache.txt

.. _concepts/feature-flags/named-presets:

Recommended named presets and their rationale
==============================================

The recommended hierarchy (see :ref:`concepts/project-setup/presets` for
the JSON) defines a small set of named presets. Each exists as a
first-class named preset — rather than a runtime flag — so that it appears
in IDE preset pickers and can be driven by plain ``cmake`` as well as
``clibra``.

.. list-table::
   :header-rows: 1
   :widths: 22 30 48

   * - Preset
     - Sets
     - Why it is a separate preset

   * - ``base`` (hidden)
     - Generator ``Ninja``; every ``LIBRA_*`` flag off
     - Never used directly; always inherited. Guarantees each child is
       fully self-describing with no stray inherited flags.

   * - ``debug``
     - ``CMAKE_BUILD_TYPE=Debug``, ``LIBRA_TESTS=ON``
     - The everyday development preset. Tests are on because that is the
       most common iteration loop.

   * - ``release``
     - ``CMAKE_BUILD_TYPE=Release``, ``LIBRA_LTO=ON``
     - Portable optimised build. LTO is almost always wanted for a release
       binary and has no portability cost.

   * - ``native-release``
     - inherits ``release`` + ``LIBRA_OPT_NATIVE=ON``
     - A ``native-release`` binary is not portable across CPU
       microarchitectures, so it must never be the default release preset
       for a distributed build.

   * - ``asan`` / ``tsan`` / ``msan``
     - inherit ``debug`` + ``LIBRA_SAN=<value>``
     - ``msan`` also sets ``LIBRA_STDLIB=CXX`` because MSan needs an
       instrumented standard library. First-class named presets so they
       appear in IDE pickers.

   * - ``coverage``
     - inherits ``debug`` + ``LIBRA_COVERAGE=ON``
     - Coverage instrumentation changes build output (object files are not
       reusable between coverage and non-coverage builds), so it warrants
       its own build directory.

   * - ``ci``
     - inherits ``debug`` + ``LIBRA_COVERAGE=ON``
     - Nearly identical to ``coverage`` today, but kept separate
       intentionally so CI can diverge over time (e.g. adding analysis)
       without coupling the two. The current ``ci`` preset does *not*
       enable ``LIBRA_ANALYSIS=ON``; analysis is slow and belongs in a
       distinct CI job.

   * - ``analyze``
     - inherits ``debug`` + ``LIBRA_ANALYSIS=ON``, ``LIBRA_USE_COMPDB=YES``
     - Its build preset pins ``"targets": ["analyze"]`` so
       ``cmake --build --preset analyze`` runs analysis directly without
       building the full project first.

   * - ``fortify``
     - inherits ``release`` + ``LIBRA_FORTIFY=ALL``
     - Release build with all hardening options. Separate because
       fortification can affect ABI and is not universally appropriate.

   * - ``valgrind``
     - inherits ``debug`` + ``LIBRA_VALGRIND_COMPAT=ON``
     - Valgrind-compatible codegen (disabling SSE/AVX) affects the whole
       binary; its output is not interchangeable with a normal debug build.

   * - ``pgo-gen`` / ``pgo-use``
     - inherit ``release``; set ``LIBRA_PGO=GEN`` (+ ``LIBRA_LTO=OFF``) /
       ``LIBRA_PGO=USE``
     - Two-phase PGO. Kept as composable presets rather than one
       ``performance`` preset, which would conflate native-opt, LTO, and
       PGO — three independent concerns.

   * - ``docs``
     - ``CMAKE_BUILD_TYPE=Debug``, ``LIBRA_DOCS=ON``, ``LIBRA_TESTS=OFF``
     - Keeps documentation builds isolated from build artifacts that have
       different caching properties.
