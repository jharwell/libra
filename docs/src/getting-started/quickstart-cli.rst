.. SPDX-License-Identifier: MIT

.. _getting-started/quickstart-cli:

==================
Quickstart — CLI
==================

This page gets you to a working build in under five minutes. For a
complete walkthrough including tests, coverage, and analysis, see
:ref:`cookbook/new-project`.

If you have not installed ``clibra`` yet, start at
:ref:`getting-started/installation`.


1. Set up your project
======================

You must define:

.. tab-set::

   .. tab-item:: CMakeLists.txt:

      .. include:: /src/integrate-cpm.rst

      For other integration methods (Conan, installed package, submodule), see
      :ref:`concepts/project-setup/integration`.

   .. tab-item:: cmake/project-local.cmake:

      .. include:: /src/ex-project-local.rst

Optionally, you can define:

.. dropdown:: CMakePresets.json:

   .. code-block:: json

      {
        "version": 6,
        "configurePresets": [
          {
            "name": "base",
            "hidden": true,
            "generator": "Ninja",
            "binaryDir": "${sourceDir}/build/${presetName}",
            "cacheVariables": {
              "LIBRA_TESTS": "OFF", "LIBRA_CODE_COV": "OFF",
              "LIBRA_ANALYSIS": "OFF", "LIBRA_DOCS": "OFF"
            }
          },
          {
            "name": "debug",
            "inherits": "base",
            "cacheVariables": { "CMAKE_BUILD_TYPE": "Debug", "LIBRA_TESTS": "ON" }
          }
        ],
        "buildPresets": [{ "name": "debug", "configurePreset": "debug" }],
        "testPresets": [{ "name": "debug", "configurePreset": "debug",
                          "output": { "outputOnFailure": true } }]
      }

3. Build and test
=================

.. code-block:: bash

   clibra build --preset debug   # configure + build
   clibra test  --preset debug   # build tests + run

4. Inspect your build
=====================

.. code-block:: bash

   clibra doctor   # check tool availability
   clibra info     # show feature flags and available targets

Troubleshooting
===============

See :ref:`getting-started/troubleshooting` for common errors.

Next steps
==========

- **Complete new-project walkthrough**: :ref:`cookbook/new-project`
- **Full CLI reference**: :ref:`cli/reference`
- **Preset configuration**: :ref:`cli/presets`
- **CMake variables**: :ref:`reference/variables`
