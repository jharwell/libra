.. _bazel/debugging:

===================================
Debugging Programs Built With Bazel
===================================


Working With GDB
================

.. list-table::
   :header-rows: 1
   :widths: 20 80

   * - Problem

     - Solution

   * - "No symbol table is loaded"

     - Change the build mode you use to build the project to one which includes
       ``-g`` and tell Bazel *never* to strip debugging info::

         --compilation-mode=dbg --strip=never

       or::

         -c dbg --strip=never

       Bazel's default mode is ``fastbuild``, which will strip debug info unless
       you tell it otherwise.

   * - GDB can't find source files

     - Options:

       - Launch GDB from the RHSF repo, where a ``.gdbinit`` file takes care of
         mapping where source files actually live to where Bazel built them. If
         you're already doing that the ``.gdbinit`` is probably out of
         date--read on below and update it.

       - Run ``substitute-path <baked path> <source path>`` in GDB. For example,
         if GDB says::

           external/geomeas/src/stl2datainterp.cpp: No such file or directory.

         when you hit a breakpoint in that file, run::

           set substitute-path external/geomeas dependencies/xGPSnonItar/sw/geomeas

         Then ``list`` and other such commands will work as expected. To see all
         the currently loaded ``substitute-path`` expressions, do ``show
         substitute-path``.
