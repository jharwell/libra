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

- No existing C/C++ build system supported doing things like running one or
  more static analyzers on a repository, formatting the repository, building and
  running tests, etc., using ``make analyze``, ``make format``, or ``make
  tests``, or other simple cmdline syntax.

- No existing C/C++ build system supported doing configuring compilation in a
  declarative way across compilers. E.g., "enable the standard library", "enable
  the address sanitizer and the undefined behavior sanitizer, but not any of the
  others". Doing so is incredibly useful because it allows devs to focus on the
  *result* of what they want, and not have to worry about compiler specifics, or
  even to remember the specify option to do what they want on e.g., gcc.

Capabilities
============

.. _main/build-process:

Configure Time
--------------

LIBRA can do many things for you when cmake is run. Some highlights include:

- Configuring builds in a wide variety of ways, for everything for bare-metal to
  supercomputing multithread/multiprocess applications.

- Support for fortifying projects from security attacks.

- Providing plumbing for running various static analyzers, including those for
  checking code documentation markup.

- Providing plumbing to aid in debugging; e.g., through various sanitizers.

- Providing plumbing for easily configuring Cmake's (really CPack's) packaging
  capabilities. See

- Handling populating a source file of your choosing so that your software can
  accurately report the project version when run/loaded. This supports DRY of
  the project version.

- Providing plumbing for simple installation needs for {headers, binaries,
  libraries} via globs.

- Providing a nice summary of the exact configuration options set to make
  debugging strange configuration problems much easier.

See :ref:`usage/configure-time` for details.

Build Time
----------

After configuration, LIBRA can do many things when running ``make`` (or whatever
the build system is). In addition to being able to actually build the software,
this project enables many additional capabilities via targets. Some highlights
include:

- Running all tests {unit, regression, integration}

- Running static analyzers, formatters, etc.

- Building documentation

- Generating coverage reports

- Packaging tasks

See :ref:`usage/build-time` for details.

.. _main/flavors:

Flavors
=======

LIBRA can be used in any of the following mutually exclusive ways:

- Conan middleware, providing nice syntactic sugar for automating various
  things, but not: packaging, versioning, installation, and deployment. Conan
  handles all the package-y things, and let LIBRA handle all the build system-y
  things (separation of responsibilities), rather than having a package manager
  or LIBRA do everything.

- As a raw CMake package, handling everything above but also packaging,
  versioning, installation, and deployment, using CMake facilities.

- In-situ as a repo subdirectory or git submodule.

The first flavor is preferred, as it is more scalable, and sticks to the single
responsibility principle. When possible, LIBRA will detect if it is running
under e.g., conan, and configure itself accordingly.

.. toctree::
   :maxdepth: 1
   :caption: Getting Started

   startup/index.rst

.. toctree::
   :maxdepth: 1
   :caption: LIBRA Feature Reference

   usage/index.rst

.. toctree::
   :maxdepth: 1
   :caption: LIBRA Design And Customization

   design/index.rst
