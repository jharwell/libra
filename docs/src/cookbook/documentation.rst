.. SPDX-License-Identifier: MIT

.. _cookbook/documentation:

=============
Documentation
=============

This page covers setting up Doxygen API documentation and Sphinx
project documentation, checking doc quality, and resolving third-party
header issues with the clang doc checker.

For conceptual background, see :ref:`concepts/docs`. For the target
reference, see :ref:`reference/targets`. For the flag reference, see
:ref:`cli/reference/docs`.

1. Add a docs preset
=====================

.. code-block:: json

   {
     "configurePresets": [
       {
         "name": "docs",
         "inherits": "base",
         "cacheVariables": {
           "CMAKE_BUILD_TYPE": "Release",
           "LIBRA_DOCS": "ON"
         }
       }
     ],
     "buildPresets": [
       { "name": "docs", "configurePreset": "docs" }
     ]
   }

2. Set up Doxygen
==================

LIBRA requires a ``docs/Doxyfile.in`` template. CMake substitutes
project variables (``@PROJECT_NAME@``, ``@PROJECT_SOURCE_DIR@``, etc.)
at configure time to produce ``docs/Doxyfile``.

Minimal ``docs/Doxyfile.in``:

.. code-block:: text

   PROJECT_NAME      = "@PROJECT_NAME@"
   INPUT             = "@PROJECT_SOURCE_DIR@/include" \
                       "@PROJECT_SOURCE_DIR@/src"
   OUTPUT_DIRECTORY  = "@PROJECT_BINARY_DIR@/docs/doxygen"
   GENERATE_HTML     = YES
   GENERATE_XML      = YES
   RECURSIVE         = YES
   EXTRACT_ALL       = YES
   QUIET             = YES

Generate the docs:

.. tab-set::

   .. tab-item:: CLI

      .. code-block:: bash

         clibra docs --preset docs

   .. tab-item:: CMake

      .. code-block:: bash

         cmake --preset docs
         cmake --build --preset docs --target apidoc

3. Set up Sphinx
=================

LIBRA's ``sphinxdoc`` target runs ``sphinx-build`` against ``docs/``
and generates HTML output. You need a working Sphinx project (a
``docs/conf.py``) already set up. If ``apidoc`` also exists, Sphinx
automatically depends on it — Doxygen XML is regenerated before each
Sphinx build.

.. tab-set::

   .. tab-item:: CLI

      .. code-block:: bash

         clibra docs --preset docs

   .. tab-item:: CMake

      .. code-block:: bash

         cmake --preset docs
         cmake --build --preset docs --target sphinxdoc

To use a custom Sphinx command (e.g., with ``-W`` to turn warnings
into errors):

.. code-block:: cmake

   # In project-local.cmake
   set(LIBRA_SPHINXDOC_COMMAND "sphinx-build -W -b html")

4. Check API documentation
============================

Two checkers are available with complementary strengths:

.. tab-set::

   .. tab-item:: doxygen checker

      Runs Doxygen with ``WARN_AS_ERROR=FAIL_ON_WARNINGS``. Detects
      missing documentation and malformed tags. Does *not* check that
      documentation matches the code. This is a limitation of doxygen, not LIBRA.

      .. tab-set::

         .. tab-item:: CLI

            .. code-block:: bash

               clibra docs --check --preset docs

         .. tab-item:: CMake

            .. code-block:: bash

               cmake --build --preset docs --target apidoc-check-doxygen

   .. tab-item:: clang checker

      AST-aware: detects mismatches between documentation and code
      (wrong parameter names, missing ``@param`` for an existing
      parameter, etc.). Only checks *existing* documentation — does not
      flag undocumented symbols. This is a limitation of clang, not LIBRA.

      .. tab-set::

         .. tab-item:: CLI

            .. code-block:: bash

               clibra docs --check-clang --preset docs

         .. tab-item:: CMake

            .. code-block:: bash

               cmake --build --preset docs --target apidoc-check-clang

5. Fix third-party header warnings with the clang checker
===========================================================

If the clang checker reports errors from third-party headers that are
not your code, you need to mark those include directories as system
headers so clang passes them as ``-isystem`` rather than ``-I``.

**Option 1 — mark at the target level (preferred):**

.. code-block:: cmake

   # In project-local.cmake or CMakeLists.txt
   target_include_directories(my_target SYSTEM PRIVATE
       ${third_party_include_dir})

   # For an imported target:
   set_target_properties(third_party::lib PROPERTIES
       INTERFACE_SYSTEM_INCLUDE_DIRECTORIES
       "$<TARGET_PROPERTY:third_party::lib,INTERFACE_INCLUDE_DIRECTORIES>")

**Option 2 — pragma suppression in your source files:**

.. code-block:: cpp

   #pragma clang diagnostic push
   #pragma clang diagnostic ignored "-Wdocumentation"
   #include <third_party/problematic.hpp>
   #pragma clang diagnostic pop

Option 1 is less invasive and handles transitively-included headers
automatically. Use Option 2 only when you cannot modify the CMake
target (e.g., for a system-installed library with no CMake target).

6. Documentation in CI
=======================

Documentation targets do not depend on the main project build, so they
can run independently — even before the build step if desired. See
:ref:`cookbook/ci-setup` for the full pipeline context:

.. code-block:: yaml

   # GitHub Actions
   docs:
     name: Documentation
     runs-on: ubuntu-latest
     steps:
       - uses: actions/checkout@v4
       - name: Install
         run: |
           sudo apt-get update
           sudo apt-get install -y cmake ninja-build doxygen graphviz python3-sphinx
       - name: Build and check docs
         run: |
           cmake --preset docs
           cmake --build --preset docs --target apidoc-check-doxygen
           cmake --build --preset docs --target sphinxdoc
