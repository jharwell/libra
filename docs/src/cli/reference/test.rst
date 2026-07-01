.. SPDX-License-Identifier: MIT

.. _cli/reference/test:

test
====

Build (if needed) and run tests via ``ctest``.

.. code-block:: bash

   clibra test --preset debug                      # build then run all tests
   clibra test --preset debug --type unit          # only unit-labeled tests
   clibra test --preset debug --filter '^io_'      # tests matching a regex
   clibra test --preset debug --no-build           # skip build, run ctest only

Requires :cmake:variable:`LIBRA_TESTS` to be ``ON`` in the preset's CMake
cache. ``clibra test`` first builds the ``all-tests`` target, then runs
``ctest``. Use ``--no-build`` to skip the build step and run ``ctest``
directly against already-built test binaries.

Selecting tests
---------------

``--type`` filters by test label and accepts ``all`` (the default, no
filtering), ``unit``, ``integration``, or ``regression``; the non-``all``
values map to ``ctest -L <label>``. ``--filter <regex>`` restricts the run
to tests whose names match the expression (``ctest --tests-regex``). The
two can be combined.

Run control
-----------

``--parallel <N>`` runs ``N`` tests concurrently (defaults to the logical
CPU count). ``--stop-on-failure`` halts at the first failing test.
``--rerun-failed`` runs only the tests that failed on the previous
invocation. ``--valgrind`` runs the suite under Valgrind's memcheck tool
and requires Valgrind to be installed. ``-v/--verbose`` prints the
underlying build and test commands.

CMake equivalent
----------------

.. code-block:: bash

   cmake --build --preset <name> --target all-tests
   ctest --preset <name> [--parallel <N>] [-L <label>] [--tests-regex <re>]

Flag reference
--------------

.. include:: ../../../_generated/test.md
   :parser: myst_parser.sphinx_
