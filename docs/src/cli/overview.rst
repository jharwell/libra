.. SPDX-License-Identifier: MIT

.. _cli/overview:

========
Overview
========

``clibra`` wraps ``cmake``, ``cmake --build``, and ``ctest`` with
preset-aware defaults. Every command it runs is visible and reproducible
without the CLI — see :ref:`cli/overview/escape-hatch`.

How It Works
============

Each ``clibra`` subcommand maps to one or more ``cmake`` / ``ctest``
invocations. For example:

.. code-block:: bash

   clibra build --preset debug
   # is exactly:
   cmake --preset debug            # only on cold start
   cmake --build --preset debug -j$(nproc)

   clibra test --preset debug
   # is exactly:
   cmake --build --preset debug --target all-tests
   ctest --preset debug

   clibra ci --preset ci
   # preferred (if workflow preset exists):
   cmake --workflow --preset ci
   # fallback (if no workflow preset):
   cmake --build --preset ci --target all-tests
   ctest --preset ci
   cmake --build --preset ci --target gcovr-check

Before running, each subcommand:

1. Verifies ``CMakeLists.txt`` exists in the current directory.
2. Resolves a preset name — see :ref:`cli/presets`.
3. Checks that the preset's CMake cache has the required ``LIBRA_*``
   flags enabled (e.g. ``LIBRA_TESTS=ON`` for ``clibra test``).
4. Checks that the required CMake targets exist.

Steps 3 and 4 are skipped when :option:`--dry-run` is given.

.. _cli/overview/global-flags:

Global Flags
============

These flags are accepted by every subcommand.

.. option:: --preset <NAME>

   CMake preset name to use. When absent, ``clibra`` resolves a preset
   automatically — see :ref:`cli/presets` for the full resolution order.

.. option:: --dry-run

   Print the ``cmake`` / ``ctest`` commands that would be run, then exit
   without executing them. Target availability checks and filesystem checks
   are skipped. Useful for verifying what a command will do before running
   it:

   .. code-block:: bash

      clibra build --preset debug --dry-run
      # prints: cmake --preset debug
      #         cmake --build --preset debug --parallel 8

.. option:: --log <LEVEL>

   Log verbosity. Controls ``clibra``'s own diagnostic output, not CMake's.

   Values: ``error`` | ``warn`` (default) | ``info`` | ``debug`` | ``trace``

   For more CMake output, use ``--log info`` or ``--log debug``. For
   per-command cmake verbosity, pass ``-DCMAKE_VERBOSE_MAKEFILE=ON`` via
   ``-D``.

.. option:: --color <MODE>

   ANSI color output control.

   Values: ``auto`` (default) | ``always`` | ``never``

   ``auto`` enables color when stdout is a TTY. Use ``always`` to force
   color through a pager, or ``never`` to disable it entirely.

.. _cli/overview/escape-hatch:

The escape hatch
================

``clibra`` never introduces state that CMake cannot read. The only files
it ever writes are ``CMakePresets.json`` and ``CMakeUserPresets.json``,
and only on explicit request. You can stop using ``clibra`` at any point
and drive the build with plain ``cmake`` / ``ctest`` — no cleanup
required.

To see the exact commands ``clibra`` would run for any operation, use
:option:`--dry-run`.
