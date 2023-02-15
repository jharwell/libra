################################################################################
# Cmake Configuration Template
#
# Can be used for the root/top-level meta-project, or for a submodule.
#
################################################################################

# CMake version
cmake_minimum_required(VERSION 3.21 FATAL_ERROR)

# I define the current target as the same as the directory that the
# CMakeLists.txt resides in--simpler that way.
get_filename_component(target ${CMAKE_CURRENT_LIST_DIR} NAME)

project(${target} C CXX)

# The current version of LIBRA, to make debugging strange build
# problems easier
set(LIBRA_VERSION 0.6.8)

################################################################################
# Cmake Environment
################################################################################
include(${CMAKE_ROOT}/Modules/ExternalProject.cmake)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/libra/cmake")

option(LIBRA_TESTS     "Build tests."                                          OFF)
option(LIBRA_OPENMP    "Enable OpenMP code."                                   OFF)
option(LIBRA_PGO_GEN   "Enable compiler PGO generation phase."                 OFF)
option(LIBRA_PGO_USE   "Enable compiler PGO use phase."                        OFF)
option(LIBRA_MPI       "Enable MPI code."                                      OFF)
option(LIBRA_RTD_BUILD "Indicate that the build is for ReadTheDocs"            OFF)
option(LIBRA_CODE_COV  "Compile with code coverage instrumentation"            OFF)
option(LIBRA_DOCS      "Enable documentation build"                             ON)
option(LIBRA_VALGRIND_COMPAT "Disable compiler instructions to 64-bit code can robustly be run under valgrind" OFF)
option(LIBRA_ANALYSIS "Enable static analysis checkers"                         ON)

set(LIBRA_FPC "RETURN" CACHE STRING "[RETURN,ABORT] for function predcondition checking")
set_property(CACHE LIBRA_FPC PROPERTY STRINGS RETURN ABORT)

set(LIBRA_ER "INHERIT" CACHE STRING "[NONE, ASSERT, ALL, INHERIT] Set the logging level")

set_property(CACHE LIBRA_ER PROPERTY STRINGS NONE ASSERT ALL INHERIT)
set(FPC FPC_TYPE="${LIBRA_FPC}")

include(colorize)
include(reporting)

if (NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE "DEV")
endif()
include(compile-options) # Must be before build modes to populate options
include(build-modes)

include(custom-cmds)
include(components)
include(install)
include(deploy)
include(uninstall)
include(version)

if (LIBRA_CODE_COV)
  include(coverage)
endif()

# Set policies
set_policy(CMP0028 NEW) # ENABLE CMP0028: Double colon in target name means ALIAS or IMPORTED target.
set_policy(CMP0054 NEW) # ENABLE CMP0054: Only interpret if() arguments as variables or keywords when unquoted.
set_policy(CMP0063 NEW) # ENABLE CMP0063: Honor visibility properties for all target types.
set_policy(CMP0074 NEW) # ENABLE CMP0074: find_package uses <PackageName>_ROOT variables.
set_policy(CMP0072 NEW) # Prefer modern OpenGL

################################################################################
# Project Configuration
################################################################################
if (NOT DEFINED LIBRA_DEPS_PREFIX)
  if(CMAKE_CROSSCOMPILING)
    set(CMAKE_INSTALL_PREFIX ${CMAKE_INSTALL_PREFIX}/${CMAKE_SYSTEM_PROCESSOR})
    set(LIBRA_DEPS_PREFIX $ENV{HOME}/.local/${CMAKE_SYSTEM_PROCESSOR}/system)
  else()
    set(LIBRA_DEPS_PREFIX $ENV{HOME}/.local/system)
  endif()
endif()

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

################################################################################
# Source Definitions
################################################################################
# If this is not defined, we are the root project
if(NOT "${${PROJECT_NAME}_DIR}")
  set(${PROJECT_NAME}_DIR ${CMAKE_CURRENT_LIST_DIR})
endif()

set(${PROJECT_NAME}_SRC_PATH ${${PROJECT_NAME}_DIR}/src)
set(${PROJECT_NAME}_INC_PATH "${CMAKE_CURRENT_SOURCE_DIR}/include/")

