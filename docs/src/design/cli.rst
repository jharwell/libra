.. _design/cli:

===============
CLI Tool Design
===============

Design Goals
============

The following goals, ordered by priority, shape every decision in this
document.

**Escape hatch first.**
  A developer must be able to drop the CLI at any point and drive the
  build with plain ``cmake`` / ``ctest`` / ``cmake --build`` /
  ``cmake --workflow`` without any manual cleanup or migration step.
  The CLI must never introduce state that CMake itself cannot read.

**Reduce typing, not control.**
  The CLI shortens long ``cmake`` invocations. It does not replace CMake
  or add a layer of indirection between the developer and the build
  system. When in doubt, pass through to CMake rather than abstract it.

**Minimal inter-invocation state.**
  The CLI avoids sidecar files and hidden directories.
  ``CMakeUserPresets.json`` and ``CMakePresets.json`` are the only files
  the CLI ever writes, and only on explicit request.

**No required onboarding.**
  ``clibra build --preset debug`` must work on a fresh checkout with no
  prior ``clibra`` invocation, as long as ``CMakePresets.json`` or
  ``CMakeUserPresets.json`` defines a preset named ``debug``.

**No implied default action.**
  A bare ``clibra`` invocation prints help and exits. It does not imply
  ``clibra build``. The typing saving is marginal; the costs — typo
  swallowing, argument grammar ambiguity — are concrete.


Relationship to CMake Presets
==============================

CMake presets are the persistence and discoverability layer for build
configuration. ``clibra`` wraps them, not the other way around.

The CLI reads presets and, for sequenced operations, invokes them via
``cmake --workflow``. All other commands are pass-throughs to
``cmake --build`` or ``ctest``, using a preset name supplied by the
developer or resolved from the preset files.

.. code-block:: text

   clibra build --preset debug
   # is exactly equivalent to:
   cmake --preset debug && cmake --build --preset debug -j$(nproc)

   clibra ci --preset ci
   # is exactly equivalent to (if a ci workflow preset exists):
   cmake --workflow --preset ci

Preset resolution
-----------------

Preset resolution is user-facing behaviour and is specified in one place:
:ref:`cli/presets`. The design constraint that shapes it is that the only
persistent default the CLI honours is
``vendor.libra.defaultConfigurePreset`` in ``CMakeUserPresets.json`` — a
per-developer, git-ignored setting, never a shared project decision in
``CMakePresets.json``. No sidecar file tracks an "active" preset; the
vendor field is the sole persistent default, and it is a plain JSON key
that stock CMake ignores.

The vendor namespace (``vendor.libra``) is used rather than a custom
top-level field because it is the correct CMake extension mechanism for
tool-specific metadata that CMake itself ignores. A developer sets this
default with :ref:`clibra preset default <cli/reference/preset>`.

Subcommand feature-flag validation
==================================

Each subcommand validates the relevant ``LIBRA_*`` feature flags against
the CMake cache of the already-configured build directory before
proceeding. A missing build directory causes an early, actionable error
rather than a silent misfire.

The authoritative table of which ``LIBRA_*`` variables and CMake targets
each subcommand requires lives in the reference: see
:ref:`cli/presets`. The two behaviours below are specific to the CLI's
implementation and are documented here rather than in the reference.

``clibra analyze`` — tool sub-targets
-------------------------------------

The ``analyze`` umbrella target depends on ``LIBRA_ANALYSIS=ON``. When
a tool subcommand is given (e.g. ``clibra analyze clang-tidy``), the
specific target (e.g. ``analyze-clang-tidy``) is checked individually
via the ``help-targets`` output. A tool target that is listed as
unavailable produces an error with the reason from the build system
rather than a generic failure.

``clibra coverage`` — target discovery
--------------------------------------

Coverage target discovery is dynamic: the CLI queries the ``help-targets``
target and selects the first available HTML-generating target from the
ordered list ``[gcovr-report, llvm-report]``. The check target
(``gcovr-check``) is not discovered dynamically — it is looked up by
name directly, because that is currently the only check target that the
LIBRA CMake framework supports.

CMake Workflow Presets
======================

CMake workflow presets (preset schema version 6) sequence configure →
build → test → package in a single invocation::

  cmake --workflow --preset <name>

This is the correct mechanism for any ``clibra`` command that runs a
fixed, multi-phase sequence. The CLI uses it where the sequence is
predetermined; it falls back to individual ``cmake``/``ctest``
invocations where the developer needs runtime control.

When workflow presets are used
-------------------------------

``clibra ci``
  Checks whether a workflow preset named ``<name>`` exists in either
  preset file. If found, delegates entirely to
  ``cmake --workflow --preset <name>``. If absent, falls back to
  sequencing individual cmake/ctest invocations and emits a warning
  suggesting the workflow preset be added.

When workflow presets are not used
----------------------------------

Workflow presets are rigid: the sequence is fixed at definition time,
steps cannot be skipped at runtime, and filtering (e.g. ``--type=unit``)
cannot be expressed in the preset JSON. The CLI therefore sequences
individual cmake/ctest calls in the following cases:

- ``clibra test --type=unit`` — requires a ``-L`` filter passed to
  ``ctest`` at runtime.
