.. SPDX-License-Identifier: MIT

.. _cli/reference/clean:

clean
=====

Clean build artifacts for the active preset.

.. code-block:: bash

   clibra clean                # run cmake --build --target clean
   clibra clean --all          # remove the entire build directory

Without ``--all``, ``clibra clean`` runs the ``clean`` target via the
build system — this removes compiled objects and binaries but preserves
the CMake cache and generated build files, so the next build does not
need to reconfigure.

With ``--all``, the entire ``binaryDir`` is deleted (equivalent to
``rm -rf``). The build directory must exist; ``clibra clean --all`` exits
with an error if it does not. The next ``clibra build`` will reconfigure
from scratch.

CMake equivalent
----------------

.. code-block:: bash

   # Without --all
   cmake --build --preset <n> --target clean

   # With --all (binaryDir from preset)
   rm -rf <binaryDir>

Flag reference
--------------

.. include:: ../../../_generated/clean.md
   :parser: myst_parser.sphinx_
