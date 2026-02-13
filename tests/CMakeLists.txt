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

if(NOT BATS_EXECUTABLE)
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
# CMake Function Tests
# ##############################################################################
enable_testing()

add_test(NAME libra.sample_basic
         COMMAND ${CMAKE_COMMAND} -S ${CMAKE_CURRENT_LIST_DIR}/sample_basic -B
                 ${CMAKE_BINARY_DIR}/sample_basic)

add_test(NAME libra.sample_keywords
         COMMAND ${CMAKE_COMMAND} -S ${CMAKE_CURRENT_LIST_DIR}/sample_keywords
                 -B ${CMAKE_BINARY_DIR}/sample_keywords)

add_test(NAME libra.sample_export
         COMMAND ${CMAKE_COMMAND} -S ${CMAKE_CURRENT_LIST_DIR}/sample_export -B
                 ${CMAKE_BINARY_DIR}/sample_export)

add_test(NAME libra.sample_consumer
         COMMAND ${CMAKE_COMMAND} -S ${CMAKE_CURRENT_LIST_DIR}/sample_consumer
                 -B ${CMAKE_BINARY_DIR}/sample_consumer)

add_test(
  NAME libra.error.missing_name
  COMMAND
    ${CMAKE_COMMAND} -S ${CMAKE_CURRENT_LIST_DIR}/sample_errors/missing_name -B
    ${CMAKE_BINARY_DIR}/err_missing_name)
set_tests_properties(libra.error.missing_name PROPERTIES WILL_FAIL TRUE)

add_test(
  NAME libra.error.bad_target
  COMMAND
    ${CMAKE_COMMAND} -S ${CMAKE_CURRENT_LIST_DIR}/sample_errors/bad_target -B
    ${CMAKE_BINARY_DIR}/err_bad_target)
set_tests_properties(libra.error.bad_target PROPERTIES WILL_FAIL TRUE)
