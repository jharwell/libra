.. _usage/build-time:

==================
Build Time Actions
==================

This page details LIBRA usage and actions when *after* you've invoked CMake on
the cmdline (see :ref:`usage/configure-time`), and the build system has been
generated.

.. NOTE:: All examples assume the CMake generator is ``Unix Makefiles``, and
          therefore all targets can be built with ``make``; adjust as needed if
          you use a different generator.

- :ref:`usage/build-time/build`

- :ref:`usage/build-time/sw-eng`

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

       - ``fix-clang-check`` - Runs ``clang-checkg`` as a checker, but also
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

   * - ``precoverage-info``

     - Run ``lcov`` to generate a baseline code coverage info (0%) for the
       entire project to eventually generate an *absolute* code coverage report
       after executing the project. That is, this target is used as part of a
       sequence like so::

         make                     # Build in coverage info into project
         make all-tests           # Build in coverage info into tests
         make precoverage-info    # Set baseline coverage info for ENTIRE project
         make test                # Populate coverage for executed parts of project
         make coverage-report     # Build ABSOLUTE coverage report for all files

       An *absolute* code coverage report uses the baseline info and the #
       lines/functions executed in all files. If there are files which have no
       functions executed, then they **WILL** be included in the results. This
       may or may not be desirable; if it is not, then don't call this target
       before running the project, and you'll get a relative report instead.

       Requires :cmake:variable:`LIBRA_TESTS` is true.

   * - ``coverage-report``

     - Run ``lcov`` to generate a code coverage report (presumably from the
       results of running unit tests, though that does not have to be the
       case). That is::

         make                 # Build in coverage info into project
         make all-tests       # Build in coverage info into tests
         make test            # Populate coverage for executed parts of project
         make coverage-report # Build RELATIVE report for files had some execution


       Not that this is a *relative* code coverage report. That is, #
       lines/functions executed out of the total # lines/functions in all files
       which have at least one function executed. If there are files which have
       no functions executed, then they will not be included in the results,
       skewing reporting coverage. This may or may not be desirable. See
       ``precoverage-report`` if it is undesirable.

       Requires :cmake:variable:`LIBRA_TESTS` is true.
