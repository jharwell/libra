.. SPDX-License-Identifier: MIT

.. _cookbook/sanitizers:

==========
Sanitizers
==========

Runtime sanitizers catch memory errors, undefined behaviour, and data
races at test time. This page covers adding sanitizer presets, the
library requirements for each sanitizer, stacking rules, and how to
run them.

For the variable reference, see :cmake:variable:`LIBRA_SAN` in
:ref:`reference/variables`.

Available sanitizers
====================

.. list-table::
   :header-rows: 1
   :widths: 15 20 65

   * - Value
     - Name
     - What it detects

   * - ``ASAN``
     - AddressSanitizer
     - Heap/stack buffer overflows, use-after-free, use-after-return,
       double-free. Requires ``libasan`` (GCC) or bundled with Clang.

   * - ``UBSAN``
     - UndefinedBehaviourSanitizer
     - Signed integer overflow, null pointer dereference, misaligned
       access, invalid enum values, and more.

   * - ``TSAN``
     - ThreadSanitizer
     - Data races between threads. Requires ``libtsan`` (GCC) or
       bundled with Clang.

   * - ``MSAN``
     - MemorySanitizer
     - Reads from uninitialised memory. Clang only — GCC does not
       support MSAN.

   * - ``SSAN``
     - Stack sanitizer
     - Aggressive stack checking beyond what ASAN provides.

Stacking rules
==============

ASAN, UBSAN, and SSAN can be combined freely. TSAN and MSAN less so, depending
on compiler.

1. Add sanitizer presets
=========================

Add dedicated presets to ``CMakePresets.json`` rather than enabling
sanitizers in the ``debug`` preset. This keeps debug builds fast and
gives sanitizer runs their own build directories:

.. code-block:: json

   {
     "configurePresets": [
       {
         "name": "asan",
         "inherits": "base",
         "cacheVariables": {
           "CMAKE_BUILD_TYPE": "Debug",
           "LIBRA_TESTS": "ON",
           "LIBRA_SAN": "ASAN;UBSAN"
         }
       },
       {
         "name": "tsan",
         "inherits": "base",
         "cacheVariables": {
           "CMAKE_BUILD_TYPE": "Debug",
           "LIBRA_TESTS": "ON",
           "LIBRA_SAN": "TSAN"
         }
       },
       {
         "name": "msan",
         "inherits": "base",
         "cacheVariables": {
           "CMAKE_BUILD_TYPE": "Debug",
           "LIBRA_TESTS": "ON",
           "LIBRA_SAN": "MSAN"
         }
       }
     ],
     "buildPresets": [
       { "name": "asan", "configurePreset": "asan" },
       { "name": "tsan", "configurePreset": "tsan" },
       { "name": "msan", "configurePreset": "msan" }
     ],
     "testPresets": [
       {
         "name": "asan",
         "configurePreset": "asan",
         "output": { "outputOnFailure": true }
       },
       {
         "name": "tsan",
         "configurePreset": "tsan",
         "output": { "outputOnFailure": true }
       }
     ]
   }

2. Install runtime libraries
==============================

Some sanitizers require runtime libraries separate from the compiler.

**GCC:**

.. code-block:: bash

   # Debian/Ubuntu
   sudo apt-get install libasan8 libubsan1 libtsan2

   # Fedora/RHEL
   sudo dnf install libasan libubsan libtsan

**Clang:** ASAN, UBSAN, TSAN, and MSAN are bundled with the Clang
installation — no separate install needed.

.. note::

   The runtime library version must match the compiler version. If
   ``libasan8`` is not available for your GCC version, install the
   package that matches: ``libasan6`` for GCC 11, ``libasan8`` for
   GCC 13, etc.

3. Build and run tests
=======================

.. tab-set::

   .. tab-item:: CLI

      .. code-block:: bash

         clibra test --preset asan
         clibra test --preset tsan
         clibra test --preset msan   # Clang only

   .. tab-item:: CMake

      .. code-block:: bash

         cmake --preset asan
         cmake --build --preset asan --target all-tests
         ctest --preset asan --output-on-failure

4. Interpreting sanitizer output
=================================

Sanitizer violations are printed to stderr before or after the test
output. Each report includes a stack trace and the type of violation.

With ASAN:

.. code-block:: text

   ==12345==ERROR: AddressSanitizer: heap-buffer-overflow on address ...
       #0 0x... in my_function src/core.cpp:42
       #1 0x... in main src/main.cpp:10

With TSAN:

.. code-block:: text

   WARNING: ThreadSanitizer: data race on 0x...
     Write by thread T2:
       #0 0x... in MyClass::write() src/myclass.cpp:55
     Previous read by thread T1:
       #0 0x... in MyClass::read() src/myclass.cpp:47

Set ``ASAN_OPTIONS``, ``TSAN_OPTIONS``, or ``UBSAN_OPTIONS`` in your
test preset's ``environment`` field to control sanitizer behaviour:

.. code-block:: json

   "testPresets": [
     {
       "name": "asan",
       "configurePreset": "asan",
       "environment": {
         "ASAN_OPTIONS": "halt_on_error=1:abort_on_error=1",
         "UBSAN_OPTIONS": "halt_on_error=1:print_stacktrace=1"
       }
     }
   ]

Adding sanitizers to CI
========================

Add a sanitizer job to your pipeline after the basic test job. See
:ref:`cookbook/ci-setup` for the full pipeline context:

.. code-block:: yaml

   # GitHub Actions
   sanitizers:
     name: Sanitizers (ASAN/UBSAN)
     runs-on: ubuntu-latest
     steps:
       - uses: actions/checkout@v4
       - name: Install
         run: |
           sudo apt-get update
           sudo apt-get install -y cmake ninja-build gcc g++ libasan8 libubsan1
       - name: Test with ASAN+UBSAN
         run: |
           cmake --preset asan
           cmake --build --preset asan --target all-tests
           ctest --preset asan --output-on-failure
