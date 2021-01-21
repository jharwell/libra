################################################################################
# Testing Options                                                              #
################################################################################
enable_testing()

if("${target}" STREQUAL "${root_target}")
  # Add each test in tests/ under the current project one at a time.
  foreach(t ${c_utests} ${cxx_utests})
    string(FIND ${t} ".#" position)
    if(NOT "${position}" MATCHES "-1")
      continue()
    endif()

    # Tests are named the same thing as their source file, sans extension.
    get_filename_component(test_name ${t} NAME_WE)
    get_filename_component(test_file ${t} NAME)

    add_executable(${root_target}-${test_name} EXCLUDE_FROM_ALL ${c_test_harness} ${cxx_test_harness} ${${target}_TEST_PATH}/${test_file})
    add_dependencies(${root_target}-${test_name} ${root_target})
    set_target_properties(${root_target}-${test_name} PROPERTIES LINKER_LANGUAGE CXX)

    # If the project is a C project, then we will probably be casting in the C
    # way, so turn off the  usual compile warnings about this.
    if ("${${root_target}_CHECK_LANGUAGE}" MATCHES "C")
      target_compile_options(${root_target}-${test_name} PUBLIC -Wno-old-style-cast)
    endif()

    # Tests might also depend on the special 'tests' submodule in the root
    # project (common test code), so add it as a dependency to the
    # test if it exists.
    if (TARGET ${root_target}-tests)
      add_dependencies(${root_target}-${test_name} ${root_target}-tests)
      target_link_libraries(${root_target}-${test_name}
        ${root_target}-tests
        ${root_target}
        )
    else()
      target_link_libraries(${root_target}-${test_name}
        ${root_target}
        )
    endif()
    target_include_directories(${root_target}-${test_name} PUBLIC "${${target}_INCLUDE_DIRS}")

    add_test(${test_name} ${CMAKE_BINARY_DIR}/bin/${root_target}-${test_name})

    if (NOT TARGET ${root_target}-unit-tests)
      add_custom_target(${root_target}-unit-tests)
    endif()

    if (NOT TARGET ${root_target}-build-and-test)
      add_custom_target(${root_target}-build-and-test COMMAND ${CMAKE_CTEST_COMMAND})
    endif()

    if (NOT TARGET unit-tests)
      add_custom_target(unit-tests)
    endif()

    if (NOT TARGET build-and-test)
      add_custom_target(build-and-test COMMAND ${CMAKE_CTEST_COMMAND})
    endif()

    # Add to project unit tests target
    add_dependencies(${root_target}-unit-tests ${root_target}-${test_name})

    # Add to project target to build library+run unit tests
    add_dependencies(${root_target}-build-and-test ${root_target}-${test_name})

    # Add to global unit tests target
    add_dependencies(unit-tests ${root_target}-${test_name})

    # Add to global target to build library+run unit tests
    add_dependencies(build-and-test ${root_target}-${test_name})
  endforeach()
endif()
