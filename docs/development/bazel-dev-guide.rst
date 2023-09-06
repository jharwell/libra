.. SPDX-License-Identifier:  MIT

.. _dev/bazel-guide:

=======================
Bazel Development Guide
=======================

Unsurprisingly, some of the items in this development guide are dictated by
LIBRA, and are intended for use with it; these are clearly stated below. If you
are not using LIBRA, then you can ignore them if you want to--but you shouldn't!

In general, follow the `rules style guide
<https://bazel.build/rules/bzl-style>`_ and the `BUILD style guide
<https://bazel.build/build/style-guide>`_ (unless something below contradicts
it, then go with what is below).

Commandments
============

These are higher-level stylistic advice which has been hard-fought and
hard-won. Ignore them at your peril; read: FOLLOW THEM.

#. If a project ``X`` has API headers in ``<repo_root>/include/X/*.h*``, then
   thou shalt make those headers available to downstream projects under
   ``X/*.h*``. This enforces the following effects in downstream C/C++ code:

   - Avoiding subtle/hard to find bugs if you happen to name a file the same as
     a system header.

   - Makes the intent of the code clearer.

#. Bazel does **NOT** allow for precise control of link order of static
   libraries, which is needed to get downstream applications to link with the
   static libraries from some packages.

   Taking our FreeRTOS fork as a concrete example, it has the following
   libraries which have to be linked in the EXACT order shown below to get all
   references to resolve:

   - freertos-kernel
   - freertos-kernel-port
   - freertos-heap4

   The possible workarounds are:

   - Pass ``alwayslink = True`` to the ``cc_library()`` definition for all
     libraries.

     Pros: Downstream targets will correctly link with ``FreeRTOS`` by simply
     declaring ``@FreeRTOS//:*`` as dependencies.

     Cons: It causes bazel to create ``.lo`` files instead of ``.a`` files, AND
     to link all files/functions, even if they are unused, bloating final binary
     size. In addition, an ``-lfoo`` option passed to the linker will NOT find
     ``libfoo.lo`` (for unknown reasons).

   - Manually add output directory where the ``FreeRTOS`` libraries can be found
     after being built to their link options which will be inherited by all
     downstream targets.

     Pros: Links files/functions on an as-needed basis, minimizing resulting
     binary size.

     Cons: Downstream targets will have to:

     - Manually link the FreeRTOS libraries in the EXACT order needed, where
       "EXACT" is determined by reading the documentation in the repository for
       the Satelles FreeRTOS fork.

     - Consume FreeRTOS OUTSIDE of their workspace so that the link directory::

         $(BINDIR)/external/FreeRTOS

       baked into the config for the FreeRTOS libraries will work.

   Decision: Thou shalt implement #2, because minimizes resulting binary size is
   more important in systems with limited memory.

#. Thou shalt not place common build options need by a target and all its
   dependencies into ``.bazelrc`` unless no other option is available. 99% of
   the time, thou can and shall put them into a target such that they are
   inherited as needed.

#. Thou shalt comment *EVERY* significant bit of configuration in thy bazel
   configuration, including:

   - Current date
   - Who commented
   - Why the configuration is significant

   For example::

     # 2023/7/21 [JRH]: Define the 'foo' library. Notice we depending on
     fizzbuzz and not bar, because bar doesn't frobnicate, and this application
     requires that.
     cc_library(...)

Project Layout
==============

File Naming
-----------

Name source files according to the following table:

.. list-table::
   :header-rows: 1
   :widths: 10 10 80

   * - Language

     - Extension

     - Rationale

   * - C++

     - ``.cpp``/``.hpp``

     - Clearly distinguishes C++ code from C code when developers are browsing
       source trees, and less likely to confuse coding tools than if you use
       e.g. ``.h`` for all headers.

   * - C

     - ``.c``/``.h``

     - Clearly distinguishes C code from C++ code when developers are browsing
       source trees, and less likely to confuse coding tools than if you use
       e.g. ``.h`` for all headers.

   * - Assembly

     - ``.S``

     - Bazel treats ``.s`` files as preprocessed source, and therefore makes
       them not depend on the selected toolchain, so any ``.s`` assembly files
       you have will not have links to e.g., the selected compiler put in
       their sandbox, and therefore not be able to find them.

Required Files: ``repositories.bzl``
------------------------------------

For projects which do not use the more recent ``bzlmod`` system, and therefore
do not support recursive workspaces, thou shalt include a ``repositories.bzl``
in the root of the project. This file defines/declares the repository
dependencies of a project:

- Local folders to treat as repositories
- Remote http archives to fetch
- Remote git repositories to fetch

Needed to build *this* project in place, and needed by downstream projects to
build this project as part of *their* dependencies. This file should define a
single macro: ``load_xx_repositories()`` where ``xx`` is the name of the project
(probably the same as the git repo).

.. IMPORTANT:: The ``load_xx_repositories()`` macro must be idempotent!

               To work with arbitrarily nested downstream targets, you will need
               to handle the dreaded diamond configuration; in this context that
               means making ``load_xx_repositories()`` idempotent. That is, for
               a project ``X``, if a downstream target ``A`` has two
               dependencies ``B`` and ``C`` who both depend on ``X``::

                      A
                    /   \
                   B     C
                    \   /
                      X

               bazel will error out when building ``A`` if
               ``load_X_repositories()`` is not idempotent with duplicate
               repository definition errors.


  An example implementation might look like::

    ##
    # \brief The first stage of a two stage process to load dependencies
    #        for X into other projects.
    #
    # Stages:
    #
    # 1. Load repository dependencies (where the actual dependencies can
    #    be found) by declaring them (this file).
    #
    # 2. Load the actual dependencies from each repository we depend on
    #    into bazel (deps.bzl).
    #
    # We need to do this until migrating to bzlmod.
    #
    # \param pathprefix The prefix to prepend to all dependency paths for
    #                   local repositories so that whatever "name" is
    #                   provided will map to the correct filesystem path.
    ##
    def load_X_repositories(pathprefix=^^):
        # these are the repository "targets" which are already defined
        excludes = native.existing_rules().keys()

        if "project1" not in excludes:
            native.local_repository(
                name = "project1",
                path = pathprefix + 'dependencies/project1',
            )

         if "project2" not in excludes:
             native.local_repository(
                 name = "project2",
                 path = pathprefix + 'dependencies/project2',
             )


Required Files: ``deps.bzl``
----------------------------

For projects which do not use the more recent ``bzlmod`` system, and therefore
do not support recursive workspaces, thou shalt include a ``deps.bzl`` in the
root of the project. This file ``load()``s from repositories defined in
``repositories.bzl`` and runs their "setup/load dependencies" hooks.  This file
should define a single macro to do this: ``load_xx_dependencies()``, where
``xx`` is the name of the project (probably the same as the git repo).  An
example implementation might look like::

   load("@project1//:deps.bzl", "load_project1_dependencies")
   load("@project2//:deps.bzl", "load_project2_dependencies")

    def load_X_dependencies(pathprefix=^^):
        load_project1_dependencies(pathprefix)
        load_project2_dependencies(pathprefix)


Miscellaneous
-------------

- If you project can be compiled standalone, place a ``WORKSPACE`` file at the
  project root. If it can only be built as part of another project (e.g., it is
  a git submodule), then don't. Correctness by construction FTW!


- It is often necessary to determine if a project dependency:

  - Should be a submodule in git and a local bazel repository.

  - Should a remote bazel dependency which is transparently fetched by bazel
    during the build process and which does not exist in version control.

  Use the following criteria: if the dependency is highly unlikely to change use
  a remote bazel dependency via ``http_archive``, etc.), otherwise use a git
  submodule. Some examples:

  - A Xilinx BSP for a particular board model -> remote bazel dependency

  - A new OS kernel PAL can be built against -> git submodule

Naming
------

- When creating a new platform, use the following naming convention
  (everything lower case!!)::

    <board>-<cpu>-<os>

  This makes platform designations unambiguous and future proof.  E.g., for a
  ORCA7090 board with an ARM-M7 processor running FreeRTOS, you would do
  something like::

    orca7090-armv7m-freertos

  .. IMPORTANT:: Obeying Principle of Least Surprise, the name of the board,
                 CPU, and OS should **EXACTLY** match items defined under
                 ``//platform-constraints:*``.


  Good example::

    platform(
    name = "orca7090-armv7m-freertos",
    constraint_values = [
        "@platform-constraints//cpu:armv7-m",
        "@platform-constraints//board:orca7090",
    ],
    )

  Bad example (violates principle of least surprise)::

    platform(
    name = "orca7090-arm-rev1",
    constraint_values = [
        "@platform-constraints//cpu:armv7-m",
        "@platform-constraints//board:orca7090",
    ],
    )


- Do not rely on the namespace/scoping of packages for unique library
  names. That is, do not define ``//awesome-project/:submodule`` as a target,
  but rather ``//awesome-project/:awesome-project-submodule`` (or something
  similar). This is because Bazel does not give you a clean way to rename the
  output file name of a target to something different than the target name
  (which sort of makes sense, given the Principle of Least Surprise). This has
  two benefits:

  - It makes ``BUILD`` files easier to understand when skimmed, as the file
    scoped name of a target is embedded into the "leaf" name that Bazel sees.

  - It reduces chances of linker collisions on the cmdline if two packages both
    define a ``libfoo.a`` and your projects depends on both. You **MIGHT** get
    an error message , or you **MIGHT** get a silent choice by the linker of
    which library to choose, depending on any number of things. Better not to
    risk it.


Documentation
=============

- All macros should have a doxygen brief.

- All functions should be documented with at least a brief. All non-obvious
  parameters should be documented.
