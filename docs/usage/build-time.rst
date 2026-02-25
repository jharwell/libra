.. _usage/build-time:

==================
Build Time Actions
==================

This page details LIBRA usage and actions when *after* you've invoked CMake on
the cmdline (see :ref:`usage/configure-time`), and the build system has been
generated.

.. NOTE:: All build targets are only defined by LIBRA for the top-level CMake
          ``project()``. All dependent projects are unaffected.

.. plantuml::

   !theme cerulean-outline

   skinparam DefaultFontSize 14
   skinparam defaultTextAlignment center
   skinparam TitleFontSize 24
   skinparam SequenceMessageAlignment center
   skinparam DefaultFontColor #black
   skinparam TitleFontColor #black
   skinparam ParticipantFontColor #black

   title LIBRA Build Targets

   skinparam componentStyle rectangle

   component "Build" as Build
   component "Test" as Test
   component "Analyze" as Analyze
   component "Format" as Format
   component "Coverage" as Coverage
   component "Docs" as Docs
   component "Package" as Package

   component "LIBRA" as Libra

   Libra --> Build
   Libra --> Test
   Libra --> Analyze
   Libra --> Format
   Libra --> Coverage
   Libra --> Docs
   Libra --> Package


.. NOTE:: All examples assume the CMake generator is ``Unix Makefiles``, and
          therefore all targets can be built with ``make``; adjust as needed if
          you use a different generator.

- :ref:`usage/build-time/build`

- :ref:`usage/build-time/sw-eng`

Quick Reference
===============

Common Workflows
----------------

**Build and run tests**::

    make build-and-test

**Generate code coverage (GNU/gcov format)**::

    make all-tests
    make test
    make gcovr-report  # or gcovr-check for threshold checking

**Generate code coverage (LLVM/Clang format)**::

    make all-tests
    make test
    make llvm-coverage  # Generates HTML + summary

**Run static analysis**::

    make analyze  # All analyzers
    make analyze-clang-tidy  # Just clang-tidy

**Auto-fix code style**::

    make format  # All formatters
    make fix-clang-tidy  # Auto-fix clang-tidy warnings

.. _usage/build-time/help:

Utility Actions
===============

.. list-table::
   :widths: 5,95
   :header-rows: 1

   * - Target

     - Description

   * - ``help-targets``

     - Emit a table of all LIBRA targets, whether or not they are
       enabled/available, and (more importantly), *why*. E.g., a necessary
       program was not found, disabled by a ``LIBRA_`` variable.

   * - ``help-vars``

     - Emit the LIBRA variable reference: a table of all ``LIBRA_`` variables
       (both those that control build target creation, and those that configure
       other things).

.. _usage/build-time/build:

Actions That Build Things
=========================

.. list-table::
   :header-rows: 1

   * - Target

     - Description

   * - ``unit-tests``

     - Build all of the unit tests for the project. If you want to just build a
       single unit test, you can do ``make <name of test>``. For example::

         make hfsm-utest

       for a single unit test named ``hfsm-utest.cpp`` that lives somewhere
       under ``tests/``.

       Requires that :cmake:variable:`LIBRA_TESTS` is true. No tests are
       included in the default build--see :ref:`usage/testing/default-build` for
       rationale.

   * - ``integration-tests``

     - Build all of the integration tests for the project. If you want to just
       build a single test, you can do ``make <name of test>``. For example::

         make hfsm-itest

       for a single unit test named ``hfsm-itest.cpp`` that lives somewhere
       under ``tests/``.

       Requires that :cmake:variable:`LIBRA_TESTS` was passed to cmake during
       configuration. No tests are included in the default build--see
       :ref:`usage/testing/default-build` for rationale.

   * - ``regression-tests``

     - Build all of the regression tests for the project. If you want to just
       build a single test, you can do ``make <name of test>``. For example::

         make hfsm-itest

       for a single unit test named ``hfsm-rtest.cpp`` that lives somewhere
       under ``tests/``.

       Requires that :cmake:variable:`LIBRA_TESTS` was passed to cmake during
       configuration. No tests are included in the default build--see
       :ref:`usage/testing/default-build` for rationale.

   * - ``build-and-test``

     - Build ``all-tests``, and then run them via ``CTest``.

       Requires that :cmake:variable:`LIBRA_TESTS` was passed to cmake during
       configuration. See :ref:`usage/testing/builtin` for more details about
       this target.

   * - ``all-tests``

     - Build all of the integration and unit tests for the project; same as
       ``make unit-tests && make integration-tests``.

       Requires that :cmake:variable:`LIBRA_TESTS` was passed to cmake during
       configuration. Not included in the default build--see
       :ref:`usage/testing/default-build` for rationale.

.. _usage/build-time/sw-eng:

Actions For Supporting SW Engineering
=====================================

