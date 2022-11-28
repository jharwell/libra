#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#
find_package(lcov)
find_package(genhtml)

set(CMAKE_CXX_OUTPUT_EXTENSION_REPLACE ON)
set(CMAKE_C_OUTPUT_EXTENSION_REPLACE ON)

if (lcov_FOUND)
  set(genhtml_CMD ${genhtml_EXECUTABLE} coverage.info --output-directory coverage)

  set(lcov_CMD ${lcov_EXECUTABLE} --include \*/${PROJECT_NAME}/\* --exclude \*/ext/\* --capture --directory . --output-file coverage.info && ${genhtml_CMD})

  # Coverage for the root project
  add_custom_target(${PROJECT_NAME}-coverage-report
    COMMAND ${lcov_CMD}
    COMMENT "Generating ${PROJECT_NAME} code coverage report in coverage/" VERBATIM)

  # Coverage for ALL libraries known to cmake
  add_custom_target(coverage-report
    COMMAND ${lcov_CMD}
    COMMENT "Generating ${PROJECT_NAME} code coverage report in coverage/" VERBATIM)

else()
  message(WARNING "lcov needs to be installed to generate code coverage reports!")
endif(lcov_FOUND)
