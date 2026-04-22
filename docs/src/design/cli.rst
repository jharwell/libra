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
  ``libra cbuild``. The typing saving is marginal; the costs — typo
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

Preset resolution order
------------------------

When ``--preset`` is not given, the CLI resolves a preset as follows:

1. ``--preset=<n>`` on the current invocation.
2. ``vendor.libra.defaultConfigurePreset`` in ``CMakeUserPresets.json``.
3. ``vendor.libra.defaultConfigurePreset`` in ``CMakePresets.json``.
4. A subcommand-specific default (``ci``, ``coverage``, ``analyze``,
   ``docs``).
5. Fail with a clear, actionable message if none of the above resolves.

The vendor namespace (``vendor.libra``) is used rather than a custom
``defaultConfigurePreset`` top-level field because it is the correct
extension mechanism for tool-specific metadata that CMake itself ignores.

No sidecar file tracks an "active" preset. A developer who wants a
persistent personal default sets it explicitly via ``clibra preset
default <n>`` (planned — see `Planned Improvements`_), which writes
``vendor.libra.defaultConfigurePreset`` into ``CMakeUserPresets.json``.


Preset Requirements by Subcommand
=================================

Each subcommand validates relevant ``LIBRA_*`` feature flags from the
CMake cache before proceeding. The following table documents the minimum
``LIBRA_*`` variables a preset must have enabled for each subcommand to
succeed, and the CMake targets it expects to be present.

.. list-table::
   :widths: 15 30 55
   :header-rows: 1

   * - Subcommand
     - Required ``LIBRA_*`` variables
     - Required CMake targets
   * - ``build``
     - *(none)*
     - *(any valid CMake build target)*
   * - ``test``
     - ``LIBRA_TESTS=ON``
     - ``all-tests``
   * - ``ci``
     - ``LIBRA_TESTS=ON``, ``LIBRA_COVERAGE=ON``
     - ``all-tests``, ``gcovr-check``
   * - ``analyze``
     - ``LIBRA_ANALYSIS=ON``
     - ``analyze`` (or a tool-specific sub-target; see below)
   * - ``coverage``
     - ``LIBRA_COVERAGE=ON``
     - ``gcovr-report`` or ``llvm-report`` (for ``--html``);
       ``gcovr-check`` (for ``--check``)
   * - ``docs``
     - ``LIBRA_DOCS=ON``
     - ``apidoc`` and/or ``sphinxdoc`` (each is optional; missing
       targets produce a warning rather than an error)
   * - ``clean``
     - *(none)*
     - ``clean``
   * - ``info``
     - *(none)*
     - ``help-targets`` (used to enumerate available targets and their
       status)

The validation is performed against the CMake cache of the already-configured
build directory. A missing build directory causes an early, actionable
error rather than a silent misfire.

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
name directly, because that is currently the only check target that the LIBRA
cmake framework supports.

CMake Workflow Presets
======================

CMake workflow presets (preset schema version 6) sequence configure →
build → test → package in a single invocation::

  cmake --workflow --preset <n>

This is the correct mechanism for any ``libra`` command that runs a
fixed, multi-phase sequence. The CLI uses it where the sequence is
predetermined; it falls back to individual ``cmake``/``ctest``
invocations where the developer needs runtime control.

When workflow presets are used
-------------------------------

``libra ci``
  Checks whether a workflow preset named ``<n>`` exists in either preset
  file. If found, delegates entirely to ``cmake --workflow --preset <n>``.
  If absent, falls back to sequencing individual cmake/ctest invocations
  and emits a warning suggesting the workflow preset be added.

When workflow presets are not used
----------------------------------

Workflow presets are rigid: the sequence is fixed at definition time,
steps cannot be skipped at runtime, and filtering (e.g. ``--type=unit``)
cannot be expressed in the preset JSON. The CLI therefore sequences
individual cmake/ctest calls in the following cases:

- ``libra test --type=unit`` — requires a ``-L`` filter passed to
  ``ctest`` at runtime.
- ``libra test --stop-on-failure`` — requires a runtime ctest flag.
- ``libra test --rerun-failed`` — requires a runtime ctest flag.
- ``libra ci --no-coverage`` — requires selectively omitting a step.
- Any command where the developer passes runtime flags incompatible with
  a fixed workflow sequence.

