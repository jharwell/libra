.. SPDX-License-Identifier:  MIT

.. _ln-libra-capabilities:

==================
LIBRA Capabilities
==================

Configure Time
==============

These are things LIBRA can do when running cmake.

File Discovery
--------------

LIBRA globs all files under ``src/`` (see :ref:`ln-libra-req` for repository
layout requirements) so that if you add a new source file, rename a source file,
etc., you just need to re-run cmake. This means you don't have to MANUALLY
specify all the files in the cmake project. Woo-hoo!


Build Modes
-----------

There are 3 build modes that I use, which are different from the default ones
that ``cmake`` uses, because they did not do what I wanted.

- ``DEV`` - Development mode. Turns on all compiler warnings and NO
  optimizations.

- ``DEVOPT`` - Development mode + light optimizations. Turns on all compiler
  warnings + ``-Og`` + parallelization (if configured). Does not define
  ``NDEBUG``.

- ``OPT`` - Optimized mode. Turns on all compiler warnings and maximum
  optimizations (``O2``), which is separate from enabled automatic/OpenMP based
  paralellization. Defines ``NDEBUG``.

If you don't select one via ``-DCMAKE_BUILD_TYPE=XXX`` at configure time, you
get ``DEV``.

Configuring The Build Process
-----------------------------

The following variables are available for fine-tuning the build process. All of
these variables can be specified on the command line, or put in your
``project-local.cmake``--see :ref:`ln-libra-project-local` for details.

.. list-table::
   :widths: 25,50,50
   :header-rows: 1

   * - Variable

     - Description

     - Default

   * - ``LIBRA_DEPS_PREFIX``

     - The location where cmake should search for other locally installed
       libraries (e.g., ``$HOME/.local``). VERY useful to separate out 3rd party
       headers which you want to suppress all warnings for by treating them as
       system headers when you can't/don't want to install things as root.

     - ``$HOME/.local/system``

   * -  ``LIBRA_TESTS``

     - Enable building of unit tests via ``make unit-tests``.

     - NO

   * - ``LIBRA_OPENMP``

     - Enable OpenMP code for the selected compiler, if supported.

     - NO

   * - ``LIBRA_MPI``

     - Enable MPI code for the selected compiler, if supported

     - NO

   * - ``LIBRA_FPC``

     - Enable Function Precondition Checking (FPC): checking function
       parameters/global state before executing a function, for functions which
       a library/application has defined conditions for. LIBRA does not define
       *how* precondition checking is implemented for a given
       library/application using it, only a simple declarative interface for
       specifying *what* type of checking is desired at build time; a library
       application can choose how to interpret the specification. This
       flexibility and simplicity is part of what makes LIBRA a very useful
       build process front-end across different projects.

       FPC is, generally speaking, mostly used in C, and is very helpful for
       debugging, but can slow things down in production builds. Possible values
       for this option are:

       * ``NONE`` - Checking compiled out.

       * ``RETURN`` - If at least one precondition is not met, return without
         executing the function. Do not abort() the program.

       * ``ABORT`` - If at least one precondition is not met, abort() the
         program.

       * ``INHERIT`` - FPC configuration should be inherited from a parent
         project which exposes it.

   * - ``LIBRA_ERL``

     - Specify Event Reporting Level (ERL). LIBRA does not prescribe a given
       event reporting framework (e.g., log4ccx, log4c) which must be
       used. Instead, it provides a simple declarative interface for specifying
       the desired *result* of framework configuration at the highest
       level. Possible values of this option are:

       * ``ALL`` - Event reporting is compiled in fully and linked with; that
         is, all possible events of all levels are present in the compiled
         binary, and whether an encountered event is emitted is dependent on the
         level and scope of the event (which may be configured at runtime).

       * ``FATAL`` - Disable and compile out event reporting EXCEPT for FATAL
         events.

       * ``ERROR`` - Disable and compile out event reporting EXCEPT for [FATAL,
         ERROR] events.

       * ``WARN`` - Disable and compile out event reporting EXCEPT for [FATAL,
         ERROR, WARN] events.

       * ``INFO`` - Disable and compile out event reporting EXCEPT for [FATAL,
         ERROR, WARN, INFO] events.

       * ``DEBUG`` - Disable and compile out event reporting EXCEPT for [FATAL,
         ERROR, WARN, INFO, DEBUG] events.

       * ``TRACE`` - Same as ``ALL``.

       * ``NONE`` - Disable event reporting entirely: all logging compiled out.

       * ``INHERIT`` - Event reporting configuration should be inherited from a
         parent project which exposes it.


   * - ``LIBRA_PGO_GEN``

     - Generate a PGO build, input stage, for the selected compiler, if
       supported.

     - NO

   * - ``LIBRA_PGO_USE``

     - Generate a PGO build, final stage, for the selected compiler, if
       supported.

     - NO

   * - ``LIBRA_DOCS``

     - Enable documentation build.

     - YES

   * - ``LIBRA_RTD_BUILD``

     - Specify that the build is for ReadTheDocs. This suppresses the usual
       compiler version checks since we won't actually be compiling anything,
       and the version of compilers available on ReadTheDocs is probably much
       older than what LIBRA requires.

     - NO

   * - ``LIBRA_CODE_COV``

     - Build in runtime code-coverage instrumentation for use with ``make
       coverage-report``.

     - NO

   * - ``LIBRA_SAN``

     - Build in runtime checking of code using any compiler. When passed, the
       value should be a comma-separated list of sanitizer groups to enable:

       * ``MSAN`` - Memory checking/sanitization.

       * ``ASAN`` - Address sanitization.

       * ``SSAN`` - Aggressive stack checking.

       * ``UBSAN`` - Undefined behavior checks.

       * ``TSAN`` - Multithreading checks.

       The first 4 can generally be stacked together without issue. Depending on
       compiler; the thread sanitizer is incompatible with some other sanitizer
       groups.

     - ""

   * - ``LIBRA_VALGRIND_COMPAT``

     - Disable compiler instructions in 64-bit code so that programs will run
       under valgrind reliably.

     - NO

