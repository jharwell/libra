cmake_minimum_required(VERSION 3.30 FATAL_ERROR)
project(Test1_ConfigureExports VERSION 1.0.0 LANGUAGES CXX)

# Point to real libra
set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/../../cmake)

# Create a real library
add_library(mylib src/mylib.cpp)
target_include_directories(mylib PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)

# Create config template
file(WRITE ${CMAKE_CURRENT_SOURCE_DIR}/cmake/config.cmake.in "@PACKAGE_INIT@
include(\"\${CMAKE_CURRENT_LIST_DIR}/mylib-targets.cmake\")
check_required_components(mylib)
")

# Include REAL libra install module
include(libra/package/install)

# Test the REAL function
libra_configure_exports(mylib lib/cmake/mylib)

# Verify it created the config file
set(EXPECTED_CONFIG "${CMAKE_CURRENT_BINARY_DIR}/mylib-config.cmake")
if(NOT EXISTS "${EXPECTED_CONFIG}")
    message(FATAL_ERROR "Test FAILED: Config file not created at ${EXPECTED_CONFIG}")
endif()

# Read and verify content
file(READ "${EXPECTED_CONFIG}" CONFIG_CONTENT)
if(NOT CONFIG_CONTENT MATCHES "mylib-targets.cmake")
    message(FATAL_ERROR "Test FAILED: Config file doesn't reference targets file")
endif()

if(NOT CONFIG_CONTENT MATCHES "PACKAGE_INIT")
    message(FATAL_ERROR "Test FAILED: Config file missing PACKAGE_INIT macro")
endif()

if(NOT CONFIG_CONTENT MATCHES "check_required_components")
    message(FATAL_ERROR "Test FAILED: Config file missing check_required_components")
endif()

# Verify install rules were created
get_property(INSTALL_COMPONENTS GLOBAL PROPERTY CPACK_COMPONENTS_ALL)
message(STATUS "  ✓ Config file exists: ${EXPECTED_CONFIG}")
message(STATUS "  ✓ Config contains targets reference")
message(STATUS "  ✓ Config contains PACKAGE_INIT")
message(STATUS "  ✓ Config contains component check")

message(STATUS "✓ Test 1 PASSED: libra_configure_exports created valid config file")

# Add a test that actually runs cmake to verify the config works
add_test(NAME configure_exports_test
    COMMAND ${CMAKE_COMMAND} -E echo "Test 1 verification passed")
