.. SPDX-License-Identifier:  MIT

.. _reference/project-local:

.. _usage/project-local:

===========================================
project-local.cmake: How To Hook Into LIBRA
===========================================

``cmake/project-local.cmake`` is the file where you define your project's
targets, configure LIBRA features, and hook into LIBRA's build machinery. You
can put standard CMake in this file alongside LIBRA-specific calls.

For an introduction to what this file should contain and a minimal working
example, see :ref:`concepts/project-setup/project-local`. This page covers the
full reference: target declaration wrappers, all available variables,
configure-time utilities, and installation/deployment helpers.

.. NOTE:: All cmake functions which LIBRA exposes are prefixed with ``libra_``;
          anything else should be considered non-API and may change at any time.


.. _usage/project-local/targets:

Target Declaration Wrappers
===========================

.. cmake-module:: ../../../cmake/libra/targets.cmake

.. _usage/project-local/variables:

Variables
=========

The variables listed in this section are generally for configuring various LIBRA
features on a per-project basis, and be stable for the duration of the
project. However, they are NOT defined as cache variables because (a) they don't
*need* to be, and (b) so the user doesn't need to remember to ``set(VAR "value"
CACHE FORCE)`` them instead of just ``set(VAR "value")`` them.

.. NOTE:: Many of the cmdline interface variables detailed in
   :ref:`reference/variables` can be set permanently in ``project-local.cmake``
   too, but not all of them. Exceptions are:

   - :cmake:variable:`LIBRA_C_STANDARD`
   - :cmake:variable:`LIBRA_CXX_STANDARD`

   If you do set any, you will need to add ``CACHE FORCE`` when setting or
   things may break it subtle ways.

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
   :cmake:variable:`LIBRA_TEST_HARNESS_PACKAGES`. Does not apply to interpreted
   tests.

.. cmake:variable:: LIBRA_TEST_HARNESS_PACKAGES

   Defines the packages that contain the libraries that all tests/test harnesses
   need to link with, if any. Goes hand in hand with
   :cmake:variable:`LIBRA_TEST_HARNESS_LIBS`. Does not apply to interpreted
   tests.

.. cmake:variable:: LIBRA_UNIT_TEST_MATCHER

   The common suffix before the ``.cpp`` that all unit tests under ``tests/``
   will have so LIBRA can glob them. If not specified, defaults to ``-utest``; a
   valid unit test would then be, e.g., ``tests/myclass-utest.cpp``.

.. cmake:variable:: LIBRA_INTEGRATION_TEST_MATCHER

   The common suffix before the ``.cpp`` that all integration tests under
   ``tests/`` will have so LIBRA can glob them. If not specified, defaults to
   ``-itest``; a valid integration test would then be, e.g.,
   ``tests/thing-itest.cpp``.

.. cmake:variable:: LIBRA_REGRESSION_TEST_MATCHER

   The common suffix before the ``.cpp`` that all regression tests under
   ``tests/`` will have so LIBRA can glob them. If not specified, defaults to
   ``-rtest``; a valid integration test would then be, e.g.,
   ``tests/thing-rtest.cpp``.

.. cmake:variable:: LIBRA_NEGATIVE_TEST_INCLUDE_DIRS

   Knob for additional include directories that need to be passed to negative
   compile tests. ``-I`` is added to each directory by LIBRA. Because these
   tests do *not* depend on the main target, we can only extract the dirs from
   the main target itself, *not* from its transitive dependencies. This is a
   limitation of CMake.

.. cmake:variable:: LIBRA_NEGATIVE_TEST_COMPILE_FLAGS

   Knob for additional compile flags that need to be passed to negative compile
   tests. Because these tests do *not* depend on the main target, we can only
   extract the flags, definitions, etc. from the main target itself, *not* from
   its transitive dependencies. This is a limitation of CMake.

.. cmake:variable:: LIBRA_TEST_HARNESS_MATCHER

   The common suffix before the ``{.cpp,.hpp}`` that all test harness files
   tests under ``tests/`` will have so LIBRA can glob them. If not specified,
   defaults to ``_test``; valid test harness would then be, e.g.,
   ``tests/thing_test{.cpp,.hpp}``. Does not apply to interpreted tests.

