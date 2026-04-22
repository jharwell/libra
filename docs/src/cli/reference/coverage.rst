.. SPDX-License-Identifier: MIT

.. _cli/reference/coverage:

coverage
========

Configure (if needed) and generate a coverage report, or check coverage
against configured thresholds.

.. code-block:: bash

   clibra coverage --preset coverage          # generate HTML report
   clibra coverage --preset coverage --check  # check thresholds
   clibra coverage --preset coverage --open   # generate and open in browser

Requires :cmake:variable:`LIBRA_COVERAGE` to be ``ON`` in the preset's
CMake cache.

CMake equivalent
----------------

``clibra coverage`` discovers the first available HTML-generating target
from the ordered list ``[gcovr-report, llvm-report]`` by querying the
``help-targets`` output. The check target (``gcovr-check``) is looked up
directly.

.. code-block:: bash

   # HTML report (gcovr)
   cmake --build --preset <n> --target gcovr-report

   # HTML report (llvm-cov, used if gcovr-report unavailable)
   cmake --build --preset <n> --target llvm-report

   # Threshold check
   cmake --build --preset <n> --target gcovr-check

Coverage thresholds are configured via :cmake:variable:`LIBRA_GCOVR_LINES_THRESH`,
:cmake:variable:`LIBRA_GCOVR_FUNCTIONS_THRESH`,
:cmake:variable:`LIBRA_GCOVR_BRANCHES_THRESH`, and
:cmake:variable:`LIBRA_GCOVR_DECISIONS_THRESH`. See
:ref:`usage/build-time/sw-eng` for the full target reference.

Flag reference
--------------

.. include:: ../../../_generated/coverage.md
   :parser: myst_parser.sphinx_
