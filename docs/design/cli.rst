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
  ``CMakeUserPresets.json`` and ``CMakePresets.json`` are the only files
  the CLI ever writes, and only on explicit request. A developer who
  never runs ``libra preset`` can use every other command by passing
  ``--preset`` explicitly.

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
developer or resolved from the preset files.

.. code-block:: text

   libra build --preset debug
   # is exactly equivalent to:
   cmake --preset debug && cmake --build --preset debug -j$(nproc)

   libra ci --preset ci
   # is exactly equivalent to the following, IF a ci workflow preset exists:
   cmake --workflow --preset ci

Because ``cmake --preset``, ``cmake --build --preset``, ``ctest
--preset``, and ``cmake --workflow --preset`` are always the underlying
mechanism, switching away from the CLI at any time costs nothing.

Preset resolution order
------------------------

When ``--preset`` is not given, the CLI resolves a preset as follows:

1. ``--preset=<n>`` on the current invocation.
2. ``vendor.libra.defaultConfigurePreset`` in ``CMakeUserPresets.json``.
3. ``vendor.libra.defaultConfigurePreset`` in ``CMakePresets.json``.
4. Fail with a clear, actionable message if none of the above resolves.

The vendor namespace (``vendor.libra``) is used rather than CMake's own
``defaultConfigurePreset`` field because ``defaultConfigurePreset`` is
not a standard CMake preset field. The vendor namespace is the correct
extension mechanism for tool-specific metadata that CMake itself ignores.

No sidecar file tracks an "active" preset. A developer who wants a
persistent personal default sets it explicitly via ``libra preset
default <n>`` (Phase 3), which writes ``vendor.libra.defaultConfigurePreset``
into ``CMakeUserPresets.json``.

Preset open-endedness
----------------------

``libra`` looks for presets by name and expects certain LIBRA variables
to be set within them, but it does not restrict what else a preset may
contain. This is a deliberate and powerful property.

A user may add any CMake cache variables, environment variables, or
generator settings to a preset that ``libra`` uses. For example, a
developer who always wants to compile with ``-march=native`` during
debug builds can add that to their personal ``debug`` preset in
``CMakeUserPresets.json`` — ``libra build`` will pick it up
transparently because it delegates entirely to cmake.

This means ``libra`` presets are augmentable at any level:

- **Project-wide** (``CMakePresets.json``): shared settings committed
  to the repository, visible to all developers and CI.
- **Developer-local** (``CMakeUserPresets.json``): personal overrides
  that inherit from the shared presets and add or override variables
  without modifying the committed file.

The CLI never restricts or validates preset contents beyond what CMake
itself enforces. A preset that ``libra build`` uses is the same preset
that ``cmake --build --preset <n>`` uses — the CLI adds no additional
interpretation layer.

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
  Checks whether a workflow preset named ``<n>`` exists in either preset
  file. If found, delegates entirely to ``cmake --workflow --preset <n>``.
  If absent, falls back to sequencing individual cmake/ctest invocations
  and emits a warning suggesting the workflow preset be added.

When workflow presets are not used
-----------------------------------

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
gap by reading ``binaryDir`` from the preset JSON (walking the
``inherits`` chain as needed) and checking whether that directory
exists. This is more reliable than parsing cmake output, which is not
part of cmake's stable interface.

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
       stderr pass through unchanged. The preset resolution source is
       also annotated (resolved via ``--preset``, ``CMakeUserPresets.json``,
       etc.). Gives the developer the exact command to copy for direct
       cmake use.
   * - ``--dry-run``
     - Prints the cmake/ctest commands that would be executed without
       running them. Exits 0. Target availability checks and filesystem
       checks are skipped; assumed targets are used as placeholders.
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
     - Rust
     - Full rewrite with enhanced command set, ``--dry-run``, ``--color``,
       shell completions, structured error messages, and ``libra info``.
   * - 3
     - Rust (feature-complete)
     - Preset management, project scaffolding, PGO orchestration.

Phase 2 is a clean Rust rewrite that goes beyond parity with Phase 1.
It adds commands and flags that were deferred from Phase 1 for
implementation complexity reasons but are fully within the "reduce
typing, not control" design goal. Phase 3 adds features that require
JSON manipulation and template rendering.


