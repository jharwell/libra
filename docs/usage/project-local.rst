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
          all other functions should be considered not part of the API can can
          change at any time.

.. _usage/project-local/variables:

Variables
=========

Most variables of the form ``LIBRA_XX`` detailed in :ref:`usage/configure-time`
can be permanently set in your ``project-local.cmake``, but not all. Exceptions
are:

- ``LIBRA_DEPS_PREFIX``

LIBRA also provides the following additional variables which can be used. You
*might* be able to set them on the cmdline, but doing so is not recommended.

  - ``LIBRA_ANALYSIS_LANGUAGE`` - Defines the language that the different static
    analysis checkers/formatters/fixers will use for checking the project. This
    should be specified BEFORE any subdirectories, external projects, etc. are
    specified. Only used if ``LIBRA_ANALYSIS`` is enabled. If used, value must
    be one of:

    - C
    - CXX

  - ``LIBRA_CPPCHECK_IGNORES`` - A list of files to totally ignore when running
    ``cppcheck``. Only used if ``LIBRA_ANALYSIS`` is enabled and ``cppcheck`` is
    found. The ``-i`` separators are added by LIBRA--this should just be a raw
    list.

    .. versionadded:: 0.8.5

  - ``LIBRA_CPPCHECK_SUPPRESSIONS`` - A list of categories of warnings to
    suppress for matching patterns ``cppcheck``. Only used if ``LIBRA_ANALYSIS``
    is enabled and ``cppcheck`` is found. The ``--suppress=`` separators are
    added by LIBRA--this should just be a raw list.

    .. versionadded:: 0.8.5

  - ``LIBRA_CPPCHECK_EXTRA_ARGS`` - A list of extra arguments to pass to
    cppcheck. If you want to pass suppressions or ignores, use the above
    variables; this is for other things which don't fit in those buckets. Passed
    as-is to cppcheck.

    .. versionadded:: 0.8.5

  - ``LIBRA_CLANG_FORMAT_FILEPATH`` - The path to the ``.clang-format`` file you
    want to use. If not defined, LIBRA will use its internal .clang-format file.

    .. versionadded:: 0.8.8

  - ``LIBRA_CLANG_TIDY_FILEPATH`` - The path to the ``.clang-tidy`` file
    you want to use. If not defined, LIBRA will use its internal .clang-format
    file.

    .. versionadded:: 0.8.8

  - ``LIBRA_CLANG_TIDY_CHECKS_CONFIG`` - Any additional things to pass to
    ``--checks``. If non empty, must start with ``,``. Useful to disable certain
    checks within a each category of checks that LIBRA creates targets
    for. Defaults to::

      ,-clang-diagnostic-*

    .. versionadded:: 0.8.15

  - ``LIBRA_C_DIAG_CANDIDATES`` - The list of compiler warning options you want
    to pass to the C compiler. This can be a superset of the options supported
    by the minimum C compiler version you target; each option in the list is
    checked to see if the current C compiler supports it. If not defined, uses
    LIBRA's internal C diagnostic option set, which is fairly comprehensive.  If
    you don't want to compile with any warnings, set this to ``""``.

    .. versionadded: 0.8.6

  - ``LIBRA_CXX_DIAG_CANDIDATES`` - The list of compiler warning options you
    want to pass to the compiler. This can be a superset of the options
    supported by the minimum compiler version you target; each option in the
    list is checked to see if the current CXX compiler supports it. If not
    defined, uses LIBRA's internal CXX diagnostic option set, which is fairly
    comprehensive. If you don't want to compile with any warnings, set this to
    ``""``.

    .. versionadded 0.8.6

  - ``LIBRA_TEST_HARNESS_LIBS`` - Defines the link libraries that all
    tests/test harnesses need to link with, if any. Goes hand
    in hand with ``LIBRA_TEST_HARNESS_PACKAGES``.

  - ``LIBRA_TEST_HARNESS_PACKAGES`` - Defines the packages that contain the
    libraries that all tests/test harnesses need to link with, if any. Goes hand
    in hand with ``LIBRA_TEST_HARNESS_LIBS``.

  - ``LIBRA_UNIT_TEST_MATCHER`` - The common suffix before the ``.cpp`` that all
    unit tests under ``tests/`` will have so LIBRA can glob them. If not
    specified, defaults to ``-utest``; a valid unit test would then be, e.g.,
    ``tests/myclass-utest.cpp``.

  - ``LIBRA_INTEGRATION_TEST_MATCHER`` - The common suffix before the ``.cpp``
    that all integration tests under ``tests/`` will have so LIBRA can glob
    them. If not specified, defaults to ``-itest``; a valid integration test
    would then be, e.g.,  ``tests/thing-itest.cpp``.

  - ``LIBRA_TEST_HARNESS_MATCHER`` - The common suffix before the
    ``{.cpp,.hpp}`` that all test harness files tests under ``tests/`` will have
    so LIBRA can glob them. If not specified, defaults to ``_test``; valid
    test harness would then be, e.g., ``tests/thing_test{.cpp,.hpp}``.

  - ``${PROJECT_NAME}_C_SRC`` - Glob containing all C source files.

  - ``${PROJECT_NAME}_CXX_SRC`` - Glob containing all C++ source files.

  - ``${PROJECT_NAME}_C_HEADERS`` - Glob containing all C header files.

  - ``${PROJECT_NAME}_CXX_HEADERS`` - Glob containing all C++ header files.

