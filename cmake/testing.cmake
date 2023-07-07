#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#
################################################################################
# Testing Options                                                              #
################################################################################
# This also does enable_testing(), but also configures the
# DartConfiguration.tcl file needed to run tests under valgrind
include(CTest)

set(${PROJECT_NAME}_TEST_PATH ${CMAKE_CURRENT_SOURCE_DIR}/tests)

# Convention: Unit tests end with '-utest.c' or '-utest.cpp'
# Convention: Test harness bits end with '_test.c' or '_test.cpp'
file(GLOB LIBRA_c_utests ${${PROJECT_NAME}_TEST_PATH}/*-utest.c)
file(GLOB LIBRA_c_utest_harness ${${PROJECT_NAME}_TEST_PATH}/*_test.c ${${PROJECT_NAME}_TEST_PATH}/*.h ${${PROJECT_NAME}_TEST_PATH}/*.hpp)
file(GLOB LIBRA_cxx_utests ${${PROJECT_NAME}_TEST_PATH}/*-utest.cpp)
file(GLOB LIBRA_cxx_utest_harness ${${PROJECT_NAME}_TEST_PATH}/*_test.cpp  ${${PROJECT_NAME}_TEST_PATH}/*.hpp)

################################################################################
# Enable a single test                                                         #
################################################################################
function(enable_single_test t)
  # Tests are named the same thing as their source file, sans
  # extension, in the spirit of the Principle of Least Surprise.
  get_filename_component(test_name ${t} NAME_WE)
  get_filename_component(test_file ${t} NAME)

  add_executable(${PROJECT_NAME}-${test_name}
    EXCLUDE_FROM_ALL
    ${LIBRA_c_utest_harness}
    ${LIBRA_cxx_utest_harness}
    ${${PROJECT_NAME}_TEST_PATH}/${test_file}
    )
  add_dependencies(${PROJECT_NAME}-${test_name} ${PROJECT_NAME})
  set_target_properties(${PROJECT_NAME}-${test_name} PROPERTIES LINKER_LANGUAGE CXX)

  # If the project is a C project, then we will probably be casting in the C
  # way, so turn off the  usual compile warnings about this.
  #
  # This will only work with GCC/clang compilers, but that's OK for
  # now, as I'm not doing anything that requires running unit tests
  # on strange platforms requiring more exotic compilers.
  if ("${${PROJECT_NAME}_CHECK_LANGUAGE}" MATCHES "C")
    target_compile_options(${PROJECT_NAME}-${test_name} PUBLIC
      -Wno-old-style-cast
      -Wno-useless-cast)
  endif()

  # Tests depend on the project library (DUH)
  target_link_libraries(${PROJECT_NAME}-${test_name} ${PROJECT_NAME})

  # Tests might depend on headers under <repo root>/tests
  target_include_directories(${PROJECT_NAME}-${test_name} PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
  add_test(${test_name} ${CMAKE_BINARY_DIR}/bin/${PROJECT_NAME}-${test_name})

  # Target for building all unit tests
  if (NOT TARGET unit-tests)
    add_custom_target(unit-tests)
  endif()

  # Target for building and running all unit tests
  if (NOT TARGET build-and-test)
    add_custom_target(build-and-test COMMAND ${CMAKE_CTEST_COMMAND})
  endif()

  # Add to global "unit-tests" target
  add_dependencies(unit-tests ${PROJECT_NAME}-${test_name})

  # Add to global "build-and-test" target to build library+run unit tests
  add_dependencies(build-and-test ${PROJECT_NAME}-${test_name})
endfunction()


# Add each test in tests/ under the current project one at a time.
foreach(t ${LIBRA_c_utests} ${LIBRA_cxx_utests})
  string(FIND ${t} ".#" position)
  if(NOT "${position}" MATCHES "-1")
    continue()
  endif()

  enable_single_test(${t})
endforeach()
