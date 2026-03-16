.. SPDX-License-Identifier: MIT

.. _reference/targets:

.. _usage/build-time:

================
Target reference
================

All LIBRA build targets. Targets are only defined for the top-level
CMake ``project()`` — dependent projects that also use LIBRA are
unaffected.

For a conceptual overview of how targets are organised and the
availability model, see :ref:`concepts/targets`. For common workflows
using these targets, see :ref:`concepts/build-lifecycle`.

.. NOTE:: All examples assume the Ninja or Unix Makefiles generator.
          Adjust ``make`` → ``cmake --build .`` as needed.

.. _usage/build-time/help:

Discovery
=========

.. list-table::
   :widths: 20 80
   :header-rows: 1

   * - Target
     - Description

   * - ``help-targets``
     - Emit a table of all LIBRA targets, whether or not they are
       enabled/available, and — more importantly — *why*. E.g., a
       necessary program was not found, or a ``LIBRA_`` variable is
       disabled.

.. _usage/build-time/build:

Test targets
============

Requires :cmake:variable:`LIBRA_TESTS` to be enabled. No tests are
included in the default build — see :ref:`concepts/testing` for the
rationale.

.. list-table::
   :widths: 20 80
   :header-rows: 1

   * - Target
     - Description

   * - ``unit-tests``
     - Build all unit tests. To build a single test::

         make hfsm-utest

       for a file named ``hfsm-utest.cpp`` anywhere under ``tests/``.

   * - ``integration-tests``
     - Build all integration tests. To build a single test::

         make hfsm-itest

   * - ``regression-tests``
     - Build all regression tests. To build a single test::

         make hfsm-rtest

   * - ``all-tests``
     - Build all unit, integration, and regression tests. Equivalent to
       ``make unit-tests && make integration-tests && make
       regression-tests``.

   * - ``build-and-test``
     - Build ``all-tests`` and run them via CTest. ``--output-on-failure``
       and ``--test-dir build/`` are passed unconditionally.

   * - ``test``
     - Run already-built tests via ``ctest``. Does *not* build the
       tests first — use ``build-and-test`` to build and run in one
       step.

.. _usage/build-time/sw-eng:

Analysis and formatting targets
================================

Requires :cmake:variable:`LIBRA_ANALYSIS` to be enabled. Only targets
for tools that are found on ``PATH`` are created — see
:ref:`concepts/targets` for the availability model.

.. list-table::
   :widths: 20 80
   :header-rows: 1

   * - Target
     - Description

   * - ``analyze``
     - Run all enabled static checkers. Runs the following sub-targets
       individually:

       - ``analyze-cppcheck`` — runs ``cppcheck``
       - ``analyze-clang-check`` — runs the clang static checker
       - ``analyze-clang-tidy`` — runs clang-tidy using ``.clang-tidy``
         in the repo root. Per-category targets also exist:
         ``analyze-clang-tidy-modernize``, ``analyze-clang-tidy-bugprone``,
         etc. — see ``cmake --build . --target help`` for the full set.
       - ``analyze-clang-format`` — runs ``clang-format`` in check mode
         (no changes made). .. versionadded:: 0.8.15
       - ``analyze-cmake-format`` — runs ``cmake-format`` in check mode.
         .. versionadded:: 0.8.15

       .. versionchanged:: 0.8.5
          Renamed from ``check/check-XX`` to ``analyze/analyze-XX``.

       For tool-specific configuration, see :ref:`concepts/analysis`.

   * - ``format``
     - Run all enabled formatters (changes files in place):

       - ``format-clang-format`` — runs ``clang-format``
       - ``format-cmake-format`` — runs ``cmake-format``

       .. versionadded:: 0.8.15

   * - ``fix``
     - Run all enabled auto-fixers:

       - ``fix-clang-tidy`` — runs clang-tidy with ``--fix``
       - ``fix-clang-check`` — runs clang-check with ``--fixit``
         .. versionadded:: 0.8.12

Coverage targets
================

Requires :cmake:variable:`LIBRA_CODE_COV` to be enabled.

.. list-table::
   :widths: 20 80
   :header-rows: 1

   * - Target
     - Description

   * - ``lcov-preinfo``
     - Capture baseline coverage data (0%) for all files before running
       tests. First step in generating an *absolute* report that shows
       untested files. Requires GNU format
       (:cmake:variable:`LIBRA_CODE_COV_NATIVE` = NO).

   * - ``lcov-report``
     - Generate an **absolute** HTML coverage report using
       lcov/genhtml. All source files are included; files with 0%
       coverage are shown. Requires ``lcov-preinfo`` to have been run
       first. Requires GNU format.

   * - ``gcovr-report``
     - Generate a **relative** HTML coverage report using gcovr. Only
       files with >0% coverage are included. Requires GNU format.

   * - ``gcovr-check``
     - Check coverage against configured thresholds and fail if any
       threshold is not met. Thresholds are set via:

       - :cmake:variable:`LIBRA_GCOVR_LINES_THRESH`
       - :cmake:variable:`LIBRA_GCOVR_FUNCTIONS_THRESH`
       - :cmake:variable:`LIBRA_GCOVR_BRANCHES_THRESH`
       - :cmake:variable:`LIBRA_GCOVR_DECISIONS_THRESH`

       Requires GNU format.

   * - ``llvm-profdata``
     - Merge raw ``.profraw`` files into a single ``.profdata`` file.
       Runs automatically as a dependency of other LLVM targets, but can
       be run manually. Requires LLVM format.

       .. WARNING:: Run test binaries from the build directory root to
                    ensure ``.profraw`` files are generated in
                    ``PROJECT_BINARY_DIR`` where this target expects them.

   * - ``llvm-summary``
     - Print LLVM coverage summary to the terminal. Requires LLVM format.

   * - ``llvm-show``
     - Print detailed per-file LLVM coverage to the terminal. Requires
       LLVM format.

   * - ``llvm-report``
     - Generate an HTML LLVM coverage report. Requires LLVM format.

   * - ``llvm-export-lcov``
     - Export LLVM coverage data to lcov format for further processing.
       Requires LLVM format.

   * - ``llvm-coverage``
     - Run ``llvm-report`` and ``llvm-summary`` in sequence. Requires
       LLVM format.

Documentation targets
=====================

Requires :cmake:variable:`LIBRA_DOCS` to be enabled. For tool-specific
configuration, see :ref:`concepts/docs`.

.. list-table::
   :widths: 20 80
   :header-rows: 1

   * - Target
     - Description

   * - ``apidoc``
     - Generate API documentation with Doxygen.

   * - ``apidoc-check``
     - Check API documentation. Sub-targets:

       - ``apidoc-check-clang`` — checks consistency between docs and
         code (AST-aware; requires existing docs to be present).
       - ``apidoc-check-doxygen`` — runs doxygen with
         ``WARN_AS_ERROR=FAIL_ON_WARNINGS``.

       For tool-specific notes, see :ref:`concepts/docs`.

   * - ``sphinxdoc``
     - Generate project documentation with Sphinx. Depends on
       ``apidoc`` if that target exists. The sphinx command can be
       customized via :cmake:variable:`LIBRA_SPHINXDOC_COMMAND`.

Packaging targets
=================

.. list-table::
   :widths: 20 80
   :header-rows: 1

   * - Target
     - Description

   * - ``package``
     - Build deployable packages using CPack. Requires
       ``libra_configure_cpack()`` to have been called in
       ``project-local.cmake``, and :cmake:variable:`LIBRA_DRIVER`
       to be ``SELF``.
