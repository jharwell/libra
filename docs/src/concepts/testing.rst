.. SPDX-License-Identifier: MIT

.. _concepts/testing:

=======
Testing
=======

How to work with LIBRA's test infrastructure day-to-day. For the
reference material on test discovery, naming conventions, and the test
harness, see :ref:`reference/testing`.

Why tests are not in the default build
=======================================

LIBRA does not include test targets in the default build. The reasoning
follows the natural rhythm of development:

.. list-table::
   :header-rows: 1
   :widths: 40 15 45

   * - Phase
     - Include tests?
     - Why

   * - Initial code development
     - No
     - You are trying to get something implemented. Waiting for tests
       to build when your library hasn't compiled yet yet adds friction
       without value.

   * - Writing tests to validate what you just wrote
     - Yes
     - You want one command to build and run. ``make build-and-test``
       provides this; all test targets depend on the main target.

   * - Validating in a broader context (integration, real hardware)
     - No
     - The code already passed unit and integration tests. Rebuilding
       a large test suite on every iteration is wasted time.

Use ``make all-tests`` or ``clibra test`` explicitly when you want
tests built. Use ``make build-and-test`` or ``clibra test`` when you
want them built and run.

Leveraging CTest
================

Building and running tests
--------------------------

CMake does not allow adding dependencies to the built-in ``test``
target, so ``make test`` runs already-built tests without building
them first. To build and run in one step:

.. code-block:: bash

   make build-and-test        # cmake / make
   clibra test --preset debug  # CLI

.. NOTE:: All tests have their working directory set to
          ``CMAKE_SOURCE_DIR``, which is usually the repository root.

Two CTest behaviours are set unconditionally by the ``build-and-test``
target:

- ``--output-on-failure`` — test output is shown when a test fails.
  If you run ``ctest`` directly, add this yourself or configure it in
  a test preset.
- ``--test-dir build/`` — CTest runs from the build directory, not the
  source tree. If you run ``ctest`` directly without a preset, pass
  ``--test-dir`` explicitly.

.. _usage/testing/builtin/filtering:

Filtering and running specific tests
--------------------------------------

Tests are grouped into categories by type. Run a single category:

.. code-block:: bash

   ctest -L unit
   ctest -L integration
   ctest -L regression
   ctest -L negative

Run a single test by name:

.. code-block:: bash

   ctest -R hfsm-utest

Run tests matching a pattern:

.. code-block:: bash

   ctest -R "myfeature.*"

With the CLI, use :option:`--type` and :option:`--filter`:

.. code-block:: bash

   clibra test --type unit
   clibra test --filter "myfeature.*"

.. _usage/testing/builtin/debugging:

Debugging failing tests
-----------------------

CTest suppresses output by default. To show output from failing tests:

.. code-block:: bash

   ctest --output-on-failure

Full verbose output:

.. code-block:: bash

   ctest -V    # verbose
   ctest -VV   # extra verbose (shows exact commands)

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

``verbosity`` accepts ``"default"``, ``"verbose"`` (equivalent to
``-V``), or ``"extra"`` (equivalent to ``-VV``). Leave verbosity at
``"default"`` in committed presets — it gets noisy otherwise. Use
``-V`` / ``-VV`` on the command line when actively debugging.

.. _usage/testing/builtin/blessing:

Blessing test outputs
---------------------

If your tests compare output against known-good references, pass
``BLESS=1`` on the command line to update all blessed outputs at once:

.. code-block:: bash

   BLESS=1 ctest                  # bless all tests
   BLESS=1 ctest -L regression    # bless regression tests only

LIBRA passes this environment variable through to each test process.
There is no mechanism to bless a single test's output.

Using CDash
===========

CTest can report results to a CDash server. LIBRA does not currently
configure this, but nothing prevents you from adding CDash integration
to your own ``CMakeLists.txt`` or preset files.
