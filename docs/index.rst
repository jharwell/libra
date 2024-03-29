.. SPDX-License-Identifier:  MIT

.. _main:

=======================================
LIBRA (Luigi buIld Reusable Automation)
=======================================

Motivation
==========

- No existing C/C++/CUDA build system supported automatic file discovery like
  ``make`` via globs.

- No existing C/C++/CUDA build system provided 100% reusability across projects
  (assuming some conventions for file naming, directory layout, etc.). I found
  myself frequently copying and pasting ``CmakeLists.txt`` (or whatever the
  tool's configuration was) between projects, as I added and when I find a new
  flag I want to add, or a new static analysis checker, etc., I would have to go
  and add it to EVERY project.

- No existing C/C++/CUDA build systems supported doing things like running one
  or more static analyzers on a repository, formatting the repository, building
  and running tests, etc., using ``make check``, ``make format``, or ``make
  tests``, or other simple cmdline syntax.

This documentation has two parts: How to use LIBRA and software development
guides, each detailed below.

.. toctree::
   :maxdepth: 2
   :caption: How To Use LIBRA

   usage/quickstart.rst
   usage/requirements.rst
   usage/capabilities.rst
   usage/project-local.rst

.. toctree::
   :maxdepth: 1
   :caption: Software Development Guides

   development/core-dev-guide.rst
   development/c-dev-guide.rst
   development/cxx-dev-guide.rst
   development/python-dev-guide.rst
   development/cuda-dev-guide.rst
   development/bazel-dev-guide.rst
   development/ld-dev-guide.rst
   development/git-usage-guide.rst
   development/git-commit-guide.rst
   development/git-issue-guide.rst
   development/workflow.rst
