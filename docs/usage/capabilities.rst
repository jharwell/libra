.. SPDX-License-Identifier:  MIT

.. _usage/capabilities:

==================
LIBRA Capabilities
==================

Configure Time
==============

These are things LIBRA can do when running cmake.

File Discovery
--------------

- All files under ``src/`` ending in:

  - ``.c``
  - ``.cpp``
  - ``.cu``

  are globbed as source files (see :ref:`usage/req` for repository layout
  requirements) so that if you add a new source file, rename a source file,
  etc., you just need to re-run cmake. This means you don't have to MANUALLY
  specify all the files in the cmake project. Woo-hoo!

- All files under ``tests/`` ending in:

  - ``-utest.c``
  - ``-utest.cpp``

  are globbed as unit test files which will be compiled into executable unit
  tests at build time if ``LIBRA_TESTS=YES``.

- All files under ``tests/`` ending in:

  - ``-itest.c``
  - ``-itest.cpp``

  are globbed as integration test files which will be compiled into executable
  unit tests at build time if ``LIBRA_TESTS=YES``.

- All files under ``tests/`` ending in:

  - ``_test.c``
  - ``_test.cpp``

  are globbed as the test harness for unit/integration tests. All test harness
  files will be compiled into static libraries at build time and all test
  targets link against them if ``LIBRA_TESTS=YES``.

.. NOTE:: The difference between unit tests and integration tests is purely
          semantic, and exists solely to help organize your tests. LIBRA treats
          both types of tests equivalently.

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
``project-local.cmake``--see :ref:`usage/project-local` for details.

.. list-table::
   :widths: 5,90,5
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

     - Enable building of tests via:

       - ``make unit-tests`` (unit tests only)

       - ``make integration-tests`` (integration tests only)

       - ``make tests`` (all tests)

     - NO

   * - ``LIBRA_MT``

     - Enable multithreaded code/OpenMP code via compiler flags (e.g.,
       ``-fopenmp``), and/or selecting additional code for compilation.

     - NO

   * - ``LIBRA_MP``

     - Enable multiprocess code/MPI code for the selected compiler, if
       supported.

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

     -  RETURN

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

       * ``FATAL`` - Compile out event reporting EXCEPT FATAL events.

       * ``ERROR`` - Compile out event reporting EXCEPT [FATAL, ERROR] events.

       * ``WARN`` - Compile out event reporting EXCEPT [FATAL, ERROR, WARN]
         events.

       * ``INFO`` - Compile out event reporting EXCEPT [FATAL, ERROR, WARN,
         INFO] events.

       * ``DEBUG`` - Compile out event reporting EXCEPT [FATAL, ERROR, WARN,
         INFO, DEBUG] events.

       * ``TRACE`` - Same as ``ALL``.

       * ``NONE`` - All event reporting compiled out.

       * ``INHERIT`` - Event reporting configuration should be inherited from a
         parent project which exposes it.

     - ""

   * - ``LIBRA_PGO``

     - Generate a PGO build for the selected compiler, if supported. Possible
       values for this option are:

       - ``NONE``

       - ``GEN`` - Input stage

       - ``USE`` - Final stage (after executed the ``GEN`` build to get
         profiling info)

     - NONE

   * - ``LIBRA_DOCS``

     - Enable documentation build via ``make apidoc``.

     - NO

   * - ``LIBRA_RTD_BUILD``

     - Specify that the build is for ReadTheDocs. This suppresses the usual
       compiler version checks since we won't actually be compiling anything,
       and the version of compilers available on ReadTheDocs is probably much
       older than what LIBRA requires.

     - NO

   * - ``LIBRA_CODE_COV``

     - Build in runtime code-coverage instrumentation for use with ``make
       precoverage-report`` and ``make coverage-report``.

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

   * - ``LIBRA_ANALYSIS``

     - Enable static analysis targets for checkers, formatters, etc. Enables the
       following ``make`` targets (assuming the necessary executables are
       found):

       - ``${PROJECT_NAME}-clang-check}`` - Static analysis via ``clang-check``

       - ``${PROJECT_NAME}-tidy-check}`` - Static analysis via ``clang-tidy``

       - ``${PROJECT_NAME}-tidy-fix}`` - Static analysis AND automatic fixing of
         issues via ``clang-tidy``.

       - ``${PROJECT_NAME}-clang-format}`` - Code formatting via
         ``clang-format``.

       - ``${PROJECT_NAME}-cppcheck}`` - Static analysis via ``cppcheck``.

     - NO

   * - ``LIBRA_SUMMARY``

     - Show a configuration summary after finishing.

     - YES

   * - ``LIBRA_LTO``

     - Enable Link-Time Optimization.

     - NO

   * - ``LIBRA_OPT_REPORT``

     - Enable compiler-generated reports for optimizations performed, as well as
       suggestions for further optimizations.

     - NO



