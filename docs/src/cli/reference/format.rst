.. SPDX-License-Identifier: MIT

.. _cli/reference/format:

format
=======

Configure (if needed) and check/apply formatting.

.. code-block:: bash

   clibra format --preset format           # all tools
   clibra format -c clang --preset format  # one tool

Requires :cmake:variable:`LIBRA_FORMAT` to be ``ON`` in the preset's
CMake cache. Without a subcommand, runs the ``format`` umbrella target.
With a subcommand, runs only the corresponding target. If a target is
unavailable, ``clibra`` emits an error with the reason from the build
system rather than a generic failure.

CMake equivalent
----------------

.. code-block:: bash

   cmake --build --preset <n> --target format

For tool-specific configuration (suppression files, extra args, etc.) see
:ref:`cookbook/analysis`.

Flag reference
--------------

.. include:: ../../../_generated/format.md
   :parser: myst_parser.sphinx_
