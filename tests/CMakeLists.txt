cmake_minimum_required(VERSION 3.30 FATAL_ERROR)
project(LibraPackageTests NONE)

# Point to real libra
set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/../cmake)
message("CMAKE_MODULE_PATH: ${CMAKE_MODULE_PATH}")
enable_testing()

message(STATUS "========================================")
message(STATUS "LIBRA Package Function Tests")
message(STATUS "Testing with REAL CMake projects (no mocking)")
message(STATUS "========================================")

# Each test is a separate CMake project
add_subdirectory(test1_package_configure_exports)
add_subdirectory(test2_package_register_target)
add_subdirectory(test3_package_register_headers)
add_subdirectory(test4_package_register_copyright)
add_subdirectory(test5_package_register_extra_configs)
add_subdirectory(test6_package_requested_components)

message(STATUS "========================================")
message(STATUS "Configured 6 tests for libra/package/ functions")
message(STATUS "========================================")
