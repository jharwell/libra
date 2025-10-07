#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#
# ##############################################################################
# Testing Options
# ##############################################################################
# This also does enable_testing(), but also configures the DartConfiguration.tcl
# file needed to run tests under valgrind
include(CTest)

include(libra/messaging)
include(libra/defaults)

# ##############################################################################
# Test sources
# ##############################################################################
set(${PROJECT_NAME}_TEST_PATH ${CMAKE_CURRENT_SOURCE_DIR}/tests)

# Convention: Unit tests end with '-utest.c' or '-utest.cpp' unless otherwise
# specified.
if(NOT LIBRA_UNIT_TEST_MATCHER)
  set(LIBRA_UNIT_TEST_MATCHER ${LIBRA_UNIT_TEST_MATCHER_DEFAULT})
endif()

if(NOT LIBRA_CTEST_INCLUDE_UNIT_TESTS)
  set(LIBRA_CTEST_INCLUDE_UNIT_TESTS ${LIBRA_CTEST_INCLUDE_UNIT_TESTS_DEFAULT})
endif()

# Convention: Integration tests end with '-itest.c' or '-itest.cpp' unless
# otherwise specified
if(NOT LIBRA_INTEGRATION_TEST_MATCHER)
  set(LIBRA_INTEGRATION_TEST_MATCHER ${LIBRA_INTEGRATION_TEST_MATCHER_DEFAULT})
endif()

if(NOT LIBRA_CTEST_INCLUDE_INTEGRATION_TESTS)
  set(LIBRA_TEST_INCLUDE_INTEGRATION_TESTS
      ${LIBRA_CTEST_INCLUDE_INTEGRATION_TESTS_DEFAULT})
endif()

# Convention: Regression tests end with '-rtest.c' or '-rtest.cpp' unless
# otherwise specified
if(NOT LIBRA_REGRESSION_TEST_MATCHER)
  set(LIBRA_REGRESSION_TEST_MATCHER ${LIBRA_REGRESSION_TEST_MATCHER_DEFAULT})
endif()

if(NOT LIBRA_CTEST_INCLUDE_REGRESSION_TESTS)
  set(LIBRA_TEST_INCLUDE_REGRESSION_TESTS
      ${LIBRA_CTEST_INCLUDE_REGRESSION_TESTS_DEFAULT})
endif()

# Convention: Test harness bits end with '_test.c' or '_test.cpp' unless
# otherwise specified.
if(NOT LIBRA_TEST_HARNESS_MATCHER)
  set(LIBRA_TEST_HARNESS_MATCHER ${LIBRA_TEST_HARNESS_MATCHER_DEFAULT})
endif()

