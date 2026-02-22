cmake_minimum_required(VERSION 3.30 FATAL_ERROR)
project(LibraSmokeTests NONE)

# LIBRA source root is one level above this file
set(LIBRA_SOURCE_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/..")
set(CMAKE_MODULE_PATH "${LIBRA_SOURCE_ROOT}/cmake")
message(STATUS "CMAKE_MODULE_PATH: ${CMAKE_MODULE_PATH}")

enable_testing()

# ##############################################################################
# CMake Function Tests
#
# These invoke cmake directly on each sample project to verify that LIBRA's
# CMake API functions work correctly.  Each sample now uses libra_consume.cmake
# so we must pass -DLIBRA_SOURCE_ROOT to provide the in_situ fallback path.
# ##############################################################################

# Common args passed to every sample cmake invocation
set(SAMPLE_CMAKE_ARGS -DLIBRA_SOURCE_ROOT=${LIBRA_SOURCE_ROOT})

add_test(NAME libra.sample_basic
         COMMAND ${CMAKE_COMMAND} -S ${CMAKE_CURRENT_LIST_DIR}/sample_basic -B
                 ${CMAKE_BINARY_DIR}/sample_basic ${SAMPLE_CMAKE_ARGS})

add_test(NAME libra.sample_keywords
         COMMAND ${CMAKE_COMMAND} -S ${CMAKE_CURRENT_LIST_DIR}/sample_keywords
                 -B ${CMAKE_BINARY_DIR}/sample_keywords ${SAMPLE_CMAKE_ARGS})

add_test(NAME libra.sample_export
         COMMAND ${CMAKE_COMMAND} -S ${CMAKE_CURRENT_LIST_DIR}/sample_export -B
                 ${CMAKE_BINARY_DIR}/sample_export ${SAMPLE_CMAKE_ARGS})

add_test(NAME libra.sample_consumer
         COMMAND ${CMAKE_COMMAND} -S ${CMAKE_CURRENT_LIST_DIR}/sample_consumer
                 -B ${CMAKE_BINARY_DIR}/sample_consumer ${SAMPLE_CMAKE_ARGS})

add_test(
  NAME libra.error.missing_name
  COMMAND
    ${CMAKE_COMMAND} -S ${CMAKE_CURRENT_LIST_DIR}/sample_errors/missing_name -B
    ${CMAKE_BINARY_DIR}/err_missing_name ${SAMPLE_CMAKE_ARGS})
set_tests_properties(libra.error.missing_name PROPERTIES WILL_FAIL TRUE)

add_test(
  NAME libra.error.bad_target
  COMMAND
    ${CMAKE_COMMAND} -S ${CMAKE_CURRENT_LIST_DIR}/sample_errors/bad_target -B
    ${CMAKE_BINARY_DIR}/err_bad_target ${SAMPLE_CMAKE_ARGS})
set_tests_properties(libra.error.bad_target PROPERTIES WILL_FAIL TRUE)
