#
# Copyright 2026 John Harwell, All rights reserved.
#
# SPDX-License-Identifier: MIT
#
file(WRITE ${CMAKE_BINARY_DIR}/main.c "int main(void) { return 0; }\n")

libra_add_executable(${PROJECT_NAME} ${CMAKE_BINARY_DIR}/main.c)

# The version is resolved once at configure time; this is how it gets baked
# into the build.
libra_configure_source_file(
  ${PROJECT_NAME} ${CMAKE_CURRENT_LIST_DIR}/../src/version_info.c.in
  ${CMAKE_BINARY_DIR}/version_info.c)
