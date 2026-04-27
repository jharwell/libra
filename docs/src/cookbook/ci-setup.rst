
.. SPDX-License-Identifier: MIT

.. _cookbook/ci-setup:

========
CI setup
========

Complete pipeline configurations for GitHub Actions and GitLab CI.
The pipelines implement the standard LIBRA workflow: build → test →
coverage check → analysis, with analysis as a separate job.

Prerequisite: add workflow and analyze presets
===============================================

The CI pipelines assume your ``CMakePresets.json`` includes ``ci``,
``coverage``, and ``analyze`` presets. If you used the starting-point
hierarchy from :ref:`concepts/project-setup/presets` you already have
these. If not, add them:

.. code-block:: json

   {
     "configurePresets": [
       {
         "name": "ci",
         "inherits": "base",
         "cacheVariables": {
           "CMAKE_BUILD_TYPE": "Debug",
           "LIBRA_TESTS":    "ON",
           "LIBRA_COVERAGE": "ON"
         }
       },
       {
         "name": "analyze",
         "inherits": "base",
         "cacheVariables": {
           "CMAKE_BUILD_TYPE": "Debug",
           "LIBRA_ANALYSIS":  "ON",
           "LIBRA_USE_COMPDB": "YES"
         }
       }
     ],
     "buildPresets": [
       { "name": "ci",      "configurePreset": "ci" },
       { "name": "analyze", "configurePreset": "analyze",
         "targets": ["analyze"] }
     ],
     "testPresets": [
       {
         "name": "ci",
         "configurePreset": "ci",
         "output": { "outputOnFailure": true }
       }
     ],
     "workflowPresets": [
       {
         "name": "ci",
         "steps": [
           { "type": "configure", "name": "ci" },
           { "type": "build",     "name": "ci" },
           { "type": "test",      "name": "ci" },
           { "type": "build",     "name": "ci",
             "targets": ["gcovr-check"] }
         ]
       }
     ]
   }

GitHub Actions
==============

Two jobs: ``ci`` (build + test + coverage) and ``analyze`` (static
analysis). Analysis runs in parallel with CI but does not block
deployment — adjust ``needs:`` to change this.

.. code-block:: yaml

   name: CI

   on:
     push:
       branches: [main]
     pull_request:

   jobs:
     ci:
       name: Build, test, coverage
       runs-on: ubuntu-latest

       steps:
         - uses: actions/checkout@v4

         - name: Install dependencies
           run: |
             sudo apt-get update
             sudo apt-get install -y \
               cmake ninja-build gcovr \
               gcc g++

         - name: Install clibra
           run: cargo install clibra

         - name: Run CI pipeline
           run: clibra ci --preset ci

         # --- OR without clibra ---
         # - name: Configure
         #   run: cmake --preset ci
         # - name: Build
         #   run: cmake --build --preset ci
         # - name: Test
         #   run: ctest --preset ci
         # - name: Coverage check
         #   run: cmake --build --preset ci --target gcovr-check

     analyze:
       name: Static analysis
       runs-on: ubuntu-latest

       steps:
         - uses: actions/checkout@v4

         - name: Install dependencies
           run: |
             sudo apt-get update
             sudo apt-get install -y \
               cmake ninja-build \
               clang clang-tidy clang-format \
               cppcheck

         - name: Install clibra
           run: cargo install clibra

         - name: Run analysis
           run: clibra analyze --preset analyze

         # --- OR without clibra ---
         # - name: Configure
         #   run: cmake --preset analyze
         # - name: Analyze
         #   run: cmake --build --preset analyze

.. note::

   ``cargo install clibra`` compiles from source and takes ~60 seconds
   on first run. See :ref:`getting-started/installation` for caching
   tips to speed up subsequent CI runs.

GitLab CI
=========

Equivalent pipeline using GitLab CI/CD. Uses a Docker image to avoid
installing dependencies on every run.

.. code-block:: yaml

   stages:
     - build
     - test
     - quality

   variables:
     CMAKE_BUILD_PARALLEL_LEVEL: "$(nproc)"

   default:
     image: ubuntu:24.04
     before_script:
       - apt-get update -qq
       - apt-get install -y -qq
           cmake ninja-build curl
           gcc g++ gcovr

   ci:
     stage: build
     script:
       - cmake --preset ci
       - cmake --build --preset ci
       - ctest --preset ci
       - cmake --build --preset ci --target gcovr-check
     artifacts:
       reports:
         junit: build/ci/test-results.xml
       paths:
         - build/ci/coverage/

   analyze:
     stage: quality
     before_script:
       - apt-get update -qq
       - apt-get install -y -qq
           cmake ninja-build
           clang clang-tidy clang-format cppcheck
     script:
       - cmake --preset analyze
       - cmake --build --preset analyze
     allow_failure: true   # analysis failures block MR but not deployment

   # With clibra installed:
   # ci:
   #   script:
   #     - cargo install clibra
   #     - clibra ci --preset ci
   #
   # analyze:
   #   script:
   #     - cargo install clibra
   #     - clibra analyze --preset analyze

Coverage reporting
==================

To upload coverage results to a service like Codecov or Coveralls,
add a step after the coverage check:

.. code-block:: yaml

   # GitHub Actions — Codecov
   - name: Upload coverage
     uses: codecov/codecov-action@v4
     with:
       files: build/ci/coverage/coverage.xml
       fail_ci_if_error: true

Generate the XML report instead of (or alongside) the HTML report by
adding ``gcovr-xml`` to the workflow preset's ``gcovr-check`` build
step, or by running:

.. tab-set::

   .. tab-item:: CLI

      .. code-block:: bash

         clibra coverage --preset ci --format xml

   .. tab-item:: CMake

      .. code-block:: bash

         cmake --build --preset ci --target gcovr-xml

Coverage thresholds are configured in ``project-local.cmake`` via
:cmake:variable:`LIBRA_GCOVR_LINES_THRESH`,
:cmake:variable:`LIBRA_GCOVR_FUNCTIONS_THRESH`, and
:cmake:variable:`LIBRA_GCOVR_BRANCHES_THRESH`. See
:ref:`cookbook/coverage` for details.
