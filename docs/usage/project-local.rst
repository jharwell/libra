.. SPDX-License-Identifier:  MIT

.. _usage/project-local:

===========================================
project-local.cmake: How To Hook Into LIBRA
===========================================

To hook into LIBRA, you define a ``cmake/project-local.cmake``. Basically, you
can put WHATEVER you want in this file--all the usual cmake stuff--drawing on
predefined things in LIBRA to make your life easier. For what things LIBRA
defines for you to use in this file, see below.

.. NOTE:: All cmake functions which LIBRA exposes are prefixed with ``libra_``;
          all other functions should be considered not part of the API and can
          change at any time.

Target Declaration Wrappers
===========================

.. cmake:command:: libra_add_library

   Thin wrapper around :cmake:command:`add_library()` which forwards all
   arguments to the built in function, and adds the target name to
   :cmake:variable:`LIBRA_TARGETS`. You don't *have* to use this function, but
   if you don't then much of the LIBRA magic w.r.t. compilers/compilation can
   only be applied to the :cmake:variable:`PROJECT_NAME` target.


.. cmake:command:: libra_add_executable

   Thin wrapper around :cmake:command:`add_executable()` which forwards all
   arguments to the built in function, and adds the target name to
   :cmake:variable:`LIBRA_TARGETS`. You don't *have* to use this function, but
   if you don't then much of the LIBRA magic w.r.t. compilers/compilation can
   only be applied to the :cmake:variable:`PROJECT_NAME` target.

.. _usage/project-local/variables:

Variables
=========

The variables listed in this section are generally for configuring various LIBRA
features, and therefore are intended to be set via
``project-local.cmake``. However, many of the cmdline interface variables
detailed in :ref:`usage/configure-time` can be set permanently in
``project-local.cmake`` too, but not all of them. Exceptions are:

- :cmake:variable:`LIBRA_DEPS_PREFIX`
- :cmake:variable:`LIBRA_C_STANDARD`
- :cmake:variable:`LIBRA_CXX_STANDARD`

.. cmake:variable:: LIBRA_ANALYSIS_LANGUAGE

   Defines the language that the different static analysis
   checkers/formatters/fixers will use for checking the project. This should be
   specified BEFORE any subdirectories, external projects, etc. are
   specified. Only used if :cmake:variable:`LIBRA_ANALYSIS` is true. If used,
   value must be one of:

   - C
   - CXX

   You should only ever need to set this if your project contains both C and
   C++ code, to switch between which is checked.

.. cmake:variable:: LIBRA_CPPCHECK_IGNORES

   A list of files to totally ignore when running ``cppcheck``. Only used if
   :cmake:variable:`LIBRA_ANALYSIS` is enabled and ``cppcheck`` is found. The
   ``-i`` separators are added by LIBRA--this should just be a raw list.

   .. versionadded:: 0.8.5

.. cmake:variable:: LIBRA_CPPCHECK_SUPPRESSIONS

   A list of categories of warnings to suppress for matching patterns
   ``cppcheck``. Only used if :cmake:variable:`LIBRA_ANALYSIS` is enabled and
   ``cppcheck`` is found. The ``--suppress=`` separators are added by
   LIBRA--this should just be a raw list.

   .. versionadded:: 0.8.5

.. cmake:variable:: LIBRA_CPPCHECK_EXTRA_ARGS

   A list of extra arguments to pass to cppcheck. If you want to pass
   suppressions or ignores, use the above variables; this is for other things
   which don't fit in those buckets. Passed as-is to cppcheck.

   .. versionadded:: 0.8.5

.. cmake:variable:: LIBRA_CLANG_FORMAT_FILEPATH

   The path to the ``.clang-format`` file you want to use. If not defined, LIBRA
   will use its internal .clang-format file.

   .. versionadded:: 0.8.8

.. cmake:variable:: LIBRA_CLANG_TIDY_FILEPATH

   The path to the ``.clang-tidy`` file you want to use. If not defined, LIBRA will
   use its internal .clang-format file.

   .. versionadded:: 0.8.8

.. cmake:variable:: LIBRA_CLANG_TIDY_CHECKS_CONFIG

   Any additional things to pass to ``--checks``. If non empty, must start with
   ``,``. Useful to disable certain checks within a each category of checks that
   LIBRA creates targets for. Defaults to::

     ,-clang-diagnostic-*

   .. versionadded:: 0.8.15

.. cmake:variable:: LIBRA_C_DIAG_CANDIDATES

   The list of compiler warning options you want to pass to the C compiler. This
   can be a superset of the options supported by the minimum C compiler version
   you target; each option in the list is checked to see if the current C
   compiler supports it. If not defined, uses LIBRA's internal C diagnostic
   option set, which is fairly comprehensive.  If you don't want to compile with
   any warnings, set this to ``""``.

   .. versionadded:: 0.8.6

