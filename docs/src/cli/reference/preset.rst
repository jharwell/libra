.. SPDX-License-Identifier: MIT

.. _cli/reference/preset:

preset
======

Inspect configure presets and manage the per-developer default.

.. code-block:: bash

   clibra preset list                      # enumerate all configure presets
   clibra --preset debug preset show       # resolved cache variables for a preset
   clibra --preset debug preset default    # set the default configure preset

``clibra preset`` groups three subcommands. ``list`` and ``show`` are
read-only; ``default`` writes to ``CMakeUserPresets.json``.

Subcommands
-----------

**list**
  Enumerate every configure preset visible to CMake, walking both
  ``CMakePresets.json`` and ``CMakeUserPresets.json``. This delegates to
  ``cmake --list-presets=all``.

**show**
  Print the resolved cache variables for a preset, following the full
  inheritance chain. The preset is resolved from ``--preset`` (or the
  configured default if ``--preset`` is omitted). Fails if the named
  preset does not exist.

**default**
  Record a per-developer default configure preset so that later commands
  can be run without repeating ``--preset``. The value comes from the
  global ``--preset`` flag, which is **required** for this subcommand;
  running ``clibra preset default`` with no ``--preset`` is an error. The
  named preset must exist, or the command fails without writing anything.

The default preset
------------------

``clibra preset default`` writes the chosen preset name to the
``vendor.libra.defaultConfigurePreset`` key of ``CMakeUserPresets.json``:

.. code-block:: json

   {
     "version": 6,
     "vendor": {
       "libra": {
         "defaultConfigurePreset": "debug"
       }
     }
   }

This is written to ``CMakeUserPresets.json`` (never ``CMakePresets.json``)
because the default is a per-developer, per-workspace convenience setting
rather than a shared project decision. If ``CMakeUserPresets.json`` does
not exist, a minimal stub is created. Existing content — including other
keys under ``vendor`` and ``vendor.libra`` — is preserved; only
``defaultConfigurePreset`` is set, overwriting any previous value.

Commands that accept ``--preset`` fall back to this default when the flag
is omitted, so the typical workflow is to set it once per working session:

.. code-block:: bash

   clibra --preset debug preset default
   clibra build          # uses debug
   clibra test           # uses debug

CMake equivalent
----------------

.. code-block:: bash

   # list
   cmake --list-presets=all

There is no direct CMake equivalent for ``show`` or ``default``; both
operate on the preset JSON directly. ``CMake`` itself never reads
``vendor.libra.defaultConfigurePreset`` — it is a
vendor-namespaced key that stock CMake ignores.

Flag reference
--------------

.. include:: ../../../_generated/preset.md
   :parser: myst_parser.sphinx_
