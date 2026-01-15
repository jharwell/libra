.. SPDX-License-Identifier:  MIT

.. _startup/quickstart:

==========
Quickstart
==========

After picking your LIBRA flavor as described :ref:`here <main/flavors>`, proceed
onward to the appropriate section below. Make sure you've checked the
:ref:`environment setup and requirements <startup/config>` first!

#. Setup your repo:

   .. tabs::

      .. group-tab:: Conan package

          Create ``CMakeLists.txt`` in the root of your repo. Within that
          file, create something like this::

            cmake_minimum_required(VERSION 3.31 FATAL_ERROR) # whatever version you like
            include(libra/project)
            project(my_project CXX) # languages can be anything cmake supports

            # Whatever other cmake config you like starts here


      .. group-tab:: CMake package

          Create ``CMakeLists.txt`` in the root of your repo. Within that
          file, create something like this::

            cmake_minimum_required(VERSION 3.31 FATAL_ERROR) # whatever version you like
            find_package(libra REQUIRED)
            include(libra/project)

            project(my_project CXX) # languages can be anything cmake supports
            # Whatever other cmake config you like starts here

      .. group-tab:: In situ

         Add the libra repository as a sub-module ``libra/`` in your repo OR
         direct your meta-level build system to cloned LIBRA into ``libra/`` in
         your repo.

#. Create ``cmake/project-local.cmake`` in the root of your project repo. This
   is where you define what targets you want to build, how to build them,
   etc. See :ref:`usage/project-local` for more details.

#. Make LIBRA accessible to CMake:

   .. tabs::

      .. group-tab:: Conan package

         In ``conanfile.py`` put the following::

           def build_requirements(self):
               self.tool_requires("cmake/3.30")
               self.tool_requires("libra/0.8.0") # arbitrary LIBRA version

      .. group-tab:: CMake package

         ::

             git clone https://github.com/jharwell/libra.git /path/to/libra
             cd /path/to/libra
             cmake -DCMAKE_INSTALL_PREFIX=/path/to/prefix .
             make install


      .. group-tab:: In situ


         Link ``libra/cmake/project.cmake`` -> ``CMakeLists.txt`` in the root
         of your repo. On linux::

              ln -s libra/cmake/project.cmake CMakeLists.txt

#. Build your project:


   .. tabs::

      .. group-tab:: Conan package

         Via conan::

           conan build .

         from the root of the repo. Or::

           cmake --build . -t <target> --preset conan-{debug,release}

         from the root of the repo. Or::

           make <target>

         from the ``build/{Debug,Release,...}`` directory.


      .. group-tab:: CMake package

         ::

            mkdir build && cd build
            cmake -DCMAKE_INSTALL_PREFIX=/path/to/prefix ..
            make

         The prefix *must* be the same as where LIBRA was installed to, or
         ``find_package()`` won't work out-of-the-box. If you need a different
         install prefix at this stage, you can do::

           cmake -DCMAKE_PREFIX_PATH=/path/to/prefix -DCMAKE_INSTALL_PREFIX=/path/to/wherever ..

         ``CMAKE_PREFIX_PATH`` is a list of dirs telling CMake where to look for
         packages.

      .. group-tab:: In situ

         ::

            mkdir build && cd build
            cmake ..
            make
