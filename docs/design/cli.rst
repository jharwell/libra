.. _design/cli:

==============
LIBRA CLI Tool
==============

.. DANGER::

   This is an in-progress design document which may change at any time.

.. contents:: Table of Contents
   :depth: 1
   :local:


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
  ``CMakeUserPresets.json`` is the only file the CLI ever writes, and
  only on explicit request. A developer who never runs ``libra preset``
  can use every other command by passing ``--preset`` explicitly.

**No required onboarding.**
  ``libra build --preset debug`` must work on a fresh checkout with no
  prior ``libra`` invocation, as long as ``CMakePresets.json`` or
  ``CMakeUserPresets.json`` defines a preset named ``debug``.

**No implied default action.**
  A bare ``libra`` invocation prints help and exits. It does not imply
  ``libra build``. The typing saving is marginal; the costs — typo
  swallowing, argument grammar ambiguity — are concrete.


Relationship to CMake Presets
==============================

CMake presets are the persistence and discoverability layer for build
configuration. ``libra`` wraps them, not the other way around.

The CLI reads presets and, for sequenced operations, invokes them via
``cmake --workflow``. All other commands are pass-throughs to
``cmake --build`` or ``ctest``, using a preset name supplied by the
developer or inferred from CMake's own ``defaultConfigurePreset`` field.

.. code-block:: text

   libra build --preset debug
   # is exactly equivalent to:
   cmake --preset debug && cmake --build --preset debug -j$(nproc)

   libra ci --preset ci
   # is exactly equivalent to:
   cmake --workflow --preset ci

Because ``cmake --preset``, ``cmake --build --preset``, ``ctest
--preset``, and ``cmake --workflow --preset`` are always the underlying
mechanism, switching away from the CLI at any time costs nothing.

Preset resolution order
------------------------

When ``--preset`` is not given, the CLI resolves a preset as follows:

1. ``--preset=<n>`` on the current invocation.
2. ``defaultConfigurePreset`` in ``CMakeUserPresets.json``.
3. ``defaultConfigurePreset`` in ``CMakePresets.json``.
4. Fail with a clear message if none of the above resolves.

No sidecar file tracks an "active" preset. A developer who wants a
persistent personal default sets it explicitly via ``libra preset
default <n>`` (Phase 3), which writes ``defaultConfigurePreset`` into
``CMakeUserPresets.json`` — a standard CMake field, not a CLI invention.

Why ``CMakePresets.json`` vs. ``CMakeUserPresets.json``
--------------------------------------------------------

Both files are valid targets for the CLI to write. The distinction
follows from intent:

``CMakePresets.json``
  Encodes the project's *supported* configurations. Version-controlled
  and shared. Written by the CLI only for operations whose output is
  meant to be committed: ``libra init`` seeding the initial preset
  hierarchy, or ``libra preset new --project`` promoting a preset to a
  shared definition.

``CMakeUserPresets.json``
  Encodes a *developer's local* preferences. ``.gitignore``\d by
  convention. The default target for ``libra preset new`` and the only
  file written by Phase 1 or Phase 2.

The guiding rule: *if the result should be committed, it belongs in*
``CMakePresets.json``; *if it is developer-local, it belongs in*
``CMakeUserPresets.json``.


CMake Workflow Presets
=======================

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
  Maps directly to ``cmake --workflow --preset ci``. The CI pipeline
  is a fixed sequence (configure → build → test) that a workflow preset
  expresses exactly. ``CMakePresets.json`` ships a ``ci`` workflow
  preset; the CLI invokes it.

``libra test`` (implicit build)
  When the preset's build directory does not exist, ``libra test`` must
  configure and build before testing. If a workflow preset exists with
  the same name as the configure preset, ``libra test`` uses
  ``cmake --workflow --preset <n>`` for this cold-start path. If no
  workflow preset exists, it falls back to sequencing the individual
  steps itself.

When workflow presets are not used
-----------------------------------

Workflow presets are rigid: the sequence is fixed at definition time,
steps cannot be skipped at runtime, and filtering (e.g. ``--type=unit``)
cannot be expressed in the preset JSON. The CLI therefore sequences
individual cmake/ctest calls in the following cases:

- ``libra test --type=unit`` — requires a ``-L`` filter passed to
  ``ctest`` at runtime.
