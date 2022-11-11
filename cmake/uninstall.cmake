#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  LGPL-2.0-or-later
#
# make uninstall
add_custom_target("uninstall" COMMENT "Uninstall installed files")
add_custom_command(
  TARGET "uninstall"
  POST_BUILD
  COMMENT "Uninstall files installed with install_manifest.txt"
  COMMAND xargs rm -f < install_manifest.txt || echo "Nothing in install_manifest.txt to be uninstalled!"
  )
