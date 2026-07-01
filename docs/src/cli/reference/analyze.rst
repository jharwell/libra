.. SPDX-License-Identifier: MIT

.. _cli/reference/analyze:

analyze
=======

Configure (if needed) and run static analysis.

.. code-block:: bash

   clibra analyze --preset analyze              # all tools
   clibra analyze clang-tidy --preset analyze   # one tool
   clibra analyze clang-tidy --fix --preset analyze  # apply fixes

Requires :cmake:variable:`LIBRA_ANALYSIS` to be ``ON`` in the preset's
CMake cache. Without a tool subcommand, runs the ``analyze`` umbrella
target. With a tool subcommand, runs only that tool's target. If a target
is unavailable, ``clibra`` emits an error with the reason from the build
system rather than a generic failure.

The available tool subcommands are ``clang-tidy``, ``clang-check``,
``cppcheck``, ``clang-format``, and ``cmake-format``.

Applying fixes
--------------

``--fix`` runs the auto-fixing variant of a tool instead of the
report-only one. Only ``clang-tidy`` and ``clang-check`` support fixing;
combining ``--fix`` with ``cppcheck``, ``clang-format``, or
``cmake-format`` is an error. With no tool subcommand, ``--fix`` runs the
``fix`` umbrella target.

Other flags
-----------

``-j/--jobs`` sets the parallel job count (defaults to the logical CPU
count). ``-k/--keep-going`` continues past errors and is only valid with
the Ninja or Unix Makefiles generators.

CMake equivalent
----------------

.. code-block:: bash

   # All tools
   cmake --build --preset <name> --target analyze

   # Single tool (report)
   cmake --build --preset <name> --target analyze-clang-tidy
   cmake --build --preset <name> --target analyze-clang-check
   cmake --build --preset <name> --target analyze-cppcheck
   cmake --build --preset <name> --target analyze-clang-format
   cmake --build --preset <name> --target analyze-cmake-format

   # Fixes (clang-tidy / clang-check only; umbrella "fix" with no tool)
   cmake --build --preset <name> --target fix-clang-tidy
   cmake --build --preset <name> --target fix-clang-check
   cmake --build --preset <name> --target fix

For tool-specific configuration (suppression files, extra args, etc.) see
:ref:`cookbook/analysis`.

Flag reference
--------------

.. include:: ../../../_generated/analyze.md
   :parser: myst_parser.sphinx_
