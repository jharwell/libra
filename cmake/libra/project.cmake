# ##############################################################################
# CMake Configuration
# ##############################################################################

# CMake version
cmake_minimum_required(VERSION 3.21 FATAL_ERROR)

# This will be set when LIBRA is used as a conan backend (we can't test directly
# for that at this point in the file, because that option isn't defined yet).
if(NOT PROJECT_NAME)
  # I define the current target as the same as the directory that the
  # CMakeLists.txt resides in--simpler that way.
  get_filename_component(LIBRA_TARGET ${CMAKE_CURRENT_LIST_DIR} NAME)

  project(${LIBRA_TARGET} C CXX)
endif()

# The current version of LIBRA, to make debugging strange build problems easier
set(LIBRA_VERSION 0.8.5)

# ##############################################################################
# Cmake Environment
# ##############################################################################
include(${CMAKE_ROOT}/Modules/ExternalProject.cmake)
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/libra/cmake")
include(libra/messaging)
include(libra/colorize)
include(libra/custom-cmds)

# Set policies
cmake_policy(SET CMP0028 NEW) # ENABLE CMP0028: Double colon in target name
                              # means ALIAS or IMPORTED target.
cmake_policy(SET CMP0054 NEW) # ENABLE CMP0054: Only interpret if() arguments as
                              # variables or keywords when unquoted.
cmake_policy(SET CMP0063 NEW) # ENABLE CMP0063: Honor visibility properties for
                              # all target types.
cmake_policy(SET CMP0074 NEW) # ENABLE CMP0074: find_package uses
                              # <PackageName>_ROOT variables.
cmake_policy(SET CMP0072 NEW) # Prefer modern OpenGL

# ##############################################################################
# Project Cmdline Configuration
# ##############################################################################
option(LIBRA_TESTS "Build tests." OFF)
option(LIBRA_MT "Enable multithreaded+openmp code." OFF)
option(LIBRA_MP "Enable multiprocess+MPI code." OFF)
option(LIBRA_CODE_COV "Compile with code coverage instrumentation" OFF)
option(LIBRA_DOCS "Enable documentation build" OFF)
option(
  LIBRA_VALGRIND_COMPAT
  "Disable some compiler instructions so 64-bit code can robustly be run under valgrind"
  OFF)
option(LIBRA_ANALYSIS "Enable static analysis checkers" OFF)
option(LIBRA_SUMMARY "Show a configuration summary" ON)
option(LIBRA_LTO "Enable Link-Time Optimization" OFF)
option(LIBRA_OPT_REPORT "Emit-generated reports related to optimizations" OFF)
option(LIBRA_STDLIB "Enable usage of the standard library" ON)
option(LIBRA_NO_DEBUG_INFO
       "Disable inclusion of debug info, independent of build type" OFF)
set(LIBRA_DRIVER
    "SELF"
    CACHE STRING "{SELF,CONAN} Set the user front end for the build process")

set(LIBRA_PGO
    "NONE"
    CACHE STRING "{NONE,GEN,USE} Compiler PGO generation/use ")
set_property(CACHE LIBRA_PGO PROPERTY STRINGS NONE GEN USE)

set(LIBRA_FPC
    "RETURN"
    CACHE STRING "{RETURN,ABORT,NONE} Function Predcondition Checking (FPC)")
set_property(CACHE LIBRA_FPC PROPERTY STRINGS RETURN ABORT NONE INHERIT)

set(LIBRA_ERL
    "ALL"
    CACHE
      STRING
      "{NONE, ERROR, WARN, INFO, DEBUG, TRACE, ALL, INHERIT} Set the logging level"
)

set(LIBRA_FORTIFY
    "NONE"
    CACHE
      STRING
      "{NONE, STACK, SOURCE, CFI, GOT, FORMAT, LIBCXX_FAST, LIBCXX_EXTENSIVE,LIBCXX_DEBUG,ALL"
)
set_property(
  CACHE LIBRA_FORTIFY
  PROPERTY STRINGS NONE STACK
  SOURCE CFI
         GOT
         FORMAT
         LIBCXX_FAST
         LIBCXX_EXTENSIVE
         LIBCXX_DEBUG
         ALL)

set_property(
  CACHE LIBRA_ERL
  PROPERTY STRINGS
           NONE
           ERROR
           WARN
           INFO
           DEBUG
           TRACE
           ALL
           INHERIT)

# ##############################################################################
# Conan Configuration
#
# Disable all packaging stuff, connect to conan's cmake interface.
# ##############################################################################
if("${LIBRA_DRIVER}" MATCHES "CONAN")
  # This is how the conan docs show to test this variable; testing any other way
  # didn't work.
  if(NOT BUILD_TESTING STREQUAL OFF)
    set(LIBRA_TESTS ON)
  else()
    set(LIBRA_TESTS OFF)
  endif()
else()
  # Conan handles all packaging related things, so don't even bother.
  include(libra/package/components)
  include(libra/package/install)
  include(libra/package/deploy)
  include(libra/package/uninstall)
  include(libra/package/version)

  # Conan handles this too via the conan cache
  if(NOT DEFINED LIBRA_DEPS_PREFIX)
    if(CMAKE_CROSSCOMPILING)
      set(CMAKE_INSTALL_PREFIX
          ${CMAKE_INSTALL_PREFIX}/${CMAKE_SYSTEM_PROCESSOR})
      set(LIBRA_DEPS_PREFIX $ENV{HOME}/.local/${CMAKE_SYSTEM_PROCESSOR}/system)
    else()
      set(LIBRA_DEPS_PREFIX $ENV{HOME}/.local/system)
    endif()
  endif()

  set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
  set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
  set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
