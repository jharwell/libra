.. _usage/testing:

=======
Testing
=======

LIBRA attempts to make building and running unit/integration/etc tests as
painless as possible through automatic test discovery if
:cmake:variable:`LIBRA_TESTS` is enabled. To enable tests, pass
``-DLIBRA_TESTS=ON`` at configure time::

  cmake -DLIBRA_TESTS=ON <other options> ..

LIBRA supports automatic discovery, registration, and running of compiled and
non-compiled tests transparently. Currently tests can be any of the following:

.. list-table::
   :header-rows: 1

   * - File extension
     - Interpreter used?

   * - .c
     - N/A

   * - .cpp
     - N/A

   * - .py
     - ``python3``

   * - .bats
     - ``bats``

   * - .sh
     - ``bash``

There is not currently a way to change the interpreter used; this may change in
a future version of LIBRA. You may wonder "Why does LIBRA support discovery of
interpreted tests--it's a C/C++ CMake framework?", and that's a valid
question. The answer is that it is often more convenient to write tests in other
languages/using other cmdline tools for {integration,regression} tests (though
of course that doesn't *have* to be the case).

.. _usage/testing/builtin:

Leveraging CTest
================

.. _usage/testing/builtin/building:

Building and Running Tests
--------------------------

You can't add dependencies to the ``test`` target to build the tests and then
run them in a single command; this is a CMake restriction. Thus, in LIBRA ``make
test`` *runs* all built tests, but does not build any tests; adding tests as
dependencies to this built-in target doesn't work. If you want to build *AND*
run tests in one shot, do ``make build-and-test``.

.. _usage/testing/builtin/filtering:

Filtering and Running Specific Tests
-------------------------------------

Registered tests are grouped into categories, so you can run only a single
category of tests if you want::

  ctest -L {unit,regression,integration}

Tests are assigned to these categories based on the type they were registered as
(e.g., unit, regression). To run a single test by name::

  ctest -R <test_name>

To run multiple tests matching a pattern::

  ctest -R "myfeature.*"

.. _usage/testing/builtin/debugging:

Debugging Failing Tests
-----------------------

By default CTest suppresses test output. To see output from failing tests::

  ctest --output-on-failure

For full verbose output from all tests::

  ctest -V

For even more detail (e.g. the exact commands being run)::

  ctest -VV

Or, if you'd like to use ``CMakeUserPresets.json``::

  "testPresets": [
    {
      "name": "default",
      "configurePreset": "debug",
      "output": {
        "outputOnFailure": true,
        "verbosity": "verbose"
      }
    }
  ]

``verbosity`` can be "default", "verbose", or "extra" (equivalent to -V and
-VV). You probably want ``outputOnFailure`` always on but leave verbosity at
"default" unless you're actively debugging - it gets noisy otherwise.

.. _usage/testing/builtin/blessing:

Blessing Test Outputs
---------------------

If you have tests which require comparison with a known good set of outputs,
you can set ``BLESS=1`` on the cmdline, and it will be passed to the test, so
that updating all "blessed" outputs at once is straightforward. E.g.::

  BLESS=1 ctest            # Run all tests and bless all outputs
  BLESS=1 ctest -L regression  # Run regression tests and bless all outputs

LIBRA does not provide functionality to only bless a single test or update
individual outputs.

.. _usage/testing/default-build:

Tests Are Not Included In Default Build
=======================================

When writing code with LIBRA, your coding can be broken down in the following
functional ways:

.. list-table::
   :header-rows: 1

   * - Category

     - Include tests?

     - Why?


   * - Initial code development

     - No

     - You are just trying to get something implemented, and aren't worried
       *yet* about getting test coverage, just that your code builds. Thus,
       having to wait for tests to build is a minor inconvenience (only would
       happen after the library/executable you are modifying finally compiles).

   * - Writing tests to validate the code you just wrote

     - Yes

     - Since you are actively writing unit/integration/etc tests, logically you
       want to build the tests with a single command to minimize cognitive
       load. LIBRA provides this; all ``XX-test`` targets depend on the main
       executable/library.

   * - Validating the code you just wrote in a broader sense (e.g., in
       integration, on real hw, etc.).

     - No

     - The code you wrote has already passed its unit/integration tests; if it
       didn't you wouldn't be testing it at a higher level. Thus, having to wait
       for potentially a large number of unit tests to build and link repeatedly
       is a waste of time.

       This use case is the primary reason why LIBRA does not include any
       defined tests in the default build.


Using CDash
===========

CTest also has the ability to build and run tests, gather coverage info, and
report results to a centralized server; LIBRA does not currently use this
functionality, though it might in the future.

Testing LIBRA Itself
====================
LIBRA uses `BATS <https://github.com/bats-core/bats-core>`_ (Bash Automated
Testing System) for testing its CMake configuration logic. The tests verify that
compiler flags, build options, and feature toggles work correctly across
different compilers (GNU, Clang, Intel).

Running LIBRA's Tests
---------------------
Tests are run via suite scripts under ``tests/suites/``. Each script sets the
appropriate consumption mode and invokes all ``.bats`` files together in
parallel (using ``bats -j $(nproc)``)::

    cd tests
    ./suites/run_suite_add_subdirectory.sh
    ./suites/run_suite_conan.sh
    ./suites/run_suite_cpm.sh
    ./suites/run_suite_installed_package.sh

Individual test files can also be run directly, but require setting
``LIBRA_CONSUME_MODE`` explicitly::

    LIBRA_CONSUME_MODE=add_subdirectory bats LIBRA_SAN.bats
    LIBRA_CONSUME_MODE=add_subdirectory bats LIBRA_CODE_COV.bats

The suite scripts also accept bats options directly, for example to filter to
specific tests or control parallelism::

    ./suites/run_suite_add_subdirectory.sh --filter "ASAN"
    ./suites/run_suite_add_subdirectory.sh --jobs 4

Consumption Modes
-----------------
LIBRA can be consumed by a project in several ways, and the test suite verifies
correctness under each mode. The mode is controlled by the
``LIBRA_CONSUME_MODE`` environment variable and set automatically by the suite
scripts:

- ``add_subdirectory`` — LIBRA is included via CMake's ``add_subdirectory()``
- ``installed_package`` — LIBRA is installed and found via ``find_package()``
- ``cpm`` — LIBRA is fetched and included via `CPM.cmake <https://github.com/cpm-cmake/CPM.cmake>`_
- ``conan`` — LIBRA is consumed as a Conan package with a generated CMake toolchain

Test Environment Variables
--------------------------
The following environment variables control test behavior:

- ``COMPILER_TYPE`` — compiler family to test: ``gnu``, ``clang``, or
  ``intel`` (default: ``gnu``)
- ``CMAKE_BUILD_TYPE`` — build type passed to CMake (default: ``Debug``)
- ``LOGLEVEL`` — CMake log verbosity level (default: ``STATUS``)
- ``LIBRA_CONSUME_MODE`` — consumption mode; set automatically by suite scripts
  but can be overridden manually

Test Coverage
-------------

All public vars (``LIBRA_XX``)are tested, along with:

- Dependency isolation - all LIBRA magic only applied to root in dependency
  chain, not any children using LIBRA.

Where applicable, tests build a minimal ``sample_build_info`` project, generates
a ``build_info`` file containing all compile/link flags, verifies that expected
flags are present or absent, and executes the resulting binary and makefile
targets. Tests run in parallel with each invocation receiving its own isolated
temporary build directory to avoid collisions.