.. cmake:variable:: LIBRA_CTEST_INCLUDE_UNIT_TESTS

   :default: YES
   :type: BOOL

   Should registered unit tests be included in the ``test`` target to run?

.. cmake:variable:: LIBRA_CTEST_INCLUDE_INTEGRATION_TESTS

   :default: YES
   :type: BOOL

   Should registered integration tests be included in the ``test`` target to
   run?

.. cmake:variable:: LIBRA_CTEST_INCLUDE_REGRESSION_TESTS

   :default: YES
   :type: BOOL

   Should registered regression tests be included in the ``test`` target to run?

.. cmake:variable:: LIBRA_GCOVR_LINES_THRESH

   :default: 95
   :type: STRING

   Threshold for line coverage under which the ``gcovr-check`` target will
   return non-zero.

.. cmake:variable:: LIBRA_GCOVR_FUNCTIONS_THRESH

   :default: 60
   :type: STRING

   Threshold for functions coverage under which the ``gcovr-check`` target will
   return non-zero.

.. cmake:variable:: LIBRA_GCOVR_BRANCHES_THRESH

   :default: 50
   :type: STRING

   Threshold for branches coverage under which the ``gcovr-check`` target
   will return non-zero.

.. cmake:variable:: LIBRA_GCOVR_DECISIONS_THRESH

   :default: 50
   :type: STRING

   Threshold for decisions coverage under which the ``gcovr-check`` target will
   return non-zero.

.. cmake:variable:: LIBRA_SPHINXDOC_COMMAND

   :default: ``sphinx-build``
   :type: STRING

   The command to run sphinx and generate documentation. via ``make sphinxdoc``.

.. cmake:variable:: ${PROJECT_NAME}_C_SRC

   Glob containing all C source files.

.. cmake:variable:: ${PROJECT_NAME}_CXX_SRC

   Glob containing all C++ source files.

.. cmake:variable:: ${PROJECT_NAME}_C_HEADERS

   Glob containing all C header files.

.. cmake:variable:: ${PROJECT_NAME}_CXX_HEADERS

   Glob containing all C++ header files.

.. NOTE:: See :ref:`design/philosophy/globbing` for rationale on why globs are
          used, contrary to common cmake guidance.

.. _usage/project-local/diagnostics:

Configure-time Utilities
========================

LIBRA provides a number of functions/macros to simplify the complexity of cmake,
and answer questions such as "am I really building/running what I think I
am?". Some useful functions available in ``project-local.cmake`` are:

.. cmake-module:: ../../../cmake/libra/compile/version.cmake

.. cmake-module:: ../../../cmake/libra/summary.cmake

.. cmake-module:: ../../../cmake/libra/diagnostics_pre.cmake


.. _usage/project-local/install:

Installation
============

All functions in this section are only available if
:cmake:variable:`LIBRA_DRIVER` is ``SELF``.

.. cmake-module:: ../../../cmake/libra/package/install.cmake

.. _usage/project-local/deploy:

Deployment
==========

All functions in this section are only available if :cmake:variable:`LIBRA_DRIVER`
is ``SELF``.

.. cmake-module:: ../../../cmake/libra/package/deploy.cmake

Complete Example
================

Here's a full-featured ``cmake/project-local.cmake`` showing common patterns::

    # Library target
    libra_add_library(my_library STATIC
        src/core.cpp
        src/utils.cpp
    )
    target_include_directories(my_library PUBLIC include)

    # Application target
    libra_add_executable(my_app src/main.cpp)
    target_link_libraries(my_app PRIVATE my_library)

    # Enable features (optional)
    # set(LIBRA_TESTS ON)        # Enable test discovery
    # set(LIBRA_DOCS ON)          # Enable API docs
    # set(LIBRA_ANALYSIS ON)      # Enable static analysis
    # set(LIBRA_CODE_COV ON)      # Enable coverage instrumentation

    # Compiler-specific options
    # set(LIBRA_NATIVE_OPT ON)    # Optimize for this CPU
    # set(LIBRA_LTO ON)           # Link-time optimization
    # set(LIBRA_FORTIFY ALL)      # Security hardening
    # set(LIBRA_SAN "ASAN+UBSAN") # Runtime sanitizers (Debug builds)
