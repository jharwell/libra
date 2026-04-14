# ##############################################################################
# CMake Configuration
# ##############################################################################

# CMake version
cmake_minimum_required(VERSION 3.31 FATAL_ERROR)

# This will be set when LIBRA is used as a conan backend (we can't test directly
# for that at this point in the file, because that option isn't defined yet).
if(NOT PROJECT_NAME)
  # I define the current target as the same as the directory that the
  # CMakeLists.txt resides in--simpler that way.
  get_filename_component(LIBRA_TARGET ${CMAKE_CURRENT_LIST_DIR} NAME)
  project(${LIBRA_TARGET} C CXX)
endif()

include(libra/version)

# This should generally be set undconditionally.
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# This makes ninja add stuff for C++20 modules, which confuses clang-tidy.
set(CMAKE_CXX_SCAN_FOR_MODULES OFF)

# ##############################################################################
# Cmake Environment
# ##############################################################################
include(libra/messaging)
include(libra/colorize)
include(libra/utils)
include(libra/diagnostics_pre)
include(libra/targets)
include(libra/defaults)
include(libra/compile/version) # To be available in project-local.cmake

# 2026-02-26 [JRH]: Some of the variables used in here are undefined at this
# point, but that's OK because libra_config_summary() isn't called until the end
# of this file. It needs to be here so libra_config_summary_prepare_fields() is
# available in project-local.cmake.
include(libra/summary)

# Set policies
include(libra/policies)

# ##############################################################################
# Project Cmdline Configuration
# ##############################################################################
option(LIBRA_TESTS "Build tests." OFF)
option(LIBRA_CODE_COV "Compile with code coverage instrumentation" OFF)
option(LIBRA_DOCS "Enable documentation build" OFF)
option(
  LIBRA_VALGRIND_COMPAT
  "Disable some compiler instructions so 64-bit code can robustly be run under valgrind"
  OFF)
option(LIBRA_ANALYSIS "Enable static analysis checkers" OFF)
option(LIBRA_SUMMARY "Show a configuration summary" OFF)
option(LIBRA_LTO "Enable Link-Time Optimization" OFF)
option(LIBRA_NATIVE_OPT "Enable native optimization options" OFF)
option(LIBRA_OPT_REPORT "Emit-generated reports related to optimizations" OFF)
option(LIBRA_NO_CCACHE "Disable usage of ccache, even if found" OFF)
option(LIBRA_BUILD_PROF "Enable build profiling" OFF)
option(LIBRA_GLOBAL_C_FLAGS "Should LIBRA set C flags globally?" OFF)
option(LIBRA_GLOBAL_CXX_FLAGS "Should LIBRA set C++ flags globally?" OFF)
option(LIBRA_FPC_EXPORT "Should LIBRA_FPC be visible downstream?" OFF)
option(LIBRA_ERL_EXPORT "Should LIBRA_ERL be visible downstream?" OFF)
option(LIBRA_CODE_COV_NATIVE
       "Should code coverage be emitted in the compiler's native format?" YES)
option(LIBRA_USE_COMPDB "Should analysis tools use a compilation database?" YES)
option(
  LIBRA_CLANG_TOOLS_USE_FIXED_DB
  "Use the '--' separator (fixed compilation database for clang-based tools)"
  YES)

# 2026-02-02 [JRH]: All of these are cache variables, because option() does not
# support non-boolean things.

set(LIBRA_DRIVER
    "SELF"
    CACHE STRING "{SELF,CONAN} Set the user front end for the build process")

set(LIBRA_PGO
    "NONE"
    CACHE STRING "{NONE,GEN,USE} Compiler PGO generation/use ")

set(LIBRA_FPC
    "INHERIT"
    CACHE STRING
          "{RETURN,ABORT,NONE,INHERIT} Function Predcondition Checking (FPC)")

set(LIBRA_ERL
    "INHERIT"
    CACHE
      STRING
      "{NONE, ERROR, WARN, INFO, DEBUG, TRACE, ALL, INHERIT} Set the logging level"
)

set(LIBRA_FORTIFY
    ${LIBRA_FORTIFY_DEFAULT}
    CACHE STRING "{NONE, STACK, SOURCE, ALL")
set(LIBRA_SAN
    ${LIBRA_SAN_DEFAULT}
    CACHE STRING "{NONE,MSAN,ASAN,SSAN,UBSAN,TSAN")
set(LIBRA_STDLIB
    ${LIBRA_STDLIB_DEFAULT}
    CACHE STRING "{NONE, CXX, STDCXX")

# Unlike the MATCHER variables (which encode naming conventions and belong in
# project-local.cmake), these control whether tests are registered with CTest
# and are legitimate per-build knobs — e.g. a CI job that wants to skip slow
# integration tests can pass -DLIBRA_CTEST_INCLUDE_INTEGRATION_TESTS=NO.
set(LIBRA_CTEST_INCLUDE_UNIT_TESTS
    ${LIBRA_CTEST_INCLUDE_UNIT_TESTS_DEFAULT}
    CACHE STRING "Register discovered unit tests with CTest (YES/NO)")
