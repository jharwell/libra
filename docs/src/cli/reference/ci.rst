.. SPDX-License-Identifier: MIT

.. _cli/reference/ci:

ci
==

Run the full CI pipeline: build with coverage, run tests, and check
coverage thresholds.

.. code-block:: bash

   clibra ci --preset ci

Requires :cmake:variable:`LIBRA_TESTS` and :cmake:variable:`LIBRA_COVERAGE`
to be ``ON`` in the preset's CMake cache.

CMake equivalent
----------------

**Preferred** — when a workflow preset named ``<n>`` exists in either
``CMakePresets.json`` or ``CMakeUserPresets.json``:

.. code-block:: bash

   cmake --workflow --preset <n>

**Fallback** — when no workflow preset exists (emits a warning):

.. code-block:: bash

   cmake --preset <n>                              # if reconfigure needed
   cmake --build --preset <n> --target all-tests
   ctest --preset <n>
   cmake --build --preset <n> --target gcovr-check

.. note::

   Adding a workflow preset to ``CMakePresets.json`` is recommended. It
   makes the CI sequence explicit, reproducible, and usable directly with
   ``cmake --workflow`` without the CLI:

   .. code-block:: json

      {
        "workflowPresets": [
          {
            "name": "ci",
            "steps": [
              { "type": "configure", "name": "ci" },
              { "type": "build",     "name": "ci" },
              { "type": "test",      "name": "ci" },
              { "type": "build",     "name": "ci",
                "targets": ["gcovr-check"] }
            ]
          }
        ]
      }

Flag reference
--------------

.. include:: ../../../_generated/ci.md
   :parser: myst_parser.sphinx_
