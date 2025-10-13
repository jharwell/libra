.. SPDX-License-Identifier:  MIT

.. _philosophy:

=======================
LIBRA Design Philosophy
=======================

This page details the "why" behind some of the foundational design decisions
within LIBRA.

.. _philosophy/globbing:

Using cmake Globbing
====================

The general consensus is that globbing source files=bad in
cmake, for some very valid reasons, list below along with my experience in why
the each reason isn't a dealbreaker for using globbing.

#. Using globs can result in non-deterministic builds: the same cmake project
   might produce different results depending on the state of the filesystem. If
   new  files are added to the globbed directory, the build process might not
   detect these changes, resulting in inconsistent builds.

   However, the *benefit* of not having to modify CMakeLists.txt
   every. single. time. you add/remove files outweighs the potential pitfalls:

   - Since cmake is re-run when you add a file anyway, remembering to re-run
     manually after adding/removing files is not THAT terrible.

   - Globbing makes it trivial to move files around/rename
     files, which happens all the time during iterative design/refactoring.

   - Build inconsistency of the sort caused by globbing is only a problem w.r.t
     globbing for developers, not in CI/CD, which is what most teams use as a
     source of ground truth for "is this build broken/does this feature work".

#. When you use globbing, CMake cannot accurately track dependencies on the
   globbed files. This can lead to build failures if a globbed file is modified,
   but CMake doesn't rebuild the dependent targets.

   This is strictly true, but if you get build failures resulting from globbing,
   99% of the time you can resolve them by just re-running cmake manually to
   pick up file changes. This is both quick and low cognitive load.

   If you reference some functionality which doesn't get compiled in because you
   didn't re-run cmake, you get a linking error anyway, or a run-time error on
   dynamic library load. I have never personally seen bad functionality make
   it into a build as a result of globbing.

#. Performance overhead: Globbing can introduce performance overhead, especially
   in large projects. CMake has to perform the globbing operation every time it
   generates the build files, which can slow down the build process.

   100% true. BUT, it only matters at truly large scales (> 100,000 files); at
   less than that, I have never really noticed a difference. Plus, if you have a
   giant project with tens of thousands of source files, you probably need to
   break it up anyway.

#. Readability and maintainability: Globbing can make CMake projects less
   readable and maintainable. Explicitly listing source files makes it clear
   which files are part of the build, making it easier to understand the project
   structure and modify it in the future.

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

.. _philosophy/floor-ceiling:

Low Floor, High Ceiling
=======================

LIBRA was designed to be "low floor, high ceiling", meaning that:

- It can be pretty much dropped into any project meeting the
  :ref:`requirements<startup/req>` and requiring minimal to no effort to start
  using.

- It provides configurability for almost *every* single thing it does, so that
  users can tweak for a wide range of use cases, from building software for
  embedded environments, to optimizing code for supercomputing clusters.

This is why *everything* in LIBRA is thoroughly documented, and great effort is
put into various guides and howtos.

This is also why LIBRA can be used as a standalone framework capable of handling
cmake builds and packaging, OR as a cmake middleware / sister framework to
a package manager like conan, where it then only is responsible for things
related to building and analyzing the code.

Automate Everything
===================

By automating say, the task of running clang-tidy on a codebase, LIBRA makes it
easy to ensure that all developers, and CI/CD, run it the same way every
time. Yes, there are other ways to set that up for consistency across developers
(e.g., vscode extension), but to *also* have consistency with CI/CD, you need
a cmdline interface, and the build system is a reasonable place to put that.

Furthermore, automating "plumbing" tasks like running static analysis,
formatting, packaging, etc., LIBRA frees up developers to do things which are
much more interesting; someone solved the problem once, and it doesn't need to
be solved again.
