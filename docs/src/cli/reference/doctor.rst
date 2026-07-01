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
- ``✗`` — required tool (or invalid JSON in a presets file); must be
  resolved before proceeding.

Example output:

.. code-block:: text

   Checking LIBRA environment...

   Tools:
     ✓ cmake       -> /usr/bin/cmake >= 3.31.0
     ✓ ninja       -> /usr/bin/ninja (present)
     ✓ gcc         -> /usr/bin/gcc >= 9.0.0
     ✓ g++         -> /usr/bin/g++ >= 9.0.0
     ⚠ clang       not found (optional)
     ⚠ gcovr       not found (optional)
     ⚠ cppcheck    not found (optional)
     ⚠ clang-tidy  not found (optional)

   Project structure:

     ✓ CMakePresets.json exists
     ✓ src/ exists
     ⚠ tests/ does not exist
     ⚠ docs/Doxyfile.in does not exist
     ✓ CMakePresets.json is valid JSON

   Checked 14 items: 0 errors, 5 warnings, 9 ok

``clibra doctor`` exits non-zero if any ``✗`` items are found. Warnings
do not affect the exit code.

Checked tools
-------------

Only ``cmake`` is required; every other tool is optional and gates a
specific feature. Tools without a listed minimum version are checked for
presence only.

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

   * - ``valgrind``
     - any
     - ``clibra test --valgrind`` memory checking. Optional.

   * - ``gcc`` / ``g++``
     - 9
     - C/C++ compilation. Optional (one compiler family required).

   * - ``clang`` / ``clang++``
     - 14
     - C/C++ compilation, analysis, formatting. Optional.

   * - ``icx`` / ``icpx``
     - 2025.0
     - Intel LLVM compilation. Optional.

   * - ``gcovr``
     - 5.0
     - GNU coverage reports and checks. Optional.

   * - ``lcov``
     - 2.0
     - Alternative coverage tooling. Optional.

   * - ``cppcheck``
     - 2.1
     - Static analysis. Optional.

   * - ``clang-tidy``
     - 14
     - Static analysis and auto-fixing. Optional.

   * - ``clang-check``
     - 14
     - Static analysis and auto-fixing. Optional.

   * - ``clang-format``
     - 14
     - Code formatting. Optional.

   * - ``llvm-cov``
     - 14
     - LLVM-based coverage reports. Optional.

   * - ``llvm-profdata``
     - 14
     - LLVM coverage data processing. Optional.

   * - ``ccache``
     - any
     - Build caching. Optional.

   * - ``cmake-format``
     - 0.6
     - CMake formatting and format checks. Optional.

   * - ``bats``
     - any
     - Shell-based testing. Optional.

   * - ``doxygen``
     - any
     - API documentation generation. Optional.

   * - ``genhtml``
     - any
     - HTML coverage report generation. Optional.

Checked project structure
-------------------------

Every path below is reported as ``⚠`` (not ``✗``) when missing, so a
lean project that omits, say, ``docs/`` still passes. The two presets
files are additionally validated as well-formed JSON; invalid JSON is a
hard error (``✗``).

.. list-table::
   :header-rows: 1
   :widths: 35 65

   * - Path
     - Notes

   * - ``CMakePresets.json``
     - Recommended. Required for preset-based workflows. Validated as JSON.

   * - ``CMakeUserPresets.json``
     - Optional. Personal default preset configuration. Validated as JSON.

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
