.. _design/testing:

=============
Testing LIBRA
=============

LIBRA's own CMake logic is tested with
`BATS <https://github.com/bats-core/bats-core>`_ (Bash Automated
Testing System). The tests verify that compiler flags, build options,
and feature toggles work correctly across GCC, Clang, and Intel.

Running the test suite
=======================

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
   LIBRA_CONSUME_MODE=add_subdirectory bats LIBRA_COVERAGE.bats

Suite scripts forward bats options:

.. code-block:: bash

   ./suites/run_suite_add_subdirectory.sh --filter "ASAN"
   ./suites/run_suite_add_subdirectory.sh --jobs 4

Consumption modes
==================

The test suite verifies LIBRA under all supported integration methods.
``LIBRA_CONSUME_MODE`` is set automatically by the suite scripts but
can be overridden:

- ``add_subdirectory`` — via CMake's ``add_subdirectory()``
- ``installed_package`` — via ``find_package()`` after installation
- ``cpm`` — via `CPM.cmake <https://github.com/cpm-cmake/CPM.cmake>`_
- ``conan`` — via a Conan-generated CMake toolchain

Environment variables
======================

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
=============

All public ``LIBRA_*`` variables are tested, along with dependency
isolation (LIBRA features apply only to the root project, not
children that also use LIBRA). Tests build a minimal project, check
compile/link flags, and run the resulting binary and makefile targets.
Each test invocation gets its own isolated temporary build directory.