file(GLOB_RECURSE ${PROJECT_NAME}_C_SRC ${${PROJECT_NAME}_SRC_PATH}/*.c )
file(GLOB_RECURSE ${PROJECT_NAME}_CXX_SRC ${${PROJECT_NAME}_SRC_PATH}/*.cpp)
file(GLOB_RECURSE ${PROJECT_NAME}_CUDA_SRC ${${PROJECT_NAME}_SRC_PATH}/*.cu)
file(GLOB_RECURSE ${PROJECT_NAME}_C_HEADERS ${${PROJECT_NAME}_INC_PATH}/*.h)
file(GLOB_RECURSE ${PROJECT_NAME}_CXX_HEADERS ${${PROJECT_NAME}_INC_PATH}/*.hpp)

file(GLOB_RECURSE ${PROJECT_NAME}_SRC
  ${${PROJECT_NAME}_C_SRC}
  ${${PROJECT_NAME}_CXX_SRC}
  ${${PROJECT_NAME}_CUDA_SRC})


################################################################################
# Target Definitions
################################################################################
# Add project-local config
include(${CMAKE_CURRENT_LIST_DIR}/cmake/project-local.cmake)

################################################################################
# Code Checking/Analysis Options
################################################################################
if (${LIBRA_ANALYSIS})
  include(analysis)

  if (NOT ${PROJECT_NAME}_CHECK_LANGUAGE)
    message(WARNING "Static analysis enabled but ${PROJECT_NAME}_CHECK_LANGUAGE not set")
  else()

    if("${${PROJECT_NAME}_CHECK_LANGUAGE}" STREQUAL "C")
      set(${PROJECT_NAME}_CHECK_SRC ${${PROJECT_NAME}_C_SRC})
    elseif ("${${PROJECT_NAME}_CHECK_LANGUAGE}" STREQUAL "CXX")
      set(${PROJECT_NAME}_CHECK_SRC ${${PROJECT_NAME}_CXX_SRC})
    else()
      message(FATAL_ERROR "Bad static analysis language for project: must be [C,CXX]")
    endif()

    register_checkers(${PROJECT_NAME} ${${PROJECT_NAME}_CHECK_SRC})
    register_auto_formatters(${PROJECT_NAME} ${${PROJECT_NAME}_CHECK_SRC})
    register_auto_fixers(${PROJECT_NAME} ${${PROJECT_NAME}_CHECK_SRC})

    # Handy checking tools
    message(CHECK_START "Finding checkers")
    list(APPEND CMAKE_MESSAGE_INDENT "  ")
    toggle_cppcheck(ON)
    toggle_clang_tidy_check(ON)
    toggle_clang_static_check(ON)
    list(POP_BACK CMAKE_MESSAGE_INDENT)
    if (CPPCHECK_ENABLED AND
        CLANG_TIDY_CHECK_ENABLED AND
        CLANG_STATIC_CHECK_ENABLED)
      message(CHECK_PASS "All checkers enabled")
    else()
      message(CHECK_FAIL "One or more checkers disabled")
    endif()

    message(CHECK_START "Finding formatters")
    list(APPEND CMAKE_MESSAGE_INDENT "  ")
    toggle_clang_format(ON)
    list(POP_BACK CMAKE_MESSAGE_INDENT)
    if (CLANG_FORMAT_ENABLED)
      message(CHECK_PASS "All formatters enabled")
    else()
      message(CHECK_FAIL "One or more formatters disabled")
    endif()

    message(CHECK_START "Finding fixers")
    list(APPEND CMAKE_MESSAGE_INDENT "  ")
    toggle_clang_tidy_fix(ON)
    list(POP_BACK CMAKE_MESSAGE_INDENT)
    if (CLANG_TIDY_FIX_ENABLED)
      message(CHECK_PASS "All fixers enabled")
    else()
      message(CHECK_FAIL "One or more fixers disabled")
    endif()
  endif()
else()
  message(STATUS "Skipping static analysis init")
endif()

################################################################################
# Documentation Options
################################################################################
# Put this AFTER sourcing the project-local.cmake to enable disabling
# documentation builds for projects that don't have docs.
if (LIBRA_DOCS)
  include(doxygen)
endif()

################################################################################
# Testing Options
################################################################################
if (LIBRA_TESTS)
  include(testing)
endif()

################################################################################
# Config Summary
################################################################################
if (NOT ${LIBRA_SHOWED_SUMMARY})
  libra_config_summary()
endif()

