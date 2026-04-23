.. SPDX-License-Identifier: MIT

.. _cookbook/pgo:

===========================
Profile-Guided Optimisation
===========================

Profile-Guided Optimisation (PGO) is a two-phase process: first build
an instrumented binary, run it with a representative workload to collect
profile data, then rebuild with the profile data to produce an optimised
binary. LIBRA automates the compiler flags for both phases.

For the variable reference, see :cmake:variable:`LIBRA_PGO` in
:ref:`reference/variables`.

1. Add PGO presets
===================

.. code-block:: json

   {
     "configurePresets": [
       {
         "name": "pgo-gen",
         "inherits": "base",
         "cacheVariables": {
           "CMAKE_BUILD_TYPE": "Release",
           "LIBRA_PGO": "GEN"
         }
       },
       {
         "name": "pgo-use",
         "inherits": "base",
         "cacheVariables": {
           "CMAKE_BUILD_TYPE": "Release",
           "LIBRA_PGO": "USE"
         }
       }
     ],
     "buildPresets": [
       { "name": "pgo-gen", "configurePreset": "pgo-gen" },
       { "name": "pgo-use", "configurePreset": "pgo-use" }
     ]
   }

2. GEN phase — build and profile
==================================

Build the instrumented binary and run it with a representative
workload. The workload should cover the hot paths you want the
compiler to optimise — typically your benchmarks or a realistic
subset of your test suite.

.. tab-set::

   .. tab-item:: CLI

      .. code-block:: bash

         clibra build --preset pgo-gen
         ./build/pgo-gen/my_application --representative-workload

   .. tab-item:: CMake

      .. code-block:: bash

         cmake --preset pgo-gen
         cmake --build --preset pgo-gen
         ./build/pgo-gen/my_application --representative-workload

3. Merge profile data (Clang only)
====================================

GCC writes ``.gcda`` files directly in a form the USE phase can read.
Clang writes ``.profraw`` files that must be merged first:

.. code-block:: bash

   # Clang / Intel LLVM only
   llvm-profdata merge \
     -output=build/pgo-gen/default.profdata \
     build/pgo-gen/default*.profraw

If you have multiple ``.profraw`` files from different runs, merge
them all to produce a single ``.profdata``:

.. code-block:: bash

   llvm-profdata merge \
     -output=build/pgo-gen/merged.profdata \
     build/pgo-gen/*.profraw

4. USE phase — build the optimised binary
==========================================

.. tab-set::

   .. tab-item:: CLI

      .. code-block:: bash

         clibra build --preset pgo-use

   .. tab-item:: CMake

      .. code-block:: bash

         cmake --preset pgo-use
         cmake --build --preset pgo-use

The compiler reads the profile data from the GEN build directory
automatically (LIBRA passes the correct ``-fprofile-use=`` path). The
resulting binary in ``build/pgo-use/`` is tuned to the workload you
ran in the GEN phase.

.. note::

   For Clang, LIBRA passes ``-fprofile-use=build/pgo-gen/default.profdata``
   by default. If you merged to a different path, set
   :cmake:variable:`LIBRA_PGO_PROFILE_PATH` in your ``pgo-use`` preset's
   ``cacheVariables``.

5. Verify the improvement
==========================

Compare the instrumented and optimised binaries with your benchmark:

.. code-block:: bash

   # Instrumented binary (GEN phase — slower due to instrumentation)
   time ./build/pgo-gen/my_application --benchmark

   # Optimised binary (USE phase)
   time ./build/pgo-use/my_application --benchmark

Typical improvements are 5–20% for CPU-bound workloads. Memory-bound
workloads see smaller gains.

Common issues
=============

**"Profile data not found" during USE phase**
   The compiler looks for profile data relative to the build directory.
   Make sure the GEN binary was run from or wrote data to the expected
   location. For Clang, verify the ``.profdata`` file exists at
   ``build/pgo-gen/default.profdata``.

**"Profile data out of date" warnings**
   The source changed between the GEN and USE builds. The compiler
   falls back to non-PGO optimisation for affected functions. Re-run
   the GEN phase with the current source before rebuilding with USE.

**Low workload coverage**
   If the workload only exercises 20% of the code, PGO only helps that
   20%. Profile data from test suites tends to cover more code paths
   than a single benchmark run — consider running the full test suite
   as the GEN workload if individual benchmarks are insufficient.
