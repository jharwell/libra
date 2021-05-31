################################################################################
# Cmake Configuration Template
#
# Can be used for the root/top-level meta-project, or for a submodule.
#
################################################################################

# CMake version
cmake_minimum_required(VERSION 3.9 FATAL_ERROR)

# I define the current target as the same as the directory that the
# CMakeLists.txt resides in--simpler that way.
get_filename_component(target ${CMAKE_CURRENT_LIST_DIR} NAME)

# The name of the target at the root of the project/repo gets a special name,
# because sometimes you need it in subdirs. Note that at the root
# target=root_target.
get_filename_component(root_target ${CMAKE_SOURCE_DIR} NAME)

project(${target} C CXX)

# Set a handy macro for determining if we are the root project/module in a
# cmake build/configure process.
if ("${CMAKE_CURRENT_SOURCE_DIR}" STREQUAL "${CMAKE_SOURCE_DIR}")
  set(IS_ROOT_PROJECT TRUE)
else()
  set(IS_ROOT_PROJECT FALSE)
endif()

if ("${target}" STREQUAL "${root_target}")
  set(IS_ROOT_TARGET TRUE)
else()
  set(IS_ROOT_TARGET FALSE)
endif()

# Output some nice status info.
if(IS_ROOT_PROJECT)
  set(module_display "${root_target}")
else()
  set(module_display "${module_display}/${target}")
endif()
message(STATUS "Found ${module_display}")

################################################################################
# Cmake Environment                                                            #
################################################################################
include(${CMAKE_ROOT}/Modules/ExternalProject.cmake)

