#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#

# This avoids namespace collisions in when using LIBRA to build dependency
# chains across multiple repos.

if("${CMAKE_SOURCE_DIR}" STREQUAL "${CMAKE_CURRENT_SOURCE_DIR}")
  add_custom_target("uninstall" COMMENT "Uninstall all installed files")
  add_custom_command(
    TARGET "uninstall"
    POST_BUILD
    COMMENT "Uninstall files installed with install_manifest.txt"
    COMMAND xargs rm -f < install_manifest.txt || echo
            "Nothing in install_manifest.txt to be uninstalled!")
endif()