In every case, the fallback is explicit ``cmake``\/``ctest`` invocations
that the developer could type themselves — not hidden orchestration
logic.

Canonical Preset Hierarchy
==========================

The following preset hierarchy represents what the project's
``CMakePresets.json`` should contain. It is documented here because the
CLI's design — particularly which commands map to which presets — depends
on it.

All configure presets should inherit from a ``base`` hidden preset that
sets every ``LIBRA_*`` variable to its off/default state. This ensures
that every preset is fully self-describing and no variable is left to
chance.

``base`` (hidden configure preset)
  Generator: Ninja. Sets all ``LIBRA_*`` variables to their default/off
  values. Never used directly; always inherited.

  The explicit-off pattern matters: a preset that inherits ``base`` and
  sets ``LIBRA_SAN=ASAN;UBSAN`` is guaranteed not to have stray
  sanitizer flags from some other ancestor. Developers reading the
  preset file know exactly what they are getting.

``debug``
  ``CMAKE_BUILD_TYPE=Debug``, ``LIBRA_TESTS=ON``. The everyday
  development preset. Tests are on by default for debug builds because
  that is the most common iteration loop.

``release``
  ``CMAKE_BUILD_TYPE=Release``, ``LIBRA_LTO=ON``. Portable optimised
  build. LTO is on because it is almost always wanted for a release
  binary and has no portability cost.

``native-release``
  Inherits ``release``, adds ``LIBRA_NATIVE_OPT=ON``. Separate from
  ``release`` because a ``native-release`` binary is not portable across
  CPU microarchitectures and should never be the default release preset
  for a distributed build. The distinction is meaningful enough to
  warrant its own preset rather than a flag.

``asan``, ``tsan``, ``msan``
  Inherit ``debug``, set ``LIBRA_SAN`` to the appropriate value.
  ``msan`` additionally sets ``LIBRA_STDLIB=CXX`` because MSan requires
  an instrumented standard library. These are first-class named presets,
  not transient presets synthesised at runtime by the CLI. Naming them
  explicitly in ``CMakePresets.json`` means they appear in IDE preset
  pickers and can be referenced by name with plain ``cmake``.

  These presets are also the reason why Phase 3's ``libra test
  --sanitizer`` shortcut is syntactic sugar only: a developer who uses
  sanitizers regularly will simply use ``--preset asan`` directly. The
  shortcut exists for one-off runs where the developer does not want to
  remember the preset name.

``coverage``
  Inherits ``debug``, adds ``LIBRA_COVERAGE=ON``. A dedicated coverage
  preset is cleaner than adding a flag to the debug preset because
  coverage instrumentation measurably changes build output (object files
  are not reusable between coverage and non-coverage builds) and
  warrants its own build directory.

``ci``
  Inherits ``debug``, adds ``LIBRA_COVERAGE=ON``. Nearly identical to
  ``coverage`` in the current preset file. The separation is intentional:
  ``ci`` may diverge from ``coverage`` over time (e.g. adding
  ``LIBRA_ANALYSIS=ON`` to CI), and coupling them via inheritance from
  a common parent would obscure the intent. Note that the current ``ci``
  preset does *not* enable ``LIBRA_ANALYSIS=ON``; analysis is a separate
  ``analyze`` preset and a separate step, reflecting that analysis is
  slow and belongs in a distinct CI job rather than the build-and-test
  job.

``analyze``
  Inherits ``debug``, adds ``LIBRA_ANALYSIS=ON`` and
  ``LIBRA_USE_COMPDB=YES``. The corresponding build preset pins
  ``"targets": ["analyze"]`` so that ``cmake --build --preset analyze``
  runs the analysis targets directly without building the full project
  first.

``fortify``
  Inherits ``release``, adds ``LIBRA_FORTIFY=ALL``. A release build
  with all hardening options (stack protection, ``_FORTIFY_SOURCE``,
  etc.) enabled. Separate from ``release`` because fortification options
  affect ABI in some cases and are not universally appropriate.

``valgrind``
  Inherits ``debug``, adds ``LIBRA_VALGRIND_COMPAT=ON``. A dedicated
  preset rather than a runtime flag because Valgrind-compatible codegen
  (disabling SSE/AVX instructions) affects the whole binary and its
  output is not interchangeable with a normal debug build.

