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

You must define the CMake base layer:

.. tab-set::

   .. tab-item:: CMakeLists.txt:

      .. include:: /src/integrate-cpm.rst

      For other integration methods (Conan, installed package, submodule), see
      :ref:`concepts/project-setup/integration`.

   .. tab-item:: cmake/project-local.cmake:

      .. include:: /src/ex-project-local.rst

You also must define CMake presets; ``clibra`` is entirely preset driven:

.. dropdown:: CMakePresets.json:

   .. include:: /src/ex-cmake-presets.rst

2. Build and test
=================

.. code-block:: bash

   clibra build --preset debug   # configure + build
   clibra test  --preset debug   # build tests + run

3. Inspect your build
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
