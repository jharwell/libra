.. SPDX-License-Identifier: MIT

.. _cli/reference/coverage:

coverage
========

Configure (if needed) and generate a coverage report, check coverage
against configured thresholds, or both.

.. code-block:: bash

   clibra coverage --preset coverage --html          # generate HTML report
   clibra coverage --preset coverage --check         # check thresholds
   clibra coverage --preset coverage --html --open   # generate and open in browser
   clibra coverage --preset coverage --html --check  # do both

Requires :cmake:variable:`LIBRA_COVERAGE` to be ``ON`` in the preset's
CMake cache. At least one of ``--html`` or ``--check`` must be given;
running ``clibra coverage`` with neither is an error. The two may be
combined, in which case the report is generated first and the check runs
after.

``--open`` opens the generated ``index.html`` in the system browser after
a successful ``--html`` run (ignored under ``--dry-run``).

.. note::

   Unlike most other subcommands, ``clibra coverage`` reconfigures only
   when ``--reconfigure`` is passed. ``--fresh`` selects a fresh
   reconfigure but has no effect on its own — pair it with
   ``--reconfigure``.

CMake equivalent
----------------

``clibra coverage --html`` discovers the first available HTML-generating
target from the ordered list ``[gcovr-report, llvm-report]`` by querying
target availability. ``--check`` uses ``gcovr-check`` directly.

.. code-block:: bash

   # HTML report (gcovr)
   cmake --build --preset <name> --target gcovr-report

   # HTML report (llvm-cov, used if gcovr-report unavailable)
   cmake --build --preset <name> --target llvm-report

   # Threshold check
   cmake --build --preset <name> --target gcovr-check

Coverage thresholds are configured via :cmake:variable:`LIBRA_GCOVR_LINES_THRESH`,
:cmake:variable:`LIBRA_GCOVR_FUNCTIONS_THRESH`,
:cmake:variable:`LIBRA_GCOVR_BRANCHES_THRESH`, and
:cmake:variable:`LIBRA_GCOVR_DECISIONS_THRESH`. See
:ref:`usage/build-time/sw-eng` for the full target reference.

Flag reference
--------------

.. include:: ../../../_generated/coverage.md
   :parser: myst_parser.sphinx_
