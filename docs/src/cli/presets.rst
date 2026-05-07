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
3. ``vendor.libra.defaultConfigurePreset`` in ``CMakePresets.json``.
4. A subcommand-specific default (see table below).
5. Fail with a clear, actionable error.

.. list-table::
   :header-rows: 1
   :widths: 25 25 50

   * - Subcommand
     - Default preset
     - Notes

   * - ``build``
     - *(none)*
     - Must be given explicitly or via vendor field.

   * - ``test``
     - *(none)*
     - Must be given explicitly or via vendor field.

   * - ``ci``
     - ``ci``
     - Falls back to ``ci`` preset if no vendor field is set.

   * - ``analyze``
     - ``analyze``
     - Falls back to ``analyze`` preset.

   * - ``coverage``
     - ``coverage``
     - Falls back to ``coverage`` preset.

   * - ``docs``
     - ``docs``
     - Falls back to ``docs`` preset.

   * - ``clean``
     - *(none)*
     - Must be given explicitly or via vendor field.

   * - ``info``
     - *(none)*
     - Must be given explicitly or via vendor field.

   * - ``doctor``
     - *(none)*
     - Does not require a configured build directory.

Setting a personal default
==========================

Create ``CMakeUserPresets.json`` in your project root (git-ignored) with
the ``vendor.libra`` namespace:

.. code-block:: json

   {
     "version": 6,
     "vendor": {
       "libra": {
         "defaultConfigurePreset": "debug"
       }
     }
   }

With this in place, ``clibra build``, ``clibra test``, and other
subcommands without a built-in default all resolve to ``debug`` without
requiring ``--preset``.

The ``vendor`` namespace is used rather than a top-level field because it
is the correct CMake extension mechanism for tool-specific metadata that
CMake itself ignores.

No sidecar files
================

``clibra`` does not maintain any sidecar files or hidden directories
beyond ``CMakePresets.json`` and ``CMakeUserPresets.json``. There is no
"active preset" concept stored on disk — the vendor field is the only
persistent default, and it is always a plain JSON file that ``cmake``
itself can read.

Inheritance and binaryDir resolution
=====================================

When ``clibra`` needs the build directory path (e.g. to check whether
a configure step is needed), it reads it from the preset's ``binaryDir``
field, walking the ``inherits`` chain and expanding CMake preset macros
(``${sourceDir}``, ``${presetName}``, ``${sourceDirName}``). If
``binaryDir`` is absent, ``./build`` is used as the default.

Recommended preset hierarchy
============================

See :ref:`concepts/project-setup/presets` for the full recommended
``CMakePresets.json`` starting point, including the ``base`` hidden preset
pattern that ensures every child preset is fully self-describing.
