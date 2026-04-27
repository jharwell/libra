.. SPDX-License-Identifier: MIT

.. _main:

================================
Luigi Builds Reusable Automation
================================

LIBRA is a build platform for C/C++ projects built on top of CMake.  Instead of
writing project-specific CMake for testing, coverage, analysis, and
documentation, you define your targets and enable features — LIBRA handles the
rest with consistent, production-ready defaults.

Think of LIBRA as a standardized way to use CMake across projects, rather than a
replacement for it: it automates build, test, analysis, and documentation
workflows across C/C++ projects while remaining fully compatible with CMake.

Smallest possible project
=========================

.. code-block:: cmake

   cmake_minimum_required(VERSION 3.31)
   project(hello CXX)

   include(libra/project)
   libra_add_executable(my_app ${hello_CXX_SOURCES})

No source lists.  No test wiring.  No flags.

LIBRA auto-discovers sources under ``src/``, tests under ``tests/``, and
configures your toolchain automatically.  See
:ref:`getting-started/choose-your-path` to select your workflow.

.. note::

   **Requires** CMake ≥ 3.31 · one of {GCC / Clang / Intel LLVM} · Linux or
   macOS.  See :ref:`getting-started/installation` for the full requirements and
   compiler version table.

----

What LIBRA is (and is not)
==========================

LIBRA **is** a thin, declarative layer on top of CMake — a set of conventions
for structuring C/C++ projects and a unified interface for build, test, analysis,
and documentation workflows.

LIBRA **is not** a replacement for CMake, a new build system, or a tool that
prevents you from dropping down to raw CMake when necessary.  Only targets
registered with :cmake:command:`libra_add_executable()` or
:cmake:command:`libra_add_library()` receive LIBRA features unless you specify
otherwise; your existing ``add_executable()`` / ``add_library()`` calls are
unaffected.

LIBRA is a good fit if you use CMake but want less boilerplate, maintain
multiple C/C++ projects, or want consistent CI workflows across repositories.
It may not be a good fit if you want a completely new build system (see Bazel
or Meson), need full control over every CMake detail, or your project is very
small.

----

.. grid:: 1 2 2 2
   :gutter: 3

   .. grid-item-card:: 🚀 Getting started
      :link: getting-started
      :link-type: ref

      CLI or CMake-only? Install your tools, and build your first project (CLI
      optional).

   .. grid-item-card:: 🗂 Concepts
      :link: concepts
      :link-type: ref

      Project layout, the declarative target model, ``LIBRA_*`` feature
      flags, preset hierarchy, and test file naming conventions.

   .. grid-item-card:: 📖 Cookbook
      :link: cookbook
      :link-type: ref

      End-to-end task guides: new project, adding LIBRA to an existing
      project, CI setup, sanitizers, coverage, analysis, docs, and PGO.

   .. grid-item-card:: ⌨ CLI reference
      :link: cli/reference
      :link-type: ref

      All ``clibra`` subcommands and flags.  The CLI is optional — all
      functionality is available through plain ``cmake`` and ``ctest``.

   .. grid-item-card:: 📐 CMake reference
      :link: reference/variables
      :link-type: ref

      Every ``LIBRA_*`` variable, build targets, ``libra_add_*``
      functions, and ``project-local.cmake`` hooks.

   .. grid-item-card:: 💡 Design & rationale
      :link: design
      :link-type: ref

      Philosophy, architecture, compiler support, and the reasoning
      behind LIBRA's conventions.

----

.. rubric:: Common questions

**Does LIBRA replace CMake?**
No.  It is a layer on top of CMake.  You still write CMake; LIBRA reduces
how much of it you need to write.

**Can I mix LIBRA and plain CMake targets?**
Yes.  Only targets registered with :cmake:command:`libra_add_executable()`
or :cmake:command:`libra_add_library()` receive LIBRA features.  Existing
targets are unaffected.  See :ref:`cookbook/existing-project` for a
step-by-step migration guide.

**Do I need the CLI to use LIBRA?**
No.  ``clibra`` is an optional convenience wrapper.  All functionality is
available through plain ``cmake``, ``cmake --build``, and ``ctest``.
See :ref:`getting-started/choose-your-path` to decide which interface
suits you.

**Is globbing mandatory?**
No.  You can disable auto-discovery and pass explicit source lists to
:cmake:command:`libra_add_executable()` / :cmake:command:`libra_add_library()`.
See :ref:`reference/variables` for the relevant variables.

----

.. toctree::
   :hidden:
   :maxdepth: 1

   src/getting-started/index
   src/concepts/index
   src/cookbook/index
   src/cli/index
   src/reference/index
   src/design/index