Build Time
==========

These are the things that LIBRA can do when running ``make`` (or whatever the
build engine is).

In addition to being able to actually build the software, this project enables
the following additional capabilities via targets:

.. list-table::
   :widths: 30,70
   :header-rows: 1

   * - ``make`` target

     - Description

   * - ``format-all``

     - Run the clang formatter on the repository, using the ``.clang-format`` in
       the root of the repo.

   * - ``check-all``

     - Run ALL enabled static checkers on the repository. If the repository
       using modules/cmake subprojects, you can also run it on a per-module
       basis. This runs the following sub-targets, which can also be run
       individually:

       * ``cppcheck-all`` - Runs ``cppcheck`` on the repository.

       * ``static-check-all`` - Runs the clang static checker on the repository.

       * ``tidy-check-all`` - Runs the clang-tidy checker on the repository,
         using the ``.clang-format`` in the root of the repo.

   * - ``unit-tests``

     - Build all of the unit tests for the project. If you want to just build a
       single unit test, you can do ``make <project name>-<root
       namespace>-<class name>-utest``. For example::

         make rcppsw-fsm-hfsm-utest

       for a single unit test named ``hfsm-utest.cpp`` that lives under
       ``tests/`` in the ``rcppsw`` project in the ``fsm`` namespace. Requires
       that ``LIBRA_TESTS=YES`` was passed to cmake during configuration.

   * - ``test``

     - Run all of the tests for the project via ``ctest``.

   * - ``apidoc``

     - Generate the API documentation.

   * - ``package``

     - Build one or more deployable packages using CPACK. Requires
       ``libra_configure_cpack()`` to have been called in
       ``project-local.cmake``.

   * - ``coverage-report``

     - Run ``lcov`` to generate a code coverage report (presumably from the
       results of running unit tests, though that does not have to be the
       case). That is::

         make unit-tests
         make test
         make coverage-report

   * - ``package``

     - Build a ``.deb`` package from the project and all its sub-project (i.e.,
       a stand-alone ``.deb``). This is alpha-level functionality.

Git Commit Checking
===================

LIBRA can lint commit messages, checking they all have a consistent format. The
format is controlled by the file ``commitlint.config.js``. See the `husky
<https://www.npmjs.com/package/husky>`_ for details. The default format LIBRA
enforces is described in :ref:`ln-libra-git-commit-guide`. To use it run ``npm
install`` in the repo where you have setup LIBRA.
