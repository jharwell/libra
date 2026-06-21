.. _design/compilers:

=================================
Compiler Support: All The Details
=================================

.. plantuml::

   !theme cerulean-outline

   skinparam DefaultFontSize 14
   skinparam defaultTextAlignment center
   skinparam TitleFontSize 24
   skinparam SequenceMessageAlignment center
   skinparam DefaultFontColor #black
   skinparam TitleFontColor #black
   skinparam ParticipantFontColor #black

   title Compiler Abstraction Layer

   skinparam componentStyle rectangle

   component "User Intent\n(e.g. Enable ASAN,\nEnable LTO)" as Intent

   component "LIBRA Compiler Interface" as Interface

   component "GCC Flags" as GCC
   component "Clang Flags" as Clang
   component "Intel LLVM Flags" as Intel

   Intent --> Interface

   Interface --> GCC
   Interface --> Clang
   Interface --> Intel

The variables in the table are an attempt at a polymorphic interface for
supporting different compilers, cmake style. In the compiler-specific sections
that follow, the shown variables have suffixes (``{_GNU,_CLANG,_INTEL}``) which
are purely to get the docs to link unambiguously and are not present in the code.

.. NOTE:: The Intel compilers are less feature-complete than others by design:
          they are targeted to working with optimized builds/codebases *later*
          in the development cycle.

GNU (gcc/g++)
==============

.. cmake-module:: ../../../cmake/libra/compile/gnu.cmake

.. NOTE:: :cmake:variable:`LIBRA_OPT_REPORT` is isn't supported for GNU
   compilers because there is not a clean/easy way to get per-file optimization
   reports without name collisions.

clang (clang/clang++)
=====================

.. cmake-module:: ../../../cmake/libra/compile/clang.cmake

Intel LLVM (icx/icpx)
=====================

.. cmake-module:: ../../../cmake/libra/compile/intel.cmake
