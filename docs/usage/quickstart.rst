.. SPDX-License-Identifier:  MIT

.. _usage/quickstart:

==========
Quickstart
==========

After picking your LIBRA flavor as described :ref:`<main/flavors> here`,
proceed onward to the appropriate section below.

Build System Middleware
=======================

In this flavor, LIBRA is a "backend" for a supported build system/package
manager. Supported drivers currently are:

- conan - :ref:`usage/conan/setup`


Stand-Alone Framework
=====================

#. Add the libra repository as a sub-module ``libra/`` in your repo.

#. Link ``libra/cmake/project.cmake`` -> ``CMakeLists.txt`` in the root of your
   repo. On linux::

     ln -s libra/cmake/project.cmake CmakeLists.txt

#. Create ``cmake/project-local.cmake`` in the root of your project repo. See
   :ref:`usage/project-local` for more details.

After you hook in, you can do::

  mkdir build && cd build
  cmake ..
  make

as you would expect.
