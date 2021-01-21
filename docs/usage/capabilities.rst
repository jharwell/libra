LIBRA Capabilities
==================

Build Modes
-----------

There are 3 build modes that I use, which are different from the default ones
that ``cmake`` uses, because they did not do what I wanted.

- ``DEV`` - Development mode. Turns on all compiler warnings and NO optimizations.

- ``DEVOPT`` - Development mode + light optimizations. Turns on all compiler
  warnings + ``-Og`` + parallelization (if configured). Does not define
  ``NDEBUG``.

- ``OPT`` - Optimized mode. Turns on all compiler warnings and maximum
  optimizations (``O2``), which is separate from enabled automatic/OpenMP based
  paralellization. Defines ``NDEBUG``.

Build Process Options
---------------------

The following variables are available for fine-tuning the build process:

.. list-table::
   :widths: 25,50,50
   :header-rows: 1

   * - Variable

     - Description

     - Default

   * -  ``LIBRA_TESTS``

     - Enable building of unit tests via ``make unit-tests``.

     - NO

   * - ``LIBRA_OPENMP``

     - Enable OpenMP code

     - NO

   * - ``LIBRA_MPI``

     - Enable MPI code

     - NO

   * - ``LIBRA_FPC``

     - Enable function precondition checking (mostly used in C).  This is very
       helpful for debugging. Possible values are:

       * ``FPC_RETURN`` - Return without executing a function, but do not
         assert().

       * ``FPC_ABORT`` - Abort the program whenever a function precondition
         fails.

     - ``FPC_ABORT``

   * - ``LIBRA_ER``

     - Specify event reporting. Possible values are:

       * ``ALL`` - Event reporting via log4cxx, which is compiled in fully and
         linked with. Both debug printing and logging macros enabled.

       * ``FATAL`` - Disable event reporting EXCEPT for fatal events, use
         ``printf()`` for those (Log4cxx compiled out).  Debug logging disabled
         (needs log4cxx), macros for printing of FATAL events only enabled.

       * ``NONE`` - Disable event reporting entirely: log4cxx compiled out and
         debug printing/logging macros disabled.

     - ``ALL``


   * - ``LIBRA_PGO_GEN``

     - Generate a PGO build, input stage, for the selected compiler.

     - NO

   * - ``LIBRA_PGO_USE``

     - Generate a PGO build, final stage, for the selected compiler.

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
       compiler; the thread sanitizer is incomptable with some other sanitizer
       groups.

     - ""


Automation via ``make`` Targets
-------------------------------

LIBRA uses file globs and wildcards to figure out the list of files to give to
``cmake`` to build, which mens that you don't have to  manually specify all the
files in the ``cmake`` project!

In addition to being able to actually build the software, this project enables
the following additional capabilities via makefile targets:

.. list-table::
   :widths: 25,50
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
       single unit test, you can do ``make <project name>-<root namespace>-<class
       name>-utest``. For example::

         make rcppsw-fsm-hfsm-utest

       for a single unit test named ``hfsm-utest.cpp`` that lives under
       ``tests/`` in the ``rcppsw`` project in the ``fsm`` namespace. Requires
       that ``LIBRA_TESTS=YES`` was passed to cmake during configuration.

   * - ``test``

     - Run all of the tests for the project via ``ctest``.

   * - ``coverage-report``

     - Run ``lcov`` to generate a code coverage report (presumably from the
       results of running unit tests, though that does not have to be the
       case). That is::

         make unit-tests
         make test
         make coverage-report
