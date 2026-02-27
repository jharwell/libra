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

set(_LIBRA_TEST_EXTENSIONS
    c
    cpp
    bats
    py
    sh)
# ##############################################################################
# Test sources
# ##############################################################################
set(${PROJECT_NAME}_TEST_PATH ${CMAKE_CURRENT_SOURCE_DIR}/tests)

# Matcher variables: set in project-local.cmake to encode the project's
# file-naming convention.  Non-cache: they are a structural property of the
# project, not a per-build knob.  All guards use if(NOT DEFINED ...) so that
# any project-local value, including an unusual one, is always respected.
if(NOT DEFINED LIBRA_UNIT_TEST_MATCHER)
  set(LIBRA_UNIT_TEST_MATCHER ${LIBRA_UNIT_TEST_MATCHER_DEFAULT})
endif()

if(NOT DEFINED LIBRA_INTEGRATION_TEST_MATCHER)
  set(LIBRA_INTEGRATION_TEST_MATCHER ${LIBRA_INTEGRATION_TEST_MATCHER_DEFAULT})
endif()

if(NOT DEFINED LIBRA_REGRESSION_TEST_MATCHER)
  set(LIBRA_REGRESSION_TEST_MATCHER ${LIBRA_REGRESSION_TEST_MATCHER_DEFAULT})
endif()

if(NOT DEFINED LIBRA_TEST_HARNESS_MATCHER)
  set(LIBRA_TEST_HARNESS_MATCHER ${LIBRA_TEST_HARNESS_MATCHER_DEFAULT})
endif()

# ##############################################################################
# Extension classification
# ##############################################################################
# Extensions that go through add_executable/linking. Hardcoded for now.
set(LIBRA_COMPILED_EXTENSIONS c cpp)

# Map interpreted extensions to their interpreter executable.
set(_LIBRA_INTERPRETER_bats "bats")
set(_LIBRA_INTERPRETER_py "python3")
set(_LIBRA_INTERPRETER_sh "bash")

