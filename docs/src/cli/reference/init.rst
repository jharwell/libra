.. SPDX-License-Identifier: MIT

.. _cli/reference/init:

init
====

Scaffold a new LIBRA project.

.. code-block:: bash

   clibra init --name foo           # scaffold the project structure
   clibra init --name foo --force   # overwrite existing files

``clibra init`` writes starter templates and creates the conventional
project directory layout. The ``--name`` flag is required and sets the
project name substituted into the generated ``CMakeLists.txt``.

Without ``--force``, existing files are left untouched — ``clibra init``
skips writing any template whose destination already exists, so it is safe
to re-run in a partially populated tree. With ``--force``, existing
templates are overwritten. Directory creation is always skip-if-present.

Writes (templates):

- ``CMakeLists.txt``
- ``CMakePresets.json``
- ``cmake/project-local.cmake``

Creates (directories):

- ``src/``
- ``include/``
- ``docs/``
- ``tests/``

Under ``--dry-run``, ``clibra init`` reports what it would write and
create without touching the filesystem.

Flag reference
--------------

.. include:: ../../../_generated/init.md
   :parser: myst_parser.sphinx_