set(LIBRA_CTEST_INCLUDE_INTEGRATION_TESTS
    ${LIBRA_CTEST_INCLUDE_INTEGRATION_TESTS_DEFAULT}
    CACHE STRING "Register discovered integration tests with CTest (YES/NO)")
set(LIBRA_CTEST_INCLUDE_REGRESSION_TESTS
    ${LIBRA_CTEST_INCLUDE_REGRESSION_TESTS_DEFAULT}
    CACHE STRING "Register discovered regression tests with CTest (YES/NO)")
if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
  set(_LIBRA_TARGETS
      ""
      CACHE INTERNAL "List of target to apply LIBRA magic to" FORCE)
endif()

# ##############################################################################
# Conan Configuration
#
# Disable all packaging stuff, connect to conan's cmake interface.
#
# We attempt to automatically detect if LIBRA is running under conan by checking
# for some variables that conan defines. This is not guaranteed to work, but
# heuristically seems to work pretty well.
#
# IMPORTANT! On x64, conan defines a number of flag variables with -m64, but
# doesn't do anything analogous for e.g. arm. So those flags will be unset.
# However, CONAN_RUNTIME_LIB_DIRS is defined in both cases, but hinging conan
# detection for arm on a single variable is rather brittle, so we add a check
# for the toolchain file matching a specific substring to help with that.
# ##############################################################################
set(_libra_conan_var_check_list
    CONAN_EXPORTED
    CONAN_CMAKE_TOOLCHAIN_FILE
    CONAN_C_FLAGS
    CONAN_CXX_FLAGS
    CONAN_RUNTIME_LIB_DIRS
    CONAN_EXE_LINKER_FLAGS
    CONAN_SHARED_LINKER_FLAGS)
foreach(var ${_libra_conan_var_check_list})
  if(DEFINED ${var})
    libra_message(STATUS "${var} defined, probably a conan-based environment")
    set(LIBRA_DRIVER "CONAN")
    break()
  endif()
endforeach()

string(FIND "${CMAKE_TOOLCHAIN_FILE}" "generators/conan_toolchain.cmake"
            string_position)
if(string_position GREATER -1)
  libra_message(
    STATUS
    "CMAKE_TOOLCHAIN_FILE matches conan conventions; probably a conan-based environment"
  )
  set(LIBRA_DRIVER "CONAN")
endif()

if("${LIBRA_DRIVER}" MATCHES "CONAN")
  libra_message(STATUS "Conan detected--using LIBRA_DRIVER=CONAN")

  # This is how the conan docs show to test this variable; testing any other way
  # didn't work.
  if(NOT BUILD_TESTING STREQUAL OFF)
    set(LIBRA_TESTS ON)
  else()
    set(LIBRA_TESTS OFF)
  endif()

else()
  if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    include(libra/package/components)
    include(libra/package/install)
    include(libra/package/deploy)
    include(libra/package/uninstall)
  endif()
endif()

# We do this even under conan, because a conan-specific flat layout is
# unnecessary — conan doesn't care where the build outputs land, it only cares
# about the install layout (what goes where after cmake --install). The build
# output directory is purely a developer convenience.
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/${CMAKE_INSTALL_LIBDIR})
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/${CMAKE_INSTALL_LIBDIR})
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/${CMAKE_INSTALL_BINDIR})

# ##############################################################################
# Source Definitions
# ##############################################################################
# Project name is set via CMAKE_CURRENT_SOURCE_DIR to get the name of the
# directory that LIBRA is used in, not the name of the directory where LIBRA
# resides (which can be anywhere).
if(NOT "${${PROJECT_NAME}_DIR}")
  set(${PROJECT_NAME}_DIR ${CMAKE_CURRENT_SOURCE_DIR})
endif()

set(${PROJECT_NAME}_SRC_PATH ${${PROJECT_NAME}_DIR}/src)
set(${PROJECT_NAME}_INC_PATH ${${PROJECT_NAME}_DIR}/include)
set(${PROJECT_NAME}_TESTS_PATH ${${PROJECT_NAME}_DIR}/tests)

