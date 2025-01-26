.. _usage/capabilities/build-time:

==================
Build Time Actions
==================

.. _usage/capabilities/build-time/build:

Actions That Build Things
=========================

.. list-table::
   :widths: 5,95
   :header-rows: 1

   * - ``unit-tests``

     - Build all of the unit tests for the project. If you want to just build a
       single unit test, you can do ``make <name of test>``. For example::

         make hfsm-utest

       for a single unit test named ``hfsm-utest.cpp`` that lives somewhere
       under ``tests/``.

       Requires that ``LIBRA_TESTS=YES`` was passed to cmake during
       configuration.

   * - ``integration-tests``

     - Build all of the integration tests for the project. If you want to just
       build a single test, you can do ``make <name of test>``. For example::

         make hfsm-itest

       for a single unit test named ``hfsm-itest.cpp`` that lives somewhere
       under ``tests/``.

       Requires that ``LIBRA_TESTS=YES`` was passed to cmake during
       configuration.

   * - ``build-and-test``

     - Build ``all-tests``, and then run them via ``CTest``.

       Requires that ``LIBRA_TESTS=YES`` was passed to cmake during
       configuration.

   * - ``all-tests``

     - Build all of the integration and unit tests for the project; same as
       ``make unit-tests && make integration-tests``.

       Requires that ``LIBRA_TESTS=YES`` was passed to cmake during
       configuration.

.. _usage/capabilities/build-time/sw-eng:

Actions For Supporting SW Engineering
=====================================

.. list-table::
   :widths: 5,95
   :header-rows: 1

   * - make target

     - Description

   * - ``test``

     - Run all of the built tests for the project via ``ctest``. Does *NOT*
       actually build the tests, which is unfortunate.

   * - ``format``

     - Run ALL enabled formatters on the repository. This runs the
       following sub-targets, which can also be run individually:

       - ``format-clang-format`` - Runs ``clang-format`` on the
           repository.

       - ``format-cmake-format`` - Runs the ``cmake-format`` on the
           repository.

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


       For more details, see :ref:`usage/analysis`.

   * - ``fix``

     - Run ALL enabled auto fixers on the repository. This runs the following
       sub-targets, which can also be run individually:

       - ``fix-clang-tidy`` - Runs ``clang-tidy`` as a checker, but also passing
         the ``--fix`` argument.

       - ``fix-clang-check`` - Runs ``clang-checkg`` as a checker, but also
         passing the ``--fixit`` argument.

         .. versionadded:: 0.8.12


   * - ``apidoc``

     - Generate the API documentation.

   * - ``package``

     - Build one or more deployable packages using CPACK. Requires
       ``libra_configure_cpack()`` to have been called in
       ``project-local.cmake``.

       Not available if ``LIBRA_DRIVER=CONAN``.

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