``pgo-gen`` / ``pgo-use``
  Two-phase PGO presets. ``pgo-gen`` inherits ``release`` and sets
  ``LIBRA_PGO=GEN``, ``LIBRA_LTO=OFF``. ``pgo-use`` inherits
  ``release`` and sets ``LIBRA_PGO=USE``.

``docs``
  ``CMAKE_BUILD_TYPE=Debug``, ``LIBRA_DOCS=ON``, ``LIBRA_TESTS=OFF``.
  A dedicated docs preset keeps documentation builds isolated from build
  artifacts that have different caching properties.

Presets not included and why
-----------------------------

``performance``
  The earlier design included a ``performance`` seed preset combining
  ``LIBRA_LTO=ON``, ``LIBRA_NATIVE_OPT=ON``, and ``LIBRA_PGO=GEN``.
  This conflates three independent concerns: portability (native opt),
  link-time optimisation, and profile-guided optimisation. The existing
  ``native-release``, ``pgo-gen``, and ``pgo-use`` presets compose more
  cleanly. A developer who wants all three can inherit from ``release``
  and add the relevant variables in a user preset.

``dev``
  Earlier design iterations used ``dev`` as a friendly alias for the
  everyday development preset. The existing ``debug`` preset fills this
  role. Introducing ``dev`` as a synonym adds a name that appears in
  CMake's own tooling (IDEs, ``cmake --list-presets``) without adding
  any configuration meaning.

Workflow presets in ``CMakePresets.json``
------------------------------------------

The preset file shipped by ``libra init`` (see `Planned Improvments`_) includes
workflow presets for the fixed sequences.

.. code-block:: json

   "workflowPresets": [
     {
       "name": "ci",
       "displayName": "CI pipeline",
       "description": "Configure, build, and test with coverage",
       "steps": [
         { "type": "configure", "name": "ci" },
         { "type": "build",     "name": "ci" },
         { "type": "test",      "name": "coverage" }
       ]
     },
     {
       "name": "debug",
       "displayName": "Debug build and test",
       "steps": [
         { "type": "configure", "name": "debug" },
         { "type": "build",     "name": "debug" },
         { "type": "test",      "name": "debug" }
       ]
     }
   ]



Output Verbosity
=================

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
=========================

``clibra build`` runs the CMake configure step only if the preset's
build directory does not yet exist. For incremental builds, the CLI
invokes ``cmake --build --preset <n>`` directly, relying on CMake's
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
     - Runs ``cmake --fresh --preset <n>`` then build.
   * - ``--clean`` given
     - Runs build with ``--clean-first``; does not reconfigure.


Planned Improvements
=====================

The following features are not yet implemented. They are grouped by the
work required rather than a phased timeline.

Preset management (requires JSON read/write)
---------------------------------------------

.. list-table::
   :widths: 30 70
   :header-rows: 1

   * - Feature
     - Notes
   * - ``clibra preset list [--all]``
     - List presets from both files; mark the default with ``*``.
       ``--all`` annotates each with its source file.
   * - ``clibra preset new <n> [--from=<seed>] [--project]``
     - Create a configure/build/test triple. ``--from`` sets
       ``"inherits"``. ``--project`` writes to ``CMakePresets.json``;
       default is ``CMakeUserPresets.json``.
   * - ``clibra preset default [<n>]``
     - Write ``vendor.libra.defaultConfigurePreset`` to
       ``CMakeUserPresets.json``, or print the current default.
   * - ``clibra preset set <n> VAR=VALUE ...``
     - Update ``cacheVariables`` for a preset.
   * - ``clibra preset show <n>``
     - Pretty-print fully resolved ``cacheVariables`` (including
       inherited values).
   * - ``clibra preset rm <n>``
     - Remove the configure/build/test triple; refuse to remove the
       current default without ``--force``.
   * - ``clibra preset validate``
     - Validate both preset files against the CMake JSON schema
       (version 6).
   * - ``clibra init``
     - Scaffold a new project with the canonical preset hierarchy and
       workflow presets. Interactive questionnaire if no options given.

Multi-phase orchestration
--------------------------

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
--------------------

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
