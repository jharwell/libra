.. SPDX-License-Identifier: MIT

.. _concepts/analysis:

===============
Static analysis
===============

LIBRA makes static analysis nearly zero-configuration: enable
:cmake:variable:`LIBRA_ANALYSIS` and the targets appear automatically
for every tool found on ``PATH``. This page explains the design
decisions behind that behaviour and documents tool-specific quirks.
For the target reference, see :ref:`reference/targets`.

How LIBRA configures analysis
==============================

LIBRA detects the languages enabled for your CMake project and sets the
source files passed to each analysis tool accordingly. This allows
tools that only support C or C++ to coexist without causing errors on
incompatible source files. You should never need to set
:cmake:variable:`LIBRA_ANALYSIS_LANGUAGE` directly.

An individual target is created per auto-registered source file, giving
you per-file warnings and errors — the same granularity as compilation.

Compilation database
====================

All supported analysis tools can use a compilation database
(``compile_commands.json``), but can also work without one if given
the correct ``#defines``, includes, and language standard. LIBRA does
*not* use a compilation database by default for the following reasons:

- ``clang-tidy`` and ``cppcheck`` do not work well with a compilation
  database for header-only libraries that have nothing to compile. We
  cannot safely assume all header-only libraries have tests.

- If the compiler is not clang, the compilation database may contain
  flags that clang does not understand, causing clang-based analysis
  to fail even if the project builds cleanly with the configured
  compiler.

Override with :cmake:variable:`LIBRA_USE_COMPDB` if you need it — for
example, when your code uses ``-f`` options that cannot be extracted
from the target directly. For best results, set the compiler to clang
when enabling ``LIBRA_USE_COMPDB`` alongside clang-based tools.

Best practices and tool-specific configuration (suppression files,
``clang-tidy`` check categories, compilation database trade-offs) are
covered in :ref:`cookbook/analysis`.
