.. SPDX-License-Identifier: MIT

.. _cli/reference/doctor:

doctor
======

Check tool availability and minimum versions, and validate the project
layout.

.. code-block:: bash

   clibra doctor

Run this before starting a new project or after setting up a new
machine. It checks every tool LIBRA can use, reports which are missing
or below the minimum version, and validates that the project layout
follows the expected conventions.

Output
------

Each checked item is reported with one of three symbols:

- ``✓`` — present and meets the minimum version requirement.
- ``⚠`` — optional tool or recommended convention; missing it limits
  specific features but does not prevent basic builds.
- ``✗`` — required tool; must be resolved before proceeding.

Example output:

.. code-block:: text

   Checking LIBRA environment...

   Tools:
     ✓ cmake       -> /usr/bin/cmake (3.31.2)
     ✓ ninja       -> /usr/bin/ninja (1.11.1)
     ✓ gcc         -> /usr/bin/gcc (13.2.0)
     ✓ g++         -> /usr/bin/g++ (13.2.0)
     ⚠ clang       not found (optional)
     ⚠ gcovr       not found (optional)
     ⚠ cppcheck    not found (optional)
     ⚠ clang-tidy  not found (optional)

   Project structure:
     ✓ CMakePresets.json exists
     ✓ src/ exists
     ⚠ tests/ does not exist
     ⚠ docs/Doxyfile.in does not exist

   Checked 14 items: 0 errors, 5 warnings, 9 ok

``clibra doctor`` exits non-zero if any ``✗`` items are found. Warnings
do not affect the exit code.

Checked tools
-------------

.. list-table::
   :header-rows: 1
   :widths: 25 20 55

   * - Tool
     - Min version
     - Required for

   * - ``cmake``
     - 3.31
     - Everything. Required.

   * - ``ninja``
     - any
     - Recommended generator. Optional.

   * - ``make``
     - any
     - Alternative generator. Optional.

   * - ``gcc`` / ``g++``
     - 9
     - C/C++ compilation. Optional (one compiler family required).

   * - ``clang`` / ``clang++``
     - 17
     - C/C++ compilation, analysis, formatting. Optional.

   * - ``icx`` / ``icpx``
     - 2025.0
     - Intel LLVM compilation. Optional.

   * - ``gcovr``
     - 5.0
     - GNU coverage reports. Optional.

   * - ``cppcheck``
     - 2.1
     - Static analysis. Optional.

   * - ``clang-tidy``
     - 17
     - Static analysis and auto-fixing. Optional.

   * - ``clang-format``
     - 17
     - Code formatting. Optional.

   * - ``ccache``
     - any
     - Build caching. Optional.

Checked project structure
-------------------------

.. list-table::
   :header-rows: 1
   :widths: 35 65

   * - Path
     - Notes

   * - ``CMakePresets.json``
     - Recommended. Required for preset-based workflows.

   * - ``CMakeUserPresets.json``
     - Optional. Personal default preset configuration.

   * - ``src/``
     - Recommended. Required for source file auto-discovery.

   * - ``include/``
     - Recommended. Required for header auto-discovery.

   * - ``tests/``
     - Recommended. Required for test auto-discovery.

   * - ``docs/``
     - Optional. Required if ``LIBRA_DOCS=ON``.

   * - ``docs/Doxyfile.in``
     - Optional. Required for Doxygen API doc generation.

   * - ``docs/conf.py``
     - Optional. Required for Sphinx doc generation.

Flag reference
--------------

.. include:: ../../../_generated/doctor.md
   :parser: myst_parser.sphinx_