- ``libra test --stop-on-failure`` — requires a runtime ctest flag.
- ``libra ci --no-coverage`` — requires selectively omitting a step.
- Any command where the developer passes ``-- <extra-args>`` to the
  underlying tool.

In every case, the fallback is explicit ``cmake``/``ctest`` invocations
that the developer could type themselves — not hidden orchestration
logic.

Workflow presets in ``CMakePresets.json``
------------------------------------------

The preset file shipped by ``libra init`` (Phase 3) includes workflow
presets for the fixed sequences. The CLI depends on these being present
for ``libra ci``. If they are absent, ``libra ci`` falls back to
sequencing individual steps and emits a warning suggesting the missing
workflow preset be added.

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


Canonical Preset Hierarchy
===========================

The following preset hierarchy is derived from real-world LIBRA usage
and represents what ``libra init`` generates in ``CMakePresets.json``.
It is documented here because the CLI's design — particularly which
commands map to which presets — depends on it.

All configure presets inherit from ``base``, which is hidden and sets
every LIBRA variable to its off/default state. This ensures that every
preset is fully self-describing and no variable is left to chance.

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
  Inherits ``debug``, adds ``LIBRA_CODE_COV=ON``. A dedicated coverage
  preset is cleaner than adding a flag to the debug preset because
  coverage instrumentation measurably changes build output (object files
  are not reusable between coverage and non-coverage builds) and
  warrants its own build directory.

``ci``
  Inherits ``debug``, adds ``LIBRA_CODE_COV=ON``. Nearly identical to
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
  first. This means ``libra analyze`` is just ``libra build --preset
  analyze`` — no special analysis command is needed.

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
  First-class named presets for the two PGO phases. ``pgo-gen`` inherits
  ``release`` and sets ``LIBRA_PGO=GEN``, ``LIBRA_LTO=OFF`` (LTO
  interferes with profile generation). ``pgo-use`` inherits ``release``
  and sets ``LIBRA_PGO=USE``. Having these as named presets means the
  PGO workflow is fully expressible without the CLI: the developer runs
  ``cmake --build --preset pgo-gen``, exercises the binary, then runs
  ``cmake --build --preset pgo-use``. ``libra pgo`` (Phase 3) is
  orchestration sugar over these two existing presets, not a new
  mechanism.

``docs``
  ``CMAKE_BUILD_TYPE=Debug``, ``LIBRA_DOCS=ON``, ``LIBRA_TESTS=OFF``.
  A dedicated docs preset keeps documentation builds isolated from build
  artifacts that have different caching properties. The build preset
  pins ``"targets": ["docs"]``.

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


Configure-Step Behaviour
=========================

``libra build`` runs the CMake configure step only if the preset's
build directory does not yet exist. For incremental builds, the CLI
invokes ``cmake --build --preset <n>`` directly.

This is not a heuristic the CLI maintains independently. CMake's own
``cmake_check_build_system`` mechanism re-runs the configure step
automatically whenever configure inputs change (``CMakeLists.txt``
files, ``*.cmake`` includes, preset JSON files, the cache). The CLI
does not replicate this logic. Doing so would introduce a second,
potentially inconsistent definition of "needs reconfiguration."

The only gap CMake's re-run mechanism does not cover is the cold start:
the build directory does not exist at all. ``libra build`` fills this
gap with a single directory-existence check.

``--reconfigure`` is provided for cases where the developer knows the
cache needs rebuilding but CMake's heuristics have not caught up (e.g.
after changing a compiler via an environment variable).

.. list-table::
   :widths: 45 55
   :header-rows: 1

   * - Situation
     - What ``libra build`` does
   * - Build directory absent
     - Runs configure, then build
   * - Build directory present, inputs unchanged
     - Runs build only (CMake no-ops the re-run check internally)
   * - Build directory present, inputs changed
     - Runs build; CMake internally re-runs configure
   * - ``--reconfigure`` given
     - Always runs configure, then build
   * - ``--clean`` given
     - Runs build with ``--clean-first``; does not reconfigure


Output Verbosity
=================

``libra`` passes cmake and ctest output through to the terminal
unchanged by default.

