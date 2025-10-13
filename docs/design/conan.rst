.. _design/conan:

=========================
Conan Integration Details
=========================

This pages provides details on how LIBRA integrates with conan.


Build Types
===========

LIBRA only current supports compiler-based features (e.g., ``LIBRA_LTO``) for
the following cmake build types:

- Debug

- Release

Not because it *can't* support other build types, but because the ones above are
the most common. It is very straightforward to add other build types if needed.

Variables
=========

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
============

The following ``make`` targets are not available (package-y things handled by
conan):

- ``package``

- ``install``