# ##############################################################################
# Glob for all test sources across all extensions and test types
# ##############################################################################
foreach(ext ${_LIBRA_TEST_EXTENSIONS})
  file(GLOB_RECURSE LIBRA_${ext}_utests
       ${${PROJECT_NAME}_TEST_PATH}/*${LIBRA_UNIT_TEST_MATCHER}.${ext})
  file(GLOB_RECURSE LIBRA_${ext}_itests
       ${${PROJECT_NAME}_TEST_PATH}/*${LIBRA_INTEGRATION_TEST_MATCHER}.${ext})
  file(GLOB_RECURSE LIBRA_${ext}_rtests
       ${${PROJECT_NAME}_TEST_PATH}/*${LIBRA_REGRESSION_TEST_MATCHER}.${ext})
endforeach()

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
# Enable a single compiled test (C/C++)
# ##############################################################################
function(enable_single_compiled_test t UMBRELLA_TARGET INCLUDE_IN_CTEST)
  # Tests are named the same thing as their source file, sans extension, in the
  # spirit of the Principle of Least Surprise.
  get_filename_component(test_name ${t} NAME_WE)
  get_filename_component(test_file ${t} NAME)

  # Define the test executable
  add_executable(${PROJECT_NAME}-${test_name} EXCLUDE_FROM_ALL ${t})
  _libra_configure_standard(${PROJECT_NAME}-${test_name})
  set_target_properties(${PROJECT_NAME}-${test_name} PROPERTIES LINKER_LANGUAGE
                                                                CXX)

  # Tests depend on the test harness
  add_dependencies(${PROJECT_NAME}-${test_name} ${PROJECT_NAME}
                   ${LIBRA_test_harness})

  # Tests depend on the project library (DUH)
  target_link_libraries(${PROJECT_NAME}-${test_name} ${PROJECT_NAME}
                        ${LIBRA_test_harness} ${LIBRA_TEST_HARNESS_LIBS})

  # If the project is a C project, then we will probably be casting in the C
  # way, so turn off the usual compile warnings about this.
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
             ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${PROJECT_NAME}-${test_name})
    # Set target properties:
    #
    # * Propagate BLESS through to the interpreter if set on the ctest
    #   invocation
    #
    # * Add the {unit,regression,integration} label for more convenient ctest
    #   usage.
    #
    # Derive label from umbrella target name: "unit-tests" -> "unit"
    string(REPLACE "-tests" "" test_label ${UMBRELLA_TARGET})
    set_tests_properties(${test_name} PROPERTIES LABELS ${test_label}
                                                 ENVIRONMENT "BLESS=${BLESS}")

  endif()

  # Add to global umbrella target
  add_dependencies(${UMBRELLA_TARGET} ${PROJECT_NAME}-${test_name})

  # Add to global "build-and-test" target to build library+test harness+unit
  # tests and then run the unit tests
  add_dependencies(build-and-test ${PROJECT_NAME}-${test_name})
endfunction()

# ##############################################################################
# Enable a single interpreted test (BATS, Python, shell, etc.)
# ##############################################################################
function(enable_single_interpreted_test t UMBRELLA_TARGET INCLUDE_IN_CTEST)
  get_filename_component(test_name ${t} NAME_WE)
  get_filename_component(test_ext ${t} EXT)

  # Strip the leading dot from the extension to get the key
  string(SUBSTRING ${test_ext} 1 -1 ext_key)

  # Look up the interpreter for this extension
  if(NOT DEFINED _LIBRA_INTERPRETER_${ext_key})
    libra_message(
      WARNING
      "No interpreter registered for extension '${ext_key}' (file: ${t}) -- skipping"
    )
    return()
  endif()

  find_program(_LIBRA_INTERP_${ext_key}_EXE ${_LIBRA_INTERPRETER_${ext_key}})
  if(NOT _LIBRA_INTERP_${ext_key}_EXE)
    string(CONCAT _msg "Interpreter '${_LIBRA_INTERPRETER_${ext_key}}' for "
                  "extension '${ext_key}' not found -- skipping ${test_name}")
    libra_message(WARNING "${_msg}")
    return()
  endif()

  # Interpreted tests have nothing to compile, so register with ctest directly.
  if(INCLUDE_IN_CTEST)
    add_test(
      NAME ${test_name}
      COMMAND ${_LIBRA_INTERP_${ext_key}_EXE} ${t}
      WORKING_DIRECTORY ${${PROJECT_NAME}_TEST_PATH})

    # Set target properties:
    #
    # * Propagate BLESS through to the interpreter if set on the ctest
    #   invocation
    #
    # * Add the {unit,regression,integration} label for more convenient ctest
    #   usage.
    #
    # Derive label from umbrella target name: "unit-tests" -> "unit"
    string(REPLACE "-tests" "" test_label ${UMBRELLA_TARGET})
    set_tests_properties(${test_name} PROPERTIES LABELS ${test_label}
                                                 ENVIRONMENT "BLESS=${BLESS}")

  endif()

  # No-op target — named handle for build-and-test only
  add_custom_target(${PROJECT_NAME}-${test_name})

  # NOT added to umbrella (unit-tests/integration-tests/regression-tests) since
  # there's nothing to build -- only build-and-test runs them via ctest
  add_dependencies(build-and-test ${PROJECT_NAME}-${test_name})
endfunction()

# ##############################################################################
# Dispatch: compiled vs interpreted
# ##############################################################################
function(dispatch_enable_single_test t UMBRELLA_TARGET INCLUDE_IN_CTEST)
  get_filename_component(test_ext ${t} EXT)
  string(SUBSTRING ${test_ext} 1 -1 ext_key)

  if(ext_key IN_LIST LIBRA_COMPILED_EXTENSIONS)
    enable_single_compiled_test(${t} ${UMBRELLA_TARGET} ${INCLUDE_IN_CTEST})
  else()
    enable_single_interpreted_test(${t} ${UMBRELLA_TARGET} ${INCLUDE_IN_CTEST})
  endif()
endfunction()

# ##############################################################################
# Configure test harness (C/C++ only)
# ##############################################################################
function(configure_test_harness)
  foreach(pkg ${LIBRA_TEST_HARNESS_PACKAGES})
    find_package(${pkg} CONFIG REQUIRED)
  endforeach()

  if(NOT TARGET ${PROJECT_NAME}-c-harness AND "${LIBRA_HAVE_c_test_harness}"
                                              MATCHES "YES")
    add_library(${PROJECT_NAME}-c-harness STATIC EXCLUDE_FROM_ALL
                ${LIBRA_c_test_harness})
    _libra_configure_standard(${PROJECT_NAME}-c-harness)

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
    _libra_configure_standard(${PROJECT_NAME}-cxx-harness)

    set_target_properties(${PROJECT_NAME}-cxx-harness PROPERTIES LINKER_LANGUAGE
                                                                 CXX)

    # Harness might depend on headers under <repo root>/tests
    target_include_directories(${PROJECT_NAME}-cxx-harness
                               PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

    # Have to link with the main project to propagate includes, defines, etc.
    target_link_libraries(${PROJECT_NAME}-cxx-harness ${PROJECT_NAME}
                          ${LIBRA_TEST_HARNESS_LIBS})

    # If the project is a C project, then we will probably be casting in the C
    # way, so turn off the usual compile warnings about this.
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
# Basic test setup
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

# ##############################################################################
# Register all tests across all extensions
# ##############################################################################

# Unit tests
set(num_utests_total 0)
foreach(ext ${_LIBRA_TEST_EXTENSIONS})
  foreach(t ${LIBRA_${ext}_utests})
    string(FIND ${t} ".#" position)
    if(NOT "${position}" MATCHES "-1")
      continue()
    endif()

    dispatch_enable_single_test(${t} unit-tests
                                ${LIBRA_CTEST_INCLUDE_UNIT_TESTS})
  endforeach()

  list(LENGTH LIBRA_${ext}_utests num_ext_utests)
  math(EXPR num_utests_total "${num_utests_total} + ${num_ext_utests}")
  if(num_ext_utests GREATER 0)
    libra_message(STATUS "Registered ${num_ext_utests} .${ext} unit tests")
  endif()
endforeach()
libra_message(STATUS "Registered ${num_utests_total} unit tests total")

# Integration tests
set(num_itests_total 0)
foreach(ext ${_LIBRA_TEST_EXTENSIONS})
  foreach(t ${LIBRA_${ext}_itests})
    string(FIND ${t} ".#" position)
    if(NOT "${position}" MATCHES "-1")
      continue()
    endif()

    dispatch_enable_single_test(${t} integration-tests
                                ${LIBRA_CTEST_INCLUDE_INTEGRATION_TESTS})
  endforeach()

  list(LENGTH LIBRA_${ext}_itests num_ext_itests)
  math(EXPR num_itests_total "${num_itests_total} + ${num_ext_itests}")
  if(num_ext_itests GREATER 0)
    libra_message(STATUS
                  "Registered ${num_ext_itests} .${ext} integration tests")
  endif()
endforeach()
libra_message(STATUS "Registered ${num_itests_total} integration tests total")

# Regression tests
set(num_rtests_total 0)
foreach(ext ${_LIBRA_TEST_EXTENSIONS})
  foreach(t ${LIBRA_${ext}_rtests})
    string(FIND ${t} ".#" position)
    if(NOT "${position}" MATCHES "-1")
      continue()
    endif()

    dispatch_enable_single_test(${t} regression-tests
                                ${LIBRA_CTEST_INCLUDE_REGRESSION_TESTS})
  endforeach()

  list(LENGTH LIBRA_${ext}_rtests num_ext_rtests)
  math(EXPR num_rtests_total "${num_rtests_total} + ${num_ext_rtests}")
  if(num_ext_rtests GREATER 0)
    libra_message(STATUS
                  "Registered ${num_ext_rtests} .${ext} regression tests")
  endif()
endforeach()
libra_message(STATUS "Registered ${num_rtests_total} regression tests total")