Build Time
==========

These are the things that LIBRA can do when running ``make`` (or whatever the
build engine is).

In addition to being able to actually build the software, this project enables
the following additional capabilities via targets:

.. list-table::
   :widths: 5,95
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

       - ``cppcheck-all`` - Runs ``cppcheck`` on the repository.

       - ``static-check-all`` - Runs the clang static checker on the repository.

       - ``tidy-check-all`` - Runs the clang-tidy checker on the repository,
         using the ``.clang-format`` in the root of the repo.

   * - ``unit-tests``

     - Build all of the unit tests for the project. If you want to just build a
       single unit test, you can do ``make <name of test>``. For example::

         make rcppsw-fsm-hfsm-utest

       for a single unit test named ``hfsm-utest.cpp`` that lives under
       ``tests/`` in the ``rcppsw`` project.

       Requires that ``LIBRA_TESTS=YES`` was passed to cmake during
       configuration.

   * - ``integration-tests``

     - Build all of the integration tests for the project. If you want to just
       build a single test, you can do ``make <name of test>``. For example::

         make rcppsw-fsm-itest

       for a single unit test named ``hfsm-itest.cpp`` that lives under
       ``tests/`` in the ``rcppsw`` project.

       Requires that ``LIBRA_TESTS=YES`` was passed to cmake during
       configuration.

   * - ``tests``

     - Build all of the integration and unit tests for the project; same as
       ``make unit-tests && make integration-tests``.

       Requires that ``LIBRA_TESTS=YES`` was passed to cmake during
       configuration.

   * - ``test``

     - Run all of the tests for the project via ``ctest``.

   * - ``apidoc``

     - Generate the API documentation.

   * - ``package``

     - Build one or more deployable packages using CPACK. Requires
       ``libra_configure_cpack()`` to have been called in
       ``project-local.cmake``.

   * - ``precoverage-report``

     - Run ``lcov`` to generate a baseline code coverage info (0%) for the
       entire project to eventually generate an *absolute* code coverage report
       after executing the project. That is, something like::

         make                     # Build in coverage info into project
         make unit-tests          # Build in coverage info into tests
         make precoverage-report  # Set baseline coverage info for ENTIRE project
         make test                # Populate coverage for executed parts of project
         make coverage-report     # Build ABSOLUTE coverage report for all files

       An *absolute* code coverage report uses the baseline info and the #
       lines/functions executed in all files. If there are files which have no
       functions executed, then they **WILL** be included in the results. This
       may or may not be desirable; if it is not, then don't call this target
       before running the project, and you'll get a relative report instead.

   * - ``coverage-report``

     - Run ``lcov`` to generate a code coverage report (presumably from the
       results of running unit tests, though that does not have to be the
       case). That is::

         make                 # Build in coverage info into project
         make unit-tests      # Build in coverage info into tests
         make test            # Populate coverage for executed parts of project
         make coverage-report # Build RELATIVE report for files had some execution


       Not that this is a *relative* code coverage report. That is, #
       lines/functions executed out of the total # lines/functions in all files
       which have at least one function executed. If there are files which have
       no functions executed, then they will not be included in the results,
       skewing reporting coverage. This may or may not be desirable. See
       ``precoverage-report`` if it is undesirable.

   * - ``package``

     - Build a ``.deb`` package from the project and all its sub-project (i.e.,
       a stand-alone ``.deb``). This is alpha-level functionality.

Git Commit Checking
===================

LIBRA can lint commit messages, checking they all have a consistent format. The
format is controlled by the file ``commitlint.config.js``. See the `husky
<https://www.npmjs.com/package/husky>`_ for details. The default format LIBRA
enforces is described in :ref:`dev/git-commit-guide`. To use it run ``npm
install`` in the repo where you have setup LIBRA.
