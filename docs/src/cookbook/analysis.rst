.. SPDX-License-Identifier: MIT

.. _cookbook/analysis:

===============
Static analysis
===============

This page covers running LIBRA's static analysis tools: running all
tools or a single tool, auto-fixing warnings, suppressing noise,
and configuring clang-tidy check categories.

For conceptual background on how LIBRA uses a compilation database, language
detection, and header coverage, see :ref:`concepts/analysis`. For the target
reference, see :ref:`reference/targets`. For the flag reference, see
:ref:`cli/reference/analyze`.

1. Add an analyze preset
=========================

Analysis should run in its own preset and build directory, separate
from debug builds:

.. code-block:: json

   {
     "configurePresets": [
       {
         "name": "analyze",
         "inherits": "base",
         "cacheVariables": {
           "CMAKE_BUILD_TYPE": "Debug",
           "LIBRA_ANALYSIS":  "ON"
         }
       }
     ],
     "buildPresets": [
       {
         "name": "analyze",
         "configurePreset": "analyze",
         "targets": ["analyze"]
       }
     ]
   }

Setting ``"targets": ["analyze"]`` in the build preset means
``cmake --build --preset analyze`` runs analysis directly without
building the full project first.

2. Run all tools
=================

.. tab-set::

   .. tab-item:: CLI

      .. code-block:: bash

         clibra analyze --preset analyze

   .. tab-item:: CMake

      .. code-block:: bash

         cmake --preset analyze
         cmake --build --preset analyze --target analyze

Only tools found on ``PATH`` are run. If ``cppcheck`` is not
installed, ``analyze-cppcheck`` does not exist and is silently skipped
by the umbrella ``analyze`` target. Run ``clibra info`` or
``cmake --build --preset analyze --target help-targets`` to see which
tools are available.

3. Run a single tool
=====================

.. tab-set::

   .. tab-item:: CLI

      .. code-block:: bash

         clibra analyze clang-tidy   --preset analyze

   .. tab-item:: CMake

      .. code-block:: bash

         cmake --build --preset analyze --target analyze-clang-tidy

4. Auto-fix warnings
====================

.. tab-set::

   .. tab-item:: CLI

      .. code-block:: bash

         clibra analyze --fix --preset analyze       # all auto-fixers
         clibra analyze clang-tidy --fix --preset analyze

   .. tab-item:: CMake

      .. code-block:: bash

         cmake --build --preset analyze --target fix
         cmake --build --preset analyze --target fix-clang-tidy
         cmake --build --preset analyze --target fix-clang-check


5. Run a specific clang-tidy check category
============================================

LIBRA creates per-category targets for each clang-tidy check group,
each of which enables only that category's checks via ``-*,+category.*``:

.. tab-set::

   .. tab-item:: CLI

      .. code-block:: bash

         clibra analyze clang-tidy-modernize     --preset analyze
         clibra analyze clang-tidy-bugprone      --preset analyze
         clibra analyze clang-tidy-readability   --preset analyze

   .. tab-item:: CMake

      .. code-block:: bash

         cmake --build --preset analyze --target analyze-clang-tidy-modernize
         cmake --build --preset analyze --target analyze-clang-tidy-bugprone

Available categories are listed in :ref:`reference/targets`. Run
``cmake --build --preset analyze --target help-targets`` to confirm
which are active in your build.

6. Suppress warnings
=====================

**cppcheck — inline suppression:**

.. code-block:: cpp

   // cppcheck-suppress uninitvar
   int x;

**cppcheck — file or pattern suppression** (in ``project-local.cmake``):

.. code-block:: cmake

   set(LIBRA_CPPCHECK_SUPPRESSIONS
       "uninitvar:src/generated.cpp"
       "syntaxError")

   set(LIBRA_CPPCHECK_IGNORES
       "src/third_party/")

**clang-tidy — disable checks within a category:**

Because LIBRA's per-category targets use ``-*`` to disable all
checks before enabling the category, suppressions in ``.clang-tidy``
have no effect on per-category targets. To disable specific checks
across all targets, use ``LIBRA_CLANG_TIDY_CHECKS_CONFIG`` in
``project-local.cmake``:

.. code-block:: cmake

   # Appended to --checks; must start with ","
   set(LIBRA_CLANG_TIDY_CHECKS_CONFIG
       ",-clang-diagnostic-*,-modernize-use-trailing-return-type")

**clang-tidy — NOLINT inline suppression:**

.. code-block:: cpp

   int x = getValue(); // NOLINT(readability-identifier-naming)

7. Supply your own tool config files
====================================

.. code-block:: cmake

   # In project-local.cmake
   set(LIBRA_CLANG_TIDY_FILEPATH
       ${CMAKE_SOURCE_DIR}/.clang-tidy)
