.. SPDX-License-Identifier: MIT

.. _main:

.. figure:: figures/libra-logo-banner-light.png

Luigi Builds Reusable Automation
================================

LIBRA is a reusable build framework for C/C++ projects built on top of CMake.
It transforms the build process from manual scripting into a **declarative
workflow**, providing compiler abstraction and near-zero boilerplate
configuration. Its core goal: To make building complex C++ projects as simple as
declaring intent (e.g., "I want a library with coverage") rather than writing
imperative CMake logic.

Who Should Use LIBRA
====================

* **Platform Engineers** looking to standardize build quality across multiple
  repositories.
* **C/C++ Developers** who want to focus on code rather than debugging
  ``.cmake`` modules.
* **Teams** requiring consistent "push-button" integration for sanitizers,
  static analysis, and documentation generation.

Design Philosophy
=================

* **Convention over Configuration:** Standardized project layouts mean zero
  setup for new repos.
* **Declarative Intent:** Focus on *what* to build (e.g.,
  :cmake:command:`libra_add_library()`), not *how* to set compiler flags.
* **Toolchain Agnostic:** A single configuration should work across GCC, Clang,
  and Intel LLVM without ``if(MSVC)`` blocks.

Architecture Overview
=====================

This diagram shows which parts of LIBRA are active during CMake configuration
and which parts are active when build targets are executed.

.. figure:: figures/arch.png

Features & Capabilities
=======================

Configure Time (Setup Logic)
----------------------------
During the ``cmake ..`` phase, LIBRA automates the heavy lifting:

* **Security & Hardening:** Automatic injection of stack protectors,
  fortify-source, etc.
* **Quality Gates:** Seamless setup for **clang-tidy**, **cppcheck**, and custom
  linters, and various sanitizers.
* **Dependency Orchestration:** Smart globbing for source discovery that
  respects build-system boundaries.
* **Environment Discovery:** Automatic detection and registration of tests and
  source files.

Build Time (Execution Targets)
------------------------------
LIBRA injects standardized targets into your build system. E.g., for GNU make:

* ``make analyze``: Run the full suite of configured static analyzers.
* ``make format``: Apply project-wide formatting via clang-Format, cmake-format.
* ``make apidoc``: Generate API documentation (Doxygen).


Integration Modes
=================

LIBRA scales with your project's complexity. Choose the mode that fits your
infrastructure:

#. **Conan Middleware (recommended):** The most robust path. LIBRA acts as a
   `Conan <https://conan.io>`_ build helper.
#. **CPM (CMake Package Manager):** Integrated via ``cpmaddpackage()``.
#. **Standard CMake Package:** Integrated via ``find_package(libra)``.
#. **In-Situ (submodule):** Drop LIBRA directly into your source tree.

----

.. toctree::
   :maxdepth: 1
   :caption: Getting Started

   startup/index.rst

.. toctree::
   :maxdepth: 1
   :caption: LIBRA Feature Reference

   usage/index.rst

.. toctree::
   :maxdepth: 1
   :caption: LIBRA Design And Customization

   design/index.rst
