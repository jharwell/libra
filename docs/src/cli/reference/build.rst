.. SPDX-License-Identifier: MIT

.. _cli/reference/build:

build
=====

Configure (if needed) and build the project.

.. code-block:: bash

   clibra build --preset debug

On first run, ``clibra`` detects that no build directory exists and runs
the configure step automatically. Subsequent runs skip configure unless
inputs have changed. CMake's internal re-run mechanism handles incremental
reconfigures transparently.

CMake equivalent
----------------

Cold start (no build directory):

.. code-block:: bash

   cmake --preset <n> [-D VAR=VALUE ...]
   cmake --build --preset <n> --parallel <N>

Incremental:

.. code-block:: bash

   cmake --build --preset <n> --parallel <N> [--clean-first] [--keep-going]

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
     - Runs ``cmake --fresh --preset <n>`` then build.

   * - ``--clean`` given
     - Runs build with ``--clean-first``; does not reconfigure.

Flag reference
--------------

.. include:: ../../../_generated/build.md
   :parser: myst_parser.sphinx_
