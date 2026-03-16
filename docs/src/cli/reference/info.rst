.. SPDX-License-Identifier: MIT

.. _cli/reference/info:

info
====

Show the resolved build configuration and available LIBRA targets.

.. code-block:: bash

   clibra info                # show everything (default)
   clibra info --targets      # available targets only
   clibra info --build        # build configuration only

Requires a prior ``clibra build`` to have configured the build directory.
Output is paged through ``less -rFX`` when it exceeds the terminal height.

This is the first command to run when a subcommand fails because a target
is unavailable — the ``Available LIBRA targets`` section shows each
target's status and, for unavailable targets, the exact reason reported
by the build system.

Output sections
---------------

**Build configuration**
  Build directory path, generator, and selected ``CMAKE_*`` cache
  variables: build type, compilers, flags, install prefix, project name,
  and compile-commands export status.

**LIBRA feature flags**
  All ``LIBRA_*`` cache variables. Non-default values are highlighted.

**Available LIBRA targets**
  All LIBRA-managed targets grouped by feature area (Tests, Docs,
  Coverage, Analysis). Each entry shows availability (``YES`` / ``NO``)
  and, for unavailable targets, the reason.

CMake equivalent
----------------

``clibra info`` reads the ``CMakeCache.txt`` directly and runs the
``help-targets`` build target to enumerate target availability. There is
no single cmake equivalent, but the same information can be obtained with:

.. code-block:: bash

   cmake --build --preset <n> --target help-targets
   cmake --build --preset <n> --target help-vars
   cat build/<n>/CMakeCache.txt | grep -E "^(CMAKE_|LIBRA_)"

Flag reference
--------------

.. include:: ../../../_generated/info.md
   :parser: myst_parser.sphinx_
