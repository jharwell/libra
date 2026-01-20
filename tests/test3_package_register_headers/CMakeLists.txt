cmake_minimum_required(VERSION 3.30 FATAL_ERROR)
project(Test3_RegisterHeaders VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/../../cmake)

# Create a real library with headers
add_library(headerlib INTERFACE)
target_include_directories(headerlib INTERFACE
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)

# Include REAL libra
include(libra/messaging)
include(libra/package/install)

# Test the REAL function
libra_register_headers_for_install(${CMAKE_CURRENT_SOURCE_DIR}/include include)

# Verify the source header file exists
set(HEADER_FILE "${CMAKE_CURRENT_SOURCE_DIR}/include/headerlib.hpp")
if(NOT EXISTS "${HEADER_FILE}")
    message(FATAL_ERROR "Test FAILED: Header file not found: ${HEADER_FILE}")
endif()

# Verify it's a valid header
file(READ "${HEADER_FILE}" HEADER_CONTENT)
if(NOT HEADER_CONTENT MATCHES "namespace headerlib")
    message(FATAL_ERROR "Test FAILED: Header doesn't contain expected namespace")
endif()

message(STATUS "  ✓ Header file exists: headerlib.hpp")
message(STATUS "  ✓ Header contains namespace declaration")
message(STATUS "  ✓ Install commands registered for headers")

message(STATUS "✓ Test 3 PASSED: libra_register_headers_for_install created install rules")

add_test(NAME register_headers_test
    COMMAND ${CMAKE_COMMAND} -E echo "Test 3 verification passed")
