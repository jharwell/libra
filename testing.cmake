################################################################################
# Testing Options                                                              #
################################################################################
enable_testing()

# There is a global unit_tests target, as well as per-project/module variants
# which only build the tests found in the subproject/module.
if (NOT TARGET unit_tests)
  add_custom_target(unit_tests)
endif()
if (NOT TARGET ${current_proj_name}-unit_tests)
  add_custom_target(${current_proj_name}-unit_tests)
endif()

if (NOT TARGET build_and_test)
  add_custom_target(build_and_test ${CMAKE_TEST_COMMAND} -V)
endif()

if (NOT TARGET ${current_proj_name}-build_and_test)
  add_custom_target(${current_proj_name}-build_and_test ${CMAKE_TEST_COMMAND} -V)
endif()

# Add each test in tests/ under the current project (not just the root projec)
# one at a time.
foreach(t ${c_tests} ${cxx_tests})
  string(FIND ${t} ".#" position)
  if(NOT "${position}" MATCHES "-1")
    continue()
  endif()

  # Tests are named the same thing as their source file, sans extension.
  get_filename_component(test_name ${t} NAME_WE)
  get_filename_component(test_file ${t} NAME)

  # We may be a module in a larger project, and another dependent module might
  # already have added our tests.
  if (TARGET ${current_proj_name}-${test_name})
    continue()
  endif()

  add_executable(${current_proj_name}-${test_name} EXCLUDE_FROM_ALL ${c_test_harness} ${cxx_test_harness} ${${target}_TEST_PATH}/${test_file})
  add_dependencies(${current_proj_name}-${test_name} ${root_target})
  set_target_properties(${current_proj_name}-${test_name} PROPERTIES LINKER_LANGUAGE CXX)

  # Tests might also depend on the special 'tests' submodule in the root
  # project (a library of common test code), so add it as a dependency to the
  # test if it exists.
  if (TARGET ${current_proj_name}-tests)
    target_link_libraries(${current_proj_name}-${test_name}
      ${current_proj_name}-tests
      ${current_proj_name}
      )
  else()
    target_link_libraries(${current_proj_name}-${test_name}
      ${current_proj_name}
      )
  endif()

  # Add dependencies on the global unit_tests target, which will build ALL
  # unit tests known to cmake.
  add_dependencies(unit_tests ${current_proj_name}-${test_name})
  add_dependencies(${current_proj_name}-unit_tests ${current_proj_name}-${test_name})

  add_test(${test_name} ${CMAKE_BINARY_DIR}/bin/${current_proj_name}-${test_name})

  # Add dependencies on the subproject/module unit_tests target, which will
  # only build the unit tests for that subproject/module.
  add_dependencies(build_and_test ${current_proj_name}-${test_name})
  add_dependencies(${current_proj_name}-build_and_test ${current_proj_name}-${test_name})

endforeach()
