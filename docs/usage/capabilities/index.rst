.. SPDX-License-Identifier:  MIT

.. _usage/capabilities:

==================
LIBRA Capabilities
==================

This page details the different things LIBRA can do. If some capabilities are
only available/make sense for a particular :ref:`flavor <main/flavors>`, that is
called out explicitly; otherwise, everything applies to all flavors.

.. versionchanged:: 0.8.4
   LIBRA no longer offers its {DEV,DEVOPT,OPT} build types, as they provided
   marginal benefit over the fine-grained tuning available to tweak the built-in
   cmake build types via its configure-time features.

File Discovery
==============

- All files under ``src/`` ending in:

  - ``.c``
  - ``.cpp``
  - ``.cu``

  are globbed as source files (see :ref:`usage/req` for repository layout
  requirements) so that if you add a new source file, rename a source file,
  etc., you just need to re-run cmake. This means you don't have to MANUALLY
  specify all the files in the cmake project. Woo-hoo!

  .. NOTE:: See :ref:`philosophy/globbing` for rationale on why globs are used,
     contrary to common cmake guidance.

- All files under ``tests/`` ending in a specified pattern are recursively
  globbed as unit test files which will be compiled into executable unit tests
  at build time if ``LIBRA_TESTS=YES``. See :ref:`usage/project-local/variables`
  more details on this configuration item. Same for integration tests.
  ``${LIBRA_INTEGRATION_TEST_MATCHER.{c,cpp}}``.

- All files under ``tests/`` ending in a specified pattern are recursively
  globbed as the test harness for unit/integration tests. All test harness files
  will be compiled into static libraries at build time and all test targets link
  against them if ``LIBRA_TESTS=YES``.

.. NOTE:: The difference between unit tests and integration tests is purely
          semantic, and exists solely to help organize your tests. LIBRA treats
          both types of tests equivalently.



.. _usage/capabilities/build-process:

Configure Time
==============

LIBRA can do many things for you when cmake is run. Some highlights include:

- Configuring builds in a wide variety of ways, for everything for bare-metal to
  supercomputing multithread/multiprocess applications.

- Support for fortifying projects from security attacks.

- Providing plumbing to aid in debugging; e.g., through various sanitizers.

- Providing plumbing for easily configuring Cmake's (really CPack's) packaging
  capabilities. See

- Handling populating a source file of your choosing so that your software can
  accurately report the project version when run/loaded. This supports DRY of
  the project version.

- Providing plumbing for simple installation needs for {headers, binaries,
  libraries} via globs.

- Providing a nice summary of the exact configuration options set to make
  debugging strange configuration problems much easier.

Configure-Time Knobs
--------------------

LIBRA provides many configuration knobs for configuring the cmake configuration
process. All of the knobs (cmake variables) can be specified on the command line
via ``-D``, or put in your ``project-local.cmake``--see
:ref:`usage/project-local` for more details.

- :ref:`usage/capabilities/configure-time/libra`

- :ref:`usage/capabilities/configure-time/sw-eng`

- :ref:`usage/capabilities/configure-time/builds`

Build Time
==========

After configuration, LIBRA can do many things when running ``make`` (or whatever
the build engine is). In addition to being able to actually build the software,
this project enables the following additional capabilities via targets:

.. list-table::
   :widths: 5,95
   :header-rows: 1

   * - make target

     - Description

   * - ``format``

     - Run the clang formatter on the repository.

   * - ``check``

     - Run ALL enabled static checkers on the repository. This runs the
       following sub-targets, which can also be run individually:

       - ``check-cppcheck`` - Runs ``cppcheck`` on the repository.

       - ``check-clang-check`` - Runs the clang static checker on the
         repository.

       - ``check-clang-tidy`` - Runs the clang-tidy checker on the repository,
         using the ``.clang-tidy`` in the root of the repo. There are individual
         ``check-clang-tidy-XX`` checks for each category of things that
         clang-tidy can check, see ``cmake --build . --target help`` for the
         defined set (run from build directory).


   * - ``fix``

     - Run ALL enabled auto fixers on the repository. This runs the following
       sub-targets, which can also be run individually:

       - ``fix-clang-tidy`` - Runs ``clang-tidy`` as a checker, but also passing
         the ``--fix`` argument.

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

   * - ``tests``

     - Build all of the integration and unit tests for the project; same as
       ``make unit-tests && make integration-tests``.

       Requires that ``LIBRA_TESTS=YES`` was passed to cmake during
       configuration.

   * - ``test``

     - Run all of the tests for the project via ``ctest``.

   * - ``apidoc``

     - Generate the API documentation.

   * - ``package``

     - Build one or more deployable packages using CPACK. Requires
       ``libra_configure_cpack()`` to have been called in
       ``project-local.cmake``.

       Not available if ``LIBRA_DRIVER=CONAN``.

   * - ``precoverage-report``

     - Run ``lcov`` to generate a baseline code coverage info (0%) for the
       entire project to eventually generate an *absolute* code coverage report
       after executing the project. That is, something like::

         make                     # Build in coverage info into project
         make unit-tests          # Build in coverage info into tests
         make precoverage-report  # Set baseline coverage info for ENTIRE project
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
         make unit-tests      # Build in coverage info into tests
         make test            # Populate coverage for executed parts of project
         make coverage-report # Build RELATIVE report for files had some execution


       Not that this is a *relative* code coverage report. That is, #
       lines/functions executed out of the total # lines/functions in all files
       which have at least one function executed. If there are files which have
       no functions executed, then they will not be included in the results,
       skewing reporting coverage. This may or may not be desirable. See
       ``precoverage-report`` if it is undesirable.


Git Commit Checking
===================

LIBRA can lint commit messages, checking they all have a consistent format. The
format is controlled by the file ``commitlint.config.js``. See the `husky
<https://www.npmjs.com/package/husky>`_ for details. The default format LIBRA
enforces is described in :ref:`dev/git/commit-guide`. To use it run ``npm
install`` in the repo where you have setup LIBRA.
