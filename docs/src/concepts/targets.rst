.. SPDX-License-Identifier: MIT

.. _concepts/targets:

=======
Targets
=======

LIBRA injects build targets into your project at configure time. This
page explains how targets are organised, the availability model, and
how to discover what is enabled in a given build. For the full target
reference, see :ref:`reference/targets`.

Target groups
=============

LIBRA targets are organised into feature groups. Every target in a
group requires the same feature flag to be enabled:

.. list-table::
   :header-rows: 1
   :widths: 20 20 60

   * - Group
     - Required flag
     - Key targets

   * - **Tests**
     - :cmake:variable:`LIBRA_TESTS`
     - ``all-tests``, ``unit-tests``, ``integration-tests``,
       ``regression-tests``, ``build-and-test``

   * - **Coverage**
     - :cmake:variable:`LIBRA_CODE_COV`
     - ``gcovr-report``, ``gcovr-check``, ``llvm-report``,
       ``llvm-summary``, ``lcov-report``

   * - **Analysis**
     - :cmake:variable:`LIBRA_ANALYSIS`
     - ``analyze``, ``analyze-clang-tidy``, ``analyze-cppcheck``,
       ``analyze-clang-format``, ``format``, ``fix-clang-tidy``

   * - **Docs**
     - :cmake:variable:`LIBRA_DOCS`
     - ``apidoc``, ``sphinxdoc``, ``apidoc-check-doxygen``,
       ``apidoc-check-clang``

Targets are only defined for the top-level CMake ``project()``. Dependent
sub-projects that also use LIBRA are not affected.

The availability model
======================

A target's existence depends on two conditions being true simultaneously:

1. The required feature flag is ``ON`` in the CMake cache.
2. The tools needed to run the target are present on the system.

A target that fails either condition does not exist — it is not merely
disabled, it is absent from the build system entirely. This is
intentional: attempting to build a non-existent target fails immediately
with a clear message rather than silently doing nothing.

The reason for tool-based availability is that LIBRA enables only the
analysis tools it can actually find. If ``cppcheck`` is not on ``PATH``,
the ``analyze-cppcheck`` target is not created, but ``analyze-clang-tidy``
(if ``clang-tidy`` is present) is. The umbrella ``analyze`` target runs
whatever tool targets exist. This makes builds portable across machines
with different tool installations without requiring any configuration
changes.

Discovering available targets
==============================

Two ways to see what targets exist in a configured build:

``clibra info`` — the richest view. Shows each target grouped by
feature area with its availability status and, for unavailable targets,
the exact reason:

.. code-block:: text

   Available LIBRA targets

     Tests
       all-tests .............. YES
       unit-tests ............. YES
       build-and-test ......... YES

     Coverage
       gcovr-report ........... NO  (LIBRA_CODE_COV is OFF)
       llvm-report ............ NO  (LIBRA_CODE_COV is OFF)

     Analysis
       analyze ................ NO  (LIBRA_ANALYSIS is OFF)
       analyze-clang-tidy ..... NO  (LIBRA_ANALYSIS is OFF)

     Docs
       apidoc ................. NO  (doxygen not found)
       sphinxdoc .............. YES

``help-targets`` CMake target — the same information, directly from
the build system:

.. code-block:: bash

   cmake --build build --target help-targets

Targets are only for the top-level project
==========================================

LIBRA only creates targets for the project that includes it at the top
level. If your project has dependencies that also use LIBRA internally,
those dependencies do not get LIBRA targets injected — only your root
project does. This prevents LIBRA's quality-gate targets from
propagating into dependency builds and causing unexpected failures in
code you don't own.
