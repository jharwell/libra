.. SPDX-License-Identifier: MIT

.. _cli/reference/docs:

docs
====

Configure (if needed) and build project documentation.

.. code-block:: bash

   clibra docs --preset docs

Requires :cmake:variable:`LIBRA_DOCS` to be ``ON`` in the preset's CMake
cache. ``clibra docs`` attempts to build both the ``apidoc`` and
``sphinxdoc`` targets independently. If either target is listed as
unavailable by the build system, it is skipped with a warning rather than
an error — so a project with only Doxygen (no Sphinx) or only Sphinx (no
Doxygen) works without any special configuration.

CMake equivalent
----------------

.. code-block:: bash

   cmake --build --preset <n> --target apidoc     # Doxygen API docs
   cmake --build --preset <n> --target sphinxdoc  # Sphinx docs

For documentation tool configuration, see :ref:`concepts/docs`.

Flag reference
--------------

.. include:: ../../../_generated/docs.md
   :parser: myst_parser.sphinx_
