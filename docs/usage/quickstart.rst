.. SPDX-License-Identifier:  MIT

.. _usage-quickstart:

==========
Quickstart
==========

To hook into LIBRA you need to:

#. Add the libra repository as a sub-module ``libra/`` in your repo.

#. Link ``libra/cmake/project.cmake`` -> ``CMakeLists.txt`` in the root of your
   repo. On linux::

     ln -s libra/cmake/project.cmake CmakeLists.txt

#. Create ``cmake/project-local.cmake`` in the root of your project repo. See
   :ref:`usage-project-local` for more details.

After you hook in, you can do::

  mkdir build && cd build
  cmake ..
  make

As you would expect.
