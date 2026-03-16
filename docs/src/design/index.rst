.. SPDX-License-Identifier:  MIT

.. _design:

======
Design
======

This page documents LIBRA's internal design from an architecture and
implementation point of view.

LIBRA API Conventions
=====================

- All public API functions/macros start with ``libra_``; anything else is
  non-API and can change at any time.

- All public API variables start with ``LIBRA_``; anything else is non-API and
  can change at any time.

- All private API functions/macros start with ``_libra_``. They should never be
  used outside of LIBRA itself.

- All private API variables start with ``_LIBRA_``. They should never be used
  outside of LIBRA itself. Private API variables are ones which have some
  semantic significance beyond just a temp variable for calculations.

Conan Integration Details
=========================

Build Types
-----------

LIBRA only current supports compiler-based features (e.g., ``LIBRA_LTO``) for
the following cmake build types:

- Debug

- Release

Not because it *can't* support other build types, but because the ones above are
the most common. It is very straightforward to add other build types if needed.

Variables
---------

LIBRA inherits the following cmake variables set by conan, sets the value of
its internal variable from them:

.. list-table::
   :header-rows: 1

   * - conan Variable

     - LIBRA Variable

   * - BUILD_TESTING

     - LIBRA_TESTS


make Targets
------------

The following ``make`` targets are not available (package-y things handled by
conan):

- ``package``

- ``install``

.. _design/compilers:

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

   * - :cmake:variable:`LIBRA_BUILD_PROF`
     - Yes
     - Yes
     - No

   * - :cmake:variable:`LIBRA_FORTIFY`
     - Yes
     - Yes
     - No

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
-------------

.. cmake-module:: ../../../cmake/libra/compile/gnu.cmake

.. NOTE:: :cmake:variable:`LIBRA_OPT_REPORT` is isn't supported for GNU
   compilers because there is not a clean/easy way to get per-file optimization
   reports without name collisions.

clang (clang/clang++)
---------------------

.. cmake-module:: ../../../cmake/libra/compile/clang.cmake

Intel LLVM (icx/icpx)
---------------------

.. cmake-module:: ../../../cmake/libra/compile/intel.cmake

.. _design/philosophy:

LIBRA Design Philosophy
=======================

This page details the "why" behind some of the foundational design decisions
within LIBRA.

.. _design/philosophy/globbing:

Using cmake Globbing
--------------------

The general consensus is that globbing source files=bad in
cmake, for some very valid reasons, listed below along with my experience in why
the each reason isn't a dealbreaker for using globbing.

#. **Using globs can result in non-deterministic builds: the same cmake project
   might produce different results depending on the state of the filesystem. If
   new  files are added to the globbed directory, the build process might not
   detect these changes, resulting in inconsistent builds.**

   - If your filesystem is behaving oddly, then you probably have bigger
     problems than just CMake.

   - Since cmake is re-run when you add a file anyway, remembering to re-run
     manually after adding/removing files is not THAT terrible.

   - Globbing makes it trivial to move files around/rename
     files, which happens all the time during iterative design/refactoring.

   - Build inconsistency of the sort caused by globbing is only a problem w.r.t
     globbing for developers, not in CI/CD, which is what most teams use as a
     source of ground truth for "is this build broken/does this feature work".

#. **When you use globbing, CMake cannot accurately track dependencies on the
   globbed files. This can lead to build failures if a globbed file is modified,
   but CMake doesn't rebuild the dependent targets.**

   This is strictly true, but if you get build failures resulting from globbing,
   99% of the time you can resolve them by just re-running cmake manually to
   pick up file changes. This is both quick and low cognitive load.

   If you reference some functionality which doesn't get compiled in because you
   didn't re-run cmake, you get a linking error anyway, or a run-time error on
   dynamic library load. I have never personally seen bad functionality make
   it into a build as a result of globbing.

