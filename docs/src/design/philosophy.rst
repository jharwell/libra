.. _design/philosophy:

=======================
LIBRA Design Philosophy
=======================

This page details the "why" behind some of the foundational design decisions
within LIBRA.

.. _design/philosophy/globbing:

Using cmake Globbing
====================

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
===========

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
=======================

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

Why Is Something Like LIBRA Even Necessary?
============================================

I.e., "Why not just put everything in CMakePresets.json and/or
CMakeUserPresets.json?" This enables a very minimal (nearly 100% reusable)
CMakeLists.txt which can be copied across projects, yielding a large degree of
reusability across CMake-enabled projects. Following this argument, why is LIBRA
even necessary if you following modern CMake best practices?

#. Some things that LIBRA does can't be done in presets (e.g., automatic
   source/test discovery, analysis registration, etc.).

#. The bitrot associated with presets-less CMake configuration has just been
   moved out of the CMakeLists.txt, and into the presets: if for a specific
   project a team decides to tweak setting X, developers would have to go back
   through all of the other projects and update the presets.

#. Pure CMake presets doesn't provide a means for teams to ensure consistency
   across many projects. LIBRA is opinionated about best practices/defaults,
   most of which can be changed on a per-project basis if needed, but it does
   provide a strong starting point.

Automate Everything
====================

By automating say, the task of running clang-tidy on a codebase, LIBRA makes it
easy to ensure that all developers, and CI/CD, run it the same way every
time. Yes, there are other ways to set that up for consistency across developers
(e.g., vscode extension), but to *also* have consistency with CI/CD, you need
a cmdline interface, and the build system is a reasonable place to put that.

Furthermore, automating "plumbing" tasks like running static analysis,
formatting, packaging, etc., LIBRA frees up developers to do things which are
much more interesting; someone solved the problem once, and it doesn't need to
be solved again.
