#
# Copyright 2026 John Harwell, All rights reserved.
#
# SPDX-License Identifier: MIT
#
include(${CMAKE_SOURCE_DIR}/../common.cmake)

# Build and export producer first
file(WRITE ${CMAKE_BINARY_DIR}/lib.cpp "int f(){return 0;}")

libra_add_library(NAME producer ${CMAKE_BINARY_DIR}/lib.cpp)

# Configure exports (generates the config file in the build directory and
# registers install() rules).
libra_configure_exports(TARGET producer)

# Register the target for install so it gets an export set.
libra_install_target(producer)

# Verify the generated config file exists in the build directory.
assert_file_exists("${CMAKE_BINARY_DIR}/producer-config.cmake")

# Verify the generated config file is valid by including it directly.
# configure_package_config_file() sets PACKAGE_INIT and other variables; if the
# template was malformed this would fail.
include("${CMAKE_BINARY_DIR}/producer-config.cmake")

# Verify the target is still valid after the export configuration.
assert_target_exists(producer)
