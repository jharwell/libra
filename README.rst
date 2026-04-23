.. SPDX-License-Identifier: MIT

.. |docs| image:: https://img.shields.io/badge/docs-github.io-blue
   :target: https://jharwell.github.io/libra
   :alt: Documentation

.. |ci-master| image:: https://github.com/jharwell/libra/actions/workflows/ci.yml/badge.svg?branch=master

.. |ci-devel| image:: https://github.com/jharwell/libra/actions/workflows/ci.yml/badge.svg?branch=devel

.. |license| image:: https://img.shields.io/github/license/jharwell/libra

.. |platform| image:: https://img.shields.io/badge/platform-linux%20%7C%20macos-lightgrey
   :alt: Platform

.. |cmake| image:: https://img.shields.io/badge/cmake-%3E%3D3.31-blue
   :alt: CMake

.. |compiler| image:: https://img.shields.io/badge/compilers-gcc%20%7C%20clang%20%7C%20intel-blue
   :alt: Compilers

.. |version-master| image:: https://img.shields.io/github/v/tag/jharwell/libra?filter=!*.beta*&label=master&sort=semver
   :target: https://github.com/jharwell/libra/releases
   :alt: Latest release tag

.. |version-devel| image:: https://img.shields.io/github/v/tag/jharwell/libra?filter=*-*&include_prereleases&label=devel&sort=semver
   :target: https://github.com/jharwell/libra/releases
   :alt: Latest devel tag

.. |maintenance| image:: https://img.shields.io/badge/Maintained%3F-yes-green.svg
                 :target: https://github.com/jharwell/libra/graphs/commit-activity

.. image:: docs/_static/logo-banner.png
   :width: 400px

+-----------------------------------+----------------------------------+
| Usage                             | |docs| |cmake|                   |
|                                   | |compiler| |platform|            |
+-----------------------------------+----------------------------------+
| Release                           | |ci-master| |version-master|     |
+-----------------------------------+----------------------------------+
| Development                       | |ci-devel| |version-devel|       |
+-----------------------------------+----------------------------------+
| Miscellaneous                     | |license| |maintenance|          |
+-----------------------------------+----------------------------------+

================================
Luigi Builds Reusable Automation
================================

LIBRA is a build platform for C/C++ projects built on top of CMake that turns
build configuration into a declaration of intent. Instead of writing
project-specific CMake for testing, coverage, analysis, and documentation, you
define your targets and enable features.  LIBRA handles the rest.

LIBRA standardizes build, test, analysis, and documentation workflows
across C++ projects while keeping full compatibility with CMake.

----

Why LIBRA exists
================

Modern C++ projects need more than just "builds":

- consistent compiler behavior across environments
- reliable testing and CI workflows
- coverage and analysis integrated into development
- repeatable project structure across repositories

CMake can do all of this — but only with significant per-project effort.

LIBRA provides a single, opinionated layer that standardizes these
patterns so every project doesn't have to reinvent them.

----

What LIBRA is (and is not)
==========================

LIBRA is:

- A thin, declarative layer on top of CMake
- A set of conventions for structuring C++ projects
- A unified interface for build + test + analysis + docs

LIBRA is not:

- A replacement for CMake
- A new build system
- A tool that prevents you from using raw CMake

You can always drop down to plain CMake when needed.

When to use LIBRA
=================

LIBRA is a good fit if:

- You use CMake but want less boilerplate
- You maintain multiple C++ projects
- You want consistent workflows across repositories and CI

LIBRA may not be a good fit if:

- You want a completely new build system (e.g. Bazel, Meson)
- You need full control over every CMake detail
- Your project is very small

----

Quick start
===========

.. code-block:: cmake

   # CMakeLists.txt
   cmake_minimum_required(VERSION 3.31)
   project(hello CXX)

   include(libra/project)

   # cmake/project-local.cmake
   libra_add_executable(my_app ${my_app_CXX_SOURCES})

No source lists. No test wiring. No flags.

LIBRA automatically:

- discovers sources under ``src/`` and headers under ``include/``
- discovers tests under ``tests/``
- configures compiler flags for your toolchain
- wires up test targets, coverage, and analysis (if enabled)

What you don’t have to write
============================

With LIBRA, you do not need to manually configure:

- compiler flags per toolchain
- test registration with CTest
- coverage tooling and thresholds
- static analysis integration
- sanitizer flags and wiring
- documentation targets

LIBRA provides consistent defaults for all of these.

----

Typical workflow
================

An optional CLI (``clibra``) provides shorter commands and preset-aware
defaults:

.. code-block:: bash

   clibra build --preset debug
   clibra test  --preset debug
   clibra ci    --preset ci      # build + test + coverage check

Or plain CMake:

.. code-block:: bash

   cmake --preset debug && cmake --build --preset debug
   cmake --build --preset debug --target all-tests && ctest --preset debug

----

Key capabilities
================

- Works across GCC, Clang, and Intel LLVM without per-compiler logic
- Automatically discovers and registers tests
- Integrates coverage, analysis, sanitizers, and documentation
- Enforces consistent build, test, and analysis workflows across projects

See the documentation for full details.

----

Project layout
==============

