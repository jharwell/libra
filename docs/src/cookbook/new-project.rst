.. SPDX-License-Identifier: MIT

.. _cookbook/new-project:

=================
New project setup
=================

This guide walks through creating a LIBRA project from scratch. By the
end you will have a buildable project with tests, a working preset
hierarchy, and a ``project-local.cmake`` that registers your targets.

1. Create the project skeleton
==============================

.. code-block:: bash

   mkdir my_project && cd my_project
   git init

   mkdir -p src include tests cmake docs

Create ``CMakeLists.txt`` and ``cmake/project-local.cmake`` according to the
:ref:`concepts/project-setup/integration` and
:ref:`concepts/project-setup/project-local` respectively.  See also
:ref:`reference/project-local` for the full ``project-local.cmake`` API.

Optionally, create ``CMakePresets.json``/\ ``CMakeUserPresets.json``. See
:ref:`concepts/project-setup/presets` for details.

2. Add a source file
====================

.. code-block:: cpp

   // src/main.cpp
   #include <cstdio>
   int main() { std::puts("hello from LIBRA"); }

3. Build
========

.. tab-set::

   .. tab-item:: CLI

      .. code-block:: bash

         clibra build --preset debug

      On first run, ``clibra`` detects the missing build directory and
      runs configure automatically before building.

   .. tab-item:: CMake

      .. code-block:: bash

         cmake --preset debug
         cmake --build --preset debug -j$(nproc)

4. Verify with doctor / help-targets
====================================

.. tab-set::

   .. tab-item:: CLI

      .. code-block:: bash

         clibra doctor     # check tool availability
         clibra info       # show targets and feature flag state

   .. tab-item:: CMake

      .. code-block:: bash

         cmake --build --preset debug --target help-targets

5. Add tests
============

Create a test file following the naming convention:

.. code-block:: cpp

   // tests/main-utest.cpp
   #include <cassert>
   int main() { assert(1 + 1 == 2); }

Then build and run:

.. tab-set::

   .. tab-item:: CLI

      .. code-block:: bash

         clibra test --preset debug

   .. tab-item:: CMake

      .. code-block:: bash

         cmake --build --preset debug --target all-tests
         ctest --preset debug --output-on-failure

Next steps
==========

- Add a ``coverage`` preset and generate reports: :ref:`cookbook/coverage`
- Add an ``analyze`` preset and run static analysis: :ref:`cookbook/analysis`
- Set a personal default preset so you can omit ``--preset``:
  :ref:`cli/presets`
