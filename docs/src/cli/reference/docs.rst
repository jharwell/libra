.. SPDX-License-Identifier: MIT

.. _cli/reference/docs:

docs
====

Configure (if needed) and build or check project documentation.

.. code-block:: bash

   clibra docs build --preset docs                 # build all doc targets
   clibra docs build --target api --preset docs    # Doxygen API docs only
   clibra docs build --target sphinx --preset docs # Sphinx docs only
   clibra docs check --kind doxygen --preset docs  # check Doxygen markup

Requires :cmake:variable:`LIBRA_DOCS` to be ``ON`` in the preset's CMake
cache.

Subcommands
-----------

**build**
  Build documentation. With no ``--target``, builds both ``apidoc`` and
  ``sphinxdoc`` independently, so a project with only Doxygen or only
  Sphinx works without special configuration. ``--target api`` builds
  just the Doxygen API docs; ``--target sphinx`` builds just the Sphinx
  docs.

**check**
  Check documentation consistency. ``--kind`` is required and selects the
  check: ``clang`` runs the clang-based API-doc check, ``doxygen`` runs
  the Doxygen markup check.

If a target is listed as unavailable by the build system, ``clibra``
reports an error with the reason rather than a generic failure.

CMake equivalent
----------------

.. code-block:: bash

   # build
   cmake --build --preset <name> --target apidoc     # --target api
   cmake --build --preset <name> --target sphinxdoc  # --target sphinx

   # check
   cmake --build --preset <name> --target apidoc-check-clang    # --kind clang
   cmake --build --preset <name> --target apidoc-check-doxygen  # --kind doxygen

For documentation tool configuration, see :ref:`concepts/docs`.

Flag reference
--------------

.. include:: ../../../_generated/docs.md
   :parser: myst_parser.sphinx_
