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

.. list-table:: Feature flags and what they enable
   :header-rows: 1
   :widths: 30 20 50

   * - Flag
     - Default
     - Enables

   * - :cmake:variable:`LIBRA_TESTS`
     - ``OFF``
     - Test discovery, CTest registration, test build targets

   * - :cmake:variable:`LIBRA_CODE_COV`
     - ``OFF``
     - Coverage instrumentation, ``gcovr-*`` and ``llvm-*`` targets

   * - :cmake:variable:`LIBRA_ANALYSIS`
     - ``OFF``
     - Static analysis and formatting targets (clang-tidy, cppcheck, etc.)

   * - :cmake:variable:`LIBRA_DOCS`
     - ``OFF``
     - Documentation build targets (``apidoc``, ``sphinxdoc``)

   * - :cmake:variable:`LIBRA_SAN`
     - ``NONE``
     - Runtime sanitizer instrumentation (ASAN, UBSAN, TSAN, MSAN)

   * - :cmake:variable:`LIBRA_LTO`
     - ``OFF``
     - Link-time optimisation

   * - :cmake:variable:`LIBRA_FORTIFY`
     - ``NONE``
     - Security hardening (stack protection, ``_FORTIFY_SOURCE``, etc.)

   * - :cmake:variable:`LIBRA_PGO`
     - ``NONE``
     - Profile-guided optimisation (``GEN`` or ``USE`` phase)

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
