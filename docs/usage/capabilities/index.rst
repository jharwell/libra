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
the build system is). In addition to being able to actually build the software,
this project enables the following additional capabilities via targets:

.. NOTE:: All examples assume the CMake generator is ``Unix Makefiles``, and
          therefore all targets can be built with ``make``; adjust as needed if
          you use a different generator.

- :ref:`usage/capabilities/build-time/build`

- :ref:`usage/capabilities/build-time/sw-eng`

Git Commit Checking
===================

LIBRA can lint commit messages, checking they all have a consistent format. The
format is controlled by the file ``commitlint.config.js``. See the `husky
<https://www.npmjs.com/package/husky>`_ for details. The default format LIBRA
enforces is described in :ref:`dev/git/commit-guide`. To use it run ``npm
install`` in the repo where you have setup LIBRA.
