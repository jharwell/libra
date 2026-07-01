.. SPDX-License-Identifier: MIT

.. _cli/reference/build:

build
=====

Configure (if needed) and build the project.

.. code-block:: bash

   clibra build --preset debug
   clibra build --preset debug --target mylib   # build one target
   clibra build --preset release --lto          # build with LTO

On first run, ``clibra`` detects that no build directory exists and runs
the configure step automatically. Subsequent runs skip configure unless
inputs have changed. CMake's internal re-run mechanism handles incremental
reconfigures transparently.

``--target`` restricts the build to a single CMake target. ``-v/--verbose``
prints the underlying build commands. ``-j/--jobs`` sets the parallel job
count (defaults to the logical CPU count).

Configure-time defines
----------------------

``-D VAR=VALUE`` values are forwarded to the configure step, but only when
a configure actually runs. If the build directory already exists and
neither ``--reconfigure`` nor ``--fresh`` is given, passing ``-D`` values
is treated as a configuration error and the command aborts rather than
silently ignoring them.

LTO
---

``--lto`` enables link-time optimization by appending ``LIBRA_LTO=YES`` to
the configure step, and ``--no-lto`` disables it, without requiring a
dedicated LTO preset. Either flag triggers a reconfigure only when the
requested LTO state differs from what the existing cache already holds, so
repeated builds with the same flag do not needlessly reconfigure.

CMake equivalent
----------------

Cold start (no build directory):

.. code-block:: bash

   cmake --preset <name> [-D VAR=VALUE ...]
   cmake --build --preset <name> --parallel <N>

Incremental:

.. code-block:: bash

   cmake --build --preset <name> --parallel <N> [--target <t>] [--clean-first] [--verbose]

.. list-table::
   :header-rows: 1
   :widths: 40 60

   * - Situation
     - What ``clibra build`` does

   * - Build directory absent
     - Runs configure, then build.

   * - Build directory present, inputs unchanged
     - Runs build only.

   * - Build directory present, ``--reconfigure`` given
     - Always runs configure, then build.

   * - ``--fresh`` given
     - Runs ``cmake --fresh --preset <name>`` then build.

   * - ``--clean`` given
     - Runs build with ``--clean-first``; does not reconfigure.

   * - ``--lto`` / ``--no-lto`` given
     - Reconfigures with ``LIBRA_LTO`` set accordingly, but only if the
       cache does not already match; then builds.

   * - ``-D`` given, build dir present, no ``--reconfigure`` / ``--fresh``
     - Aborts with an error (defines would be ignored).

Flag reference
--------------

.. include:: ../../../_generated/build.md
   :parser: myst_parser.sphinx_
