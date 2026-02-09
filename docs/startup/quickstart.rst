.. SPDX-License-Identifier:  MIT

.. _startup/quickstart:

==========
Quickstart
==========

This guide will get you from zero to a running LIBRA project in minutes.
Before starting, ensure your system meets the :ref:`startup/config`.

1. Choose Your Integration
==========================

Select the integration method that matches your workflow.

.. tabs::

   .. group-tab:: Conan (Recommended)

      Best for managing dependencies and multi-repo scaling.

      **Step A: Configure conanfile.py**

      .. code-block:: python

         def build_requirements(self):
             self.tool_requires("libra/0.8.0")

      **Step B: Create CMakeLists.txt**

      .. code-block:: cmake

         cmake_minimum_required(VERSION 3.31)
         include(libra/project)
         project(my_project CXX)

   .. group-tab:: CMake Package

      Best for standard system-wide or prefix-based installs.

      **Step A: Install LIBRA**

      .. code-block:: bash

         git clone https://github.com/jharwell/libra.git
         cmake -S libra -B libra/build -DCMAKE_INSTALL_PREFIX=/opt/libra
         cmake --build libra/build --target install

      **Step B: Create CMakeLists.txt**

      .. code-block:: cmake

         cmake_minimum_required(VERSION 3.31)
         find_package(libra REQUIRED)
         include(libra/project)
         project(my_project CXX)

   .. group-tab:: In Situ (Submodule)

      Best for quick prototyping or standalone repos.

      **Step A: Add Submodule**

      .. code-block:: bash

         git submodule add https://github.com/jharwell/libra.git
         ln -s libra/cmake/project.cmake CMakeLists.txt

      *Note: The symbolic link replaces the need for a manual CMakeLists.txt.*

2. Configure Your Project
=========================

LIBRA expects your logic to live in ``cmake/project-local.cmake``. This keeps your
root ``CMakeLists.txt`` clean and portable.

**Create cmake/project-local.cmake:**

.. code-block:: cmake

   # LIBRA auto-discovers files in src/ and tests/
   # Just declare the target type:
   libra_add_executable(${${PROJECT_NAME}_CXX_SOURCE})

   # Optional: Enable project-wide quality gates
   set(LIBRA_ANALYSIS ON)
   set(LIBRA_FORTIFY ON)

3. Build & Run
==============



Use standard CMake workflows. LIBRA provides the convenience targets.

.. code-block:: bash

   # Configure and enable tests
   cmake -B build -DLIBRA_TESTS=YES

   # Build everything
   cmake --build build

   # Run the LIBRA "all-in-one" test target
   make -C build build-and-test

Project Structure
=================

By following this convention, LIBRA requires zero manual file listing:

.. code-block:: text

   my_project/
   ├── CMakeLists.txt           # Framework entry point
   ├── cmake/
   │   └── project-local.cmake  # Target definitions
   ├── src/                     # .cpp/.c files (Auto-discovered)
   ├── include/                 # Public headers
   ├── tests/                   # *-utest.cpp (Auto-discovered)
   └── build/                   # Build artifacts

Common Workflows
================

See :ref:`usage/build-time` for full documentation.

Build & Run Tests
-----------------

.. code-block:: bash

   make build-and-test

Generate Code Coverage
----------------------

**GNU/gcov:**

.. code-block:: bash

   cmake -B build -DCMAKE_BUILD_TYPE=Debug -DLIBRA_CODE_COV=ON
   cd build
   make all-tests && make test && make gcovr-report
   # Open coverage/index.html

**Clang/llvm-cov:**

.. code-block:: bash

   cmake -B build -DCMAKE_BUILD_TYPE=Debug -DLIBRA_CODE_COV=ON -DLIBRA_CODE_COV_NATIVE=YES
   cd build
   make all-tests && make test && make llvm-coverage
   # Open coverage/index.html

Profile-Guided Optimization
---------------------------

.. code-block:: bash

   # Phase 1: Generate profile
   cmake -B build -DLIBRA_PGO=GEN
   cd build && make && ./bin/my_app

   # Phase 2: Optimize (Clang requires merging profiles)
   llvm-profdata merge -o default.profdata default*.profraw  # Clang only
   cmake -B build -DLIBRA_PGO=USE
   make

Static Analysis
---------------

.. code-block:: bash

   cmake -B build -DLIBRA_ANALYSIS=ON
   cd build
   make analyze              # Run all analyzers
   make analyze-clang-tidy   # Just clang-tidy
   make fix-clang-tidy       # Auto-fix issues

Sanitizers (Debug Builds)
-------------------------

.. code-block:: bash

   cmake -B build -DCMAKE_BUILD_TYPE=Debug -DLIBRA_SAN="ASAN+UBSAN"
   cd build && make && make test