LIBRA auto-discovers sources, headers, and tests from conventional
directories::

   my_project/
   ├── CMakeLists.txt
   ├── CMakePresets.json
   ├── cmake/
   │   └── project-local.cmake   ← target definitions (required)
   ├── src/                      ← .cpp / .c files (auto-discovered)
   ├── include/                  ← .hpp / .h headers (auto-discovered)
   ├── tests/                    ← test files (auto-discovered by configurable suffix)
   └── docs/
       └── Doxyfile.in           ← required if LIBRA_DOCS=ON


----

Installation
============

CMake framework
---------------

Choose the integration method that fits your project. No installation
is required beyond CMake itself.

**CPM (recommended)** — version-pinned, fetched automatically at
configure time:

.. code-block:: cmake

   cmake_minimum_required(VERSION 3.31)

   file(DOWNLOAD
        https://github.com/cpm-cmake/CPM.cmake/releases/download/v0.40.2/CPM.cmake
        ${CMAKE_CURRENT_BINARY_DIR}/cmake/CPM.cmake)

   set(CPM_SOURCE_CACHE $ENV{HOME}/.cache/CPM CACHE PATH "CPM source cache")
   set(CPM_USE_LOCAL_PACKAGES ON)
   include(${CMAKE_CURRENT_BINARY_DIR}/cmake/CPM.cmake)

   CPMAddPackage(
     NAME libra
     GIT_REPOSITORY https://github.com/jharwell/libra.git
     GIT_TAG master)

   list(APPEND CMAKE_MODULE_PATH ${libra_SOURCE_DIR}/cmake)
   project(my_project C CXX)
   include(libra/project)

**Conan** — if your project already uses Conan:

.. code-block:: python

   # conanfile.py
   def build_requirements(self):
       self.tool_requires("libra/0.8.0")

**Installed package** — system-wide or shared team installation:

.. code-block:: bash

   git clone https://github.com/jharwell/libra
   cmake -S libra -B libra/build -DCMAKE_INSTALL_PREFIX=/opt/libra
   cmake --build libra/build --target install

**Git submodule** — for projects that vendor their dependencies:

.. code-block:: bash

   git submodule add https://github.com/jharwell/libra

``clibra`` CLI (optional)
-------------------------

``clibra`` is a Rust binary that wraps ``cmake``, ``cmake --build``,
and ``ctest`` with preset-aware defaults. It never introduces state
that plain CMake cannot read — you can stop using it at any time.

Requires the Rust toolchain. Install via `rustup <https://rustup.rs>`_
if you do not have Cargo:

.. code-block:: bash

   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

Then install ``clibra``:

.. code-block:: bash

   cargo install clibra
   clibra --version

Run ``clibra doctor`` from your project root to verify tool
availability and minimum versions:

.. code-block:: text

   Checking LIBRA environment...

   Tools:
     ✓ cmake       -> /usr/bin/cmake (3.31.2)
     ✓ gcc         -> /usr/bin/gcc (13.2.0)
     ✓ g++         -> /usr/bin/g++ (13.2.0)
     ⚠ gcovr       not found (optional)
     ⚠ cppcheck    not found (optional)

   Checked 14 items: 0 errors, 3 warnings, 11 ok

----

Requirements
============

**Platform:** Linux (Ubuntu 20.04+, RHEL 8+, Arch, Fedora, Debian),
macOS, WSL. Native Windows (MSVC, MinGW) is not supported.

**CMake:** >= 3.31

**Compilers:**

+------------------+-----------------+
| Compiler         | Minimum version |
+==================+=================+
| GCC              | 9.0             |
+------------------+-----------------+
| Clang            | 17.0            |
+------------------+-----------------+
| Intel LLVM       | 2025.0          |
+------------------+-----------------+

Always use matching C and C++ compilers from the same vendor.
Mixing (e.g. ``gcc`` + ``clang++``) causes ABI incompatibilities.

**CLI:** Rust toolchain >= 1.75 (optional)

----

Documentation
=============

Full documentation including quickstarts, cookbook, concept guides, and
reference material is at https://jharwell.github.io/libra.

- `Getting started <https://jharwell.github.io/libra/getting-started>`_
- `Cookbook <https://jharwell.github.io/libra/cookbook>`_ — end-to-end
  guides for CI setup, sanitizers, coverage, analysis, PGO, and more
- `CLI reference <https://jharwell.github.io/libra/reference/cli>`_
- `Variable reference <https://jharwell.github.io/libra/reference/variables>`_

----

FAQ
===

**Does LIBRA replace CMake?**
No. It is a layer on top of CMake that provides conventions and
automation. You still write CMake; LIBRA reduces how much of it you
need to write.

**Can I mix LIBRA and plain CMake targets?**
Yes. Only targets registered with ``libra_add_executable()`` or
``libra_add_library()`` receive LIBRA features. Existing targets are
unaffected.

**Is globbing mandatory?**
No. You can disable auto-discovery and pass explicit source lists to
``libra_add_executable()`` / ``libra_add_library()``.

**Can I disable individual features?**
Yes. All features (tests, coverage, analysis, sanitizers, docs) are
opt-in via ``LIBRA_*`` cache variables, typically set in presets.

**Do I need the CLI to use LIBRA?**
No. The CLI is an optional convenience layer. All functionality is
available through plain ``cmake``, ``cmake --build``, and ``ctest``.

**Does LIBRA work with my existing CMakePresets.json?**
Yes. Add a hidden ``base`` preset that sets all ``LIBRA_*`` flags
explicitly, then make your existing presets inherit from it. See the
`existing project guide
<https://jharwell.github.io/libra/cookbook/existing-project>`_.
