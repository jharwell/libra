#
# Copyright 2024 John Harwell, All rights reserved.
#
# SPDX-License Identifier: MIT
#

# Core packages
import subprocess

# 3rd party packages
from conan import ConanFile
from conan.tools.files import copy

# Project packages


class LIBRAConan(ConanFile):
    name = "libra"
    exports_sources = ["cmake/libra/*.cmake"]

    def set_version(self):
        self.version = subprocess.run(
            ("grep LIBRA_VERSION cmake/libra/project.cmake |"
             "grep -Eo [0-9]+.[0-9]+.[0-9]+"),
            shell=True,
            check=True,
            stdout=subprocess.PIPE,
        ).stdout.decode().strip("\n")

    def package(self):
        copy(self, "*.cmake", self.source_folder, self.package_folder)

    def package_info(self):
        # This means that all include() statements will be of the form
        # include(libra/foo/bar.cmake), which is nicely self-documenting.
        self.cpp_info.builddirs = ["cmake"]
