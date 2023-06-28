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

Build and Run-time Diagnostics
==============================

LIBRA provides a number of functions/macros to simplify the complexity of cmake,
and answer questions such as "am I really building/running what I think I
am?". Some useful functions available in ``project-local.cmake`` are:

- ``libra_config_summary()`` - Will print a nice summary of its variables to the
  terminal. Helps debug the inevitable "Did I actually set the variable I
  thought I did?". Using this, you can see EXACTLY what variable values will be
  when you invoke your chosen build engine. You can put it at the end of
  ``project-local.cmake`` if you want; otherwise LIBRA will run it at the end of
  the configure step.

- ``libra_config_summary_prepare_fields()`` - Given a list of the configurable
  fields in a project as strings, define a set of new variables, one per field,
  with the prefix ``EMIT_``. The value of each new variable will be right padded
  with spaces so that any extra stuff on each line when the variables are shown
  to the user is aligned. See ``libra_config_summary()`` for an example of what
  this looks like.

- ``libra_configure_version(INFILE OUTFILE SRC)`` - Use build information from
  LIBRA to populate a source file of your choosing which you can then print out
  when your library loads/application starts as a sanity check during debugging
  that you are running what you think you are. LIBRA automatically adds this
  file to the provided list of files (``SRC``) which will ultimately be compiled
  for the project.

  Available LIBRA Cmake variables for population by cmake in your source file
  are:

  - ``LIBRA_GIT_REV`` - git SHA of the current tip; result of ``git log
    --pretty-format:%H -n 1``.

  - ``LIBRA_GIT_DIFF`` - Indicate if the build is "dirty"; i.e., if it contains
    local changes not in git. Result of ``git diff --quiet --exit-code || echo
    +``.

  - ``LIBRA_GIT_TAG`` - The current git tag for the git rev, if any; result of
    ``git describe --exact-match --tags``.

  - ``LIBRA_GIT_BRANCH`` - The current git branch, if any; result of ``git
    rev-parse --abbrev-ref HEAD``.

  - ``LIBRA_C_FLAGS_BUILD`` - The configured C compiler flags relevant for
    building (e.g., no ``-W`` flags) .

  - ``LIBRA_CXX_FLAGS_BUILD`` - The configured C compiler flags relevant for
    building (e.g., no ``-W`` flags) .

.. NOTE:: If your code is not in a git repository, then all of the above fields
          will be stubbed out and not very useful.

You can also put whatever cmake variables you want to in there as well (e.g.,
``CMAKE_C_FLAGS_RELEASE``).

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


  This function respects ``CPACK_PACKAGE_FILE_NAME`` if it is set prior to
  calling. Otherwise ``CPACK_PACKAGE_FILE_NAME`` is set to
  ``${PROJECT_NAME}-${CPACK_PACKAGE_VERSION}-${CMAKE_SYSTEM_PROCESSOR}``.

``TGZ`` Generator Notes
-----------------------

- The ``DESCRIPTION, VENDOR, HOMEPAGE, CONTACT`` fields are ignored.

``DEB`` Generator Notes
-----------------------

- .deb packages are set to always install into ``/usr``, unless
  ``CPACK_PACKAGE_INSTALL_DIRECTORY`` is set prior to calling
  ``libra_configure_cpack()``.
