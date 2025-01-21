.. _usage/conan:

=================
Conan Integration
=================

This pages provides details on how LIBRA integrates with conan.

.. _usage/conan/setup:

Setup
=====

When using conan, LIBRA can be consumed in two ways: as a cmake package,
supplementing whatever else you want to put in your cmake configuration, or
as the sum total of your cmake configuration.

#. Setup your repo:

   .. tabs::

      .. group-tab:: Supplementary cmake package

          Create your ``CMakeLists.txt`` in the root of your repo. Within that
          file, create something like this::

            cmake_minimum_required(VERSION 3.21 FATAL_ERROR) # whatever version you like
            project(my_project CXX) # languages can be anything cmake supports

            include(libra/project)

      .. group-tab:: Sole cmake configuration

         #. Add the libra repository as a sub-module ``libra/`` in your repo.

         #. Link ``libra/cmake/project.cmake`` -> ``CMakeLists.txt`` in the root of your
            repo. On linux::

              ln -s libra/cmake/project.cmake CmakeLists.txt


#. Create ``cmake/project-local.cmake`` in the root of your project repo. This
   is where you define what targets you want to build, how to build them,
   etc. See :ref:`usage/project-local` for more details.

#. Make LIBRA accessible to cmake:

   .. tabs::

      .. group-tab:: Supplementary cmake package

         In ``conanfile.py`` put the following::

           def build_requirements(self):
               self.tool_requires("cmake/3.21")
               self.tool_requires("libra/0.8.0") # arbitrary LIBRA version

           def generate(self):
               deps = CMakeDeps(self)
               deps.build_context_activated = ["libra"]

               tc = CMakeToolchain(self)
               tc.variables["LIBRA_DRIVER"] = "CONAN"

               deps.generate()
               tc.generate()

      .. group-tab:: Sole cmake configuration

         In ``conanfile.py`` put the following::

           def generate(self):
               tc = CMakeToolchain(self)
               tc.variables["LIBRA_DRIVER"] = "CONAN"

#. Build your project via conan::

     conan build .

   from the root of the repo. Or::

     cmake --build . -t <target> --preset conan-{debug,release}

   from the root of the repo. Or::

     make <target>

   from the ``build/{Debug,Release,...}`` directory.


Advanced Details
================

If you're following the quickstart, you can skip this section unless you're
curious.

Build Types
-----------

LIBRA only current supports compiler-based features (e.g., ``LIBRA_LTO``) for
the following cmake build types:

- Debug

- Release

Not because it *can't* support other build types, but because the ones above are
the most common. It is very straightforward to add other build types if needed.

Variables
---------

LIBRA inherits the following cmake variables set by conan, sets the value of
its internal variable from them:

.. list-table::
   :header-rows: 1

  * - conan Variable

    - LIBRA Variable

  * - BUILD_TESTING

    - LIBRA_TESTS


The following variables are not available (these are package manager-y things
handled by conan):

- ``LIBRA_DEPS_PREFIX``


make Targets
------------

The following ``make`` targets are not available (package-y things handled by
conan):

- ``package``

- ``install``
