..
   Copyright 2026 John Harwell, All rights reserved.

   SPDX-License-Identifier:  MIT

.. code-block:: cmake

   # Register the main executable. CXX_SOURCES is auto-populated
   # from src/ at configure time.
   libra_add_executable(${${PROJECT_NAME}_CXX_SOURCES})

   # For a library instead (C_SOURCES auto-populated):
   # libra_add_library(${${PROJECT_NAME}_C_SOURCES})

   # Optional: enable project-wide quality gates
   # set(LIBRA_ANALYSIS ON)
   # set(LIBRA_FORTIFY ALL)