#. **Performance overhead: Globbing can introduce performance overhead,
   especially in large projects. CMake has to perform the globbing operation
   every time it generates the build files, which can slow down the build
   process.**

   100% true. BUT, it only matters at truly large scales (> 100,000 files); at
   less than that, I have never really noticed a difference. Plus, if you have a
   giant project with tens of thousands of source files, you probably need to
   break it up anyway.

#. **Readability and maintainability: Globbing can make CMake projects less
   readable and maintainable. Explicitly listing source files makes it clear
   which files are part of the build, making it easier to understand the project
   structure and modify it in the future.**

   Readability/maintainability are in the eye of the beholder. Projects which
   have dozens of CMakeLists.txt in dozens of different directories, each of
   which adds a few source files to the set to build for a targets are arguably
   much less readable and maintainable than a glob based approach. Glob based
   approaches also have the advantage that MRs are not cluttered with
   CMakeLists.txt changes that 99% of reviewers ignore, but still have to
   parse.

   Globbing is also necessary if you want to create a re-usable cmake framework
   that developers can drop in to a project, hook into, and then quickly get
   back to developing; I can't tell you how many hours I've spent
   copying/pasting cmake code across projects, and then later having to make the
   SAME update in multiple repos because we needed to tweak some aspect of how
   we built some of our projects.

.. _design/philosophy/build-types:

Build Types
-----------

CMake provides the following build types:

.. list-table::
   :header-rows: 1

   * - Build type
     - Compiler flags

   * - Debug
     - ``-O0 -g``

   * - Release
     - ``-O3 -DNDEBUG``

   * - RelWithDebInfo
     - ``-O2 -DNDEBUG -g``

   * - MinSizeRel
     - ``-Os -DNDEBUG``


These build types cover a very large number of common use cases. E.g.:

.. list-table::
   :header-rows: 1

   * - Activity
     - Build properties desired
     - Maps to?

   * - Initial development
     - No optimizations, all assert()s enabled, debugging information included.
     - ``Debug``.

   * - Late stage debugging
     - Max optimizations, assert()s could be compiled in/out, as
       needed. Debugging information included for debugger usage.
     - No direct match. ``Release`` maximizes optimizations via ``-O3``, but
       also compiles out all assertions and doesn't include debug
       info. ``RelWithDebInfo`` usually has ``-O2``, includes debug info, but
       compiles out assert()S. However, when either of these is used in tandem
       with a well-designed logging system, this is usually not a problem;
       wrapped assert()s can still fire and emit a message, even if execution
       continues.

   * - Release to customer
     - Max optimizations, no assert()s, or debug information.
     - Yes - ``Release``.

Thus, LIBRA does not define any custom build types, preferring to not add
additional complexity when it does not provide strong benefit.

An important consequence of this is that because CMake does not define default
linker flags for each build type, it relies on compiler behavior to generate
link-time optimizations of the appropriate level, if they are enabled. E.g., the
GCC manpage says:

.. code-block:: bash

   If you do not specify an optimization level option -O at link time, then GCC
   uses the highest optimization level used when compiling the object files.

So *maybe* if you pass ``-O3`` to a source file you get that for the LTO level,
but again maybe not:

.. code-block:: bash

  To use the link-time optimizer, -flto and optimization options should be
  specified at compile time and during the final link.  It is recommended that
  you compile all the files participating in the same link with the same options
  and also specify those options at link time.


Further complicating the picture, clang/intel compilers give you ``-O2`` if LTO
is enabled, for a release build compiled with ``-O3``. So, following the
principle of least surprise, LIBRA copies the compile-time optimization level
associated with a given build type to the link options for all registered
targets. This is apparently a historical oversight in CMake's design.

.. _design/philosophy/floor-ceiling:

Low Floor, High Ceiling
-----------------------

LIBRA was designed to be "low floor, high ceiling", meaning that:

- It works out-of-the-box as much as possible with any repo or dependency chain
  of repos meeting the minimum requirements. For a dependency chain, that means
  building all dependent repos in ``Release`` mode by default, and allowing the
  user to specify the build type they want for the root of the chain, if any. In
  addition, that means *only* creating targets, applying flags, etc. to targets
  created in the root of the chain. In other words, the Principle of Least
  Surprise at work.