The alternative — a progress-bar model with output buffered and
replayed on failure — is appropriate for tools like ``cargo`` because
the Rust compiler emits structured, machine-parseable diagnostics.
CMake build output is an unstructured mix of CMake status messages,
generator output (Ninja/Make), compiler stdout and stderr, linker
output, and custom target output. Selectively intercepting and
replaying this stream would risk silently discarding warnings on
successful builds — exactly the signal that matters most for C/C++
development.

Full pass-through also trivially satisfies the escape hatch goal:
output from ``libra build`` is identical to output from
``cmake --build --preset <n>``.

.. list-table::
   :widths: 25 75
   :header-rows: 1

   * - Flag
     - Behaviour
   * - *(default)*
     - cmake/ctest stdout and stderr pass through unchanged
   * - ``--quiet, -q``
     - cmake/ctest stdout suppressed; stderr passes through; libra
       emits a single completion line per phase
   * - ``--verbose, -v``
     - The cmake/ctest command is printed before execution; stdout and
       stderr pass through unchanged. Gives the developer the exact
       command to copy for direct cmake use.
   * - ``--quiet --verbose``
     - Command printed; stdout suppressed; stderr passes through


Three-Phase Roadmap
====================

.. list-table::
   :widths: 10 20 70
   :header-rows: 1

   * - Phase
     - Implementation
     - Scope
   * - 1
     - Bash
     - Thin wrapper: shortens ``cmake``/``ctest``/``cmake --workflow``
       invocations. No preset management. No new state.
   * - 2
     - Rust (parity)
     - Identical commands and behaviour. Adds ``--json``, ``--dry-run``,
       shell completions, and better error messages.
   * - 3
     - Rust (feature-complete)
     - Preset management, project scaffolding, PGO orchestration.

Phase 2 is a clean Rust rewrite before new features are added. The
rationale: Phase 3 requires correct JSON manipulation of preset files,
which is not tractable in bash without an unacceptable external
dependency. Rewriting to Rust first gives a stable, tested foundation.
Phase 1 may be in production use while Phase 3 is still being designed;
Phase 2 provides a stable binary in the interim.


Phase 1 — Bash MVP
==================

Scope
-----

Phase 1 reduces the typing required to invoke CMake and CTest for
common LIBRA workflows. It writes nothing. ``CMakeUserPresets.json`` is
not touched by any Phase 1 command.

The ``--`` passthrough is the escape hatch for anything the CLI does
not natively support. Every command forwards arguments after ``--``
to the underlying cmake/ctest invocation verbatim.

Commands
--------

All commands accept ``--preset=<n>`` and resolve it via the rules
described in `Preset resolution order`_.

``libra build``
~~~~~~~~~~~~~~~

::

   libra build [--preset=<n>] [--jobs=N] [--clean] [--reconfigure]
               [-- <cmake-build-args>]

Cold start (build directory absent)::

  cmake --preset <n>
  cmake --build --preset <n> --parallel <N> [extra-args]

Incremental (build directory present)::

  cmake --build --preset <n> --parallel <N> [--clean-first] [extra-args]

``--jobs`` defaults to ``nproc``. ``--clean`` passes ``--clean-first``
to the build step only; it does not wipe the build directory.

``libra test``
~~~~~~~~~~~~~~

::

   libra test [--preset=<n>] [--type=<unit|integration|regression|all>]
              [--filter=<regex>] [--stop-on-failure] [--parallel=N]
              [-- <ctest-args>]

If a workflow preset named ``<n>`` exists and no filtering flags are
given, uses ``cmake --workflow --preset <n>``. Otherwise sequences
individual steps::

  # if build dir absent:
  cmake --preset <n>
  cmake --build --preset <n> --parallel <N>

  # always:
  ctest --preset <n> [-L <label>] [--tests-regex <filter>]
        [--stop-on-failure] [--parallel N] [extra-args]

CTest label mapping:

.. list-table::
   :widths: 20 80
   :header-rows: 1

   * - ``--type``
     - CTest flag
   * - ``unit``
     - ``-L utest``
   * - ``integration``
     - ``-L itest``
   * - ``regression``
     - ``-L rtest``
   * - ``all`` (default)
     - *(no* ``-L`` *flag)*

``libra ci``
~~~~~~~~~~~~

::

   libra ci [--preset=<n>] [-- <cmake-workflow-args>]

