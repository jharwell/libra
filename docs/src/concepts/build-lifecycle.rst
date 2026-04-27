.. SPDX-License-Identifier: MIT

.. _concepts/build-lifecycle:

===============
Build lifecycle
===============

Every LIBRA project follows the same sequence of phases. Understanding
this sequence makes it clear why certain commands must happen before
others, and how the CLI and raw CMake map to each phase.

The phases
==========

.. note::

   If no build type is specified at configure time, LIBRA defaults to
   ``Release``. This is deliberate — see :ref:`design/philosophy` for
   the rationale. The ``debug`` preset in the recommended hierarchy
   overrides this by setting ``CMAKE_BUILD_TYPE=Debug`` explicitly.

.. list-table::
   :header-rows: 1
   :widths: 15 25 30 30

   * - Phase
     - What happens
     - Raw CMake
     - ``clibra``

   * - **Configure**
     - CMake reads ``CMakeLists.txt``, resolves the preset, evaluates
       feature flags, discovers sources and tests, and generates the
       build system (Makefiles, Ninja files, etc.).
     - ``cmake --preset <n>``
     - Automatic on cold start; ``--reconfigure`` to force

   * - **Build**
     - The build system compiles sources, links targets, and builds
       any enabled test binaries.
     - ``cmake --build --preset <n>``
     - ``clibra build``

   * - **Test**
     - CTest runs the registered test executables and reports results.
     - ``ctest --preset <n>``
     - ``clibra test``

   * - **Coverage**
     - Coverage instrumentation data is collected from test runs and
       processed into reports or checked against thresholds.
     - ``cmake --build --preset <n> --target gcovr-report``
     - ``clibra coverage``

   * - **Analysis**
     - Static analysis tools (clang-tidy, cppcheck, etc.) inspect
       source files and report issues or auto-fix them.
     - ``cmake --build --preset <n> --target analyze``
     - ``clibra analyze``

   * - **Docs**
     - Doxygen and/or Sphinx generate API and project documentation.
     - ``cmake --build --preset <n> --target apidoc``
     - ``clibra docs``

   * - **Formatting**
     - Checking/applying formatting to source code
     - ``cmake --build --preset <n> --target format``
     - ``clibra format``

Phase dependencies
==================

The phases have natural ordering constraints:

- **Configure must precede build.** ``clibra build`` detects a missing build
  directory and runs configure automatically. Subsequent builds skip configure
  unless ``--reconfigure`` or ``--fresh`` is given, or CMake's internal
  dependency tracking detects that inputs have changed.

- **Build must precede test.** ``clibra test`` always builds ``all-tests`` first
  unless :option:`--no-build` is given. Running ``ctest`` directly against stale
  or absent test binaries is a common source of confusing failures.

- **Test must precede coverage.** Coverage reports are generated from data
  produced by running instrumented test binaries. Running ``gcovr-report``
  before running tests produces an empty or stale report.

- **Analysis, docs and formatting are independent.** These phases do not depend
  on a prior test run and can run after configure and build only. The
  ``analyze`` build preset sets ``"targets": ["analyze"]`` so that
  ``cmake --build --preset analyze`` runs analysis without building the full
  project first.

The CI pipeline
===============

The ``ci`` preset and ``clibra ci`` command sequence the phases that
matter for continuous integration:

.. code-block:: text

   configure  →  build (with coverage)  →  test  →  coverage check

This is the sequence that validates a change is correct (tests pass)
and meets quality thresholds (coverage does not regress). Analysis is
a separate concern — it runs in a dedicated ``analyze`` preset and a
separate CI job because it is slow and its failures represent style or
safety issues rather than correctness issues.

When a workflow preset named ``ci`` exists, ``clibra ci`` delegates the
entire sequence to ``cmake --workflow --preset ci``, which is the CMake
native way to express a multi-phase pipeline. See
:ref:`cli/reference/ci` for the fallback behaviour when no workflow
preset exists.

Cold start vs. incremental builds
==================================

The configure phase is expensive relative to an incremental build.  Each preset
has its own build directory (when using ``"binaryDir":
"${sourceDir}/build/${presetName}"``), so switching between ``debug`` and
``coverage`` is a directory switch, not a reconfigure. This is the main
practical benefit of the per-preset ``binaryDir`` convention.

Presets and the lifecycle
==========================

``clibra`` requires configure and build presets to exist for a given
name. Test presets are used by ``clibra test`` when present. Workflow
presets are used by ``clibra ci`` when a preset named ``ci`` (or the
resolved name) is found.

See :ref:`concepts/project-setup/presets` for the recommended preset
hierarchy, and :ref:`cli/presets` for how ``clibra`` resolves preset
names. See the `CMake
preset docs<https://cmake.org/cmake/help/latest/manual/cmake-presets.7.html>`
for more info on presets.
