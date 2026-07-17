.. SPDX-License-Identifier: MIT

.. _cli/presets:

=================
Preset resolution
=================

``clibra`` is preset-driven. Every subcommand needs a preset name to know
which build directory, generator, and ``LIBRA_*`` flags to use.

Resolution order
================

When ``--preset`` is not given, ``clibra`` resolves a preset name
in this order:

1. ``--preset`` on the current invocation.
2. ``vendor.libra.defaultConfigurePreset`` in ``CMakeUserPresets.json``.
3. A subcommand-specific default (see table below).
4. Fail with a clear, actionable error.

The persistent default is read **only** from ``CMakeUserPresets.json`` —
never from ``CMakePresets.json``. The default is a per-developer,
per-workspace convenience setting rather than a shared project decision,
so it lives in the git-ignored user file. ``clibra`` does not read a
``vendor.libra.defaultConfigurePreset`` key placed in
``CMakePresets.json``.

.. list-table::
   :header-rows: 1
   :widths: 25 25 50

   * - Subcommand
     - Default preset
     - Notes

   * - ``build``
     - *(none)*
     - Must be given explicitly or via the user-presets default.

   * - ``test``
     - *(none)*
     - Must be given explicitly or via the user-presets default.

   * - ``ci``
     - ``ci``
     - Falls back to the ``ci`` preset if no default is set.

   * - ``analyze``
     - ``analyze``
     - Falls back to the ``analyze`` preset.

   * - ``coverage``
     - ``coverage``
     - Falls back to the ``coverage`` preset.

   * - ``docs``
     - ``docs``
     - Falls back to the ``docs`` preset.

   * - ``clean``
     - *(none)*
     - Must be given explicitly or via the user-presets default.

   * - ``info``
     - *(none)*
     - Must be given explicitly or via the user-presets default.

   * - ``doctor``
     - *(none)*
     - Does not require a configured build directory.

Feature-flag requirements by subcommand
=======================================

Beyond resolving a preset *name*, each subcommand validates that the
resolved preset's CMake cache has the required ``LIBRA_*`` flags enabled
and that the expected targets exist. Validation runs against the cache of
the already-configured build directory; a missing build directory
produces an early, actionable error rather than a silent misfire.

.. list-table::
   :header-rows: 1
   :widths: 15 30 55

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
     - ``analyze`` (or a tool-specific sub-target)

   * - ``coverage``
     - ``LIBRA_COVERAGE=ON``
     - ``gcovr-report`` or ``llvm-report`` (for ``--html``);
       ``gcovr-check`` (for ``--check``)

   * - ``docs``
     - ``LIBRA_DOCS=ON``
     - ``apidoc`` and/or ``sphinxdoc`` (each optional; a missing target
       warns rather than errors)

   * - ``clean``
     - *(none)*
     - ``clean``

   * - ``info``
     - *(none)*
     - ``help-targets``

Setting a personal default
==========================

Use :ref:`clibra preset default <cli/reference/preset>` to record a
per-developer default. It writes the ``vendor.libra`` namespace of
``CMakeUserPresets.json`` for you:

.. code-block:: bash

   clibra --preset debug preset default
   clibra build          # uses debug
   clibra test           # uses debug

The resulting ``CMakeUserPresets.json`` (git-ignored) looks like:

.. code-block:: json

   {
     "version": 6,
     "vendor": {
       "libra": {
         "defaultConfigurePreset": "debug"
       }
     }
   }

The ``vendor`` namespace is used rather than a top-level field because it
is the correct CMake extension mechanism for tool-specific metadata that
CMake itself ignores.

No sidecar files
================

``clibra`` does not maintain any sidecar files or hidden directories
beyond ``CMakePresets.json`` and ``CMakeUserPresets.json``. There is no
"active preset" concept stored on disk — the user-presets vendor field is
the only persistent default, and it is always a plain JSON file that
``cmake`` itself can read.

Inheritance and binaryDir resolution
====================================

When ``clibra`` needs the build directory path (e.g. to check whether
a configure step is needed), it reads it from the preset's ``binaryDir``
field, walking the ``inherits`` chain and expanding CMake preset macros
(``${sourceDir}``, ``${presetName}``, ``${sourceDirName}``). If
``binaryDir`` is absent, ``./build`` is used as the default.

Recommended preset hierarchy
============================

See :ref:`concepts/project-setup/presets` for the full recommended
``CMakePresets.json`` starting point, including the ``base`` hidden preset
pattern that ensures every child preset is fully self-describing, and
:ref:`concepts/feature-flags` for the rationale behind each named preset.
