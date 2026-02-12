cmake_minimum_required(VERSION 3.30 FATAL_ERROR)
project(LibraPackageTests NONE)

# Point to real libra
set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/../cmake)
message("CMAKE_MODULE_PATH: ${CMAKE_MODULE_PATH}")
enable_testing()

# ##############################################################################
# BATS Tests (New Framework)
# ##############################################################################

find_program(BATS_EXECUTABLE bats)

if(BATS_EXECUTABLE)
  message(STATUS "Found BATS: ${BATS_EXECUTABLE}")

  # Discover all .bats files
  message("${CMAKE_CURRENT_LIST_DIR}")
  file(GLOB BATS_TEST_FILES "${CMAKE_CURRENT_LIST_DIR}/*.bats")

  foreach(bats_file ${BATS_TEST_FILES})
    get_filename_component(test_name ${bats_file} NAME_WE)

    # Add single test (uses default compiler: gnu)
    add_test(
      NAME bats-${test_name}
      COMMAND ${BATS_EXECUTABLE} ${bats_file}
      WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR})

    # Set test properties
    set_tests_properties(bats-${test_name} PROPERTIES TIMEOUT 300 LABELS "bats")

    # Run each BATS test with gnu, clang, and intel compilers foreach(compiler
    # gnu clang intel) add_test( NAME bats-${test_name}-${compiler} COMMAND
    # ${BATS_EXECUTABLE} ${bats_file} WORKING_DIRECTORY
    # ${CMAKE_CURRENT_LIST_DIR}) set_tests_properties(
    # bats-${test_name}-${compiler} PROPERTIES ENVIRONMENT
    # "COMPILER_TYPE=${compiler}" TIMEOUT 300 LABELS "bats;${compiler}")
    # endforeach()
  endforeach()

  message(STATUS "Registered ${CMAKE_MATCH_COUNT} BATS test files")
else()
  message(WARNING "BATS not found - BATS tests will not be available")
  message(WARNING "Install BATS: https://github.com/bats-core/bats-core")
endif()

# ##############################################################################
# CMake Package Tests
# ##############################################################################

# Each function test is a separate CMake project
add_subdirectory(test1_package_configure_exports)
add_subdirectory(test2_package_register_target)
add_subdirectory(test3_package_register_headers)
add_subdirectory(test4_package_register_copyright)
add_subdirectory(test5_package_register_extra_configs)
add_subdirectory(test6_package_requested_components)

# ##############################################################################
# Test Organization
# ##############################################################################

# Print test summary
message(STATUS "")
message(STATUS "Test Summary:")
message(STATUS "  BATS tests: ${CMAKE_MATCH_COUNT} files")
message(STATUS "  Legacy shell tests: 19 features")
message(STATUS "  Package tests: 6 subdirectories")
message(STATUS "")
message(STATUS "Run tests with:")
message(STATUS "  ctest                    # All tests")
message(STATUS "  ctest -L bats           # BATS tests only")
message(STATUS "  ctest -L optimization   # Optimization tests")
message(STATUS "  ctest -R LIBRA_FPC      # Specific feature")
message(STATUS "")
