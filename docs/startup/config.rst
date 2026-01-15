.. SPDX-License-Identifier:  MIT

.. _startup/config:

=========================
Environment Configuration
=========================

Platform Requirements
=====================

- A recent version of Linux.

- cmake >= 3.31

- graphviz if you want to generate API documentation.

- doxygen if you want to generate API documentation.

- lcov if you want to do code coverage.

Compiler Support
================

- ``g++/gcc``
- ``clang++/clang``
- ``icpc/icc``

A recent version of any supported compiler can be selected as the
``CMAKE_<LANG>_COMPILER`` via command line. The correct compile options will be
populated. Note that the C and CXX compiler vendors should always match, in
order to avoid strange build issues (LIBRA warns if they don't).

The exact version of the compiler you use doesn't really matter from LIBRA's
perspective, because it allows you to specify the exact set of diagnostics to
supply to the compiler (see :ref:`usage/project-local`). Non-diagnostic flags
passed to the compiler are common to all recent versions; additional
configurability may be added in the future.

LIBRA comes with an internal set of diagnostics targeted at GCC 12, icc 18,
and clang-16.

.. IMPORTANT:: If you are want to use the Intel compiler suite, you will have to
               download and install it from Intel's website. It installs to a
               non-standard location, so prior to being able to use it in the
               terminal like clang or gcc, you will need to source the compiler
               definitions (actual command varies by version).


Supported Analysis Tooling
==========================

- cppcheck - Tested with >= 1.72.

- clang-check - Tested with >= 10.0.

- clang-format - Tested with >= 10.0.

- clang-tidy - Tested with >= 10.0.


.. _startup/config/structure:

Repository/Code Structure
=========================

Requirements
------------

- All C++ source files end in ``.cpp``, and all C++ header files end in
  ``.hpp``.

- All C source files end in ``.c`` and all C header files end in ``.h``.

- All projects must include a ``cmake/project-local.cmake`` containing any
  project specific bits (i.e. adding subdirectories, what libraries to create,
  etc.). See :ref:`usage/project-local` for how to structure this file.

Recommendations
---------------

These are *recommended* elements of repository/code structure, which can safely
be ignored if you don't want to use them.

- All source files for a repository should live under ``src/`` in the root. This
  is only required if you want to take advantage of automated source file
  globbing (which you should).

  See also :ref:`philosophy/globbing`.

- All tests for a project should live under the ``tests/`` directory in the root
  of the project and must end in a configured prefix (see
  :ref:`usage/build-time`) for details. Out of the box, unit tests are expected
  to end in ``-utest.{cpp, c}``, integration tests are expected to end in
  ``-itest.{cpp, c}``, and test harness files are expected to end in ``_test.{c,
  cpp, h, hpp}``. This is only required if you want to take advantage of
  automated test globbing.

  See also :ref:`philosophy/globbing`, :cmake:variable:`LIBRA_TESTS`.

- All test harness files for a project should live under the ``tests/``
  directory in the root of the project and must end in a configured prefix (see
  :ref:`usage/build-time`) for details. Out of the box, unit they are expected
  to end in ``_test.{c, cpp, h, hpp}``. This is only required if you want to
  take advantage of automated test globbing.

  See also :ref:`philosophy/globbing`, :cmake:variable:`LIBRA_TESTS`.

- If :cmake:variable:`LIBRA_DOCS` is enabled, project documentation lives under
  ``<repo_name>/docs``, with a ``docs/Doxyfile.in`` defined to generate doxygen
  documentation.

- Use :cmake:command:`libra_add_library()` to add libraries, and
  :cmake:command:`libra_add_executable()` to add executables, so that all the
  LIBRA compiler/compilation magic can be applied to multiple targets, rather
  than only the :cmake:variable:`PROJECT_NAME` target.
