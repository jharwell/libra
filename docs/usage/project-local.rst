.. SPDX-License-Identifier:  MIT

.. _ln-libra-project-local:

======================
How To Hook Into LIBRA
======================

To hook into LIBRA, you define a ``cmake/project-local.cmake``. Basically, you
can put WHATEVER you want in this file--all the usual cmake stuff--drawing on
predefined things in LIBRA to make your life easier. For what things LIBRA
defines for you to use in this file, see below.

Variables
=========

Most variables of the form ``LIBRA_XX`` detailed in :ref:`ln-libra-capabilities`
can be permanently set in your ``project-local.cmake``, but not all. Exceptions
are:

- ``LIBRA_DEPS_PREFIX``

LIBRA also provides the following additional variables which can be used:

  - ``${PROJECT_NAME}_CHECK_LANGUAGE`` - Defines the language that the different
    static analysis checkers will use for checking the project. This should be
    specified BEFORE any subdirectories, external projects, etc. are
    specified. Only used if ``LIBRA_ANALYSIS`` is enabled. If used, value must
    be one of:

    - C
    - CXX
    - CUDA

  - ``${PROJECT_NAME}_C_SRC`` - Glob containing all C source files.

  - ``${PROJECT_NAME}_CXX_SRC`` - Glob containing all C++ source files.

  - ``${PROJECT_NAME}_CUDA_SRC`` - Glob containing all CUDA source files.

  - ``${PROJECT_NAME}_C_HEADERS`` - Glob containing all C header files.

  - ``${PROJECT_NAME}_CXX_HEADERS`` - Glob containing all C++ header files.

Diagnostics
===========

LIBRA provides a number of functions/macros to simplify the complexity of
cmake. Some useful functions available in ``project-local.cmake`` are:

- ``libra_config_summary()`` - Will print a nice summary of its variables to the
  terminal. Helps debug the inevitable "Did I actually set the variable I
  thought I did?". Using this, you can see EXACTLY what variable values will be
  when you invoke your chosen build engine. You can put it at the end of
  ``project-local.cmake`` if you want; otherwise LIBRA will run it at the end of
  the configure step.

Installation
============

TODO!