Phase 1 — Bash MVP
==================

Scope
-----

Phase 1 reduces the typing required to invoke CMake and CTest for
common LIBRA workflows. It writes nothing. ``CMakeUserPresets.json`` is
not touched by any Phase 1 command.

Commands
--------

All commands accept ``--preset=<n>`` and resolve it via the rules
described in `Preset resolution order`_.

``libra build``
~~~~~~~~~~~~~~~

::

   libra build [--preset=<n>] [--jobs=N] [--clean] [--reconfigure]

Cold start (build directory absent)::

  cmake --preset <n>
  cmake --build --preset <n> --parallel <N>

Incremental (build directory present)::

  cmake --build --preset <n> --parallel <N> [--clean-first]

``--jobs`` defaults to ``nproc``. ``--clean`` passes ``--clean-first``
to the build step only; it does not wipe the build directory.

``libra test``
~~~~~~~~~~~~~~

::

   libra test [--preset=<n>] [--type=<unit|integration|regression|all>]
              [--filter=<regex>] [--stop-on-failure] [--parallel=N]

Sequences individual cmake/ctest calls::

  # if build dir absent:
  cmake --preset <n>
  cmake --build --preset <n> --parallel <N>

  # always:
  ctest --preset <n> [-L <label>] [--tests-regex <filter>]
        [--stop-on-failure] [--parallel N]

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

   libra ci [--preset=<n>]

Preferred expansion (workflow preset present)::

  cmake --workflow --preset <n>

Fallback (no workflow preset for ``<n>``)::

  cmake --preset <n>
  cmake --build --preset <n> --parallel $(nproc)
  ctest --preset <n>

Emits a warning on fallback suggesting that a workflow preset be added
to ``CMakePresets.json``.

``libra analyze``
~~~~~~~~~~~~~~~~~

::

   libra analyze [--preset=<n>]

Expands to::

  cmake --build --preset analyze --target analyze

The ``analyze`` build preset pins ``"targets": ["analyze"]`` so no
special target flag is needed beyond specifying the preset. Emits a
clear error if the selected preset's configure cache does not contain
``LIBRA_ANALYSIS=ON``.

``libra coverage``
~~~~~~~~~~~~~~~~~~

::

   libra coverage [--preset=<n>] [--open]

Expands to::

  cmake --build --preset <n> --target <coverage-target>

Where ``<coverage-target>`` is whichever target LIBRA registered for
the active compiler (``gcovr-report``, ``lcov-report``, ``llvm-report``),
discovered at runtime via the ``help-targets`` cmake target. Requires
``LIBRA_CODE_COV=ON`` in the preset's cache. ``--open`` opens the HTML
report in the system browser.

``libra docs``
~~~~~~~~~~~~~~

::

   libra docs [--preset=<n>]

Expands to::

  cmake --build --preset docs --target apidoc     # if apidoc target available
  cmake --build --preset docs --target sphinxdoc  # if sphinxdoc target available

Each documentation target is built independently. If a target is
disabled (``LIBRA_DOCS=OFF``), it is skipped with an informational
message rather than an error. The ``docs`` preset defaults to
``CMAKE_BUILD_TYPE=Debug``, ``LIBRA_DOCS=ON``, ``LIBRA_TESTS=OFF``.

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

   libra info [--preset=<n>] [--all | --build | --targets]

Reads the preset's CMake cache (without reconfiguring) and displays:

- **Build configuration**: build directory path, generator, and
  ``CMAKE_*`` cache variables
- **LIBRA options**: all ``LIBRA_*`` cache variables, with non-default
  values highlighted
- **Available LIBRA targets**: grouped by feature area (Tests, Docs,
  Coverage, Analysis), showing which targets are available and why
  disabled targets are unavailable

Output is paged through ``less`` when longer than the terminal height.
Requires a prior ``libra build`` to have configured the build directory.

``libra doctor``
~~~~~~~~~~~~~~~~

::

   libra doctor

