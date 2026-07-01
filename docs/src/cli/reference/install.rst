.. SPDX-License-Identifier: MIT

.. _cli/reference/install:

install
=======

Configure (if needed), build, and install the project.

.. code-block:: bash

   clibra install --preset release

``clibra install`` runs the ``install`` target for the resolved preset.
Like :ref:`cli/reference/build`, it configures automatically when the
build directory is absent and otherwise builds incrementally. The install
destination is the preset's ``CMAKE_INSTALL_PREFIX``.

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
dedicated LTO preset. These trigger a reconfigure only when the requested
LTO state differs from what the existing cache already has, so repeated
installs with the same flag do not needlessly reconfigure.

CMake equivalent
----------------

Cold start (no build directory):

.. code-block:: bash

   cmake --preset <name> [-D VAR=VALUE ...]
   cmake --build --preset <name> --target install

Incremental:

.. code-block:: bash

   cmake --build --preset <name> --target install

Flag reference
--------------

.. include:: ../../../_generated/install.md
   :parser: myst_parser.sphinx_
