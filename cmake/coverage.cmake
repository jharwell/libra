find_package(lcov)
find_package(genhtml)

set(CMAKE_CXX_OUTPUT_EXTENSION_REPLACE ON)
set(CMAKE_C_OUTPUT_EXTENSION_REPLACE ON)

if (LCOV_FOUND)
  set(GENHTML_CMD ${GENHTML_EXECUTABLE} coverage.info --output-directory coverage)

  set(LCOV_CMD ${LCOV_EXECUTABLE} --include \*/${root_target}/\* --exclude \*/ext/\* --capture --directory . --output-file coverage.info && ${GENHTML_CMD})

  if("${target}" STREQUAL "${root_target}")

    # Coverage for the root project
    add_custom_target(${target}-coverage-report
    COMMAND ${LCOV_CMD}
    COMMENT "Generating ${target} code coverage report in coverage/" VERBATIM)

  # Coverage for ALL libraries known to cmake
  add_custom_target(coverage-report
    COMMAND ${LCOV_CMD}
    COMMENT "Generating ${target} code coverage report in coverage/" VERBATIM)

  endif()
else()
  message(WARNING "lcov needs to be installed to generate code coverage reports!")
endif(LCOV_FOUND)
