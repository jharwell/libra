# Replace with project requirements
libra_require_compiler(
  LANG
  CXX
  ID
  GNU
  VERSION
  12)

# ##############################################################################
# Targets
# ##############################################################################
libra_add_library(${PROJECT_NAME} STATIC ${${PROJECT_NAME}_CXX_SRC})

# Uncomment to generate .cpp file with build info (the .in file must exist).
# libra_configure_source_file( ${PROJECT_NAME}
# ${CMAKE_CURRENT_SOURCE_DIR}/src/version.cpp.in
# ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}-version.cpp)

# ./include/ directory is automatically added, and configured as
# INSTALL_INTERFACE, so no need to do that here.

# ##############################################################################
# Packaging (non-CONAN driver only)
# ##############################################################################
# libra_configure_exports(TARGET ${PROJECT_NAME} COMPATIBILITY ExactVersion)

# libra_install_target(TARGET ${PROJECT_NAME})

# libra_install_headers(DIRECTORY include/${PROJECT_NAME})
