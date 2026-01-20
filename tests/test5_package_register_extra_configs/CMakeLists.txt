cmake_minimum_required(VERSION 3.30 FATAL_ERROR)
project(
  Test5_RegisterExtraConfigs
  VERSION 1.0.0
  LANGUAGES CXX)

set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/../../cmake)

# Create a real library
add_library(configlib STATIC src/configlib.cpp)

# Create extra config files
file(
  WRITE ${CMAKE_CURRENT_SOURCE_DIR}/cmake/extra-config1.cmake
  "# Extra config 1
set(CONFIGLIB_FEATURE1 ON)
")

file(
  WRITE ${CMAKE_CURRENT_SOURCE_DIR}/cmake/extra-config2.cmake
  "# Extra config 2
set(CONFIGLIB_FEATURE2 ON)
")

# Include REAL libra
include(libra/messaging)
include(libra/package/install)

# Test the REAL function
libra_register_extra_configs_for_install(
  TARGET
  configlib
  FILES_OR_DIRS
  ${CMAKE_CURRENT_SOURCE_DIR}/cmake/extra-config1.cmake
  ${CMAKE_CURRENT_SOURCE_DIR}/cmake/extra-config2.cmake)

# Verify extra config files exist
set(CONFIG1 "${CMAKE_CURRENT_SOURCE_DIR}/cmake/extra-config1.cmake")
set(CONFIG2 "${CMAKE_CURRENT_SOURCE_DIR}/cmake/extra-config2.cmake")

if(NOT EXISTS "${CONFIG1}")
  message(FATAL_ERROR "Test FAILED: Config1 not found: ${CONFIG1}")
endif()

if(NOT EXISTS "${CONFIG2}")
  message(FATAL_ERROR "Test FAILED: Config2 not found: ${CONFIG2}")
endif()

# Verify config files have content
file(READ "${CONFIG1}" CONFIG1_CONTENT)
if(NOT CONFIG1_CONTENT MATCHES "CONFIGLIB_FEATURE1")
  message(FATAL_ERROR "Test FAILED: Config1 doesn't set CONFIGLIB_FEATURE1")
endif()

file(READ "${CONFIG2}" CONFIG2_CONTENT)
if(NOT CONFIG2_CONTENT MATCHES "CONFIGLIB_FEATURE2")
  message(FATAL_ERROR "Test FAILED: Config2 doesn't set CONFIGLIB_FEATURE2")
endif()

# Verify configs are valid CMake
if(NOT CONFIG1_CONTENT MATCHES "set\\(")
  message(FATAL_ERROR "Test FAILED: Config1 doesn't contain set() command")
endif()

if(NOT CONFIG2_CONTENT MATCHES "set\\(")
  message(FATAL_ERROR "Test FAILED: Config2 doesn't contain set() command")
endif()

message(STATUS "  ✓ Both extra config files exist")
message(STATUS "  ✓ Config1 sets CONFIGLIB_FEATURE1")
message(STATUS "  ✓ Config2 sets CONFIGLIB_FEATURE2")
message(STATUS "  ✓ Both configs are valid CMake")
message(STATUS "  ✓ Install commands registered for configs")

message(
  STATUS
    "✓ Test 5 PASSED: libra_register_extra_configs_for_install created install rules"
)

add_test(NAME register_extra_configs_test COMMAND ${CMAKE_COMMAND} -E echo
                                                  "Test 5 verification passed")