# Download repo with custom cmake config and register modules
if (IS_ROOT_PROJECT AND NOT EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/libra)
  execute_process(COMMAND git submodule update --init libra
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
endif()

list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/libra/cmake")


option(LIBRA_TESTS     "Build tests."                                          OFF)
option(LIBRA_OPENMP    "Enable OpenMP code."                                   OFF)
option(LIBRA_PGO_GEN   "Enable compiler PGO generation phase."                 OFF)
option(LIBRA_PGO_USE   "Enable compiler PGO use phase."                        OFF)
option(LIBRA_MPI       "Enable MPI code."                                      OFF)
option(LIBRA_RTD_BUILD "Indicate that the build is for ReadTheDocs"            OFF)
option(LIBRA_CODE_COV  "Compile with code coverage instrumentation"            OFF)
option(LIBRA_DOCS      "Enable documentation build"                            ON)

set(LIBRA_FPC "RETURN" CACHE STRING "[RETURN,ABORT] for function predcondition checking")
set_property(CACHE LIBRA_FPC PROPERTY STRINGS RETURN ABORT)

set(LIBRA_ER "ALL" CACHE STRING "[NONE, ASSERT, ALL] NONE to disable all event reporting. ASSERT to disable all event reporting except for failed asserts.")
set_property(CACHE LIBRA_ER PROPERTY STRINGS NONE ASSERT ALL)
set(FPC FPC_TYPE="${LIBRA_FPC}")

include(compile-options)
include(reporting)
include(build-modes)
include(analysis)
include(custom-cmds)

if (LIBRA_DOCS)
  include(doxygen)
endif()

if (LIBRA_CODE_COV)
  include(coverage)
endif()

# Set policies
set_policy(CMP0028 NEW) # ENABLE CMP0028: Double colon in target name means ALIAS or IMPORTED target.
set_policy(CMP0054 NEW) # ENABLE CMP0054: Only interpret if() arguments as variables or keywords when unquoted.
set_policy(CMP0063 NEW) # ENABLE CMP0063: Honor visibility properties for all target types.

################################################################################
# Project Configuration                                                        #
################################################################################
if (NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE "DEV")
endif()

# Handy checking tools
toggle_cppcheck(ON)
toggle_clang_tidy_check(ON)
toggle_clang_static_check(ON)
toggle_clang_format(ON)
toggle_clang_tidy_fix(ON)

# Set output directories. If we are the root project, then this is
# necessary. If not, we simply re-set the same values.
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

################################################################################
# Source Definitions                                                           #
################################################################################
# Sources
set(${target}_SRC_PATH "${CMAKE_CURRENT_SOURCE_DIR}/src")

if (IS_ROOT_TARGET)
  file(GLOB_RECURSE ${target}_ROOT_C_SRC ${${target}_SRC_PATH}/*.c)
  file(GLOB_RECURSE ${target}_ROOT_CXX_SRC ${${target}_SRC_PATH}/*.cpp)
  set(${target}_ROOT_SRC ${${target}_ROOT_C_SRC} ${${target}_ROOT_CXX_SRC})
endif()

file(GLOB_RECURSE ${target}_SRC ${${target}_SRC_PATH}/*.c ${${target}_SRC_PATH}/*.cpp)
file(GLOB_RECURSE ${target}_C_SRC ${${target}_SRC_PATH}/*.c )
file(GLOB_RECURSE ${target}_CXX_SRC ${${target}_SRC_PATH}/*.cpp)

set(${target}_INC_PATH "${CMAKE_CURRENT_SOURCE_DIR}/include/")
set(${target}_ROOT_INC_PATH "${CMAKE_SOURCE_DIR}/include/")

set(${root_target}_TEST_PATH ${CMAKE_CURRENT_SOURCE_DIR}/tests)

# Convention: Unit tests end with '-utest.c' or '-utest.cpp'
file(GLOB c_utests ${${root_target}_TEST_PATH}/*-utest.c)
file(GLOB c_utest_harness ${${root-target}_TEST_PATH}/*_test.c ${${root_target}_TEST_PATH}/*.h ${${root_target}_TEST_PATH}/*.hpp)
file(GLOB cxx_utests ${${root_target}_TEST_PATH}/*-utest.cpp)
file(GLOB cxx_utest_harness ${${root_target}_TEST_PATH}/*_test.cpp  ${${root_target}_TEST_PATH}/*.hpp)

################################################################################
# Testing Targets                                                              #
################################################################################
if (NOT IS_ROOT_PROJECT AND "${target}" STREQUAL "tests" AND NOT TARGET ${target})
  add_library(${current_proj_name}-${target} ${${target}_SRC})
  target_include_directories(${current_proj_name}-${target} PUBLIC include)
endif()

################################################################################
# Target Definitions                                                           #
################################################################################
# now we can add project-local config
if (EXISTS ${CMAKE_CURRENT_LIST_DIR}/project-local.cmake )
  set(current_proj_name ${target})
  include(${CMAKE_CURRENT_LIST_DIR}/project-local.cmake OPTIONAL)
endif()

# We are not the root project--we are a submodule. Add ourselves to the
# dependencies of the root target.
if (NOT IS_ROOT_PROJECT)
  # For my projects, all submodules EXCEPT one called tests are assumed to be
  # OBJECT libraries (i.e. transient targets only for logical organization
  # that are all rolled into the binary blob of the root target).
  if (NOT "${target}" STREQUAL "tests")

    # We may actually be part of a larger project, and thus our target has
    # already been created but a separate submodule depending on us.
    if (NOT TARGET ${current_proj_name}-${target})

      # If you have two different projects with the same submodule, say
      # 'common', then you will need to prefix the targets with the project
      # name so that they are unique and all your sources end up getting
      # compiled. Because you need to handle *NOT* adding a target if it
      # already exists, not doing this will inexplicably leave some source
      # files out of compilation of the module that gets processed SECOND by
      # cmake.
      #
      # It's safer just to do this all the time.

      if (NOT "${current_proj_name}" STREQUAL "${target}")
        add_library(${current_proj_name}-${target} OBJECT ${${target}_SRC})
      endif()
    endif()
  endif()
endif()

################################################################################
# Code Checking/Analysis Options                                               #
################################################################################
# If the root project declared itself to have recursive dirs
# (i.e. semi-independent subjprojects, then register each submodules' source
# independently so that it can be built/checked independently. Otherwise, add
# the source as one big blob.)

if("${${root_target}_CHECK_LANGUAGE}" STREQUAL "C")
  if (IS_ROOT_TARGET)
    set(${root_target}_ROOT_CHECK_SRC ${${root_target}_ROOT_C_SRC})
  else()
    set(${target}_CHECK_SRC ${${target}_C_SRC})
  endif()
else()
  if (IS_ROOT_TARGET)
    set(${root_target}_ROOT_CHECK_SRC ${${root_target}_ROOT_CXX_SRC})
  else()
    set(${target}_CHECK_SRC ${${target}_CXX_SRC})
    endif()
endif()

if (IS_ROOT_TARGET)
  register_checkers(${target} ${${target}_ROOT_CHECK_SRC})
  register_auto_formatters(${target} ${${target}_ROOT_CHECK_SRC})
  register_auto_fixers(${target} ${${target}_ROOT_CHECK_SRC})
endif()

################################################################################
# Testing Options                                                              #
################################################################################
if (LIBRA_TESTS)
  include(testing)
endif()

################################################################################
# Deployment Options                                                           #
################################################################################
if (IS_ROOT_PROJECT)
  include(deploy)
endif()
