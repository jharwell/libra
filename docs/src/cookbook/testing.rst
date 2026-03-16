.. SPDX-License-Identifier: MIT

.. _cookbook/testing:

=======
Testing
=======

How to build, run, filter, and debug tests day-to-day. For test
discovery configuration (naming matchers, negative tests, the test
harness), see :ref:`reference/testing`.

Building and running tests
==========================

CMake does not allow adding dependencies to the built-in ``test``
target, so ``make test`` runs already-built tests without building
them first. To build and run in one step:

.. tab-set::

   .. tab-item:: CLI

      .. code-block:: bash

         clibra test --preset debug

   .. tab-item:: CMake

      .. code-block:: bash

         cmake --build --preset debug --target all-tests
         ctest --preset debug --output-on-failure

.. NOTE:: All tests have their working directory set to
          ``CMAKE_SOURCE_DIR``, which is usually the repository root.

Two CTest behaviours are set unconditionally by the ``build-and-test``
target:

- ``--output-on-failure`` — shown when a test fails. If you run
  ``ctest`` directly, add this yourself or configure it in a test preset.
- ``--test-dir build/`` — CTest runs from the build directory. If you
  invoke ``ctest`` directly without a preset, pass ``--test-dir``
  explicitly.

Filtering and running specific tests
======================================

Tests are grouped into categories by type:

.. tab-set::

   .. tab-item:: CLI

      .. code-block:: bash

         clibra test --type unit
         clibra test --type integration
         clibra test --type regression
         clibra test --filter "myfeature.*"

   .. tab-item:: CMake

      .. code-block:: bash

         ctest -L unit
         ctest -L integration
         ctest -L regression
         ctest -R hfsm-utest          # single test by name
         ctest -R "myfeature.*"       # pattern match

Debugging failing tests
=======================

.. tab-set::

   .. tab-item:: CLI

      .. code-block:: bash

         clibra test --stop-on-failure
         clibra test --rerun-failed

   .. tab-item:: CMake

      CTest suppresses output by default:

      .. code-block:: bash

         ctest --output-on-failure
         ctest -V     # verbose
         ctest -VV    # extra verbose (shows exact commands)

      Via a test preset in ``CMakeUserPresets.json``:

      .. code-block:: json

         "testPresets": [
           {
             "name": "debug",
             "configurePreset": "debug",
             "output": {
               "outputOnFailure": true,
               "verbosity": "verbose"
             }
           }
         ]

      ``verbosity`` accepts ``"default"``, ``"verbose"`` (``-V``), or
      ``"extra"`` (``-VV``). Keep verbosity at ``"default"`` in
      committed presets.

Blessing test outputs
=====================

If your tests compare output against known-good references, pass
``BLESS=1`` to update all blessed outputs at once:

.. code-block:: bash

   BLESS=1 ctest                  # bless all tests
   BLESS=1 ctest -L regression    # bless regression tests only

LIBRA passes this environment variable through to each test process.
There is no mechanism to bless a single test's output.
