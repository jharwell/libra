.. SPDX-License-Identifier: MIT

.. _getting-started/troubleshooting:

===============
Troubleshooting
===============

.. _getting-started/troubleshooting/cmake-not-found:

"CMake Error: Could not find package libra"
===========================================

For **CPM**: verify the ``file(DOWNLOAD ...)`` step in ``CMakeLists.txt``
ran successfully and that ``CPM.cmake`` exists in the build directory.
A network failure during the first configure will leave it absent.

For **installed packages**: ensure ``CMAKE_PREFIX_PATH`` is set to the
LIBRA install location, or that LIBRA was installed to a prefix CMake
searches by default (e.g. ``/usr/local``).

For **Conan**: verify ``conan install`` completed without errors before
running ``cmake``.

Run ``clibra doctor`` (if using the CLI) to check your overall environment.

.. _getting-started/troubleshooting/no-targets:

"No targets to build"
======================

``cmake/project-local.cmake`` exists but contains no target definitions,
or the file does not exist at all. Add at least one
:cmake:command:`libra_add_executable()` or
:cmake:command:`libra_add_library()` call.

.. _getting-started/troubleshooting/tests-not-discovered:

"Tests not discovered" / ``all-tests`` target missing
======================================================

Two things must both be true for test targets to exist:

1. ``LIBRA_TESTS=ON`` was set during configuration.
2. Test files follow the naming convention (``*-utest.cpp``, ``*-itest.cpp``,
   ``*-rtest.cpp``) and live under ``tests/``. If you want to use something
   else, see :cmake:variable:`LIBRA_UNIT_TEST_MATCHER`,
   :cmake:variable:`LIBRA_INTEGRATION_TEST_MATCHER`,
   :cmake:variable:`LIBRA_REGRESSION_TEST_MATCHER`, respectively, to customize
   what LIBRA searches for.

If using the CLI, run ``clibra info`` to confirm :cmake:variable:`LIBRA_TESTS`
is ``ON`` in the current build. If it is ``OFF``, either pass ``--preset <n>``
where ``<n>`` has ``LIBRA_TESTS=ON``, or reconfigure with ``--reconfigure
-DLIBRA_TESTS=ON``.

.. _getting-started/troubleshooting/globbing:

"Globbing not finding my source files"
=======================================

LIBRA expects sources in ``src/``, headers in ``include/``, and tests
in ``tests/``. If your project uses a different layout, either reorganize
to match these conventions or disable globbing and list files manually
in ``project-local.cmake``. See :ref:`reference/variables` for the
relevant variables.

.. _getting-started/troubleshooting/build-and-test:

"No rule to make target 'build-and-test'"
==========================================

:cmake:variable:`LIBRA_TESTS` was not enabled during configuration. The
``build-and-test`` target only exists when tests are enabled. Reconfigure with
``-DLIBRA_TESTS=ON`` (or use a preset that enables it).

.. _getting-started/troubleshooting/compiler-version:

"Compiler version not supported"
==================================

LIBRA requires GCC >= 9, Clang >= 17, or Intel >= 2025.0. Check your
installed version:

.. code-block:: bash

   gcc --version
   clang --version
   icx --version

If you have multiple compiler versions installed, set
``CMAKE_C_COMPILER`` and ``CMAKE_CXX_COMPILER`` explicitly in your
preset's ``cacheVariables``, or pass them on the cmake command line.
Always use matching C and C++ compilers from the same vendor — see
:ref:`getting-started/installation/compilers`.

.. _getting-started/troubleshooting/feature-not-available:

"clibra <command>: required feature flag is not ON"
=====================================================

Each ``clibra`` subcommand checks that the preset it resolves to has the
necessary ``LIBRA_*`` flag enabled before running. The full mapping is:

.. list-table::
   :header-rows: 1
   :widths: 20 40

   * - Subcommand
     - Required flag

   * - ``test``
     - ``LIBRA_TESTS=ON``

   * - ``ci``
     - ``LIBRA_TESTS=ON``, ``LIBRA_CODE_COV=ON``

   * - ``coverage``
     - ``LIBRA_CODE_COV=ON``

   * - ``analyze``
     - ``LIBRA_ANALYSIS=ON``

   * - ``docs``
     - ``LIBRA_DOCS=ON``

Either pass ``--preset <n>`` where the preset enables the required flag,
or reconfigure with ``--reconfigure -D<FLAG>=ON``. Run ``clibra info``
to see which flags are active in the current build.

.. _getting-started/troubleshooting/intel-env:

Intel compiler not found after installation
===========================================

The Intel oneAPI toolkit installs to a non-standard location and requires
sourcing an environment script before use:

.. code-block:: bash

   source /opt/intel/oneapi/setvars.sh

Add this to your shell's startup file (``~/.bashrc``, ``~/.zshrc``) or
to your CI environment setup step to avoid having to run it manually.
