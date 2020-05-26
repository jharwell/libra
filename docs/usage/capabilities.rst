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

+-------------------+-------------------------------------------------------------------+---------------+
| Variable          | Description                                                       | Default       |
+-------------------+-------------------------------------------------------------------+---------------+
| ``LIBRA_TESTS``   | Enable building of unit tests via ``make unit-tests``             | NO            |
+-------------------+-------------------------------------------------------------------+---------------+
| ``LIBRA_OPENMP``  | Enable OpenMP code                                                | NO            |
+-------------------+-------------------------------------------------------------------+---------------+
| ``LIBRA_MPI``     | Enable MPI code                                                   | NO            |
+-------------------+-------------------------------------------------------------------+---------------+
| ``LIBRA_FPC``     | Enable function precondition checking (mostly used in C)          | ``FPC_ABORT`` |
|                   | This is very helpful for debugging. Possible values are:          |               |
|                   |                                                                   |               |
|                   |   - ``FPC_RETURN`` - Return without executing a function,         |               |
|                   |     but do not assert().                                          |               |
|                   |                                                                   |               |
|                   |   - ``FPC_ABORT`` - Abort the program whenever a function         |               |
|                   |     precondition fails.                                           |               |
+-------------------+-------------------------------------------------------------------+---------------+
| ``LIBRA_ER``      | Specify event reporting. Possible values are:                     | ``ALL``       |
|                   |                                                                   |               |
|                   | - ``ALL`` - Event reporting via log4cxx, which is compiled        |               |
|                   |   in fully and linked with. Both debug printing and               |               |
|                   |   logging macros enabled.                                         |               |
                                                                                        |               |
|                   | - ``FATAL`` - Disable event reporting EXCEPT for fatal            |               |
|                   |   events, use ``printf()`` for those (Log4cxx compiled            |               |
|                   |   out).  Debug logging disabled (needs log4cxx), macros           |               |
|                   |   for printing of FATAL events only enabled.                      |               |
|                   |                                                                   |               |
|                   | - ``NONE`` - Disable event reporting entirely: log4cxx            |               |
|                   |   compiled out and debug printing/logging macros disabled.        |               |
+-------------------+-------------------------------------------------------------------+---------------+
| ``LIBRA_PGO_GEN`` | Generate a PGO build, input stage, for the selected               |               |
|                   | compiler.                                                         | NO            |
+-------------------+-------------------------------------------------------------------+---------------+
| ``LIBRA_PGO_USE`` | Generate a PGO build, final stage, for the selected               |               |
|                   | compiler.                                                         | NO            |
+-------------------+-------------------------------------------------------------------+---------------+
| ``LIBRA_CHECKS``  | Build in runtime checking of code using any compiler. When        |               |
|                   | passed, the value should be a comma-separated list of             |               |
|                   | checks to enable:                                                 |               |
|                   |                                                                   |               |
|                   | ``MEM`` - Memory checking/sanitization.                           |               |
|                   | ``ADDR`` - Address sanitization.                                  |               |
|                   | ``STACK`` - Aggressive stack checking.                            |               |
|                   | ``MISC`` - Other potentially helpful checks.                      |               |
|                   |                                                                   |               |
|                   | Not all compiler configurations use all categories, and           |               |
|                   | not all combinations of checkers are compatible, so use           |               |
|                   | with care.                                                        |               |
+-------------------+-------------------------------------------------------------------+---------------+

Automation via ``make`` Targets
-------------------------------

LIBRA uses file globs and wildcards to figure out the list of files to give to
``cmake`` to build, which mens that you don't have to  manually specify all the
files in the ``cmake`` project!

In addition to being able to actually build the software, this project enables
the following additional capabilities via makefile targets:

- ``format-all`` - Run the clang formatter on the repository, using the
  ``.clang-format`` in the root of the repo.

- ``check-all`` - Run ALL enabled static checkers on the repository. If the
  repository using modules/cmake subprojects, you can also run it on a
  per-module basis. This runs the following sub-targets, which can also be run
  individually:

    - ``cppcheck-all`` - Runs ``cppcheck`` on the repository.

    - ``static-check-all`` - Runs the clang static checker on the repository.

    - ``tidy-check-all`` - Runs the clang-tidy checker on the repository, using
      the ``.clang-format`` in the root of the repo.

- ``unit-tests`` - Build all of the unit tests for the project. If you want to
  just build a single unit test, you can do ``make <project name>-<class
  name>-test``. For example::

    make rcppsw-hfsm-test

  for a single unit test named ``hfsm-test.cpp`` that lives under ``tests/`` in
  the ``rcppsw`` project.

- ``test`` - Run all of the tests for the project via ``ctest``.
