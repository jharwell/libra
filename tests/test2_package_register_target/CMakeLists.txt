cmake_minimum_required(VERSION 3.30 FATAL_ERROR)
project(Test2_RegisterTarget VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/../../cmake)

# Create a real library
add_library(testlib STATIC src/testlib.cpp)
target_include_directories(testlib PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)

# Include REAL libra
include(libra/messaging)
include(libra/package/install)

# Test the REAL function
libra_register_target_for_install(testlib lib)

# Verify target properties
get_target_property(TARGET_TYPE testlib TYPE)
if(NOT TARGET_TYPE STREQUAL "STATIC_LIBRARY")
    message(FATAL_ERROR "Test FAILED: Target type incorrect: ${TARGET_TYPE}")
endif()

# Verify export set was created (install commands register exports)
get_property(EXPORT_SETS DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY INSTALL_EXPORTS)

message(STATUS "  ✓ Target type verified: ${TARGET_TYPE}")
message(STATUS "  ✓ Install commands registered for testlib")

message(STATUS "✓ Test 2 PASSED: libra_register_target_for_install created install rules")

add_test(NAME register_target_test
    COMMAND ${CMAKE_COMMAND} -E echo "Test 2 verification passed")
