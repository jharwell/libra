.. SPDX-License-Identifier: MIT

======================================
LIBRA: Luigi Build Reusable Automation
======================================

.. |docs| image:: https://img.shields.io/badge/docs-github.io-blue
   :target: https://jharwell.github.io/libra
   :alt: Documentation

.. |build| image:: https://github.com/jharwell/libra/actions/workflows/pages.yml/badge.svg?branch=master
   :target: https://jharwell.github.io/libra
   :alt: Build

.. |license| image:: https://img.shields.io/badge/License-MIT-yellow.svg
   :target: https://opensource.org/licenses/MIT
   :alt: License: MIT

|docs| |build| |license|

LIBRA is a **declarative build orchestration framework** for C/C++ projects.
Built on top of CMake, it eliminates repetitive boilerplate by replacing
imperative scripting with convention-based automation.

* 🚀 **Zero-Boilerplate:** Define your project in 5 lines of CMake.
* 🛡️ **Hardened by Default:** Automatic security flags and sanitizers.
* 🛠️ **Unified Tooling:** One interface for GCC, Clang, and Intel compilers.
* 📊 **Quality Built-in:** Native targets for Coverage, Analysis, and Docs.

Quick Example (30 seconds)
==========================

**Top-level CMakeLists.txt**

.. code-block:: cmake

   cmake_minimum_required(VERSION 3.31)
   project(myproj)
   find_package(libra REQUIRED)

**cmake/project-local.cmake**

.. code-block:: cmake

   # LIBRA automatically finds sources in src/ and tests in tests/
   libra_add_executable(${${PROJECT_NAME}_CXX_SOURCE})

**Build and Test**

.. code-block:: bash

   cd build && cmake -DLIBRA_TESTS=YES ..
   make build-and-test

Technical Comparison
====================

Standard CMake is imperative (*how*); LIBRA is declarative (*what*).

.. list-table::
   :header-rows: 1

   * - Feature
     - Standard CMake
     - LIBRA

   * - Sanitizers
     - 10+ lines of compiler if/else
     - ``set(LIBRA_SAN "ASAN")``

   * - Static Analysis
     - Manual ``find_program`` + setup
     - ``set(LIBRA_ANALYSIS ON)``

   * - Source/test Discovery
     - Manual file listing
     - Automated via globbing

Architecture Overview
=====================

LIBRA layers on top of standard CMake. It does not replace your build system;
it orchestrates it.

.. figure:: https://raw.githubusercontent.com/jharwell/libra/master/docs/figures/arch.png

Full Documentation
==================

Detailed guides and API references are available at
`jharwell.github.io/libra <https://jharwell.github.io/libra/>`_.
