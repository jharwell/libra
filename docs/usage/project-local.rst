.. SPDX-License-Identifier:  MIT

.. _ln-libra-project-local:

======================
How To Hook Into LIBRA
======================

To hook into LIBRA, you define a ``cmake/project-local.cmake``. Basically, you
can put WHATEVER you want in this file--all the usual cmake stuff--drawing on
predefined things in LIBRA to make your life easier. For what things LIBRA
defines for you to use in this file, see below.

.. NOTE:: All cmake functions which LIBRA exposes are prefixed with ``libra_``;
          all other functions should be considered not part of the API can can
          change at any time.

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

- ``libra_configure_exports_as(TARGET PREFIX)`` - Configure the exports for a
  ``TARGET`` to be installed at ``PREFIX`` such that it can be used by *other*
  projects via ``find_package()``.

- ``libra_register_extra_configs_for_install(TARGET FILE PREFIX)`` - Configure
  additional ``.cmake`` files for export. Useful if your project provides some
  reusable cmake functionality that you want child projects to also be able to
  access.

- ``libra_register_headers_for_install(DIRECTORY PREFIX)`` - Register all
  headers (``.h`` or ``.hpp``) under ``DIRECTORY`` to be installed at ``PREFIX``
  and associated with the necessary exports file so child projects can find it.

- ``libra_register_target_for_install(TARGET PREFIX)`` - Register ``TARGET`` to
  be installed at ``PREFIX``, and associated with the necessary exports file so
  child projects can find it.

Deployment
==========

- ``libra_configure_cpack(GENERATORS DESCRIPTION VENDOR HOMEPAGE CONTACT)`` -
  Configure CPack to run the list of ``GENERATORS`` (if more than 1, must be
  separated by ``;``) via ``make package``. Can be:

  - ``TGZ`` - A tarball.

  - ``DEB`` - A Debian archive.


  If ``DEB`` is in the list of generators, then ``DESCRIPTION, VENDOR, HOMEPAGE,
  CONTACT`` fields are required. Otherwise, they are ignored.
