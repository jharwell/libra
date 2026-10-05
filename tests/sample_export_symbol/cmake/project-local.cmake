#
# Copyright 2026 John Harwell, All rights reserved.
#
# SPDX-License-Identifier: MIT
#
# A main library and a component library sharing one export macro, as in a
# real project with components. Test inputs:
#
# LIBRA_TEST_LIBTYPE       SHARED (default) or STATIC.
# LIBRA_TEST_EXPORT_SYMBOL If defined, LIBRA_EXPORT_SYMBOL is set to it.
# LIBRA_TEST_API_SYMBOL    The symbol the header's export macro tests for.
#                          Default SAMPLE_EXPORT_SYMBOL_EXPORTS.
#
# Each library defines one extern "C" function marked with the export macro.
# The tests check which of them the built libraries export.
if(NOT DEFINED LIBRA_TEST_LIBTYPE)
  set(LIBRA_TEST_LIBTYPE SHARED)
endif()
if(NOT DEFINED LIBRA_TEST_API_SYMBOL)
  set(LIBRA_TEST_API_SYMBOL SAMPLE_EXPORT_SYMBOL_EXPORTS)
endif()
if(DEFINED LIBRA_TEST_EXPORT_SYMBOL)
  set(LIBRA_EXPORT_SYMBOL "${LIBRA_TEST_EXPORT_SYMBOL}")
endif()

set(_dir ${CMAKE_BINARY_DIR}/gen)
file(
  WRITE ${_dir}/include/api.hpp
  "#pragma once
#if defined(${LIBRA_TEST_API_SYMBOL})
#define SAMPLE_API __attribute__((visibility(\"default\")))
#else
#define SAMPLE_API
#endif
extern \"C\" SAMPLE_API int sample_core_api();
extern \"C\" SAMPLE_API int sample_net_api();
")

# CMake's own per-target symbol must still be defined for shared libraries,
# and LIBRA's must not be defined for static ones.
file(
  WRITE ${_dir}/core.cpp
  "#include \"api.hpp\"
#if defined(LIBRA_TEST_SHARED) && !defined(sample_export_symbol_EXPORTS)
#error sample_export_symbol_EXPORTS from CMake is not defined
#endif
#if !defined(LIBRA_TEST_SHARED) && defined(SAMPLE_EXPORT_SYMBOL_EXPORTS)
#error SAMPLE_EXPORT_SYMBOL_EXPORTS is defined in a static library
#endif
int sample_core_api() { return 0; }
")
file(
  WRITE ${_dir}/net.cpp
  "#include \"api.hpp\"
int sample_net_api() { return 1; }
")

libra_add_library(NAME sample_export_symbol ${LIBRA_TEST_LIBTYPE}
                  ${_dir}/core.cpp)
libra_add_component_library(
  TARGET
  sample_export_symbol
  COMPONENT
  net
  SOURCES
  ${_dir}/core.cpp
  ${_dir}/net.cpp
  REGEX
  "net\\.cpp")

foreach(_target sample_export_symbol sample_export_symbol_net)
  target_include_directories(${_target} PRIVATE ${_dir}/include)
  if(LIBRA_TEST_LIBTYPE STREQUAL "SHARED")
    target_compile_definitions(${_target} PRIVATE LIBRA_TEST_SHARED)
  endif()
endforeach()