file(GLOB_RECURSE LIBRA_c_utests
     ${${PROJECT_NAME}_TEST_PATH}/*${LIBRA_UNIT_TEST_MATCHER}.c)
file(GLOB_RECURSE LIBRA_c_itests
     ${${PROJECT_NAME}_TEST_PATH}/*${LIBRA_INTEGRATION_TEST_MATCHER}.c)
file(GLOB_RECURSE LIBRA_c_rtests
     ${${PROJECT_NAME}_TEST_PATH}/*${LIBRA_REGRESSION_TEST_MATCHER}.c)
file(GLOB_RECURSE LIBRA_cxx_utests
     ${${PROJECT_NAME}_TEST_PATH}/*${LIBRA_UNIT_TEST_MATCHER}.cpp)
file(GLOB_RECURSE LIBRA_cxx_itests
     ${${PROJECT_NAME}_TEST_PATH}/*${LIBRA_INTEGRATION_TEST_MATCHER}.cpp)
file(GLOB_RECURSE LIBRA_cxx_rtests
     ${${PROJECT_NAME}_TEST_PATH}/*${LIBRA_REGRESSION_TEST_MATCHER}.cpp)

file(GLOB_RECURSE LIBRA_c_test_harness
     ${${PROJECT_NAME}_TEST_PATH}/*${LIBRA_TEST_HARNESS_MATCHER}.c
     ${${PROJECT_NAME}_TEST_PATH}/*${LIBRA_TEST_HARNESS_MATCHER}.h)

file(GLOB_RECURSE LIBRA_cxx_test_harness
     ${${PROJECT_NAME}_TEST_PATH}/*${LIBRA_TEST_HARNESS_MATCHER}.cpp
     ${${PROJECT_NAME}_TEST_PATH}/*${LIBRA_TEST_HARNESS_MATCHER}.hpp)

set(LIBRA_test_harness)

if(LIBRA_cxx_test_harness)
  set(LIBRA_HAVE_cxx_test_harness YES)
  set(LIBRA_test_harness "${LIBRA_test_harness};${PROJECT_NAME}-cxx-harness")
endif()

if(LIBRA_c_test_harness)
  set(LIBRA_HAVE_c_test_harness YES)
  set(LIBRA_test_harness "${LIBRA_test_harness};${PROJECT_NAME}-c-harness")
endif()

# ##############################################################################
# Enable a single test
# ##############################################################################
function(enable_single_test t UMBRELLA_TARGET INCLUDE_IN_CTEST)
  # Tests are named the same thing as their source file, sans extension, in the
  # spirit of the Principle of Least Surprise.
  get_filename_component(test_name ${t} NAME_WE)
  get_filename_component(test_file ${t} NAME)

  # Define the test executable
  add_executable(${PROJECT_NAME}-${test_name} EXCLUDE_FROM_ALL ${t})
  set_target_properties(${PROJECT_NAME}-${test_name} PROPERTIES LINKER_LANGUAGE
                                                                CXX)

  # Tests depend on the test harness
  add_dependencies(${PROJECT_NAME}-${test_name} ${PROJECT_NAME}
                   ${LIBRA_test_harness})

  # Tests depend on the project library (DUH)
  target_link_libraries(${PROJECT_NAME}-${test_name} ${PROJECT_NAME}
                        ${LIBRA_test_harness} ${LIBRA_TEST_HARNESS_LIBS})

  # If the project is a C project, then we will probably be casting in the C
  # way, so turn off the  usual compile warnings about this.
  #
  # This will only work with GCC/clang compilers, but that's OK for now, as I'm
  # not doing anything that requires running unit tests on strange platforms
  # requiring more exotic compilers.
  if("${${PROJECT_NAME}_ANALYSIS_LANGUAGE}" MATCHES "C")
    target_compile_options(${PROJECT_NAME}-${test_name}
                           PUBLIC -Wno-old-style-cast -Wno-useless-cast)
  endif()

  # Add the test executable to CTest
  if(INCLUDE_IN_CTEST)
    add_test(${test_name}
             ${LIBRA_RUNTIME_OUTPUT_DIRECTORY}/${PROJECT_NAME}-${test_name})
  endif()

  # Add to global umbrella target
  add_dependencies(${UMBRELLA_TARGET} ${PROJECT_NAME}-${test_name})

  # Add to global "build-and-test" target to build library+test harness+unit
  # tests and then run the unit tests
  add_dependencies(build-and-test ${PROJECT_NAME}-${test_name})
endfunction()

# ##############################################################################
# Configure test harness
# ##############################################################################
function(configure_test_harness)
  foreach(pkg ${LIBRA_TEST_HARNESS_PACKAGES})
    find_package(${pkg} CONFIG REQUIRED)
  endforeach()

  if(NOT TARGET ${PROJECT_NAME}-c-harness AND "${LIBRA_HAVE_c_test_harness}"
                                              MATCHES "YES")
    add_library(${PROJECT_NAME}-c-harness STATIC EXCLUDE_FROM_ALL
                ${LIBRA_c_test_harness})
    set_target_properties(${PROJECT_NAME}-c-harness PROPERTIES LINKER_LANGUAGE
                                                               C)
    # Harness might depend on headers under <repo root>/tests
    target_include_directories(${PROJECT_NAME}-c-harness
                               PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

    # Have to link with the main project to propagate includes, defines, etc.
    target_link_libraries(${PROJECT_NAME}-c-harness ${PROJECT_NAME}
                          ${LIBRA_TEST_HARNESS_LIBS})
  endif()

  # Create C++ test harness
  if(NOT TARGET ${PROJECT_NAME}-cxx-harness AND "${LIBRA_HAVE_cxx_test_harness}"
                                                MATCHES "YES")
    add_library(${PROJECT_NAME}-cxx-harness STATIC EXCLUDE_FROM_ALL
                ${LIBRA_cxx_test_harness})
    set_target_properties(${PROJECT_NAME}-cxx-harness PROPERTIES LINKER_LANGUAGE
                                                                 CXX)

    # Harness might depend on headers under <repo root>/tests
    target_include_directories(${PROJECT_NAME}-cxx-harness
                               PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

    # Have to link with the main project to propagate includes, defines, etc.
    target_link_libraries(${PROJECT_NAME}-cxx-harness ${PROJECT_NAME}
                          ${LIBRA_TEST_HARNESS_LIBS})

    # If the project is a C project, then we will probably be casting in the C
    # way, so turn off the  usual compile warnings about this.
    #
    # This will only work with GCC/clang compilers, but that's OK for now, as
    # I'm not doing anything that requires running unit tests on strange
    # platforms requiring more exotic compilers.
    if("${${PROJECT_NAME}_ANALYSIS_LANGUAGE}" MATCHES "C")
      target_compile_options(${PROJECT_NAME}-cxx-harness
                             PUBLIC -Wno-old-style-cast -Wno-useless-cast)
    endif()

  endif()
endfunction()

# ##############################################################################
# Enable all tests
# ##############################################################################
configure_test_harness()

# Target for building and running all tests
add_custom_target(build-and-test COMMAND ${CMAKE_CTEST_COMMAND})

# Target for building all unit tests
add_custom_target(unit-tests)

# Target for building all integration tests
add_custom_target(integration-tests)

# Target for building all regression tests
add_custom_target(regression-tests)

# Target for building all tests
add_custom_target(all-tests)

add_dependencies(all-tests unit-tests integration-tests regression-tests)

# Add each unit test in tests/ under the current project one at a time.
foreach(t ${LIBRA_c_utests} ${LIBRA_cxx_utests})
  string(FIND ${t} ".#" position)
  if(NOT "${position}" MATCHES "-1")
    continue()
  endif()

  enable_single_test(${t} unit-tests ${LIBRA_CTEST_INCLUDE_UNIT_TESTS})
endforeach()

list(LENGTH LIBRA_c_utests num_c_utests)
list(LENGTH LIBRA_cxx_utests num_cxx_utests)
libra_message(STATUS
              "Registered ${num_c_utests}+${num_cxx_utests} C/C++ unit tests")

# Add each integration test in tests/ under the current project one at a time.
foreach(t ${LIBRA_c_itests} ${LIBRA_cxx_itests})
  string(FIND ${t} ".#" position)
  if(NOT "${position}" MATCHES "-1")
    continue()
  endif()

  enable_single_test(${t} integration-tests
                     ${LIBRA_CTEST_INCLUDE_INTEGRATION_TESTS})
endforeach()

list(LENGTH LIBRA_c_itests num_c_itests)
list(LENGTH LIBRA_cxx_itests num_cxx_itests)

libra_message(
  STATUS "Registered ${num_c_itests}+${num_cxx_itests} C/C++ integration tests")

# Add each regression test in tests/ under the current project one at a time.
foreach(t ${LIBRA_c_rtests} ${LIBRA_cxx_rtests})
  string(FIND ${t} ".#" position)
  if(NOT "${position}" MATCHES "-1")
    continue()
  endif()

  enable_single_test(${t} regression-tests
                     ${LIBRA_CTEST_INCLUDE_REGRESSION_TESTS})
endforeach()

list(LENGTH LIBRA_c_rtests num_c_rtests)
list(LENGTH LIBRA_cxx_rtests num_cxx_rtests)

libra_message(
  STATUS "Registered ${num_c_rtests}+${num_cxx_rtests} C/C++ regression tests")