Checks availability and minimum versions of: ``cmake``, ``ninja``,
``gcc``/``g++``, ``clang``/``clang++``, ``gcovr``, ``lcov``,
``cppcheck``, ``clang-tidy``, ``clang-format``, ``ccache``, Intel
``icx``/``icpx``. Validates that ``CMakeLists.txt`` and at least one
preset file exist in the current directory. Checks for recommended
project structure (``src/``, ``include/``, ``tests/``, ``docs/``).

Exits non-zero if any required tool (cmake) is missing or below its
minimum version. Optional tools produce warnings, not errors.

Global flags (Phase 1)
-----------------------

::

   --preset=<n>     Preset name. Resolved via vendor field rules if absent.
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
   * - ``--dry-run`` / ``--color``
     - Infrastructure not warranted in bash; Phase 2
   * - Shell completions
     - Phase 2
   * - ``--no-coverage``, ``--no-analyze`` on ``libra ci``
     - Runtime step control; Phase 3
   * - Writing ``CMakeUserPresets.json``
     - No inter-invocation state in Phase 1


Phase 2 — Rust
===============

Goal
----

Rewrite the CLI in Rust with an enhanced command set, better error
messages, and infrastructure for Phase 3. Phase 2 goes beyond bash
parity: it adds flags and behaviours that were impractical in bash but
are fully consistent with the design goals.

Commands
---------

All Phase 1 commands are present with identical or enhanced semantics.

``libra build`` (enhanced)
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Gains ``--target`` to build a specific CMake target, and ``--keep-going``
to continue after errors::

   libra build [--preset=<n>] [--jobs=N] [--clean] [--reconfigure]
               [--target=<t>] [--keep-going] [-D VAR=VALUE ...]

``-D VAR=VALUE`` forwards cache variable definitions to the configure
step when ``--reconfigure`` is active.

``libra test`` (enhanced)
~~~~~~~~~~~~~~~~~~~~~~~~~~

Gains ``--no-build`` to skip the build step, ``--rerun-failed`` to
re-run only tests that failed in the previous run, and ``-D`` define
forwarding::

   libra test [--preset=<n>] [--type=<unit|integration|regression|all>]
              [--filter=<regex>] [--stop-on-failure] [--parallel=N]
              [--no-build] [--rerun-failed] [-D VAR=VALUE ...]

``--rerun-failed`` is particularly useful in the TDD loop: after a
full run identifies failures, subsequent runs only exercise the failing
tests, giving fast feedback while fixing them.

``libra analyze`` (enhanced)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Gains tool subcommands to run a specific analyser rather than all of
them, and ``--jobs`` / ``--keep-going`` flags::

   libra analyze [--preset=<n>] [--jobs=N] [--keep-going] [-D VAR=VALUE ...]
                 [clang-tidy | clang-check | cppcheck |
                  clang-format | cmake-format]

Without a subcommand, runs the ``analyze`` umbrella target. With a
subcommand, runs only the specified tool's target
(e.g. ``analyze-clang-tidy``). Emits a clear error with the reason if
the target is disabled (e.g. ``LIBRA_ANALYSIS=OFF``).

``libra coverage`` (enhanced)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Gains ``--check`` to run the coverage threshold check target::

   libra coverage [--preset=<n>] [--check] [--open] [-D VAR=VALUE ...]

The coverage target is discovered at runtime from the ``help-targets``
cmake target, selecting whichever of ``gcovr-report``, ``lcov-report``,
or ``llvm-report`` is available. ``--check`` runs the coverage threshold
target (``gcovr-check``). ``--open`` opens the HTML report in the system
browser after generation.

``libra info`` (enhanced)
~~~~~~~~~~~~~~~~~~~~~~~~~~

::

   libra info [--preset=<n>] [--all | --build | --targets]

``--build`` shows only the build configuration section.
``--targets`` shows only the LIBRA target availability section.
``--all`` (default) shows everything. Output is paged through ``less``.

``libra doctor``
~~~~~~~~~~~~~~~~

Same as Phase 1. The ``--fix`` flag described in earlier iterations is
out of scope: creating files on the user's behalf conflicts with the
minimal inter-invocation state goal. Diagnosis is the correct
responsibility; remediation belongs to the user or to ``libra init``
(Phase 3).