# 2024-11-18 [JRH]: See the docs for the rationale behind using globbing in
# LIBRA.
file(GLOB_RECURSE ${PROJECT_NAME}_C_SRC ${${PROJECT_NAME}_SRC_PATH}/*.c)
file(GLOB_RECURSE ${PROJECT_NAME}_CXX_SRC ${${PROJECT_NAME}_SRC_PATH}/*.cpp)
file(GLOB_RECURSE ${PROJECT_NAME}_C_HEADERS ${${PROJECT_NAME}_INC_PATH}/*.h)
file(GLOB_RECURSE ${PROJECT_NAME}_CXX_HEADERS ${${PROJECT_NAME}_INC_PATH}/*.hpp)
file(GLOB_RECURSE ${PROJECT_NAME}_CXX_TESTS_SRC
     ${${PROJECT_NAME}_TESTS_PATH}/*.cpp)
file(GLOB_RECURSE ${PROJECT_NAME}_CXX_TESTS_HEADERS
     ${${PROJECT_NAME}_TESTS_PATH}/*.hpp)
file(GLOB_RECURSE ${PROJECT_NAME}_C_TESTS_SRC ${${PROJECT_NAME}_TESTS_PATH}/*.c)
file(GLOB_RECURSE ${PROJECT_NAME}_C_TESTS_HEADERS
     ${${PROJECT_NAME}_TESTS_PATH}/*.h)

file(GLOB ${PROJECT_NAME}_CMAKE_SRC ${PROJECT_SOURCE_DIR}/CMakeLists.txt
     ${PROJECT_SOURCE_DIR}/cmake/*.cmake)

# Should not be needed because cmake-format picks up cmake files in the .conan2
# directory when we use recursive globbing, but we specifically DON'T use that
# here. But just for safety.
if("${LIBRA_DRIVER}" MATCHES "CONAN")
  list(
    FILTER
    ${PROJECT_NAME}_CMAKE_SRC
    EXCLUDE
    REGEX
    "\.conan2")
endif()

set(${PROJECT_NAME}_SRC ${${PROJECT_NAME}_C_SRC} ${${PROJECT_NAME}_CXX_SRC})

# ##############################################################################
# Target Definitions
# ##############################################################################
# Add project-local config.
include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/project-local.cmake)

# ##############################################################################
# Build/Compiler Configuration
# ##############################################################################
if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE "Release")
endif()
libra_message(STATUS
              "Configuring ${PROJECT_NAME} for ${CMAKE_BUILD_TYPE} build")

# Must be before build types to populate options
include(libra/compile/compiler)
if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
  include(libra/compile/build-types)
endif()

# Must be after compile options are populated
include(libra/diagnostics_post)

# ##############################################################################
# Code Checking/Analysis Options
# ##############################################################################
if(${LIBRA_ANALYSIS})
  include(libra/analyze/analyze)
endif()

# ##############################################################################
# Documentation Options
# ##############################################################################
# Put this AFTER sourcing the project-local.cmake to enable disabling
# documentation builds for projects that don't have docs.
if(LIBRA_DOCS)
  libra_message(STATUS "Configuring documentation generation")
  if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    include(libra/apidoc)

    add_custom_target(apidoc-check)
    set_target_properties(apidoc-check PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1)

    _libra_calculate_srcs("APIDOC" ${PROJECT_NAME}_DOCS_SRC "")
    # Should not be needed, but just for safety
    if("${LIBRA_DRIVER}" MATCHES "CONAN")
      list(
        FILTER
        ${PROJECT_NAME}_DOCS_SRC
        EXCLUDE
        REGEX
        "\.conan2")
    endif()

    _libra_apidoc_configure_doxygen()
    libra_toggle_clang(ON)

    # Handy checking tools
    libra_message(STATUS "Enabling apidoc tools: checkers")
    _libra_apidoc_register_clang(apidoc-check-clang ${${PROJECT_NAME}_DOCS_SRC})

    include(libra/sphinxdoc)
    _libra_sphinxdoc_configure()
  endif()
endif()

# ##############################################################################
# Testing Options
#
# Code coverage is included here because the way you get coverage info is
# (presumably) by running some tests. Fits better here than in analyze/.
# ##############################################################################
if(LIBRA_TESTS)
  if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    include(libra/test/testing)
  endif()
  list(POP_BACK CMAKE_MESSAGE_INDENT)
endif()

if(LIBRA_CODE_COV)
  if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)

    include(libra/test/coverage)

    if("${CMAKE_C_COMPILER_ID}" MATCHES "Clang" OR "${CMAKE_CXX_COMPILER_ID}"
                                                   MATCHES "Clang")
      if(LIBRA_CODE_COV_NATIVE)
        _libra_coverage_register_llvm()
      else()
        _libra_coverage_register_lcov()
        _libra_coverage_register_gcovr()
      endif()
    elseif("${CMAKE_C_COMPILER_ID}" MATCHES "GNU" OR "${CMAKE_CXX_COMPILER_ID}"
                                                     MATCHES "GNU")
      _libra_coverage_register_lcov()
      _libra_coverage_register_gcovr()
    else()
      libra_error("Unsupported compiler for coverage")
    endif()
  endif()
endif()

# ##############################################################################
# Config Summary
# ##############################################################################
_libra_create_help_targets()

if(${LIBRA_SUMMARY})
  if(NOT ${_LIBRA_SHOWED_SUMMARY})
    libra_config_summary()
  endif()
else()
  libra_message(
    STATUS
    "Configuration complete for ${PROJECT_NAME}. To see a detailed configuration summary, re-run with -DLIBRA_SUMMARY=YES."
  )

endif()

get_filename_component(MAKE_NAME ${CMAKE_MAKE_PROGRAM} NAME)

libra_message(STATUS
              "Run '${MAKE_NAME} help-targets' to see available build targets.")
