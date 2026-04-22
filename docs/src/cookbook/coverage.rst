.. SPDX-License-Identifier: MIT

.. _cookbook/coverage:

=============
Code coverage
=============

LIBRA supports three coverage toolchains: gcovr, lcov, and llvm-cov.
This page covers when to use each, how to configure thresholds, and
how to generate and view reports.

For the target reference, see :ref:`reference/targets`. For the flag
reference, see :ref:`cli/reference/coverage`.

Choosing a tool
===============

.. list-table::
   :header-rows: 1
   :widths: 20 20 60

   * - Tool
     - Format
     - Use when

   * - **gcovr**
     - GNU (GCC or Clang with ``-fprofile-arcs``)
     - You want threshold checking (``gcovr-check``) or fast HTML
       reports. Works with both GCC and Clang. The ``ci`` workflow
       uses ``gcovr-check`` by default.

   * - **lcov**
     - GNU
     - You need an *absolute* report that shows files with 0%
       coverage. ``gcovr-report`` only shows files that were executed;
       ``lcov-report`` shows everything.

   * - **llvm-cov**
     - LLVM native (Clang only)
     - You are building with Clang and want source-level coverage
       highlighting or integration with LLVM tooling.

Set :cmake:variable:`LIBRA_COVERAGE_NATIVE` to control which format
is generated. The default (``YES``) means GCC uses GNU format and
Clang uses LLVM format. Set it to ``NO`` to force GNU format from
both compilers.

1. Add a coverage preset
=========================

.. code-block:: json

   {
     "configurePresets": [
       {
         "name": "coverage",
         "inherits": "base",
         "cacheVariables": {
           "CMAKE_BUILD_TYPE": "Debug",
           "LIBRA_TESTS":    "ON",
           "LIBRA_COVERAGE": "ON"
         }
       }
     ],
     "buildPresets": [
       { "name": "coverage", "configurePreset": "coverage" }
     ],
     "testPresets": [
       {
         "name": "coverage",
         "configurePreset": "coverage",
         "output": { "outputOnFailure": true }
       }
     ]
   }

2. Configure thresholds
========================

Set these in ``cmake/project-local.cmake``. The ``gcovr-check`` target
fails if any threshold is not met:

.. code-block:: cmake

   set(LIBRA_GCOVR_LINES_THRESH     80)   # default: 95
   set(LIBRA_GCOVR_FUNCTIONS_THRESH 70)   # default: 60
   set(LIBRA_GCOVR_BRANCHES_THRESH  50)   # default: 50
   set(LIBRA_GCOVR_DECISIONS_THRESH 50)   # default: 50

Start with lower thresholds and raise them incrementally as you add
tests. Setting them too high initially makes CI fail immediately on a
new project.

3. Generate an HTML report
===========================

.. tab-set::

   .. tab-item:: CLI

      .. code-block:: bash

         clibra coverage --preset coverage          # generate report
         clibra coverage --preset coverage --open   # generate and open

      ``clibra coverage`` discovers the first available HTML target
      (``gcovr-report`` then ``llvm-report``) automatically.

   .. tab-item:: CMake (gcovr)

      .. code-block:: bash

         cmake --preset coverage
         cmake --build --preset coverage --target all-tests
         ctest --preset coverage
         cmake --build --preset coverage --target gcovr-report

      Report opens at ``build/coverage/coverage/index.html``.

   .. tab-item:: CMake (lcov, absolute)

      .. code-block:: bash

         cmake --preset coverage
         cmake --build --preset coverage --target all-tests
         cmake --build --preset coverage --target lcov-preinfo
         ctest --preset coverage
         cmake --build --preset coverage --target lcov-report

      ``lcov-preinfo`` must run before the tests to capture the 0%
      baseline. Omitting it produces a relative report identical to
      ``gcovr-report``.

   .. tab-item:: CMake (llvm-cov)

      Requires Clang and ``LIBRA_COVERAGE_NATIVE=YES`` (the default):

      .. code-block:: bash

         cmake --preset coverage
         cmake --build --preset coverage --target all-tests
         ctest --preset coverage
         cmake --build --preset coverage --target llvm-coverage

      ``llvm-coverage`` runs ``llvm-report`` (HTML) and
      ``llvm-summary`` (terminal) in sequence.

      .. warning::

         Run test binaries from the build directory root so that
         ``.profraw`` files land in ``PROJECT_BINARY_DIR``. ``llvm-profdata``
         looks for them there.

4. Check coverage thresholds
==============================

.. tab-set::

   .. tab-item:: CLI

      .. code-block:: bash

         clibra coverage --preset coverage --check

   .. tab-item:: CMake

      .. code-block:: bash

         cmake --build --preset coverage --target gcovr-check

The target exits non-zero if any threshold is not met, printing which
metric failed and by how much.

5. Full CI workflow
====================

The recommended CI coverage sequence:

.. tab-set::

   .. tab-item:: CLI

      .. code-block:: bash

         clibra ci --preset ci   # build + test + gcovr-check in one command

      Requires a ``ci`` workflow preset. See :ref:`cookbook/ci-setup`.

   .. tab-item:: CMake

      .. code-block:: bash

         cmake --preset ci
         cmake --build --preset ci --target all-tests
         ctest --preset ci
         cmake --build --preset ci --target gcovr-check
