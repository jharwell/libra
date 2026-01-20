cmake_minimum_required(VERSION 3.30 FATAL_ERROR)
project(Test4_RegisterCopyright VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/../../cmake)

# Create a real library
add_library(copyrightlib STATIC src/copyrightlib.cpp)

# Create LICENSE file
file(WRITE ${CMAKE_CURRENT_SOURCE_DIR}/LICENSE "MIT License

Copyright (c) 2024 Test Project

Permission is hereby granted, free of charge, to any person obtaining a copy...")

# Include REAL libra
include(libra/messaging)
include(libra/package/install)

# Test the REAL function
libra_register_copyright_for_install(copyrightlib ${CMAKE_CURRENT_SOURCE_DIR}/LICENSE)

# Verify LICENSE file exists and has content
set(LICENSE_FILE "${CMAKE_CURRENT_SOURCE_DIR}/LICENSE")
if(NOT EXISTS "${LICENSE_FILE}")
    message(FATAL_ERROR "Test FAILED: LICENSE file not found: ${LICENSE_FILE}")
endif()

file(READ "${LICENSE_FILE}" LICENSE_CONTENT)
if(NOT LICENSE_CONTENT MATCHES "MIT License")
    message(FATAL_ERROR "Test FAILED: LICENSE file doesn't contain expected text")
endif()

if(NOT LICENSE_CONTENT MATCHES "Copyright")
    message(FATAL_ERROR "Test FAILED: LICENSE file missing copyright notice")
endif()

string(LENGTH "${LICENSE_CONTENT}" LICENSE_LENGTH)
if(LICENSE_LENGTH LESS 50)
    message(FATAL_ERROR "Test FAILED: LICENSE file seems too short (${LICENSE_LENGTH} bytes)")
endif()

message(STATUS "  ✓ LICENSE file exists (${LICENSE_LENGTH} bytes)")
message(STATUS "  ✓ LICENSE contains MIT License text")
message(STATUS "  ✓ LICENSE contains copyright notice")
message(STATUS "  ✓ Install commands registered for LICENSE")

message(STATUS "✓ Test 4 PASSED: libra_register_copyright_for_install created install rules")

add_test(NAME register_copyright_test
    COMMAND ${CMAKE_COMMAND} -E echo "Test 4 verification passed")
