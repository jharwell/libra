.. SPDX-License-Identifier: MIT

.. _cli/reference/test:

test
====

Build (if needed) and run tests via ``ctest``.

.. code-block:: bash

   clibra test --preset debug

Requires :cmake:variable:`LIBRA_TESTS` to be ``ON`` in the preset's CMake
cache. ``clibra test`` first builds the ``all-tests`` target, then runs
``ctest``. Use :option:`--no-build` to skip the build step and run
``ctest`` directly against already-built test binaries.

CMake equivalent
----------------

.. code-block:: bash

   cmake --build --preset <n> --target all-tests
   ctest --preset <n>


Flag reference
--------------

.. include:: ../../../_generated/test.md
   :parser: myst_parser.sphinx_
