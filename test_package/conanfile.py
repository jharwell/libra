#
# Copyright 2025 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#

# Core packages
import pathlib

# 3rd party packages
from conan import ConanFile
from conan.tools.cmake import CMake, cmake_layout, CMakeDeps, CMakeToolchain
from conan.tools.build import can_run

# Project packages


class libraPackgeTestConan(ConanFile):
    """
    You should not need to modify ANYTHING in this class.
    """
    name = "libra-package-test"
    settings = "os", "compiler", "build_type", "arch"

    def requirements(self):
        self.requires(self.tested_reference_str)

    def generate(self):
        deps = CMakeDeps(self)
        deps.build_context_activated = ["libra"]

        tc = CMakeToolchain(self)
        tc.variables["LIBRA_ANALYSIS"] = "YES"

        deps.generate()
        tc.generate()

    def build(self):
        cmake = CMake(self)
        cmake.configure()
        # To see verbose output when building, comment/swap the build calls()
        # below
        cmake.build()
        # cmake.build(build_tool_args=["-v"])

    def layout(self):
        # This is required if the package package also has it, otherwise, conan
        # can't find the test executable to run.
        cmake_layout(self)

    def test(self):
        if can_run(self):
            path = pathlib.Path(self.cpp.build.bindir) / "libra-package-test"

            # If you don't resolve() the path, conan can't find it; this doesn't
            # happen with os.path.join(), and I don't know why. We want to use
            # pathlib though, as that is more modern.
            self.run(path.resolve(), env="conanrun")