Preferred expansion (workflow preset present)::

  cmake --workflow --preset <n>

Fallback (no workflow preset for ``<n>``)::

  cmake --preset <n>
  cmake --build --preset <n> --parallel $(nproc)
  ctest --preset <n>

Emits a warning on fallback suggesting that a workflow preset be added
to ``CMakePresets.json``.

Note: ``libra ci`` intentionally has no ``--no-coverage`` or
``--no-analyze`` flags in Phase 1. Selective step control requires
runtime orchestration logic that belongs in Phase 3. CI jobs that need
to skip steps should invoke the individual ``libra build`` / ``libra
test`` commands explicitly, or use ``cmake --workflow`` directly.

``libra analyze``
~~~~~~~~~~~~~~~~~

::

   libra analyze [--preset=<n>] [-- <cmake-build-args>]

Expands to::

  cmake --build --preset analyze [extra-args]

The ``analyze`` build preset already pins ``"targets": ["analyze"]``,
so no special target flag is needed. ``--preset`` overrides the default
only if the user explicitly wants a non-standard analyze preset.

Emits a clear error if the selected preset's configure cache does not
contain ``LIBRA_ANALYSIS=ON``.

``libra coverage``
~~~~~~~~~~~~~~~~~~

::

   libra coverage [--preset=<n>] [--open] [-- <cmake-build-args>]

Expands to::

  cmake --build --preset <n> --target <coverage-target> [extra-args]

Where ``<coverage-target>`` is whichever target LIBRA registered for
the active compiler (``gcovr``, ``lcov``, ``llvm-cov``). Requires
``LIBRA_CODE_COV=ON`` in the preset's cache. ``--open`` opens the HTML
report in the system browser.

``libra docs``
~~~~~~~~~~~~~~

::

   libra docs [--preset=<n>] [-- <cmake-build-args>]

Expands to::

  cmake --build --preset docs [extra-args]

The ``docs`` build preset already pins ``"targets": ["docs"]``.

``libra clean``
~~~~~~~~~~~~~~~

::

   libra clean [--preset=<n>] [--all]

Default::

  cmake --build --preset <n> --target clean

``--all``: removes the preset's ``binaryDir`` entirely (``rm -rf``).

``libra info``
~~~~~~~~~~~~~~

::

   libra info [--preset=<n>]

Runs ``cmake --preset <n> -N`` (no-op configure) and pretty-prints the
resolved ``LIBRA_*`` cache variables alongside ``CMAKE_BUILD_TYPE`` and
the detected generator.

``libra doctor``
~~~~~~~~~~~~~~~~

::

   libra doctor

Checks availability and minimum versions of: ``cmake``, ``ninja``,
``gcc``/``g++``, ``clang``/``clang++``, ``lcov``, ``gcovr``,
``cppcheck``, ``clang-tidy``, ``clang-format``, ``valgrind``.
Validates that ``CMakeLists.txt`` exists in the current directory.
No auto-fix in Phase 1.

Global flags (Phase 1)
-----------------------

::

   --preset=<n>     Preset name. Resolved via CMake default rules if absent.
   --verbose, -v    Print the cmake/ctest command before executing it.
   --quiet, -q      Suppress cmake/ctest stdout; stderr passes through.
   --help, -h       Show help.
   --version        Show libra CLI version.

Phase 1 non-goals
------------------

.. list-table::
   :widths: 30 70
   :header-rows: 1

   * - Feature
     - Reason deferred
   * - Preset creation/deletion/modification
     - Requires JSON manipulation; deferred to Phase 3
   * - ``libra init``
     - Requires template rendering; deferred to Phase 3
   * - ``libra pgo``
     - Two-phase orchestration with state between phases; deferred to Phase 3
   * - ``--json`` / ``--dry-run``
     - Infrastructure not warranted in bash; Phase 2
   * - Shell completions
     - Phase 2
   * - ``--no-coverage``, ``--no-analyze`` on ``libra ci``
     - Runtime step control; Phase 3
   * - Writing ``CMakeUserPresets.json``
     - No inter-invocation state in Phase 1


Phase 2 — Rust (Parity)
========================

Goal
----

