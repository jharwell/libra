.. SPDX-License-Identifier: MIT

.. _reference/testing:

.. _usage/testing:

=================
Testing Reference
=================

LIBRA automatically discovers, registers, and runs tests when
:cmake:variable:`LIBRA_TESTS` is enabled. This page covers what LIBRA
supports and how discovery is configured. For CTest usage, filtering,
and debugging, see :ref:`concepts/testing`.

Supported test types
====================

LIBRA discovers both compiled and interpreted tests:

.. list-table::
   :header-rows: 1
   :widths: 20 80

   * - File extension
     - Interpreter / compiler

   * - ``.c``, ``.cpp``
     - Compiled and linked as a test executable.

   * - ``.py``
     - ``python3``

   * - ``.bats``
     - ``bats``

   * - ``.sh``
     - ``bash``

The interpreter used for a given extension is not currently configurable.
Interpreted tests are useful for integration and regression tests where
it is more convenient to use shell scripts or Python than compiled code.

.. _usage/testing/naming:

Test naming and matchers
========================

LIBRA discovers tests by matching filenames against configurable suffix
patterns called *matchers*. Each test category has its own matcher
variable set in ``project-local.cmake``. If a variable is not set,
LIBRA uses its built-in default.

.. list-table::
   :header-rows: 1
   :widths: 40 60

   * - CMake variable
     - Category

   * - :cmake:variable:`LIBRA_UNIT_TEST_MATCHER`
     - Unit tests (default: ``-utest``)

   * - :cmake:variable:`LIBRA_INTEGRATION_TEST_MATCHER`
     - Integration tests (default: ``-itest``)

   * - :cmake:variable:`LIBRA_REGRESSION_TEST_MATCHER`
     - Regression tests (default: ``-rtest``)

   * - :cmake:variable:`LIBRA_NEGATIVE_TEST_MATCHER`
     - Negative compilation tests (see below)

   * - :cmake:variable:`LIBRA_TEST_HARNESS_MATCHER`
     - Test harness sources (default: ``_test``)

.. _usage/testing/negative:

Negative compilation tests
==========================

Files with the extensions ``.neg.cpp`` or ``.neg.c`` are *negative
compile tests*: they are expected to **fail** compilation. LIBRA
registers each as a CTest entry that inverts the compiler exit code,
so the test passes if and only if the compiler rejects the source.

Naming convention::

  er_missing_log_error-utest.neg.cpp
  bad_struct-utest.neg.c

The compiler is selected by extension:

- ``.neg.cpp`` uses ``CMAKE_CXX_COMPILER`` with ``-std=c++${LIBRA_CXX_STANDARD}``
- ``.neg.c`` uses ``CMAKE_C_COMPILER`` with ``-std=c${LIBRA_C_STANDARD}``

**Optional** ``.expected`` **companion file**

If a file ``<n>.expected`` exists alongside the negative test source,
its contents must appear somewhere in the compiler's stderr for the
test to pass. This lets you assert not just that compilation failed,
but that it failed with the right diagnostic::

  er_missing_log_error-utest.neg.cpp   # must fail to compile
  er_missing_log_error-utest.expected  # e.g. "ER_ERROR was not called"

**Project-local knobs** (set in ``project-local.cmake``):

- :cmake:variable:`LIBRA_NEGATIVE_TEST_INCLUDE_DIRS` — additional
  include directories for negative tests.
- :cmake:variable:`LIBRA_NEGATIVE_TEST_COMPILE_FLAGS` — additional
  compiler flags for negative tests.

.. NOTE:: Negative tests cannot depend on ``PROJECT_NAME`` or its
          transitive dependencies, because they are created with
          ``add_custom_target()``. Only includes and defines from the
          main target itself can be extracted — not from its transitive
          closure. This is a CMake limitation.

Negative tests participate in the ``negative-tests`` umbrella target
and in ``build-and-test``. They receive both the category label
(e.g. ``unit``) and the ``negative`` label, so ``ctest -L negative``
selects them exclusively.

.. _usage/testing/harness:

Test harness
============

Files matching :cmake:variable:`LIBRA_TEST_HARNESS_MATCHER` under
``tests/`` are compiled into static libraries linked into every test
binary automatically:

- C harness sources (``*.c``, ``*.h``) → ``${PROJECT_NAME}-c-harness``
- C++ harness sources (``*.cpp``, ``*.hpp``) → ``${PROJECT_NAME}-cxx-harness``

Both libraries link against the main project target so that all project
includes, defines, and transitive dependencies are propagated.
``-Wno-old-style-cast`` and ``-Wno-useless-cast`` are added for C
projects to silence common C-style cast warnings in test code.