endif()

# ##############################################################################
# Build/Compiler Configuration
# ##############################################################################
if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE "Debug")
endif()

# Must be before build types to populate options
include(libra/compile/compiler)
include(libra/compile/build-types)

if(LIBRA_OPT_REPORT)
  include(libra/compile/reporting)
endif()

# I can't think of a reason you wouldn't want this on, so unconditionally set
# it.
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# ##############################################################################
# Source Definitions
# ##############################################################################
# Project name is set via CMAKE_SOURCE_DIR to get the name of the directory that
# libra is used in, not the name of the directory where libra resides (which can
# be anywhere).
if(NOT "${${PROJECT_NAME}_DIR}")
  set(${PROJECT_NAME}_DIR ${CMAKE_SOURCE_DIR})
endif()

set(${PROJECT_NAME}_SRC_PATH ${${PROJECT_NAME}_DIR}/src)
set(${PROJECT_NAME}_INC_PATH ${${PROJECT_NAME}_DIR}/include)

# 2024-11-18 [JRH]: See the docs for the rationale behind using globbing in
# LIBRA.
file(GLOB_RECURSE ${PROJECT_NAME}_C_SRC ${${PROJECT_NAME}_SRC_PATH}/*.c)
file(GLOB_RECURSE ${PROJECT_NAME}_CXX_SRC ${${PROJECT_NAME}_SRC_PATH}/*.cpp)
file(GLOB_RECURSE ${PROJECT_NAME}_CUDA_SRC ${${PROJECT_NAME}_SRC_PATH}/*.cu)
file(GLOB_RECURSE ${PROJECT_NAME}_C_HEADERS ${${PROJECT_NAME}_INC_PATH}/*.h)
file(GLOB_RECURSE ${PROJECT_NAME}_CXX_HEADERS ${${PROJECT_NAME}_INC_PATH}/*.hpp)

file(GLOB_RECURSE ${PROJECT_NAME}_SRC ${${PROJECT_NAME}_C_SRC}
     ${${PROJECT_NAME}_CXX_SRC} ${${PROJECT_NAME}_CUDA_SRC})

# ##############################################################################
# Target Definitions
# ##############################################################################
# Add project-local config. We use CMAKE_SOURCE_DIR, because this file MUST be
# located in under cmake/project-local.cmake in the root of whatever
# directory/repo is using libra.
include(${CMAKE_SOURCE_DIR}/cmake/project-local.cmake)

# ##############################################################################
# Code Checking/Analysis Options
# ##############################################################################
if(${LIBRA_ANALYSIS})
  include(libra/analyze/analyze)

  # You have to be specific, because projects can have a mix of file types, and
  # we want to be sure we only enable checkers appropriately. If the check
  # language is not set, assume C++, because that is more common than CUDA, and
  # is a superset of C, so it might work OK for pure C projects too.
  if(NOT LIBRA_CHECK_LANGUAGE)
    libra_message(
      WARNING
      "Static analysis enabled but LIBRA_CHECK_LANGUAGE not set; assuming CXX")
    set(LIBRA_CHECK_LANGUAGE CXX)
  endif()

  if("${LIBRA_CHECK_LANGUAGE}" STREQUAL "C")
    set(${PROJECT_NAME}_CHECK_SRC ${${PROJECT_NAME}_C_SRC})
  elseif("${LIBRA_CHECK_LANGUAGE}" STREQUAL "CXX")
    set(${PROJECT_NAME}_CHECK_SRC ${${PROJECT_NAME}_CXX_SRC})
  elseif("${LIBRA_CHECK_LANGUAGE}" STREQUAL "CUDA")
    set(${PROJECT_NAME}_CHECK_SRC ${${PROJECT_NAME}_CUDA_SRC})
  else()
    libra_message(
      FATAL_ERROR
      "Bad static analysis language '${LIBRA_CHECK_LANGUAGE}' for project: \
must be {C,CXX,CUDA}")
  endif()

  # Handy checking tools
  libra_message(STATUS "Enabling analysis tools: checkers")
  libra_toggle_checker_cppcheck(ON)
  libra_toggle_checker_clang_tidy(ON)
  libra_toggle_checker_clang_check(ON)
  libra_register_checkers(${PROJECT_NAME} ${${PROJECT_NAME}_CHECK_SRC})

  # Handy formatting tools
  libra_message(STATUS "Enabling analysis tools: formatters")
  libra_toggle_formatter_clang_format(ON)
  libra_register_formatters(${PROJECT_NAME} ${${PROJECT_NAME}_CHECK_SRC})

  # Handy fixing tools
  libra_message(STATUS "Enabling analysis tools: fixers")
  libra_toggle_fixer_clang_tidy(ON)
  libra_register_fixers(${PROJECT_NAME} ${${PROJECT_NAME}_CHECK_SRC})

endif()

# ##############################################################################
# Documentation Options
# ##############################################################################
# Put this AFTER sourcing the project-local.cmake to enable disabling
# documentation builds for projects that don't have docs.
if(LIBRA_DOCS)
  include(libra/doxygen)
endif()

# ##############################################################################
# Testing Options
#
# Code coverage is included here because the way you get coverage info is
# (presumably) by running some tests. Fits better here than in analyze/.
# ##############################################################################
if(LIBRA_TESTS)
  include(libra/test/testing)
endif()

if(LIBRA_CODE_COV)
  include(libra/coverage)
endif()

# ##############################################################################
# Config Summary
# ##############################################################################
if(${LIBRA_SUMMARY})
  if(NOT ${LIBRA_SHOWED_SUMMARY})
    libra_config_summary()
  endif()
endif()