Deliver an identical feature set to Phase 1 in a Rust binary. No new
user-visible commands. The value is: ``--json`` and ``--dry-run``,
shell completions, structured error messages, and a foundation that
Phase 3 can build on without the constraints of bash.

Commands
---------

All Phase 1 commands with identical semantics. The expansion from
``libra <command>`` to ``cmake``/``ctest``/``cmake --workflow``
invocations is unchanged.

Additional global flags
~~~~~~~~~~~~~~~~~~~~~~~~

::

   --dry-run         Print the cmake/ctest/cmake --workflow commands that
                     would be run, then exit without executing anything.
   --json            Emit structured JSON to stdout. Errors are also JSON.
                     Intended for IDE and tooling integration.
   --color=auto|always|never

Shell completions
~~~~~~~~~~~~~~~~~

::

   libra completions bash   >> ~/.bash_completion.d/libra
   libra completions zsh    >> ~/.zfunc/_libra
   libra completions fish   > ~/.config/fish/completions/libra.fish

Generated via ``clap``'s built-in completion infrastructure. Preset
names are completed from ``CMakePresets.json`` and
``CMakeUserPresets.json``.

``libra doctor`` (enhanced)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Gains ``--fix`` for automatically addressable issues:

- Missing ``CMakeUserPresets.json`` (creates a minimal skeleton).
- Build directory present but CMake cache absent (offers to
  reconfigure).


Phase 3 — Rust (Feature-Complete)
===================================

Goal
----

Add the features that require JSON manipulation, template rendering, or
multi-phase orchestration. ``CMakeUserPresets.json`` and, where
appropriate, ``CMakePresets.json`` remain the only files written.

Preset JSON schema enforcement
-------------------------------

All reads and writes of preset files are validated against the CMake
JSON schema (schema version 6). A schema-invalid preset file produces
a clear, actionable error before any command executes.

``libra preset``
~~~~~~~~~~~~~~~~~

::

   libra preset list     [--all]
   libra preset new      <n> [--from=<seed|name>] [--project]
   libra preset default  [<n>]
   libra preset set      <n> VAR=VALUE [VAR=VALUE ...] [--project]
   libra preset show     <n>
   libra preset rm       <n> [--force]
   libra preset validate

**``libra preset list``**
  All presets from both files. Marks the default with ``*``. ``--all``
  annotates each preset with its source file.

**``libra preset new <n> [--from=<seed|name>] [--project]``**
  Creates a configure/build/test preset triple. ``--from`` accepts a
  built-in seed name or any existing preset name (sets ``"inherits"``).
  ``--project`` writes to ``CMakePresets.json``. Default target is
  ``CMakeUserPresets.json``.

  Built-in seeds correspond to the canonical presets described in
  `Canonical Preset Hierarchy`_. The seed names are the same as the
  preset names (``debug``, ``release``, ``asan``, ``coverage``, etc.)
  so that ``libra preset new my-asan --from=asan`` reads naturally.

**``libra preset default [<n>]``**
  With argument: writes ``"defaultConfigurePreset": "<n>"`` into
  ``CMakeUserPresets.json``. Without argument: prints the current
  default and its source file.

**``libra preset set <n> VAR=VALUE ...``**
  Updates ``cacheVariables`` for the named preset. Refuses to modify
  presets in ``CMakePresets.json`` unless ``--project`` is given, to
  prevent silently overwriting shared definitions.

**``libra preset show <n>``**
  Pretty-prints the fully resolved ``cacheVariables`` (including
  inherited values) in ``KEY=VALUE`` format.

**``libra preset rm <n>``**
  Removes the configure/build/test triple for the named preset.
  Refuses to remove the current default without ``--force``.

**``libra preset validate``**
  Validates both preset files against the CMake JSON schema. Reports
  errors with file and line context.

``libra init``
~~~~~~~~~~~~~~

::

   libra init [project-name] [--template=<minimal|full|quality>]
              [--language=<c|cxx|both>]
              [--type=<executable|library|header-only>]
              [--ci=<github|gitlab|none>] [--no-git]

Scaffolds a new project. Seeds ``CMakePresets.json`` with the full
canonical preset hierarchy described in `Canonical Preset Hierarchy`_,
plus workflow presets for ``ci`` and ``debug``. Seeds
``CMakeUserPresets.json`` with a ``defaultConfigurePreset`` pointing to
``debug``.

