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
     - Run already-built tests via ``ctest``; this is CMake's/CTest's built-in
       target. Does *not* build the tests first — use ``build-and-test`` to
       build and run in one step.

.. _usage/build-time/sw-eng:

Analysis and formatting targets
===============================

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
       - ``analyze-clang-tidy`` — runs clang-tidy using ``.clang-tidy`` in the
         repo root.

       - ``analyze-clang-format`` — runs ``clang-format`` in check mode
         (no changes made).
         .. versionadded:: 0.8.15

       .. versionchanged:: 0.8.5
          Renamed from ``check/check-XX`` to ``analyze/analyze-XX``.

       For tool-specific configuration, see :ref:`concepts/analysis`.

   * - ``format``
     - Run all enabled formatters (changes files in place):

       - ``format-clang`` — runs ``clang-format``
       - ``format-cmake`` — runs ``cmake-format``

       .. versionadded:: 0.8.15

   * - ``fix``
     - Run all enabled auto-fixers:

       - ``fix-clang-tidy`` — runs clang-tidy with ``--fix``
       - ``fix-clang-check`` — runs clang-check with ``--fixit``
         .. versionadded:: 0.8.12

       .. IMPORTANT:: Always reconfigure and rebuild the analysis preset
                      before running any ``fix-*`` target. See
                      :ref:`reference/targets/analysis-internals` for why.

.. _reference/targets/analysis-internals:

Analysis internals: header stubs and the ``fix`` targets
========================================================

This section documents the mechanics of how LIBRA gives analysis tools
correct compiler flags for every source file, including public headers.
For the conceptual summary, see :ref:`concepts/analysis`.

Compilation database
--------------------

All supported analysis tools use a compilation database
(``compile_commands.json``) by default. This is the most reliable source
of truth for compiler flags, include paths, and defines, since it
reflects exactly what was passed to the compiler for each translation
unit. When not using a compilation database, LIBRA walks only the
``INTERFACE_INCLUDE_DIRECTORIES`` and ``INTERFACE_COMPILE_DEFINITIONS``
of the main target — it does not recurse into ``PRIVATE`` dependencies,
as doing so would violate CMake's visibility contract. For projects with
multiple layers of ``PRIVATE`` deps, this path is unreliable;
:cmake:variable:`LIBRA_USE_COMPDB` ``=YES`` (the default) is strongly
preferred.

.. NOTE:: The GNU extension versions of ``-std`` are passed when not
          using a compilation database, to match LIBRA behaviour in
          standard autodetection.

Header stub generation
----------------------

Headers included by at least one ``.c/.cpp`` translation unit are covered
automatically by a compdb: tools analyze them in the context of the
including TU, which has a full compilation database entry and therefore
correct flags. Headers that are part of the public API but are *not*
included by any ``.c/.cpp`` — for example, in header-only libraries or
partially header-only components — would otherwise be invisible to the
compilation database. LIBRA handles these by generating a lightweight
stub translation unit for each such header at configure time in the build
directory:

.. code-block:: cpp

   // Auto-generated by libra -- DO NOT EDIT
   #include <myproject/config/profiling_config.hpp>

.. note:: ``.c`` stubs are generated for ``.h`` files and ``.cpp`` stubs
          are generated for ``.hpp`` files. Under LIBRA conventions (see
          :ref:`concepts/project-setup/layout`) ``.h`` files are always C
          code and ``.hpp`` files are always C++ code.

Each stub is compiled as part of an object library that links privately
against the analysis target, giving it a real compilation database entry
with the correct include paths and defines. The stub is then registered
as an analysis target in the same way as any other source file. If a
header fails analysis when checked via its stub, that is a real bug in the
header — not a tooling artifact. The fix is to make the header
self-contained, not to suppress the error.

Why ``fix-*`` requires a fresh configure
----------------------------------------

Stubs are only generated for headers with no real ``.c/.cpp`` coverage.
This is a correctness requirement for the ``fix`` analysis variant (e.g.
``fix-clang-tidy``): if a header gains ``.c/.cpp`` coverage after stubs
were generated, both the stub TU and the real TU will analyze it and
generate identical patches. The second patch application fails because
the first has already modified the file, invalidating the expected
context. Generating stubs only for uncovered headers also enables
``fix`` analysis to run in parallel.

To avoid this, always reconfigure and rebuild before running any
``fix-*`` target. The separate analysis preset makes this natural::

  cmake --preset analyze
  cmake --build --preset analyze
  cmake --build --preset analyze --target fix-clang-tidy

The sequence that produces a conflict:

.. tab-set::

   .. tab-item:: C

      #. ``foo.h`` has no ``.c`` coverage → stub generated → stub compiled →
         compdb entry exists.
      #. User adds ``#include <foo.h>`` to some ``.c``.
      #. User runs ``fix-clang-tidy`` **without reconfiguring**.
      #. Both the stub TU and the real TU analyze ``foo.h`` and generate
         identical patches.
      #. Second patch application fails with a conflict error.

   .. tab-item:: C++

      #. ``foo.hpp`` has no ``.cpp`` coverage → stub generated → stub compiled →
         compdb entry exists.
      #. User adds ``#include <foo.hpp>`` to some ``.cpp``.
      #. User runs ``fix-clang-tidy`` **without reconfiguring**.
      #. Both the stub TU and the real TU analyze ``foo.hpp`` and generate
         identical patches.
      #. Second patch application fails with a conflict error.

Coverage targets
================

Requires :cmake:variable:`LIBRA_COVERAGE` to be enabled.

.. list-table::
   :widths: 20 80
   :header-rows: 1

   * - Target
     - Description

   * - ``lcov-preinfo``
     - Capture baseline coverage data (0%) for all files before running
       tests. First step in generating an *absolute* report that shows
       untested files. Requires GNU format
       (:cmake:variable:`LIBRA_COVERAGE_NATIVE` = NO).

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
