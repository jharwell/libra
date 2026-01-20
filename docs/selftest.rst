..
   Copyright 2026 John Harwell, All rights reserved.

   SPDX-License-Identifier:  MIT

.. _selftest:

LIBRA Self-Test Suite
=====================

.. _selftest/package:

LIBRA Package Functions
=======================

Complete test suite for all functions in ``libra/package/`` using real CMake
projects with actual C++ code. Each test performs:

- Existence checks: files and targets were created
- Content checks: files contain expected text
- Type checks: variables have correct types
- Syntax checks: generated CMake is valid
- Completeness checks: all required elements are present

To run::

    cd tests/package
    mkdir build && cd build
    cmake ..
    ctest --output-on-failure

.. list-table::
   :header-rows: 1
   :widths: 10 40 50

   * - Test
     - Function
     - What It Verifies
   * - 1
     - ``libra_configure_exports``
     - Creates valid package config with all required sections
   * - 2
     - ``libra_register_target_for_install``
     - Registers correct target type with install commands
   * - 3
     - ``libra_register_headers_for_install``
     - Validates headers and registers install rules
   * - 4
     - ``libra_register_copyright_for_install``
     - Validates LICENSE content and install rules
   * - 5
     - ``libra_register_extra_configs_for_install``
     - Validates config content and syntax
   * - 6
     - ``libra_requested_components_check``
     - Validates component handling with multiple scenarios

Test Structure
--------------

.. code-block:: text

    package/
    ├── CMakeLists.txt                    # Main test suite
    ├── test1_configure_exports/
    │   ├── CMakeLists.txt                # Tests libra_configure_exports
    │   ├── src/mylib.cpp                 # Real C++ source
    │   ├── include/mylib.hpp             # Real C++ header
    │   └── cmake/config.cmake.in         # Package config template
    ├── test2_register_target/
    │   ├── CMakeLists.txt                # Tests libra_register_target_for_install
    │   ├── src/testlib.cpp               # Real C++ source
    │   └── include/testlib.hpp           # Real C++ header
    ├── test3_register_headers/
    │   ├── CMakeLists.txt                # Tests libra_register_headers_for_install
    │   └── include/headerlib.hpp         # Real C++ header
    ├── test4_register_copyright/
    │   ├── CMakeLists.txt                # Tests libra_register_copyright_for_install
    │   ├── src/copyrightlib.cpp          # Real C++ source
    │   └── LICENSE                       # Real license file
    ├── test5_register_extra_configs/
    │   ├── CMakeLists.txt                # Tests libra_register_extra_configs_for_install
    │   ├── src/configlib.cpp             # Real C++ source
    │   └── cmake/
    │       ├── extra-config1.cmake       # Real extra config
    │       └── extra-config2.cmake       # Real extra config
    └── test6_requested_components/
        ├── CMakeLists.txt                # Tests libra_requested_components_check
        └── src/componentlib.cpp          # Real C++ source