Additional global flags
~~~~~~~~~~~~~~~~~~~~~~~~

::

   --dry-run             Print the cmake/ctest commands that would be run,
                         then exit without executing. Target availability
                         checks and filesystem checks are skipped.
   --color=auto|always|never
                         Control ANSI color output. Defaults to auto
                         (color when stdout is a TTY).

Shell completions
~~~~~~~~~~~~~~~~~

::

   libra generate --shell=bash   >> ~/.bash_completion.d/libra
   libra generate --shell=zsh    >> ~/.zfunc/_libra
   libra generate --shell=fish   > ~/.config/fish/completions/libra.fish
   libra generate --manpage      > libra.1

Generated via ``clap``'s built-in completion infrastructure.

Phase 2 non-goals
------------------

.. list-table::
   :widths: 30 70
   :header-rows: 1

   * - Feature
     - Reason deferred
   * - ``--json`` output
     - Schema stability requires the Phase 3 stability guarantee first;
       shipping an unstabilised schema in Phase 2 creates a compatibility
       burden. Deferred to Phase 3.
   * - Dynamic preset name completions
     - Requires a custom clap completer; moderate value, non-trivial
       work. Deferred to Phase 3.
   * - Preset creation/deletion/modification
     - Requires JSON manipulation; deferred to Phase 3
   * - ``libra init``
     - Requires template rendering; deferred to Phase 3
   * - ``libra pgo``
     - Two-phase orchestration; deferred to Phase 3
   * - ``--no-coverage``, ``--no-analyze`` on ``libra ci``
     - Runtime step control; Phase 3


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

``--json`` output
------------------

::

   --json    Emit structured JSON to stdout. Errors are also JSON.
             Intended for IDE and tooling integration.

The JSON output format carries a ``"cliVersion"`` field. Breaking
changes to the schema require a major version bump.

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
  With argument: writes ``vendor.libra.defaultConfigurePreset: "<n>"``
  into ``CMakeUserPresets.json``. Without argument: prints the current
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
``CMakeUserPresets.json`` with a ``vendor.libra.defaultConfigurePreset``
pointing to ``debug``.

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

Dynamic preset name completions
--------------------------------

Shell completions gain dynamic preset name completion, reading available
preset names from ``CMakePresets.json`` and ``CMakeUserPresets.json``
at completion time.

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
     - Phase 2 (Rust)
     - Phase 3 (Rust complete)
   * - ``libra build``
     - ✓
     - ✓ + ``--target``, ``--keep-going``, ``-D``
     - ✓
   * - ``libra test``
     - ✓
     - ✓ + ``--no-build``, ``--rerun-failed``, ``-D``
     - ✓ + ``--sanitizer``
   * - ``libra ci``
     - ✓ (workflow-first)
     - ✓ (workflow-first)
     - ✓ + ``--no-coverage``, ``--no-analyze``
   * - ``libra analyze``
     - ✓
     - ✓ + tool subcommands, ``--jobs``, ``--keep-going``
     - ✓
   * - ``libra coverage``
     - ✓
     - ✓ + ``--check``, runtime target discovery
     - ✓
   * - ``libra docs``
     - ✓
     - ✓ + per-target skip with reason
     - ✓
   * - ``libra clean``
     - ✓
     - ✓
     - ✓
   * - ``libra info``
     - ✓ (basic)
     - ✓ + target availability, grouping, color, pager
     - ✓
   * - ``libra doctor``
     - ✓
     - ✓ + Intel compilers, ccache, project structure
     - ✓
   * - ``cmake --workflow`` for ``ci``
     - ✓
     - ✓
     - ✓
   * - ``--dry-run``
     - ✗
     - ✓
     - ✓
   * - ``--color``
     - ✗
     - ✓
     - ✓
   * - ``--json``
     - ✗
     - ✗
     - ✓
   * - Shell completions (static)
     - ✗
     - ✓
     - ✓
   * - Shell completions (dynamic preset names)
     - ✗
     - ✗
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
     - ✗
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
