.. SPDX-License-Identifier: MIT

.. _cli/reference/analyze:

analyze
=======

Configure (if needed) and run static analysis.

.. code-block:: bash

   clibra analyze --preset analyze           # all tools
   clibra analyze clang-tidy --preset analyze  # one tool

Requires :cmake:variable:`LIBRA_ANALYSIS` to be ``ON`` in the preset's
CMake cache. Without a subcommand, runs the ``analyze`` umbrella target.
With a subcommand, runs only the corresponding target. If a target is
unavailable, ``clibra`` emits an error with the reason from the build
system rather than a generic failure.

CMake equivalent
----------------

.. code-block:: bash

   cmake --build --preset <n> --target analyze

For tool-specific configuration (suppression files, extra args, etc.) see
:ref:`cookbook/analysis`.

Flag reference
--------------

.. include:: ../../../_generated/analyze.md
   :parser: myst_parser.sphinx_
