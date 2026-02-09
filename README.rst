.. SPDX-License-Identifier: MIT

=======================================
LIBRA: Luigi Build Reusable Automation
=======================================

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

* **Zero-Boilerplate:** Define your project in 5 lines of CMake.
* **Hardened by Default:** Automatic security flags and sanitizers.
* **Unified Tooling:** One interface for GCC, Clang, and Intel compilers.
* **Quality Built-in:** Native targets for Coverage, Analysis, and Docs.

Why Use LIBRA?
==============

**You should use LIBRA if:**

* You maintain multiple C/C++ projects with similar build needs
* You work with multiple compilers (GNU/Clang/Intel) and want consistency
* You're tired of copy-pasting CMake boilerplate between repositories
* You need reproducible builds with best-practice compiler flags
* You want automated test discovery without maintaining file lists
* You frequently switch between debug builds (sanitizers) and release builds (optimization)
* Your team has varying CMake expertise levels and you want to standardize

Why Not Use LIBRA?
===================

**You should NOT use LIBRA if:**

* You use build systems other than CMake (Bazel, Meson, autotools)
* You need Windows/MSVC support (LIBRA targets Linux/Unix)
* You have exotic/unsupported compilers (ARM, proprietary toolchains)
* Your project has non-standard directory structures LIBRA can't accommodate
* You have strict organizational "no globbing" policies
* You have a single project with a custom, hand-tuned build system you're happy with
* You require fine-grained per-file compiler flag control

Quick Example
=============

**Before LIBRA (Standard CMake):**

.. code-block:: cmake

   # 50+ lines to set up:
   # - Compiler flags for Debug/Release
   # - Sanitizer configuration with compiler detection
   # - Code coverage setup
   # - Test discovery and CTest integration
   # - Static analysis targets
   # ... (boilerplate continues)

**After LIBRA:**

.. code-block:: cmake

   # CMakeLists.txt (3 lines)
   cmake_minimum_required(VERSION 3.17)
   find_package(libra REQUIRED)
   project(myproj CXX)

.. code-block:: cmake

   # cmake/project-local.cmake (2 lines)
   libra_add_executable(${${PROJECT_NAME}_CXX_SOURCE})
   set(LIBRA_SAN "ASAN+UBSAN")  # Sanitizers on any compiler

**Build:**

.. code-block:: bash

   cmake -B build -DLIBRA_TESTS=ON -DLIBRA_CODE_COV=ON
   make -C build build-and-test gcovr-report
   # Tests run + coverage report generated

.. note::

   ``libra_add_executable()`` applies LIBRA's compiler flags, analysis targets,
   and quality gates to your target. Use it instead of ``add_executable()`` for
   LIBRA-managed builds. Standard CMake commands still work, but won't receive
   LIBRA features automatically.

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

Key Features
============

**Unified Compiler Interface**
   Consistent variables across GCC, Clang, Intel compilers.
   ``LIBRA_SAN=ASAN`` works identically on all three.
   No more ``if(CMAKE_CXX_COMPILER_ID MATCHES "GNU")`` boilerplate.

**Quality Tools Built-In**
   Code coverage: lcov, gcovr, llvm-cov (one command: ``make gcovr-report``).
   Static analysis: cppcheck, clang-tidy, clang-check.
   Sanitizers: ASAN, UBSAN, TSAN, MSAN with simple flags.
   Profile-guided optimization (PGO) workflow automation.

**Test Automation**
   Auto-discovery of ``*-utest.cpp`` and ``*-itest.cpp`` files.
   No manual test registration in CMakeLists.txt.
   Single command: ``make build-and-test``.

**Zero-Config Defaults**
   Source files in ``src/`` automatically compiled.
   Tests in ``tests/`` automatically discovered.
   Headers in ``include/`` automatically exported.

Compiler Support Matrix
========================

.. list-table::
   :header-rows: 1
   :widths: 40 20 20 20

   * - Feature
     - GNU
     - Clang
     - Intel
   * - Optimization levels (``-O0`` to ``-O3``, ``-Os``)
     - Yes
     - Yes
     - Yes
   * - Native CPU tuning (``-march=native``)
     - Yes
     - Yes
     - Yes
   * - Link-time optimization (LTO)
     - Yes
     - Yes
     - Yes
   * - Sanitizers (ASAN, UBSAN, TSAN, MSAN)
     - Yes
     - Yes
     - Yes
   * - Profile-guided optimization (PGO)
     - Yes
     - Yes
     - Yes
   * - Code coverage (gcov/llvm-cov)
     - Yes
     - Yes
     - No
   * - Security hardening
     - Yes
     - Yes
     - No
   * - Build profiling
     - Yes
     - Yes
     - No

See `Compiler Support Details <https://jharwell.github.io/libra/usage/compilers.html>`_
for complete flag mappings.

Requirements
============

**Platform:**
  Linux/Unix (Ubuntu 20.04+, RHEL 8+, macOS with Homebrew)

  Windows/MSVC is **NOT supported**. Use WSL for Windows development.

**Build Tools:**
  CMake >= 3.31

**Compilers:**
  GCC/g++ >= 9, Clang/clang++ >= 17, or Intel icx/icpx >= 2024.1

**Optional Tools:**
  lcov >= 1.14, gcovr >= 5.0, llvm-cov (bundled with Clang),
  cppcheck >= 2.0, clang-tidy, doxygen, graphviz

Architecture Overview
=====================

LIBRA layers on top of standard CMake. It does not replace your build system;
it orchestrates it.

.. figure:: https://raw.githubusercontent.com/jharwell/libra/master/docs/figures/arch.png
   :alt: LIBRA Architecture Diagram

Project Structure
=================

A typical LIBRA-enabled project::

   my_project/
   ├── CMakeLists.txt              # Minimal: find_package + project()
   ├── cmake/
   │   └── project-local.cmake     # Your targets and configuration
   ├── src/                        # Auto-discovered source files
   ├── include/                    # Auto-discovered headers
   ├── tests/                      # Auto-discovered tests (*-{u,i,r}test.{c,cpp})
   └── build/                      # Build artifacts (git-ignored)

Full Documentation
==================

Detailed guides and API references are available at
`jharwell.github.io/libra <https://jharwell.github.io/libra/>`_.

* `Quick Start Guide <https://jharwell.github.io/libra/startup/quickstart.html>`_
* `Configuration Reference <https://jharwell.github.io/libra/usage/configure-time.html>`_
* `Build Time Actions <https://jharwell.github.io/libra/usage/build-time.html>`_
* `Compiler Support Details <https://jharwell.github.io/libra/usage/compilers.html>`_
* `Static Analysis <https://jharwell.github.io/libra/usage/analysis.html>`_
* `Design Philosophy <https://jharwell.github.io/libra/design/philosophy.html>`_

License
=======

MIT License - see LICENSE file for details.

Contributing
============

Contributions welcome! When adding features:

1. Add CMake configuration to appropriate file in ``cmake/libra/``
2. Add BATS tests to ``tests/LIBRA_<FEATURE>.bats``
3. Update documentation in ``docs/``
4. Ensure tests pass: ``bats tests/LIBRA_<FEATURE>.bats``