.. cmake:variable:: LIBRA_CXX_DIAG_CANDIDATES

   The list of compiler warning options you want to pass to the compiler. This
   can be a superset of the options supported by the minimum compiler version
   you target; each option in the list is checked to see if the current CXX
   compiler supports it. If not defined, uses LIBRA's internal CXX diagnostic
   option set, which is fairly comprehensive. If you don't want to compile with
   any warnings, set this to ``""``.

   .. versionadded:: 0.8.6

.. cmake:variable:: LIBRA_TEST_HARNESS_LIBS

   Defines the link libraries that all tests/test harnesses need to link with,
   if any. Goes hand in hand with
   :cmake:variable:`LIBRA_TEST_HARNESS_PACKAGES``.

.. cmake:variable:: LIBRA_TEST_HARNESS_PACKAGES

   Defines the packages that contain the libraries that all tests/test harnesses
   need to link with, if any. Goes hand in hand with
   :cmake:variable:`LIBRA_TEST_HARNESS_LIBS``.

.. cmake:variable:: LIBRA_UNIT_TEST_MATCHER

   The common suffix before the ``.cpp`` that all unit tests under ``tests/``
   will have so LIBRA can glob them. If not specified, defaults to ``-utest``; a
   valid unit test would then be, e.g., ``tests/myclass-utest.cpp``.

.. cmake:variable:: LIBRA_INTEGRATION_TEST_MATCHER

   The common suffix before the ``.cpp`` that all integration tests under
   ``tests/`` will have so LIBRA can glob them. If not specified, defaults to
   ``-itest``; a valid integration test would then be, e.g.,
   ``tests/thing-itest.cpp``.

.. cmake:variable:: LIBRA_TEST_HARNESS_MATCHER

   The common suffix before the ``{.cpp,.hpp}`` that all test harness files
   tests under ``tests/`` will have so LIBRA can glob them. If not specified,
   defaults to ``_test``; valid test harness would then be, e.g.,
   ``tests/thing_test{.cpp,.hpp}``.

.. cmake:variable:: ${PROJECT_NAME}_C_SRC

   Glob containing all C source files.

.. cmake:variable:: ${PROJECT_NAME}_CXX_SRC

   Glob containing all C++ source files.

.. cmake:variable:: ${PROJECT_NAME}_C_HEADERS

   Glob containing all C header files.

.. cmake:variable:: ${PROJECT_NAME}_CXX_HEADERS

   Glob containing all C++ header files.

.. NOTE:: See :ref:`philosophy/globbing` for rationale on why globs are used,
          contrary to common cmake guidance.

Build And Configure-time Diagnostics
====================================

LIBRA provides a number of functions/macros to simplify the complexity of cmake,
and answer questions such as "am I really building/running what I think I
am?". Some useful functions available in ``project-local.cmake`` are:

.. cmake:command:: libra_config_summary

   Print a nice summary of its variables to the terminal. Helps debug the
   inevitable "Did I actually set the variable I thought I did?". Using this,
   you can see EXACTLY what variable values will be when you invoke your chosen
   build engine. You can put it at the end of ``project-local.cmake`` if you
   want to control when LIBRA's configuration summary vs. your projects
   configuration summary is emitted; otherwise LIBRA will run it at the end of
   the configure step.

.. cmake:command:: libra_config_summary_prepare_fields(FIELDS)

   Given a list of the configurable fields in a project as strings, define a set
   of new variables, one per field, with the prefix ``EMIT_``. The value of each
   new variable will be right padded with spaces so that any extra stuff on each
   line when the variables are printed to the screen can be left-aligned.

   :param FIELDS: List of fields.

.. cmake:command:: libra_configure_source_file(INFILE OUTFILE SRC)

   Use build information from LIBRA and your project to populate a source file
   of your choosing.  LIBRA automatically adds this file to the provided list of
   files (``SRC``) which will ultimately be compiled for the project. This is
   useful for e.g., printing out when your library loads/application starts as a
   sanity check during debugging to help ensure that you are running what you
   think you are.

   :param INFILE: The input template file.

   :param OUTFILE: The output file.

   :param SRC: An existing list of source files for compilation to which
               ``OUTFILE`` should be appended. This is the *name* of the
               variable, not its contents.


  Available LIBRA CMake variables for population by cmake in ``INFILE`` file
  are:

  - ``LIBRA_GIT_REV`` - git SHA of the current tip; result of ``git log
    --pretty-format:%H -n 1``.

  - ``LIBRA_GIT_DIFF`` - Indicate if the build is "dirty"; i.e., if it contains
    local changes not in git. Result of ``git diff --quiet --exit-code || echo
    +``.

  - ``LIBRA_GIT_TAG`` - The current git tag for the git rev, if any; result of
    ``git describe --exact-match --tags``.

  - ``LIBRA_GIT_BRANCH`` - The current git branch, if any; result of ``git
    rev-parse --abbrev-ref HEAD``.

  - ``LIBRA_C_FLAGS_BUILD`` - The configured C compiler flags relevant for
    building (e.g., no ``-W`` flags) .

  - ``LIBRA_CXX_FLAGS_BUILD`` - The configured C compiler flags relevant for
    building (e.g., no ``-W`` flags) .

