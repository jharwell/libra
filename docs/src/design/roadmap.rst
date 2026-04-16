..
   Copyright 2026 John Harwell, All rights reserved.

   SPDX-License-Identifier:  MIT

.. _design/roadmap:

=======
Roadmap
=======

This page contains ideas for (large) future expansions of LIBRA.

CLI Expansion Directions
========================

These directions deepen what ``clibra`` already does well — cmake automation,
preset management, and build observability — rather than expanding into domains
served by dedicated tools.


``clibra init`` — Project Scaffolding
--------------------------------------

Referenced in two existing error messages as ``[Phase 3]`` but not yet
implemented. This is the highest-value missing feature because it removes the
biggest friction point for new users: the bootstrapping problem of needing a
correct ``CMakeLists.txt`` and ``CMakePresets.json`` before clibra can do
anything useful.

The implementation is well-bounded. ``doctor`` already encodes the expected
project structure (``src/``, ``include/``, ``tests/``, ``docs/``,
``docs/Doxyfile.in``, ``docs/conf.py``). ``init`` would create that structure
from a template and emit a ``CMakePresets.json`` with the standard preset
hierarchy (``base``, ``debug``, ``release``, ``ci``, ``coverage``, ``docs``,
``analyze``) that the rest of the CLI assumes.

A minimal ``--bare`` flag would scaffold only ``CMakeLists.txt`` and
``CMakePresets.json`` without the directory tree, for projects that already
have their own layout.


``clibra preset`` — Preset Management
--------------------------------------

Also referenced in existing error messages as ``[Phase 3]``. Users currently
hand-edit ``CMakeUserPresets.json`` to set a default preset or add
per-machine overrides. This is error-prone and the JSON schema is non-obvious.

Concrete subcommands that cover the common cases:

- ``clibra preset default <name>`` — write
  ``vendor.libra.defaultConfigurePreset`` into ``CMakeUserPresets.json``,
  creating the file if absent
- ``clibra preset list`` — enumerate all configure presets from both preset
  files, annotating which is the current default
- ``clibra preset show <name>`` — print the resolved cache variables for a
  preset, walking the ``inherits`` chain

These close the loop on the two most common error messages clibra already
emits: *"no preset specified"* and *"no defaultConfigurePreset found"*.


``clibra compdb`` — Compile Database Management
-------------------------------------------------

LSP servers (clangd, ccls) and editor integrations depend on
``compile_commands.json`` being present at the project root. Right now users
must know to add ``CMAKE_EXPORT_COMPILE_COMMANDS=ON`` to their preset and then
manually symlink the result. This is a consistent friction point.

``clibra compdb`` would:

- Ensure ``CMAKE_EXPORT_COMPILE_COMMANDS=ON`` is active for the resolved
  preset, re-running configure if needed
- Symlink ``build/<preset>/compile_commands.json`` to the project root,
  replacing any stale link
- With ``--merge``, combine compdb files from multiple presets into a single
  file at the project root — useful when clangd should see both debug and
  release translation units

The implementation is entirely within cmake's existing output; no new
dependencies are introduced.


``clibra toolchain`` — Compiler Discovery and Selection
---------------------------------------------------------

``doctor`` already discovers installed compilers and reports their versions.
``clibra toolchain`` closes the loop by acting on that information rather than
just reporting it.

- ``clibra toolchain list`` — show all discovered compilers with versions,
  highlighting the one currently active for the resolved preset
- ``clibra toolchain use <compiler>`` — update ``CMakeUserPresets.json`` to
  point the active preset at the selected compiler, using the same vendor field
  mechanism as preset resolution

This keeps compiler selection within the cmake/preset model that clibra already
manages, rather than reaching into system package management. Installing new
compilers remains the user's responsibility.


``clibra bench`` — Benchmark Integration
-----------------------------------------

``clibra test`` maps ctest label filters to test types (``unit``,
:``integration``, ``regression``). The same infrastructure supports a
``bench`` label convention for benchmark executables, but there is no CLI
surface for it.

``clibra bench`` would:

- Build and run targets labelled ``bench`` via ctest, passing through
  ``--filter`` and ``--parallel`` as ``test`` does
- Write results to ``build/<preset>/bench-results.json`` after each run
- With ``--compare``, diff the current results against the stored baseline and
  report regressions exceeding a configurable threshold (default 10%)

The baseline file is stored in the build directory and excluded from version
control. No external benchmark framework is required; the integration is purely
at the cmake target label level.


Richer ``clibra info`` Output
------------------------------

``info`` is the primary observability surface but currently only reads the
cmake cache and the ``help-targets`` output. Two improvements that stay within
the existing architecture:

**Per-target build statistics.** After a build, cmake's ``--target`` output
contains per-file compilation times (with Ninja's ``-d stats`` or make's
``--print-directory``). Surfacing the top-N slowest translation units in
``clibra info --build`` would give users actionable data without requiring a
separate profiling tool.

**Machine-readable output.** A ``--json`` flag on ``info`` would emit the same
data as a JSON object, making ``clibra info`` composable with scripts and CI
dashboards without screen-scraping the human-formatted output. The data model
is already well-defined (cmake cache variables plus target availability);
serialising it to JSON is mechanical.


Improved Error Messages and Preset Validation
----------------------------------------------

The two most common failure modes — bad preset name and missing LIBRA feature
flag — already produce reasonable error messages. There are several adjacent
cases where the current errors are cmake's rather than clibra's:

- **Unknown preset name**: cmake emits its own error when ``--preset <name>``
  doesn't exist. clibra should validate the preset name against the parsed
  preset files before invoking cmake, and emit a message that names the
  available presets.
- **Malformed preset files**: a JSON syntax error in ``CMakePresets.json``
  currently surfaces as a serde parse error with a raw byte offset. clibra
  should catch this in ``preset::read_preset`` and emit the file name, line
  number, and a suggestion to validate with ``cmake --list-presets``.
- **``inherits`` arrays**: ``read_configure_preset_field`` silently returns
  ``None`` when ``inherits`` is a JSON array rather than a string. This is
  valid per the CMake preset schema and should be handled by walking all
  parents in order.

These are all contained changes to ``preset.rs`` and ``cmake.rs`` that make
existing functionality more robust without adding new surface area.


Configurable ``help-targets`` Format
--------------------------------------

``clibra info`` and ``clibra analyze`` parse the output of
``cmake --build --target help-targets`` to discover target availability and
reasons. This coupling means any change to the ``help-targets`` output format
breaks the CLI. A structured alternative — emitting the target list as a
cmake-generated JSON file (e.g., ``build/libra-targets.json``) at configure
time rather than at build time via a custom target — would make the data
stable, machine-readable, and available without invoking the build system.
The ``clibra info --json`` direction above would consume this file directly.
