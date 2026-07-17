.. SPDX-License-Identifier: MIT

.. _concepts/analysis:

===============
Static analysis
===============

LIBRA makes static analysis nearly zero-configuration: enable
:cmake:variable:`LIBRA_ANALYSIS` and the targets appear automatically
for every tool found on ``PATH``. This page explains the design
decisions behind that behaviour. For the target reference and the
mechanics of header coverage, see :ref:`reference/targets`.

How LIBRA configures analysis
=============================

LIBRA detects the languages enabled for your CMake project and sets the
source files passed to each analysis tool accordingly. This allows
tools that only support C or C++ to coexist without causing errors on
incompatible source files.

An individual target is created per auto-registered source file, giving
you per-file warnings and errors — the same granularity as compilation.

Analysis is a separate workflow
===============================

Analysis is a separate workflow from the usual debug/test cycle and should
run in its own preset and build directory. This is not merely a conceptual
preference — it is a correctness requirement for the ``fix`` targets.
Running fix targets against a stale build that does not reflect current
source can produce incorrect patches (see
:ref:`reference/targets/analysis-internals`).

It is (highly) unlikely that a given project will want to require that ALL
static analysis checks pass for MR merge, etc. Many of the checks overlap
with each other (esp. ``clang-tidy``), so it is up to each project to
choose which checks to use.

Compilation database
====================

By default, analysis tools consume a compilation database
(``compile_commands.json``), which is the most reliable source of truth
for compiler flags, include paths, and defines. Keeping
:cmake:variable:`LIBRA_USE_COMPDB` ``=YES`` (the default) is strongly
recommended — especially for projects with layered ``PRIVATE``
dependencies, where the non-compdb path cannot see the full flag set. The
exact fallback behaviour is documented in
:ref:`reference/targets/analysis-internals`.

.. NOTE:: For best results, set the compiler to clang when using
          clang-based tools such as ``clang-tidy``. If the compiler is not
          clang, the compilation database may contain flags that clang
          does not understand, causing analysis to fail even if the
          project builds cleanly. Using :cmake:variable:`LIBRA_USE_COMPDB`
          ``=YES`` is strongly recommended if using GCC for builds and
          clang for analysis.

.. _concepts/analysis/header-files:

Header files must be self-contained
===================================

Header files are always required to be syntactically self-contained and
valid in isolation — they must not rely on a specific include order or on
definitions provided by a prior ``#include``. This is enforced directly
by LIBRA's analysis machinery.

Headers that are consumed by a ``.c/.cpp`` translation unit are analyzed
in that context automatically. Public headers that no translation unit
includes — as in header-only libraries — are covered by a generated stub
translation unit so they receive correct flags and are analyzed like any
other source. If a header fails analysis, that is a real bug in the header;
the fix is to make it self-contained, not to suppress the error.

The full stub-generation mechanism, and why it requires a fresh configure
before every ``fix-*`` run, is documented in
:ref:`reference/targets/analysis-internals`.
