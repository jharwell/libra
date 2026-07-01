.. SPDX-License-Identifier: MIT

.. _cli/reference/format:

format
======

Configure (if needed) and apply or check code formatting.

.. code-block:: bash

   clibra format --preset format              # apply all formatters
   clibra format --check clang --preset format  # check clang-format only
   clibra format --check cmake --preset format  # check cmake-format only

Requires :cmake:variable:`LIBRA_FORMAT` to be ``ON`` in the preset's
CMake cache.

With no ``--check``, ``clibra format`` **applies** formatting by running
both the ``format-clang`` and ``format-cmake`` targets. With
``--check clang`` or ``--check cmake`` it instead runs the corresponding
check-only target and does not modify files. If a target is unavailable,
``clibra`` emits an error with the reason reported by the build system
rather than a generic failure.

CMake equivalent
----------------

.. code-block:: bash

   # Apply (default)
   cmake --build --preset <name> --target format-clang
   cmake --build --preset <name> --target format-cmake

   # Check only
   cmake --build --preset <name> --target format-check-clang   # --check clang
   cmake --build --preset <name> --target format-check-cmake   # --check cmake

For tool-specific configuration (style files, extra args, etc.) see
:ref:`cookbook/analysis`.

Flag reference
--------------

.. include:: ../../../_generated/format.md
   :parser: myst_parser.sphinx_
