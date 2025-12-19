# ##############################################################################
# CMake Configuration
# ##############################################################################

# CMake version
cmake_minimum_required(VERSION 3.30 FATAL_ERROR)

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
include(libra/custom-cmds)

# Set policies
include(libra/policies)

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
option(LIBRA_UNSAFE_OPT "Enable unsafe optimization options" OFF)
option(LIBRA_OPT_REPORT "Emit-generated reports related to optimizations" OFF)
option(LIBRA_NO_DEBUG_INFO
       "Disable inclusion of debug info, independent of build type" OFF)
option(LIBRA_NO_CCACHE "Disable usage of ccache, even if found" OFF)
option(LIBRA_BUILD_PROF "Enable build profiling" OFF)
option(LIBRA_GLOBAL_C_FLAGS "Should LIBRA set C flags globally?" OFF)
option(LIBRA_GLOBAL_CXX_FLAGS "Should LIBRA set C++ flags globally?" OFF)
option(LIBRA_GLOBAL_C_STANDARD "Should LIBRA set the C standard globally?" OFF)
option(LIBRA_GLOBAL_CXX_STANDARD "Should LIBRA set C++ standard globally?" OFF)

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
set_property(
  CACHE LIBRA_FPC
  PROPERTY STRINGS
           RETURN
           ABORT
           NONE
           INHERIT)

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

  set(LIBRA_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})
  set(LIBRA_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})
  set(LIBRA_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})

else()
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

  set(LIBRA_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
  set(LIBRA_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
  set(LIBRA_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
endif()

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${LIBRA_ARCHIVE_OUTPUT_DIRECTORY})
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${LIBRA_LIBRARY_OUTPUT_DIRECTORY})
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${LIBRA_RUNTIME_OUTPUT_DIRECTORY})