- ``clibra test --stop-on-failure`` — requires a runtime ctest flag.
- ``clibra test --rerun-failed`` — requires a runtime ctest flag.
- ``clibra ci --no-coverage`` — requires selectively omitting a step.
- Any command where the developer passes runtime flags incompatible with
  a fixed workflow sequence.

In every case, the fallback is explicit ``cmake``\/``ctest`` invocations
that the developer could type themselves — not hidden orchestration
logic.

The canonical preset hierarchy
==============================

The CLI's design — particularly which commands map to which presets —
depends on the project shipping a known set of named presets (``debug``,
``ci``, ``analyze``, ``coverage``, ``docs``, and so on). That hierarchy,
including the ``base`` hidden-preset pattern and the rationale for each
named preset, is documented once in the reference so that the CLI design
and the user-facing setup guide cannot drift apart:
see :ref:`concepts/project-setup/presets` for the recommended starting
point and :ref:`cli/presets` for the presets the CLI expects by name.

Output Verbosity
================

``clibra`` passes cmake and ctest output through to the terminal
unchanged by default. The alternative — a progress-bar model with output
buffered and replayed on failure — is inappropriate for CMake builds:
the output is an unstructured mix of generator output, compiler
diagnostics, and custom target output. Intercepting it would risk
silently discarding warnings on successful builds.

.. list-table::
   :widths: 25 75
   :header-rows: 1

   * - Flag
     - Behaviour
   * - *(default)*
     - cmake/ctest stdout and stderr pass through unchanged.
   * - ``--dry-run``
     - Prints the cmake/ctest commands that would be executed without
       running them. Exits 0.
   * - ``--log=debug`` or ``--log=trace``
     - Prints internal resolution steps (preset source, binary dir
       lookup, target availability checks) before executing commands.

All reads and writes of preset files are validated against the CMake
JSON schema (schema version 6). A schema-invalid preset file produces
a clear, actionable error before any command executes.

Configure-Step Behaviour
========================

``clibra build`` runs the CMake configure step only if the preset's
build directory does not yet exist. For incremental builds, the CLI
invokes ``cmake --build --preset <name>`` directly, relying on CMake's
own ``cmake_check_build_system`` mechanism to re-run configure whenever
inputs change.

The binary directory is resolved by reading ``binaryDir`` from the
preset JSON (walking the ``inherits`` chain as needed and expanding
``${sourceDir}``, ``${presetName}``, and ``${sourceDirName}`` macros).
If ``binaryDir`` is absent, ``./build`` is used as the default.

.. list-table::
   :widths: 45 55
   :header-rows: 1

   * - Situation
     - What ``clibra build`` does
   * - Build directory absent
     - Runs configure, then build.
   * - Build directory present, inputs unchanged
     - Runs build only (CMake no-ops the re-run check internally).
   * - Build directory present, inputs changed
     - Runs build; CMake internally re-runs configure.
   * - ``--reconfigure`` given
     - Always runs configure, then build.
   * - ``--fresh`` given
     - Runs ``cmake --fresh --preset <name>`` then build.
   * - ``--clean`` given
     - Runs build with ``--clean-first``; does not reconfigure.


Planned Improvements
====================

The following features are not yet implemented. They are grouped by the
work required rather than a phased timeline.

.. note::

   ``clibra init`` and the ``clibra preset`` subcommands (``list``,
   ``show``, ``default``) are **already implemented** and documented in
   the :ref:`CLI reference <cli/reference>`. Only the additional preset
   management verbs listed below are still planned.

Preset management (requires JSON read/write)
--------------------------------------------

.. list-table::
   :widths: 30 70
   :header-rows: 1

   * - Feature
     - Notes
   * - ``clibra preset new <name> [--from=<seed>] [--project]``
     - Create a configure/build/test triple. ``--from`` sets
       ``"inherits"``. ``--project`` writes to ``CMakePresets.json``;
       default is ``CMakeUserPresets.json``.
   * - ``clibra preset set <name> VAR=VALUE ...``
     - Update ``cacheVariables`` for a preset.
   * - ``clibra preset rm <name>``
     - Remove the configure/build/test triple; refuse to remove the
       current default without ``--force``.
   * - ``clibra preset validate``
     - Validate both preset files against the CMake JSON schema
       (version 6).

Multi-phase orchestration
-------------------------

.. list-table::
   :widths: 30 70
   :header-rows: 1

   * - Feature
     - Notes
   * - ``clibra pgo --workload=<cmd> [--phase=gen|use|auto]``
     - Orchestrate the two-phase PGO workflow over the existing
       ``pgo-gen`` / ``pgo-use`` presets. ``--phase=auto`` (default)
       runs both phases in sequence.
   * - ``clibra ci --no-coverage`` / ``--no-analyze``
     - Selective step control. Forces individual cmake/ctest invocations
       rather than ``cmake --workflow``.
   * - ``clibra test --sanitizer=<asan|tsan|msan>``
     - Syntactic sugar for ``clibra test --preset asan|tsan|msan``.

Tooling integration
-------------------

.. list-table::
   :widths: 30 70
   :header-rows: 1

   * - Feature
     - Notes
   * - ``--json`` output
     - Structured JSON on stdout. Errors also emitted as JSON.
       Carries a ``"cliVersion"`` field; breaking schema changes require
       a major version bump.
   * - Dynamic preset name completions
     - Shell completions gain dynamic preset name completion, reading
       available preset names from the preset files at completion time.
       Currently completions are static (generated by ``clap``).
