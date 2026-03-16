.. SPDX-License-Identifier: MIT

.. _getting-started/choose-your-path:

================
Choose your path
================

LIBRA has two interfaces that work together. Understanding what each does
will help you decide where to start.

.. list-table::
   :header-rows: 1
   :widths: 20 40 40

   * -
     - ``clibra`` CLI
     - CMake framework only

   * - **What it is**
     - A Rust binary that wraps ``cmake``, ``cmake --build``, and ``ctest``
       with preset-aware defaults.
     - A collection of CMake modules you include in your ``CMakeLists.txt``.

   * - **What it requires**
     - Cargo (Rust toolchain) to install; CMake and your build tools to run.
     - CMake >= 3.31. No Rust required.

   * - **Typical command**
     - ``clibra build``, ``clibra test``, ``clibra ci``
     - ``cmake --preset debug && cmake --build --preset debug``

   * - **Escape hatch**
     - Drop it at any time — ``clibra`` never introduces state that plain
       ``cmake`` cannot read.
     - N/A — this *is* the escape hatch.

The two interfaces are not mutually exclusive. The CLI is a convenience
layer; the CMake framework is always underneath it.

Which should I use?
===================

.. tab-set::

   .. tab-item:: Start with the CLI

      Use ``clibra`` if:

      - You have Rust / Cargo installed, or are willing to install it.
      - You want short commands for common workflows (build, test, coverage,
        analysis) without remembering preset flag syntax.
      - You are starting a new project and want ``clibra doctor`` to verify
        your environment before you begin.

      → Continue to :ref:`getting-started/installation`.

   .. tab-item:: CMake only

      Use the CMake framework directly if:

      - You cannot or do not want to install Rust.
      - You are integrating LIBRA into an existing CMake project that already
        has its own build scripts.
      - You need to stay within a pure-CMake toolchain (e.g., for CI images
        that do not include Rust).

      The CLI can always be added later. CMake presets written for a
      CMake-only workflow are fully compatible with ``clibra``.

      → Continue to :ref:`getting-started/installation`.

What the CLI does and does not do
===================================

``clibra`` is a thin wrapper, not a build system. It:

- Resolves a preset name and passes it to ``cmake`` / ``cmake --build`` /
  ``ctest``.
- Detects whether a configure step is needed before building.
- Checks that required ``LIBRA_*`` feature flags are set before running
  commands that depend on them (e.g., ``LIBRA_TESTS=ON`` before ``clibra
  test``).
- Provides ``clibra info`` and ``clibra doctor`` for inspecting build state
  and environment health.

It does *not*:

- Manage dependencies or compilers.
- Replace ``CMakePresets.json`` or add its own configuration layer on top.
- Require any prior ``clibra`` invocation — a fresh checkout with a valid
  preset file works immediately.