# ##############################################################################
# Source Definitions
# ##############################################################################
# Project name is set via CMAKE_SOURCE_DIR to get the name of the directory that
# LIBRA is used in, not the name of the directory where LIBRA resides (which can
# be anywhere).
if(NOT "${${PROJECT_NAME}_DIR}")
  set(${PROJECT_NAME}_DIR ${CMAKE_SOURCE_DIR})
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
     ${${PROJECT_NAME}_TESTS_PATH}/*.)

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
# 2025-10-17 [JRH]: This has to be BEFORE including the project-local stuff so
# that any targets defined in there get the correct standard set automatically.
# This only applies when LIBRA is setting global things. This file is included
# AFTER project-local stuff in the general case.
if(${LIBRA_GLOBAL_C_STANDARD} OR ${LIBRA_GLOBAL_CXX_STANDARD})
  include(libra/compile/standard)
endif()

# Add project-local config. We use CMAKE_SOURCE_DIR, because this file MUST be
# located in under cmake/project-local.cmake in the root of whatever
# directory/repo is using LIBRA.
include(${CMAKE_SOURCE_DIR}/cmake/project-local.cmake)

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

# ##############################################################################
# Code Checking/Analysis Options
# ##############################################################################
function(libra_calculate_srcs SOURCE RET)
  # Prefer C++ over C if a project enables both languages.
  if(CMAKE_CXX_COMPILER_LOADED)
    set(LIBRA_CODE_LANGUAGE CXX)
    libra_message(STATUS "Detected language C++ for project")
  elseif(CMAKE_C_COMPILER_LOADED)
    set(LIBRA_CODE_LANGUAGE C)
    libra_message(STATUS "Detected language C project")
  endif()

  if(NOT LIBRA_CODE_LANGUAGE)
    libra_message(
      WARNING "Unable to autodetect languages for static analysis--assuming CXX.
      Set LIBRA_CODE_LANGUAGE in project-local.cmake to remove this warning.")
    set(LIBRA_CODE_LANGUAGE CXX)
  endif()

  if("${LIBRA_CODE_LANGUAGE}" STREQUAL "C")
    if("${SOURCE}" STREQUAL "APIDOC")
      set(${RET}
          ${${PROJECT_NAME}_C_SRC} ${${PROJECT_NAME}_C_HEADERS}
          PARENT_SCOPE)
    else()
      set(${RET}
          ${${PROJECT_NAME}_C_SRC} ${${PROJECT_NAME}_C_HEADERS}
          ${${PROJECT_NAME}_C_TESTS_SRC} ${${PROJECT_NAME}_C_TESTS_HEADERS}
          PARENT_SCOPE)
    endif()
  elseif("${LIBRA_CODE_LANGUAGE}" STREQUAL "CXX")
    if("${SOURCE}" STREQUAL "APIDOC")
      set(${RET}
          ${${PROJECT_NAME}_CXX_SRC} ${${PROJECT_NAME}_CXX_HEADERS}
          PARENT_SCOPE)
    else()
      set(${RET}
          ${${PROJECT_NAME}_CXX_SRC} ${${PROJECT_NAME}_CXX_HEADERS}
          ${${PROJECT_NAME}_CXX_TESTS_SRC} ${${PROJECT_NAME}_CXX_TESTS_HEADERS}
          PARENT_SCOPE)
    endif()
  else()
    libra_message(
      FATAL_ERROR
      "Bad language '${LIBRA_CODE_LANGUAGE}' for project: must be {C,CXX}")
  endif()
endfunction()

if(${LIBRA_ANALYSIS})
  include(libra/analyze/analyze)

  libra_calculate_srcs("STATIC_ANALYSIS" ${PROJECT_NAME}_ANALYSIS_SRC)
  # Should not be needed, but just for safety
  if("${LIBRA_DRIVER}" MATCHES "CONAN")
    list(
      FILTER
      ${PROJECT_NAME}_ANALYSIS_SRC
      EXCLUDE
      REGEX
      "\.conan2")
  endif()

  # Multi-funtion tools
  libra_toggle_clang_tidy(ON)
  libra_toggle_clang_format(ON)
  libra_toggle_cmake_format(ON)
  libra_toggle_clang_check(ON)

  # Handy checking tools
  libra_message(STATUS "Enabling analysis tools: checkers")
  libra_toggle_checker_cppcheck(ON)
  libra_register_code_checkers(${PROJECT_NAME} ${${PROJECT_NAME}_ANALYSIS_SRC})

  libra_register_cmake_checkers(${${PROJECT_NAME}_CMAKE_SRC})

  # Handy formatting tools
  libra_message(STATUS "Enabling analysis tools: formatters")
  libra_register_code_formatters(${${PROJECT_NAME}_ANALYSIS_SRC})
  libra_register_cmake_formatters(${${PROJECT_NAME}_CMAKE_SRC})

  # Handy fixing tools
  libra_message(STATUS "Enabling analysis tools: fixers")
  libra_register_code_fixers(${PROJECT_NAME} ${${PROJECT_NAME}_ANALYSIS_SRC})

endif()

# ##############################################################################
# Documentation Options
# ##############################################################################
# Put this AFTER sourcing the project-local.cmake to enable disabling
# documentation builds for projects that don't have docs.
if(LIBRA_DOCS)
  include(libra/apidoc)

  add_custom_target(apidoc-check)
  set_target_properties(${CHECK_TARGET} PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1)

  libra_calculate_srcs("APIDOC" ${PROJECT_NAME}_DOCS_SRC)
  # Should not be needed, but just for safety
  if("${LIBRA_DRIVER}" MATCHES "CONAN")
    list(
      FILTER
      ${PROJECT_NAME}_DOCS_SRC
      EXCLUDE
      REGEX
      "\.conan2")
  endif()

  libra_apidoc_configure_doxygen()
  libra_toggle_clang(ON)

  # Handy checking tools
  libra_message(STATUS "Enabling apidoc tools: checkers")
  libra_apidoc_register_clang(apidoc-check-clang ${${PROJECT_NAME}_DOCS_SRC})
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
  include(libra/test/coverage)
  libra_coverage_register_lcov()
  libra_coverage_register_gcovr()
endif()

# ##############################################################################
# Config Summary
# ##############################################################################
if(${LIBRA_SUMMARY})
  if(NOT ${LIBRA_SHOWED_SUMMARY})
    libra_config_summary()
  endif()
endif()
