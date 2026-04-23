..
   Copyright 2026 John Harwell, All rights reserved.

   SPDX-License-Identifier:  MIT

.. code-block:: cmake

   cmake_minimum_required(VERSION 3.31)

   file(DOWNLOAD
        https://github.com/cpm-cmake/CPM.cmake/releases/download/v0.40.2/CPM.cmake
        ${CMAKE_CURRENT_BINARY_DIR}/cmake/CPM.cmake)

   set(CPM_SOURCE_CACHE
       $ENV{HOME}/.cache/CPM
       CACHE PATH "CPM source cache")

   # Prefer local packages when present — useful for simultaneous
   # local development of multiple LIBRA-enabled projects.
   set(CPM_USE_LOCAL_PACKAGES ON)
   include(${CMAKE_CURRENT_BINARY_DIR}/cmake/CPM.cmake)

   CPMAddPackage(
     NAME libra
     GIT_REPOSITORY https://github.com/jharwell/libra.git
     GIT_TAG master)

   list(APPEND CMAKE_MODULE_PATH ${libra_SOURCE_DIR}/cmake)
   project(my_project C CXX)
   include(libra/project)