Without options, presents an interactive questionnaire. All generated
files are immediately usable with plain ``cmake --preset`` as well as
``libra``.

``libra pgo``
~~~~~~~~~~~~~

::

   libra pgo [--preset=<n>] --workload=<command> [--phase=<gen|use|auto>]

Orchestrates the two-phase PGO workflow over the existing ``pgo-gen``
and ``pgo-use`` presets (or user-specified equivalents):

1. **gen**: ``cmake --build --preset pgo-gen``, then runs ``--workload``.
2. **use**: ``cmake --build --preset pgo-use``.

With ``--phase=auto`` (default), both phases run in sequence.
``--phase=gen`` or ``--phase=use`` runs only that phase. The CLI does
not create transient presets for PGO: the ``pgo-gen`` and ``pgo-use``
presets already exist in ``CMakePresets.json`` and are usable with
plain ``cmake`` independently of the CLI.

``libra ci`` (enhanced)
~~~~~~~~~~~~~~~~~~~~~~~~

::

   libra ci [--preset=<n>] [--no-coverage] [--no-analyze]
            [--upload=codecov|coveralls]

Phase 3 adds selective step control. When ``--no-coverage`` or
``--no-analyze`` is given, the CLI cannot use ``cmake --workflow``
(which does not support step skipping) and instead sequences individual
cmake/ctest invocations. When no flags are given, ``cmake --workflow
--preset ci`` remains the preferred expansion.

``libra test`` (enhanced)
~~~~~~~~~~~~~~~~~~~~~~~~~~

Gains ``--sanitizer=<asan|tsan|msan>`` as syntactic sugar: selects the
appropriate named sanitizer preset (``asan``, ``tsan``, ``msan``) and
runs the test sequence against it. Equivalent to ``libra test --preset
asan``, but more discoverable for one-off runs.

Stability guarantee
--------------------

Phase 3 declares a stable public interface. The ``--json`` output
format carries a ``"cliVersion"`` field. Breaking changes to JSON
schema or command semantics require a major version bump.


Phase Comparison
================

.. list-table::
   :widths: 44 18 18 20
   :header-rows: 1

   * - Capability
     - Phase 1 (Bash)
     - Phase 2 (Rust parity)
     - Phase 3 (Rust complete)
   * - ``libra build``
     - ✓
     - ✓
     - ✓ + ``--target``
   * - ``libra test``
     - ✓
     - ✓
     - ✓ + ``--sanitizer``
   * - ``libra ci``
     - ✓ (workflow only)
     - ✓ (workflow only)
     - ✓ + ``--no-coverage``, ``--no-analyze``
   * - ``libra analyze``
     - ✓
     - ✓
     - ✓
   * - ``libra coverage``
     - ✓
     - ✓
     - ✓
   * - ``libra docs``
     - ✓
     - ✓
     - ✓
   * - ``libra clean``
     - ✓
     - ✓
     - ✓
   * - ``libra info``
     - ✓
     - ✓
     - ✓
   * - ``libra doctor``
     - ✓ (no fix)
     - ✓ + ``--fix``
     - ✓ + ``--fix``
   * - ``cmake --workflow`` as mechanism for ``ci`` / ``test``
     - ✓
     - ✓
     - ✓
   * - ``--dry-run`` / ``--json``
     - ✗
     - ✓
     - ✓
   * - Shell completions
     - ✗
     - ✓
     - ✓
   * - ``libra preset`` (full subcommand tree)
     - ✗
     - ✗
     - ✓
   * - ``libra init``
     - ✗
     - ✗
     - ✓
   * - ``libra pgo``
     - ✗
     - ✗
     - ✓
   * - ``libra ci`` selective step control
     - ✗
     - ✗
     - ✓
   * - Preset JSON schema validation
     - ✗
     - ✗
     - ✓
   * - Writes ``CMakeUserPresets.json``
     - ✗
     - ✗ (except ``doctor --fix``)
     - ✓
   * - Writes ``CMakePresets.json``
     - ✗
     - ✗
     - ✓ (``init``, ``preset new --project``)
   * - Single binary, zero runtime deps
     - ✓
     - ✓
     - ✓
   * - Full cmake escape hatch
     - ✓
     - ✓
     - ✓
