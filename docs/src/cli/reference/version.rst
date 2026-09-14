.. SPDX-License-Identifier: MIT

.. _cli/reference/version:

version
=======

Manage software versions according to LIBRA'S :ref:`concepts/versioning`
paradigm. To use:

- Projects must have a valid CMake cache.
- Projects must use :cmake:command:`libra_extract_version`.

To use:

.. code-block:: bash

   clibra build --preset debug  # configure and build
   clibra version               # show numeric version
   clibra version --full        # show full version
   clibra version --bump        # Bump version
   clibra version --check 1.23  # CI gate: fail if resolve != 1.2.3

Requires  :cmake:variable:`LIBRA_PROJECT_VERSION`,
:cmake:variable:`LIBRA_PROJECT_VERSION_NUMERIC`,
:cmake:variable:`LIBRA_PROJECT_VERSION_PRERELEASE` to be set, which are set by
:cmake:command:`libra_extract_version`.


CMake equivalent
----------------

This command has no CMake equivalent.


Flag reference
--------------

.. include:: ../../../_generated/version.md
   :parser: myst_parser.sphinx_