.. NOTE:: If your code is not in a git repository, then all of the above fields
          will be stubbed out/empty and not very useful.

You can also put whatever cmake variables you want to in there as well (e.g.,
:cmake:variable:`CMAKE_C_FLAGS_RELEASE`).


Installation
============

.. NOTE:: These functions are only available if ``LIBRA_DRIVER=SELF``.

.. cmake:command:: libra_configure_exports(TARGET PREFIX)

   Configure the exports for a ``TARGET`` to be installed at ``PREFIX`` such
   that it can be used by *other* projects via
   :cmake:command:`find_package()`. If you want your project to be consumable
   downstream via :cmake:command:`find_package()`, then you must call this
   function.

   You *may* need to call it on header-only dependencies as well to get them
   into the export set for your project. If you do, make sure that you do *not*
   add said deps to your ``config.cmake.in`` file via
   :cmake:command:`find_dependency()`, as that will cause an infinite loop.

   To use, ``include(libra/package/install.cmake)``.

   :param TARGET: The target to add to the export set.

   :param PREFIX: The prefix that ``TARGET`` will be installed into.


.. cmake:command:: libra_register_target_for_install(TARGET PREFIX)

   Register ``TARGET`` to be installed at ``PREFIX`` and associated with the
   necessary exports file so child projects can find it.

   To use, ``include(libra/package/install.cmake)``.

   :param TARGET: The target to register for which
                  :cmake:command:`libra_configure_exports(TARGET PREFIX)` has
                  already been called.

   :param PREFIX: The prefix to install into.

.. cmake:command:: libra_register_extra_configs_for_install(TARGET FILE PREFIX)

   Configure additional ``.cmake`` files for export. Useful if your project
   provides some reusable cmake functionality that you want child projects to
   also be able to access.

   To use, ``include(libra/package/install.cmake)``.

   :param TARGET: A target for which
                  :cmake:command:`libra_configure_exports(TARGET PREFIX)` has
                  already been called.

   :param FILE: The file to register.

   :param PREFIX: The prefix that ``FILE`` will be installed into.


.. cmake:command:: libra_register_headers_for_install(DIRECTORY PREFIX)

   To use, ``include(libra/package/install.cmake)``.

   Register all headers (``.h`` or ``.hpp``) under ``DIRECTORY`` to be installed
   at ``PREFIX`` and associated with the necessary exports file so child
   projects can find it.

   :param DIRECTORY: The directory containing headers to install. These can be
                     from your project, a header-only dependency, etc.

   :paramm PREFIX: The prefix to install into.


Deployment
==========

.. NOTE:: These functions are only available if :cmake:variable:`LIBRA_DRIVER`
          is ``SELF``.

.. cmake:command:: libra_configure_cpack(GENERATORS SUMMARY DESCRIPTION VENDORHOMEPAGE CONTACT)

  Configure CPack to run the list of ``GENERATORS`` via ``make package``.  To
  use, ``include(libra/package/deploy.cmake)``.

  :param GENERATORS: The list of generators to run. Can be:

                     - ``TGZ|ZIP|STGZ|TBZ2|TXZ`` - A tarball/zip
                       archive/etc.

                     - ``DEB`` - A Debian archive. .deb packages are set to
                       always install into ``/usr``, unless
                       :cmake:variable:`CPACK_PACKAGE_INSTALL_DIRECTORY` is set
                       prior to calling
                       :cmake:command:`libra_configure_cpack()`.

                     - ``RPM`` - A Debian archive. .deb packages are set to
                       always install into ``/usr``, unless
                       :cmake:variable:`CPACK_PACKAGE_INSTALL_DIRECTORY` is set
                       prior to calling
                       :cmake:command:`libra_configure_cpack()n`.

                     You can have more than 1 generator just separate them by
                     ``;``.

  :param SUMMARY: One line package summary.

  :param DESCRIPTION: Package description.

  :param VENDERHOMEPAGE: The homepage for the package.

  :param CONTACT: Contact email for the package.

  Respects :cmake:variable:`CPACK_PACKAGE_FILE_NAME` if it is set prior to
  calling. Otherwise :cmake:variable:`CPACK_PACKAGE_FILE_NAME` is set to
  ``${PROJECT_NAME}-${CPACK_PACKAGE_VERSION}-${CMAKE_SYSTEM_PROCESSOR}``.
