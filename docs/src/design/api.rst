.. _design/api:

===
API
===


LIBRA API Conventions
=====================

- All public API functions/macros start with ``libra_``; anything else is
  non-API and can change at any time.

- All public API variables start with ``LIBRA_``; anything else is non-API and
  can change at any time.

- All private API functions/macros start with ``_libra_``. They should never be
  used outside of LIBRA itself.

- All private API variables start with ``_LIBRA_``. They should never be used
  outside of LIBRA itself. Private API variables are ones which have some
  semantic significance beyond just a temp variable for calculations.

LIBRA Private API
=================

Analysis
--------

.. cmake-module:: ../../../cmake/libra/analyze/analyze.cmake
.. cmake-module:: ../../../cmake/libra/analyze/clang_check.cmake
.. cmake-module:: ../../../cmake/libra/analyze/clang_tidy.cmake
.. cmake-module:: ../../../cmake/libra/analyze/cppcheck.cmake

Formatting
----------

.. cmake-module:: ../../../cmake/libra/format/cmake_format.cmake
.. cmake-module:: ../../../cmake/libra/format/clang_format.cmake
.. cmake-module:: ../../../cmake/libra/format/format.cmake

Documentation
-------------

.. cmake-module:: ../../../cmake/libra/docs/doxygen.cmake
.. cmake-module:: ../../../cmake/libra/docs/sphinx.cmake
