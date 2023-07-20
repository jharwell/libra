.. SPDX-License-Identifier:  MIT

.. _usage-req:

=========================
Requirements to use LIBRA
=========================

Platform Requirements
=====================

- A recent version of Linux.

- cmake >= 3.21 (``cmake`` on ubuntu)

- make >= 3.2 (``make`` on ubuntu)

- cppcheck >= 1.72. (``cppcheck`` on ubuntu)

- graphviz (``graphviz`` on ubuntu)

- doxygen (``doxygen`` on ubuntu)

- gcc/g++ >= 9.0 (``gcc-9`` on ubuntu). Only required if you want to use the GNU
  compilers. If you want to use another compiler, this is not required. gcc-9
  rather than gcc-8 is required for C++17 because of std::filesystem usage,
  which does not work well with gcc-8 on ubuntu.

- icpc/icc >= 18.0. Only required if you want to use the Intel
  compilers. If you want to use another compiler, this is not required.

- clang/clang++ >= 10.0. Only required if you want to use the LLVM compilers or
  any of the static checkers. If you want to use another compiler, this is not
  required.

- nvcc >= 11.5. Only required if you want to use the NVIDIA CUDA compilers. If
  you want to use another compiler, this is not required.

- lcov if you want to do code coverage.

Compiler Support
================

- ``g++/gcc``
- ``clang++/clang``
- ``icpc/icc``
- ``nvcc``

A recent version of any supported compiler can be selected as the
``CMAKE_<LANG>_COMPILER`` via command line. The correct compile options will be
populated (as in the ones defined in the corresponding .cmake files in this
repository). Note that the C and CXX compiler vendors should always match, in
order to avoid strange build issues.

.. IMPORTANT:: If you are want to use the Intel compiler suite, you will have to
               download and install it from Intel's website. It installs to a
               non-standard location, so prior to being able to use it in the
               terminal like clang or gcc, you will need to source the compiler
               definitions (actual command varies by version).


Clang Tooling
=============

All tools must have  <= version <= 14.0.

- Base tooling and clang-check (``libclang-14-dev`` and ``clang-tools-14``).

- clang-format (``clang-format-14``).

- clang-tidy (``clang-tidy-14``).


.. _req-assumptions:

Repository/Code Structure
=========================

Requirements
------------

- All C++ source files end in ``.cpp``, and all C++ header files end in ``.hpp``
  (which they should if you are following the :ref:`cxx-dev-guide`).

- All C source files end in ``.c`` and all C header files end in ``.h`` (which
  they should if you are following the :ref:`c-dev-guide`).

- All CUDA source files end in ``.cu`` and all CUDA header files end in
  ``.cuh`` (which they should if you are following the
  :ref:`cuda-dev-guide`).

- All source files for a repository must live under ``src/`` in the root.

- All tests (either C or C++) for a project/submodule must live under the
  ``tests/`` directory in the root of the project, and should end in
  ``-test.cpp`` or ``-test.c`` so it is clear they are not source files.

- All projects must include THIS repository as a submodule under ``libra/`` in
  the project root, and link a ``CmakeLists.txt`` in the root of the repository
  to the ``libra/cmake/project.cmake`` file in this repository.

- If ``LIBRA_DOCS=ON``, project documentation lives under ``<repo_name>/docs``,
  with a ``docs/Doxyfile.in`` defined to generate doxygen documentation.

- All projects must include a ``cmake/project-local.cmake`` in the root of the
  repository containing any project specific bits (i.e. adding subdirectories,
  what libraries to create, etc.). See :ref:`project-local` for how to
  structure this file.

- ``LIBRA_DOCS`` - Override the default value of ``YES`` if your project does
  not have docs.
