.. SPDX-License-Identifier: MIT

.. _getting-started/quickstart-cmake:

=======================
Quickstart — CMake only
=======================

This page gets you to a working build using plain CMake. For a
complete walkthrough, see :ref:`cookbook/new-project`. To add LIBRA
to an existing project, see :ref:`cookbook/existing-project`.

If you have Rust installed and want shorter commands for day-to-day
work, see :ref:`getting-started/quickstart-cli`. The project structure
and ``CMakePresets.json`` are identical — the CLI can be added at any
time.

1. Set up your project
======================

See :ref:`concepts/project-setup` for all integration methods, layout
conventions, and the recommended preset hierarchy. The minimum:

.. tab-set::

   .. tab-item:: CMakeLists.txt:

      .. include:: /src/integrate-cpm.rst


   .. tab-item:: cmake/project-local.cmake:

      .. include:: /src/ex-project-local.rst

2. Configure and build
======================

You can use any preset you have defined, not just "debug"; see
:ref:`concepts/project-setup/presets` for more info about CMake presets.

.. tab-set::

   .. tab-item:: With presets

      .. code-block:: bash

         cmake --preset debug
         cmake --build --preset debug -j$(nproc)

   .. tab-item:: Without presets

      .. code-block:: bash

         cmake -B build -DCMAKE_BUILD_TYPE=Debug
         cmake --build build -j$(nproc)

3. Run tests
============

.. code-block:: bash

   cmake --build --preset debug --target all-tests
   ctest --preset debug --output-on-failure

4. What's available
====================

.. code-block:: bash

   cmake --build --preset debug --target help-targets

Troubleshooting
===============

See :ref:`getting-started/troubleshooting`.

Next steps
==========

- **Complete new-project walkthrough**: :ref:`cookbook/new-project`
- **Add LIBRA to an existing project**: :ref:`cookbook/existing-project`
- **Variable reference**: :ref:`reference/variables`
- **Target reference**: :ref:`reference/targets`
