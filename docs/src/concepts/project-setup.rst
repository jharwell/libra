.. SPDX-License-Identifier: MIT

.. _concepts/project-setup:

=============
Project setup
=============

This page covers the setup decisions that apply to every LIBRA project
regardless of whether you use the ``clibra`` CLI or plain CMake. Read this
once — the quickstarts reference it rather than repeat it.

.. _concepts/project-setup/integration:

Integrating LIBRA into your project
===================================

Choose the integration method that fits your workflow:

.. list-table::
   :header-rows: 1
   :widths: 20 40 40

   * - Method
     - Best for
     - Use when

   * - **CPM** *(recommended)*
     - Most projects; no pre-installation needed
     - You want version-pinned, zero-install dependency management in CMake

   * - **Conan**
     - Multi-repo organisations, complex dependencies
     - You already use Conan, or manage 5+ related projects

   * - **CMake package**
     - System-wide or shared team installation
     - Multiple developers sharing one LIBRA installation

   * - **In situ (submodule)**
     - Quick prototyping, standalone repos, CI/CD simplicity
     - Single project; you want version control over LIBRA itself

.. tab-set::

   .. tab-item:: CPM (recommended)

      CPM fetches and caches LIBRA automatically at configure time. No
      pre-installation required; the version is pinned in your repository.

      .. include:: /src/integrate-cpm.rst

   .. tab-item:: Conan

      Best for managing dependencies and multi-repo scaling.

      **conanfile.py:**

      .. code-block:: python

         def build_requirements(self):
             self.tool_requires("libra/0.8.0")

      **CMakeLists.txt:**

      .. code-block:: cmake

         cmake_minimum_required(VERSION 3.31)
         find_package(libra REQUIRED)
         project(my_project C CXX)
         include(libra/project)

   .. tab-item:: CMake package

      Requires LIBRA to be installed to a system prefix or the same
      :cmake:variable:`CMAKE_INSTALL_PREFIX` as the consuming project.

      **Install LIBRA:**

      .. code-block:: bash

         git clone https://github.com/jharwell/libra.git
         cmake -S libra -B libra/build -DCMAKE_INSTALL_PREFIX=/opt/libra
         cmake --build libra/build --target install

      **CMakeLists.txt:**

      .. code-block:: cmake

         cmake_minimum_required(VERSION 3.31)
         find_package(libra REQUIRED)
         project(my_project C CXX)
         include(libra/project)

   .. tab-item:: In situ (submodule)

      Best for standalone repos where you want LIBRA under version control.

      .. code-block:: bash

         git submodule add https://github.com/jharwell/libra.git

      **CMakeLists.txt:**

      .. code-block:: cmake

         cmake_minimum_required(VERSION 3.31)
         add_subdirectory(libra)
         list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/libra/cmake)
         project(my_project C CXX)
         include(libra/project)

.. _concepts/project-setup/layout:

Project layout
==============

LIBRA auto-discovers sources, headers, and tests when you follow these
conventions:

.. code-block:: text

   my_project/
   ├── CMakeLists.txt
   ├── CMakePresets.json
   ├── cmake/
   │   └── project-local.cmake   ← target definitions (required)
   ├── src/                      ← .cpp / .c files (auto-discovered)
   ├── include/                  ← .hpp / .h headers (auto-discovered)
   ├── tests/                    ← test files (auto-discovered by suffix)
   └── docs/
       ├── Doxyfile.in           ← doxygen configuration (LIBRA_DOCS=ON)
       └── conf.py               ← sphinx configuration (LIBRA_DOCS=ON)

**Mandatory file extension conventions:**

- C++ source files must end in ``.cpp``; C++ headers in ``.hpp``
- C source files must end in ``.c``; C headers in ``.h``

If your structure differs from the above, you can disable globbing and
list files manually in ``project-local.cmake``.

In addition, build outputs in the binary directory follow these conventions. The
build directory can of course be wherever you like.

- libraries -> ``${CMAKE_BINARY_DIR}/${CMAKE_INSTALL_LIBDIR}`` (usually lib or
  lib64)
- executables -> ``${CMAKE_BINARY_DIR}/${CMAKE_INSTALL_BINDIR}`` (usually bin)

.. _concepts/project-setup/test-naming:

Test file naming
----------------

LIBRA discovers tests by matching filenames against suffix patterns. The
built-in defaults are ``-utest`` (unit), ``-itest`` (integration),
``-rtest`` (regression), and ``_test`` (harness). Negative compilation
tests use ``.neg.cpp`` / ``.neg.c``.

All patterns are configurable via matcher variables in
``project-local.cmake``. See :ref:`reference/testing` for the complete
naming reference including negative tests, the test harness, and
interpreted test support.

.. _concepts/project-setup/project-local:

project-local.cmake
===================

LIBRA expects your target definitions in ``cmake/project-local.cmake``.
This keeps the root ``CMakeLists.txt`` clean and portable:

.. include:: /src/ex-project-local.rst

.. note::

   :cmake:command:`libra_add_executable()` and
   :cmake:command:`libra_add_library()` wrap CMake's built-in equivalents
   and automatically apply LIBRA's compiler flags, analysis targets, and
   quality gates. Targets registered with plain ``add_executable()`` or
   ``add_library()`` will not receive LIBRA features unless you manually
   apply them.

   Always prefer the LIBRA variants for targets you want LIBRA to manage.

.. _concepts/project-setup/presets:

CMakePresets.json
=================

LIBRA and ``clibra`` are preset-driven. The following is the recommended
starting-point preset hierarchy. See :ref:`concepts/feature-flags` for a detailed
explanation of every preset and the rationale behind the structure.

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
           "LIBRA_TESTS":    "OFF",
           "LIBRA_COVERAGE": "OFF",
           "LIBRA_ANALYSIS": "OFF",
           "LIBRA_DOCS":     "OFF"
         }
       },
       {
         "name": "debug",
         "inherits": "base",
         "cacheVariables": {
           "CMAKE_BUILD_TYPE": "Debug",
           "LIBRA_TESTS": "ON"
         }
       },
       {
         "name": "release",
         "inherits": "base",
         "cacheVariables": {
           "CMAKE_BUILD_TYPE": "Release",
           "LIBRA_LTO": "ON"
         }
       },
       {
         "name": "coverage",
         "inherits": "base",
         "cacheVariables": {
           "CMAKE_BUILD_TYPE": "Debug",
           "LIBRA_TESTS": "ON",
           "LIBRA_COVERAGE": "ON"
         }
       },
       {
         "name": "ci",
         "inherits": "coverage"
       },
       {
         "name": "analyze",
         "inherits": "base",
         "cacheVariables": {
           "CMAKE_BUILD_TYPE": "Debug",
           "LIBRA_ANALYSIS": "ON"
         }
       }
     ],
     "buildPresets": [
       { "name": "debug",    "configurePreset": "debug" },
       { "name": "release",  "configurePreset": "release" },
       { "name": "coverage", "configurePreset": "coverage" },
       { "name": "ci",       "configurePreset": "ci" },
       { "name": "analyze",  "configurePreset": "analyze",
         "targets": ["analyze"] }
     ],
     "testPresets": [
       {
         "name": "debug",
         "configurePreset": "debug",
         "output": { "outputOnFailure": true }
       },
       {
         "name": "coverage",
         "configurePreset": "coverage",
         "output": { "outputOnFailure": true }
       },
       {
         "name": "ci",
         "configurePreset": "ci",
         "output": { "outputOnFailure": true }
       }
     ]
}
