.. SPDX-License-Identifier: MIT

.. _cookbook/analysis:

===============
Static analysis
===============

This page covers running LIBRA's formatting tools: running all
tools or a single tool, and checking formatting.

1. Add a format preset
======================

Formatting can run in its own preset and build directory, separate
from debug builds:

.. code-block:: json

   {
     "configurePresets": [
       {
         "name": "format",
         "inherits": "base",
         "cacheVariables": {
           "CMAKE_BUILD_TYPE": "Debug",
           "LIBRA_FORMAT":  "ON"
         }
       }
     ],
     "buildPresets": [
       {
         "name": "format",
         "configurePreset": "format",
         "targets": ["format"]
       }
     ]
   }

Setting ``"targets": ["format"]`` in the build preset means
``cmake --build --preset format`` runs format directly without
building the full project first.

2. Run all tools
=================

.. tab-set::

   .. tab-item:: CLI

      .. code-block:: bash

         clibra format --preset format

   .. tab-item:: CMake

      .. code-block:: bash

         cmake --preset format
         cmake --build --preset format --target format

For the full list of per-tool and per-category targets, see
:ref:`reference/targets`. Only tools found on ``PATH`` are run. Run ``clibra
info`` or ``cmake --build --preset format --target help-targets`` to see which
tools are available.

3. Check formatting
===================

.. tab-set::

   .. tab-item:: CLI

      .. code-block:: bash

         clibra format -c clang --preset format

   .. tab-item:: CMake

      .. code-block:: bash

         cmake --build --preset format --target format-check-clang


For the full list of per-tool and per-category targets, see
:ref:`reference/targets`.


4. Supply your own tool config files
====================================

.. code-block:: cmake

   # In project-local.cmake
   set(LIBRA_CLANG_FORMAT_FILEPATH
       ${CMAKE_SOURCE_DIR}/.clang-format)
