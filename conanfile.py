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
    exports_sources = [
        "cmake/libra/*.cmake",
        "dots/*.*"
    ]

    def set_version(self):
        self.version = subprocess.run(
            ("grep LIBRA_VERSION cmake/libra/project.cmake |"
             "grep -Eo [0-9]+.[0-9]+.[0-9]+"),
            shell=True,
            check=True,
            stdout=subprocess.PIPE,
        ).stdout.decode().strip("\n")

    def build_requirements(self):
        self.tool_requires("cmake/3.30.0")

    def package(self):
        # Copy everything EXCEPT packaging-related things. Even though LIBRA
        # will (eventually) become something which can only be used with package
        # managers like conan, it is not there yet, so we filter instead of just
        # removing irrelevant files.
        copy(self,
             pattern="*.cmake",
             src=self.source_folder,
             dst=self.package_folder,
             excludes=["*/package/*.cmake",
                       "*/arm-*.cmake"])

        copy(self,
             pattern="*.clang-format",
             src=self.source_folder,
             dst=self.package_folder)
        copy(self,
             pattern="*.clang-tidy",
             src=self.source_folder,
             dst=self.package_folder)
        copy(self,
             pattern="*.cmake-format",
             src=self.source_folder,
             dst=self.package_folder)

    def package_info(self):
        # This means that all include() statements will be of the form
        # include(libra/foo/bar.cmake), which is nicely self-documenting.
        self.cpp_info.builddirs = ["cmake"]