- It can be pretty much dropped into any project meeting the
  :ref:`requirements<concepts/project-setup/layout>` and requires minimal to no
  effort to start using.

- It provides configurability for almost *every* single thing it does, so that
  users can tweak for a wide range of use cases, from building software for
  embedded environments, to optimizing code for supercomputing clusters.

This is why *everything* in LIBRA is thoroughly documented, and great effort is
put into various guides and howtos.  This is also why LIBRA can be used as a
standalone framework capable of handling cmake builds and packaging, OR as a
cmake middleware / sister framework to a package manager like conan, where it
then only is responsible for things related to building and analyzing the code.

Automate Everything
-------------------

By automating say, the task of running clang-tidy on a codebase, LIBRA makes it
easy to ensure that all developers, and CI/CD, run it the same way every
time. Yes, there are other ways to set that up for consistency across developers
(e.g., vscode extension), but to *also* have consistency with CI/CD, you need
a cmdline interface, and the build system is a reasonable place to put that.

Furthermore, automating "plumbing" tasks like running static analysis,
formatting, packaging, etc., LIBRA frees up developers to do things which are
much more interesting; someone solved the problem once, and it doesn't need to
be solved again.

Testing LIBRA
=============

LIBRA's own CMake logic is tested with
`BATS <https://github.com/bats-core/bats-core>`_ (Bash Automated
Testing System). The tests verify that compiler flags, build options,
and feature toggles work correctly across GCC, Clang, and Intel.

Running the test suite
----------------------

Tests run via suite scripts under ``tests/suites/``. Each script sets
the consumption mode and runs all ``.bats`` files in parallel:

.. code-block:: bash

   cd tests
   ./suites/run_suite_add_subdirectory.sh
   ./suites/run_suite_conan.sh
   ./suites/run_suite_cpm.sh
   ./suites/run_suite_installed_package.sh

Run an individual ``.bats`` file directly with an explicit consumption
mode:

.. code-block:: bash

   LIBRA_CONSUME_MODE=add_subdirectory bats LIBRA_SAN.bats
   LIBRA_CONSUME_MODE=add_subdirectory bats LIBRA_CODE_COV.bats

Suite scripts forward bats options:

.. code-block:: bash

   ./suites/run_suite_add_subdirectory.sh --filter "ASAN"
   ./suites/run_suite_add_subdirectory.sh --jobs 4

Consumption modes
-----------------

The test suite verifies LIBRA under all supported integration methods.
``LIBRA_CONSUME_MODE`` is set automatically by the suite scripts but
can be overridden:

- ``add_subdirectory`` — via CMake's ``add_subdirectory()``
- ``installed_package`` — via ``find_package()`` after installation
- ``cpm`` — via `CPM.cmake <https://github.com/cpm-cmake/CPM.cmake>`_
- ``conan`` — via a Conan-generated CMake toolchain

Environment variables
---------------------

.. list-table::
   :header-rows: 1
   :widths: 35 65

   * - Variable
     - Description

   * - ``COMPILER_TYPE``
     - Compiler family: ``gnu``, ``clang``, or ``intel``.
       Default: ``gnu``.

   * - ``CMAKE_BUILD_TYPE``
     - Build type passed to CMake. Default: ``Debug``.

   * - ``LOGLEVEL``
     - CMake log verbosity level. Default: ``STATUS``.

   * - ``LIBRA_CONSUME_MODE``
     - Integration method. Set automatically by suite scripts.

Test coverage
-------------

All public ``LIBRA_*`` variables are tested, along with dependency
isolation (LIBRA features apply only to the root project, not
children that also use LIBRA). Tests build a minimal project, check
compile/link flags, and run the resulting binary and makefile targets.
Each test invocation gets its own isolated temporary build directory.

.. toctree::
   :maxdepth: 1
   :hidden:

   cli