.. NOTE:: See :ref:`philosophy/globbing` for rationale on why globs are used,
          contrary to common cmake guidance.

Build and Run-time Diagnostics
==============================

LIBRA provides a number of functions/macros to simplify the complexity of cmake,
and answer questions such as "am I really building/running what I think I
am?". Some useful functions available in ``project-local.cmake`` are:

- ``libra_config_summary()`` - Will print a nice summary of its variables to the
  terminal. Helps debug the inevitable "Did I actually set the variable I
  thought I did?". Using this, you can see EXACTLY what variable values will be
  when you invoke your chosen build engine. You can put it at the end of
  ``project-local.cmake`` if you want; otherwise LIBRA will run it at the end of
  the configure step.

- ``libra_config_summary_prepare_fields()`` - Given a list of the configurable
  fields in a project as strings, define a set of new variables, one per field,
  with the prefix ``EMIT_``. The value of each new variable will be right padded
  with spaces so that any extra stuff on each line when the variables are shown
  to the user is aligned. See ``libra_config_summary()`` for an example of what
  this looks like.

- ``libra_configure_version(INFILE OUTFILE SRC)`` - Use build information from
  LIBRA to populate a source file of your choosing which you can then print out
  when your library loads/application starts as a sanity check during debugging
  that you are running what you think you are. LIBRA automatically adds this
  file to the provided list of files (``SRC``) which will ultimately be compiled
  for the project.

  Available LIBRA Cmake variables for population by cmake in your source file
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
          will be stubbed out and not very useful.

You can also put whatever cmake variables you want to in there as well (e.g.,
``CMAKE_C_FLAGS_RELEASE``).

Installation
============

- ``libra_configure_exports_as(TARGET PREFIX)`` - Configure the exports for a
  ``TARGET`` to be installed at ``PREFIX`` such that it can be used by *other*
  projects via ``find_package()``.

- ``libra_register_extra_configs_for_install(TARGET FILE PREFIX)`` - Configure
  additional ``.cmake`` files for export. Useful if your project provides some
  reusable cmake functionality that you want child projects to also be able to
  access.

- ``libra_register_headers_for_install(DIRECTORY PREFIX)`` - Register all
  headers (``.h`` or ``.hpp``) under ``DIRECTORY`` to be installed at ``PREFIX``
  and associated with the necessary exports file so child projects can find it.

- ``libra_register_target_for_install(TARGET PREFIX)`` - Register ``TARGET`` to
  be installed at ``PREFIX``, and associated with the necessary exports file so
  child projects can find it.

Deployment
==========

- ``libra_configure_cpack(GENERATORS DESCRIPTION VENDOR HOMEPAGE CONTACT)`` -
  Configure CPack to run the list of ``GENERATORS`` (if more than 1, must be
  separated by ``;``) via ``make package``. ``GENERATORS`` can be a subset of:

  - ``TGZ`` - A tarball.

  - ``DEB`` - A Debian archive.


  Respects ``CPACK_PACKAGE_FILE_NAME`` if it is set prior to calling. Otherwise
  ``CPACK_PACKAGE_FILE_NAME`` is set to
  ``${PROJECT_NAME}-${CPACK_PACKAGE_VERSION}-${CMAKE_SYSTEM_PROCESSOR}``.

``TGZ`` Generator Notes
-----------------------

- The ``DESCRIPTION, VENDOR, HOMEPAGE, CONTACT`` fields are ignored.

``DEB`` Generator Notes
-----------------------

- .deb packages are set to always install into ``/usr``, unless
  ``CPACK_PACKAGE_INSTALL_DIRECTORY`` is set prior to calling
  ``libra_configure_cpack()``.