.. list-table::
   :widths: 5,95
   :header-rows: 1

   * - Target

     - Description

   * - ``test``

     - Run all of the built tests for the project via ``ctest``. Does *NOT*
       actually build the tests, which is unfortunate. Requires
       :cmake:variable:`LIBRA_TESTS` is true.

   * - ``format``

     - Run ALL enabled formatters on the repository. This runs the
       following sub-targets, which can also be run individually:

       - ``format-clang-format`` - Runs ``clang-format`` on the
           repository.

       - ``format-cmake-format`` - Runs the ``cmake-format`` on the
           repository.

       Requires :cmake:variable:`LIBRA_ANALYSIS` is true.

       .. versionadded:: 0.8.15


   * - ``analyze``

     - Run ALL enabled static checkers on the repository. This runs the
       following sub-targets, which can also be run individually:

       - ``analyze-cppcheck`` - Runs ``cppcheck`` on the repository.

       - ``analyze-clang-check`` - Runs the clang static checker on the
         repository.

       - ``analyze-clang-tidy`` - Runs the clang-tidy checker on the repository,
         using the ``.clang-tidy`` in the root of the repo. There are individual
         ``analyze-clang-tidy-XX`` checks for each category of things that
         clang-tidy can check, see ``cmake --build . --target help`` for the
         defined set (run from build directory).

         - ``analyze-clang-format`` - Runs ``clang-format`` on the
           repository in check mode (no code changes are made).

           .. versionadded:: 0.8.15

         - ``analyze-cmake-format`` - Runs the ``cmake-format`` on the
           repository in check mode (no code changes are made).

           .. versionadded:: 0.8.15

       .. versionchanged:: 0.8.5

          This family of targets used to be called ``check/check-XX``; renamed
          to more accurately reflect in-depth code analysis, as distinct from
          code checking, which is less intense.


       Requires :cmake:variable:`LIBRA_ANALYSIS` is true. For more details, see
       :ref:`usage/analysis`.

   * - ``fix``

     - Run ALL enabled auto fixers on the repository. This runs the following
       sub-targets, which can also be run individually:

       - ``fix-clang-tidy`` - Runs ``clang-tidy`` as a checker, but also passing
         the ``--fix`` argument.

       - ``fix-clang-check`` - Runs ``clang-check`` as a checker, but also
         passing the ``--fixit`` argument.

         .. versionadded:: 0.8.12

       Requires :cmake:variable:`LIBRA_ANALYSIS` is true.

   * - ``apidoc``

     - Generate the API documentation.  Requires :cmake:variable:`LIBRA_DOCS` is
       true.  For more details see :ref:`usage/apidoc`.

   * - ``apidoc-check``

     - Check the API documentation. This runs the following sub-targets, which
       can also be run individually:

       - ``apidoc-check-clang`` - Runs ``clang`` as a checker.

       - ``apidoc-check-doxygen`` - Runs ``doxygen`` with warnings as errors.

       Requires :cmake:variable:`LIBRA_DOCS` is true.  For more details see
       :ref:`usage/apidoc/check`.

   * - ``package``

     - Build one or more deployable packages using CPACK. Requires
       ``libra_configure_cpack()`` to have been called in
       ``project-local.cmake``.

       Requires :cmake:variable:`LIBRA_DRIVER` is  ``SELF``.

   * - ``lcov-preinfo``

     - Capture baseline code coverage info (0%) for the entire project before
       running any tests. This is the first step in generating an *absolute*
       coverage report. See ``lcov-report`` for the full workflow.

       Requires :cmake:variable:`LIBRA_CODE_COV` is true with GNU format.

   * - ``lcov-report``

     - Generate an HTML code coverage report using lcov/genhtml. This produces
       an **absolute** coverage report, meaning:

       - All source files are included in the report.
       - Files with 0% coverage are shown (not hidden).
       - Useful for seeing what hasn't been tested at all.

       Typical workflow::

         cmake -DCMAKE_BUILD_TYPE=Debug -DLIBRA_CODE_COV=ON ..
         make                     # Build project with coverage
         make all-tests           # Build tests with coverage
         make lcov-preinfo        # Capture baseline (0% coverage)
         make test                # Run tests to generate coverage data
         make lcov-report         # Generate HTML report

       Opens ``coverage/index.html`` when complete.

       Requires :cmake:variable:`LIBRA_CODE_COV` is true with GNU format.

   * - ``gcovr-report``

     - Generate an HTML code coverage report using gcovr. This produces
       a **relative** coverage report, meaning:

       - Only files with >0% coverage are included.
       - Untested files are excluded from the report.
       - Coverage percentages are higher but less comprehensive.

       Typical workflow::

         cmake -DCMAKE_BUILD_TYPE=Debug -DLIBRA_CODE_COV=ON ..
         make                 # Build project with coverage
         make all-tests       # Build tests with coverage
         make test            # Run tests to generate coverage data
         make gcovr-report    # Generate HTML report (relative)

       Use ``lcov-report`` if you want to see all files including untested ones.

       Requires :cmake:variable:`LIBRA_CODE_COV` is true with GNU format.

   * - ``gcovr-check``

     - Run ``gcovr`` to check code coverage (presumably from the results of
       running unit tests, though that does not have to be the case). That is::

         make                 # Build in coverage info into project
         make all-tests       # Build in coverage info into tests
         make test            # Populate coverage for executed parts of project
         make gcovr-check     # Check coverage against configured thresholds


       Requires :cmake:variable:`LIBRA_CODE_COV` is true, and that code coverage
       instrumentation is generated in the GNU format; see
       :cmake:variable:`LIBRA_CODE_COV_NATIVE` for more info. Thresholds are set
       via:

       - :cmake:variable:`LIBRA_GCOVR_LINES_THRESH`
       - :cmake:variable:`LIBRA_GCOVR_FUNCTIONS_THRESH`
       - :cmake:variable:`LIBRA_GCOVR_BRANCHES_THRESH`
       - :cmake:variable:`LIBRA_GCOVR_DECISIONS_THRESH`

   * - ``llvm-profdata``

     - Merge raw LLVM profile data (``.profraw`` files) into a single
       ``.profdata`` file for consumption by other llvm-cov targets. This
       target runs automatically as a dependency of other LLVM coverage targets,
       but can be run manually::

         make test            # Generate .profraw files
         make llvm-profdata   # Merge into coverage.profdata

       Requires :cmake:variable:`LIBRA_CODE_COV` is true with LLVM/native
       format.

       .. WARNING:: When using LLVM/Clang native coverage format, the
          ``llvm-profdata`` merge command requires that ``.profraw`` files exist
          in :cmake:variable:`PROJECT_BINARY_DIR`.  Ensure you run test binaries
          from the build directory root, not from subdirectories, to ensure
          profile data is generated in the correct location.

   * - ``llvm-summary``

     - Run ``llvm-cov`` to output code coverage (presumably from the results of
       running unit tests, though that does not have to be the case) to the
       terminal. That is::

         make                 # Build in coverage info into project
         make all-tests       # Build in coverage info into tests
         make test            # Populate coverage for executed parts of project
         make llvm-summary    # Build RELATIVE report for files had some execution


       Requires :cmake:variable:`LIBRA_CODE_COV` is true, and that code coverage
       instrumentation is generated in the LLVM format; see
       :cmake:variable:`LIBRA_CODE_COV_NATIVE` for more info.

   * - ``llvm-show``

     - Run ``llvm-cov`` to output detailed code coverage (presumably from the
       results of running unit tests, though that does not have to be the case)
       to the terminal. Basically, the same as the HTML output, but in the
       terminal. That is::

         make                 # Build in coverage info into project
         make all-tests       # Build in coverage info into tests
         make test            # Populate coverage for executed parts of project
         make llvm-show       # Build RELATIVE report for files had some execution


       Requires :cmake:variable:`LIBRA_CODE_COV` is true, and that code coverage
       instrumentation is generated in the LLVM format; see
       :cmake:variable:`LIBRA_CODE_COV_NATIVE` for more info.

   * - ``llvm-report``

     - Run ``llvm-cov`` to output detailed code coverage (presumably from the
       results of running unit tests, though that does not have to be the case)
       in a browsable HTML blob. That is::

         make                 # Build in coverage info into project
         make all-tests       # Build in coverage info into tests
         make test            # Populate coverage for executed parts of project
         make llvm-report     # Build RELATIVE report for files had some execution


       Requires :cmake:variable:`LIBRA_CODE_COV` is true, and that code coverage
       instrumentation is generated in the LLVM format; see
       :cmake:variable:`LIBRA_CODE_COV_NATIVE` for more info.

   * - ``llvm-export-lcov``

     - Run ``llvm-cov`` to export code coverage (presumably from the
       results of running unit tests, though that does not have to be the case)
       to lcov format for further processing. That is::

         make                  # Build in coverage info into project
         make all-tests        # Build in coverage info into tests
         make test             # Populate coverage for executed parts of project
         make llvm-export-lcov # Export


       Requires :cmake:variable:`LIBRA_CODE_COV` is true, and that code coverage
       instrumentation is generated in the LLVM format; see
       :cmake:variable:`LIBRA_CODE_COV_NATIVE` for more info.

   * - ``llvm-coverage``

     - Run ``llvm-report`` and ``llvm-summary`` in sequence. That is::

         make                  # Build in coverage info into project
         make all-tests        # Build in coverage info into tests
         make test             # Populate coverage for executed parts of project
         make llvm-coverage    # Generate HTML and text reports


       Requires :cmake:variable:`LIBRA_CODE_COV` is true, and that code coverage
       instrumentation is generated in the LLVM format; see
       :cmake:variable:`LIBRA_CODE_COV_NATIVE` for more info.
