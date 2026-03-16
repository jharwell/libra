.. SPDX-License-Identifier: MIT

.. _cookbook/existing-project:

===================================
Adding Libra To An Existing Project
===================================

This guide covers integrating LIBRA into a CMake project that already
exists — one with a working ``CMakeLists.txt``, existing targets, and
possibly an existing preset file. The process is non-destructive: your
existing targets and build scripts continue to work.

1. Choose An Integration Method
================================

The integration method determines how CMake finds LIBRA. See
:ref:`concepts/project-setup/integration` for options.

2. Include LIBRA After project()
================================

LIBRA must be included **after** the ``project()`` declaration so that
the compiler and language are known:

.. code-block:: cmake

   project(my_project C CXX)
   include(libra/project)   # ← add this line

3. Create project-local.cmake
=============================

If it does not exist, create ``cmake/project-local.cmake``. LIBRA
includes this file automatically. Move your target definitions here:

.. code-block:: cmake

   libra_add_executable(${${PROJECT_NAME}_CXX_SOURCES})

   # Preserve any existing link dependencies
   target_link_libraries(${PROJECT_NAME} PRIVATE my_existing_dep)


4. Migrate Existing Targets
===========================

LIBRA only manages targets registered with its own wrappers. Your
existing ``add_executable()`` and ``add_library()`` calls continue to
work, but those targets will not receive LIBRA's compiler flags,
diagnostic options, or quality-gate targets by default.

To migrate a target, replace it in ``CMakeLists.txt`` or move it to
``cmake/project-local.cmake``:

.. code-block:: cmake

   # Before
   add_executable(my_app src/main.cpp src/core.cpp)
   target_include_directories(my_app PRIVATE include)

   # After — in cmake/project-local.cmake
   libra_add_executable(${${PROJECT_NAME}_CXX_SOURCES})

   # Or if you prefer to list sources explicitly:
   libra_add_executable(src/main.cpp src/core.cpp)

.. NOTE::

   LIBRA auto-discovers sources from ``src/`` and headers from
   ``include/`` when you follow the layout conventions. If your project
   uses a different layout, you can pass sources explicitly. See
   :ref:`concepts/project-setup/layout` for the full set of conventions.

   You do not have to migrate all targets at once. Unmigrated targets
   keep working; they simply do not get LIBRA features.

5. Add Or Update CMakePresets.json
==================================

If your project already has a ``CMakePresets.json``, add a ``base``
hidden preset and make your existing presets inherit from it. This
ensures every preset explicitly declares its LIBRA feature state:

.. code-block:: json

   {
     "configurePresets": [
       {
         "name": "base",
         "hidden": true,
         "cacheVariables": {
           "LIBRA_TESTS":    "OFF",
           "LIBRA_CODE_COV": "OFF",
           "LIBRA_ANALYSIS": "OFF",
           "LIBRA_DOCS":     "OFF"
         }
       },
       {
         "name": "debug",
         "inherits": ["base", "your-existing-debug-preset"],
         "cacheVariables": {
           "LIBRA_TESTS": "ON"
         }
       }
     ]
   }

If you don't have a preset file yet, copy the starting-point hierarchy
from :ref:`concepts/project-setup/presets`.

6. Configure And Build
=======================

.. tab-set::

   .. tab-item:: CLI

      .. code-block:: bash

         clibra build --preset debug

   .. tab-item:: CMake

      .. code-block:: bash

         cmake --preset debug
         cmake --build --preset debug -j$(nproc)

7. Verify
=========

Check that your existing targets still build, and that LIBRA targets
are now available:

.. tab-set::

   .. tab-item:: CLI

      .. code-block:: bash

         clibra info    # shows LIBRA targets and feature flags

   .. tab-item:: CMake

      .. code-block:: bash

         cmake --build --preset debug --target help-targets

Common Issues
=============

**"Cannot find source files"**
   LIBRA globs from ``src/`` and ``include/``. If your project uses
   different directories, either restructure or set
   :cmake:variable:`${PROJECT_NAME}_CXX_SRC` or
   :cmake:variable:`${PROJECT_NAME}_C_SRC` explicitly in
   ``project-local.cmake`` before calling ``libra_add_executable()``.

**"Duplicate target name"**
   If you have both an existing ``add_executable(my_app ...)`` and a new
   ``libra_add_executable(...)`` in the same ``CMakeLists.txt``, CMake
   will error. Remove the old ``add_executable()`` call once you've
   migrated to the LIBRA wrapper.

**"LIBRA features applied to wrong targets"**
   LIBRA only applies to the root project's registered targets. If you
   have sub-projects via ``add_subdirectory()``, their targets are
   unaffected — this is intentional. See :ref:`concepts/targets`.
