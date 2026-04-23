..
   Copyright 2026 John Harwell, All rights reserved.

   SPDX-License-Identifier:  MIT

.. code-block:: cmake

   # Register the main executable. CXX_SRC is auto-populated
   # from src/ at configure time.
   libra_add_executable(${${PROJECT_NAME}_CXX_SRC})

   # For a library instead (C_SRC auto-populated):
   # libra_add_library(${${PROJECT_NAME}_C_SRC})

   # Optional: enable project-wide quality gates
   # set(LIBRA_ANALYSIS ON)
   # set(LIBRA_FORTIFY ALL)
