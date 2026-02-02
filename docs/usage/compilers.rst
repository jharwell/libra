..
   Copyright 2026 John Harwell, All rights reserved.

   SPDX-License-Identifier:  MIT

.. _usage/compilers:

=================================
Compiler Support: All The Details
=================================

This pages summarizes how the supported compilers interact with the variables
described on :ref:`usage/configure-time` and :ref:`usage/project-local`.
The variables in the table are an attempt at a polymorphic interface for
supporting different compilers, cmake style. In the compiler-specific sections
that follow, the shown variables have suffixes (``{_GNU,_CLANG,_INTEL}``) which
are pure to get the docs to link unambiguously and are not present in the code.

.. NOTE:: The Intel compilers are less feature-complete than others by design:
          they are targeted to working with optimized builds/codebases *later*
          in the development cycle.

.. list-table::
   :header-rows: 1

   * - LIBRA Variable
     - gcc/g++
     - clang/clang++
     - icx/icpx

   * - :cmake:variable:`LIBRA_DEBUG_INFO`
     - Yes
     - Yes
     - Yes

   * - :cmake:variable:`LIBRA_BUILD_PROF`
     - No
     - Yes
     - No

   * - :cmake:variable:`LIBRA_FORTIFY`
     - Yes
     - Yes
     - No

   * - :cmake:variable:`LIBRA_OPT_LEVEL`
     - Yes
     - Yes
     - Yes

   * - :cmake:variable:`LIBRA_NATIVE_OPT`
     - Yes
     - Yes
     - Yes

   * - :cmake:variable:`LIBRA_C_DIAG_CANDIDATES`
     - Yes
     - Yes
     - Yes

   * - :cmake:variable:`LIBRA_CXX_DIAG_CANDIDATES`
     - Yes
     - Yes
     - Yes

   * - :cmake:variable:`LIBRA_SAN`
     - Yes, all types
     - Yes, all types
     - Yes, all types

   * - :cmake:variable:`LIBRA_PGO`
     - Yes
     - Yes
     - Yes

   * - :cmake:variable:`LIBRA_CODE_COV`
     - Yes
     - Yes
     - No

   * - :cmake:variable:`LIBRA_VALGRIND_COMPAT`
     - Yes
     - Yes
     - No

   * - :cmake:variable:`LIBRA_STDLIB`
     - Yes
     - Yes
     - Yes

   * - :cmake:variable:`LIBRA_OPT_REPORT`
     - No
     - Yes
     - Yes


GNU (gcc/g++)
=============

.. cmake-module:: ../../cmake/libra/compile/gnu.cmake

.. NOTE:: :cmake:variable:`LIBRA_OPT_REPORT` is isn't supported for GNU
   compilers because there is not a clean/easy way to get per-file optimization
   reports without name collisions.

clang (clang/clang++)
=====================

.. cmake-module:: ../../cmake/libra/compile/clang.cmake

Intel LLVM (icx/icpx)
=====================

.. cmake-module:: ../../cmake/libra/compile/intel.cmake
