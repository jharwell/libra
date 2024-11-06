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

# ##############################################################################
# Test sources
# ##############################################################################
set(${PROJECT_NAME}_TEST_PATH ${CMAKE_CURRENT_SOURCE_DIR}/tests)

# Convention: Unit tests end with '-utest.c' or '-utest.cpp' unless otherwise
# specified.
if(NOT LIBRA_UNIT_TEST_MATCHER)
  set(LIBRA_UNIT_TEST_MATCHER -utest)
endif()

# Convention: Integration tests end with '-itest.c' or '-itest.cpp' unless
# otherwise specified
if(NOT LIBRA_INTEGRATION_TEST_MATCHER)
  set(LIBRA_INTEGRATION_TEST_MATCHER -itest)
endif()

# Convention: Test harness bits end with '_test.c' or '_test.cpp' unless
# otherwise specified.
if(NOT LIBRA_TEST_HARNESS_MATCHER)
  set(LIBRA_TEST_HARNESS_MATCHER _test)
endif()

file(GLOB_RECURSE LIBRA_c_utests
     ${${PROJECT_NAME}_TEST_PATH}/*${LIBRA_UNIT_TEST_MATCHER}.c)
file(GLOB_RECURSE LIBRA_c_itests
     ${${PROJECT_NAME}_TEST_PATH}/*${LIBRA_INTEGRATION_TEST_MATCHER}.c)
file(GLOB_RECURSE LIBRA_cxx_utests
     ${${PROJECT_NAME}_TEST_PATH}/*${LIBRA_UNIT_TEST_MATCHER}.cpp)
file(GLOB_RECURSE LIBRA_cxx_itests
     ${${PROJECT_NAME}_TEST_PATH}/*${LIBRA_INTEGRATION_TEST_MATCHER}.cpp)

file(
  GLOB_RECURSE
  LIBRA_c_test_harness
  ${${PROJECT_NAME}_TEST_PATH}/*${LIBRA_TEST_HARNESS_MATCHER}.c
  ${${PROJECT_NAME}_TEST_PATH}/*${LIBRA_TEST_HARNESS_MATCHER}.h
  ${${PROJECT_NAME}_TEST_PATH}/*${LIBRA_TEST_HARNESS_MATCHER}.hpp)

file(GLOB_RECURSE LIBRA_cxx_test_harness
     ${${PROJECT_NAME}_TEST_PATH}/*${LIBRA_TEST_HARNESS_MATCHER}.cpp
     ${${PROJECT_NAME}_TEST_PATH}/*${LIBRA_TEST_HARNESS_MATCHER}.hpp)

set(LIBRA_test_harness)

if(LIBRA_cxx_test_harness)
  set(LIBRA_HAVE_cxx_test_harness YES)
  set(LIBRA_test_harness
      "${LIBRA_test_harness};${PROJECT_NAME}-cxx-utest-harness")
endif()

if(LIBRA_c_test_harness)
  set(LIBRA_HAVE_c_test_harness YES)
  set(LIBRA_test_harness
      "${LIBRA_test_harness};${PROJECT_NAME}-c-utest-harness")
endif()

# ##############################################################################
# Enable a single unit test
# ##############################################################################
function(enable_single_utest t)
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
  if("${${PROJECT_NAME}_CHECK_LANGUAGE}" MATCHES "C")
    target_compile_options(${PROJECT_NAME}-${test_name}
                           PUBLIC -Wno-old-style-cast -Wno-useless-cast)
  endif()

  # Add the test executable to CTest
  add_test(${test_name} ${CMAKE_BINARY_DIR}/bin/${PROJECT_NAME}-${test_name})

  # Add to global "unit-tests" target
  add_dependencies(unit-tests ${PROJECT_NAME}-${test_name})

  # Add to global "build-and-test" target to build library+test harness+unit
  # tests and then run the unit tests
  add_dependencies(build-and-test ${PROJECT_NAME}-${test_name})
endfunction()

# ##############################################################################
# Enable a single integration test
# ##############################################################################
function(enable_single_itest t)
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

  # Tests depend on the project library (DUH), and any specified test harness
  # libraries.
  target_link_libraries(${PROJECT_NAME}-${test_name} ${PROJECT_NAME}
                        ${LIBRA_test_harness} ${LIBRA_TEST_HARNESS_LIBS})

  # If the project is a C project, then we will probably be casting in the C
  # way, so turn off the  usual compile warnings about this.
  #
  # This will only work with GCC/clang compilers, but that's OK for now, as I'm
  # not doing anything that requires running unit tests on strange platforms
  # requiring more exotic compilers.
  if("${${PROJECT_NAME}_CHECK_LANGUAGE}" MATCHES "C")
    target_compile_options(${PROJECT_NAME}-${test_name}
                           PUBLIC -Wno-old-style-cast -Wno-useless-cast)
  endif()

  # Add the test executable to CTest
  add_test(${test_name} ${CMAKE_BINARY_DIR}/bin/${PROJECT_NAME}-${test_name})

  # Add to global "integration-tests" target
  add_dependencies(integration-tests ${PROJECT_NAME}-${test_name})

  # Add to global "build-and-test" target to build library+test harness+unit
  # tests and then run the unit tests
  add_dependencies(build-and-test ${PROJECT_NAME}-${test_name})
endfunction()

# ##############################################################################
# Configure test harness
# ##############################################################################
function(configure_test_harness)
  if(NOT TARGET ${PROJECT_NAME}-c-utest-harness
     AND "${LIBRA_HAVE_c_test_harness}" MATCHES "YES")
    add_library(${PROJECT_NAME}-c-utest-harness STATIC EXCLUDE_FROM_ALL
                ${LIBRA_c_test_harness})

    # Harness might depend on headers under <repo root>/tests
    target_include_directories(${PROJECT_NAME}-c-utest-harness
                               PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

    # Have to link with the main project to propagate includes, defines, etc.
    target_link_libraries(${PROJECT_NAME}-c-utest-harness ${PROJECT_NAME}
                          ${LIBRA_TEST_HARNESS_LIBS})
  endif()

  # Create C++ test harness
  if(NOT TARGET ${PROJECT_NAME}-cxx-utest-harness
     AND "${LIBRA_HAVE_cxx_test_harness}" MATCHES "YES")
    add_library(${PROJECT_NAME}-cxx-utest-harness STATIC EXCLUDE_FROM_ALL
                ${LIBRA_cxx_test_harness})
    # Harness might depend on headers under <repo root>/tests
    target_include_directories(${PROJECT_NAME}-cxx-utest-harness
                               PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

    # Have to link with the main project to propagate includes, defines, etc.
    target_link_libraries(${PROJECT_NAME}-cxx-utest-harness ${PROJECT_NAME}
                          ${LIBRA_TEST_HARNESS_LIBS})

    # If the project is a C project, then we will probably be casting in the C
    # way, so turn off the  usual compile warnings about this.
    #
    # This will only work with GCC/clang compilers, but that's OK for now, as
    # I'm not doing anything that requires running unit tests on strange
    # platforms requiring more exotic compilers.
    if("${${PROJECT_NAME}_CHECK_LANGUAGE}" MATCHES "C")
      target_compile_options(${PROJECT_NAME}-cxx-utest-harness
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

# Target for building all tests
add_custom_target(all-tests)

add_dependencies(all-tests unit-tests integration-tests)

# Add each test in tests/ under the current project one at a time.
foreach(t ${LIBRA_c_utests} ${LIBRA_cxx_utests})
  string(FIND ${t} ".#" position)
  if(NOT "${position}" MATCHES "-1")
    continue()
  endif()

  enable_single_utest(${t})
endforeach()

# Add each test in tests/ under the current project one at a time.
foreach(t ${LIBRA_c_itests} ${LIBRA_cxx_itests})
  string(FIND ${t} ".#" position)
  if(NOT "${position}" MATCHES "-1")
    continue()
  endif()

  enable_single_itest(${t})
endforeach()
