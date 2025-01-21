.. SPDX-License-Identifier:  MIT

.. _main:

=======================================
LIBRA (Luigi buIld Reusable Automation)
=======================================

Motivation
==========


- No existing C/C++ build system supported automatic file discovery like
  ``make`` via globs.

- No existing C/C++ build system provided 100% reusability across projects
  (assuming some conventions for file naming, directory layout, etc.). I found
  myself frequently copying and pasting ``CmakeLists.txt`` (or whatever the
  tool's configuration was) between projects, as I added and when I find a new
  flag I want to add, or a new static analysis checker, etc., I would have to go
  and add it to EVERY project.

- No existing C/C++ build systems supported doing things like running one or
  more static analyzers on a repository, formatting the repository, building and
  running tests, etc., using ``make analyze``, ``make format``, or ``make
  tests``, or other simple cmdline syntax.

.. _main/flavors:

Flavors
=======

LIBRA can be used in any of the following mutually exclusive ways:

- Build system middleware, providing nice syntactic sugar for automating various
  things, but not: packaging, versioning, installation, and
  deployment. The use case here is to support using a package manager such as
  conan to manage package-y things, and let LIBRA handle all the build system-y
  things (separation of responsibilities), rather than having a package manager
  or LIBRA do everything.

- As a stand-alone cmake framework, including packaging, versioning,
  installation, and deployment.

This documentation has 3 parts, listed in probable descending order of interest:

.. toctree::
   :maxdepth: 1
   :caption: How To Use LIBRA

   usage/index.rst

.. toctree::
   :maxdepth: 1
   :caption: LIBRA Design

   design/index.rst

.. toctree::
   :maxdepth: 1
   :caption: Software Development Resources

   dev/index.rst
   bazel/index.rst
