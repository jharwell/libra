#
# Copyright 2024 John Harwell, All rights reserved.
#
# SPDX-License Identifier: MIT
#

# Core packages
import os
import sys
import pathlib

# 3rd party packages
from conan import ConanFile
from conan.tools.files import copy, save, load
from conan.errors import ConanException

# Project packages

def _resolve_live(here, numeric):
    # Imported lazily: scripts/ only exists in the source tree, and this
    # path only runs there. Consumers never reach it.
    import sys
    sys.path.insert(0, os.path.join(here, "scripts"))
    import version_helper
    return version_helper.get_version(here, numeric=numeric)

class LibraConan(ConanFile):
    name = "libra"
    exports_sources = [
        "cmake/libra/*.cmake",
        "dots/*.*"
    ]
    def set_version(self):
        here = pathlib.Path(os.path.abspath(__file__)).parent
        version_txt = here / "version.txt"
        if os.path.exists(version_txt):
            self.version = load(self, version_txt).strip()
        else:
            self.version = _resolve_live(here, numeric=True)

        if self.version.startswith("0.0.0"):
            raise ConanException(
                "Refusing to set libra version to 0.0.0: git version "
                "resolution failed. Ensure the recipe is loaded from a tree "
                "with reachable git tags, or that a valid version.txt exists."
            )

    def export(self):
        # export() runs in the source tree, where git + cmake + the helper are
        # all present -- the one environment that can resolve the version. Do
        # ALL resolution here, once, and freeze both forms into the exported
        # recipe so set_version() and package() downstream just read files and
        # never need git/cmake/scripts.
        here = pathlib.Path(os.path.abspath(__file__)).parent

        numeric = _resolve_live(here, numeric=True)
        full = _resolve_live(here, numeric=False)

        if full.startswith("0.0.0"):
            raise ConanException(
                "Refusing to export libra with version 0.0.0: git version "
                "resolution failed at export time. Ensure the recipe is "
                "exported from a tree with reachable git tags."
            )

        save(self, os.path.join(self.export_folder, "version.txt"), numeric)
        save(self, os.path.join(self.export_folder, "version_full.txt"), full)

    def build_requirements(self):
        self.tool_requires("cmake/3.31.0")

    def package(self):
        # Copy everything EXCEPT packaging-related things, since when driven by
        # conan it lets conan handle package manager-y things.
        copy(self,
             pattern="*.cmake",
             src=self.source_folder,
             dst=self.package_folder,
             excludes=["*/package/*.cmake"])

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

        # Bake the git-less LIBRA_VERSION fallback into the package.
        #
        # A Conan-consumed package has no .git, so libra's configure-time
        # diagnostic cannot resolve the framework version from git at consume
        # time. We therefore read the full version frozen by export() (when git
        # WAS present) and bake it in.
        #
        # NOTE: we deliberately do NOT reuse self.version here. self.version is
        # the *numeric* X.Y.Z; we want the full version for triaging purposes if
        # needed for dev builds. Both were resolved once in export() and written
        # beside the recipe, so package() needs neither git nor scripts/ here.
        full_version = load(
            self, os.path.join(self.recipe_folder, "version_full.txt")).strip()

        if full_version.startswith("0.0.0"):
            # export() already guards this, but re-check defensively: a 0.0.0
            # baked into every consumer would defeat the whole point of the
            # git-less diagnostic fallback.
            raise ConanException(
                "Refusing to bake LIBRA_VERSION=0.0.0 into the package: "
                "frozen full version is 0.0.0."
            )
        self_cmake_dir = os.path.join(self.package_folder, "cmake", "libra")
        os.makedirs(self_cmake_dir, exist_ok=True)
        with open(os.path.join(self_cmake_dir, "self.cmake"), "w") as f:
            f.write("# GENERATED at Conan package time -- do not edit.\n")
            f.write("# Full (triageable) version captured while git was present.\n")
            f.write(f'set(LIBRA_VERSION "{full_version}")\n')

    def package_info(self):
        # This means that all include() statements will be of the form
        # include(libra/foo/bar.cmake), which is nicely self-documenting.
        self.cpp_info.builddirs = ["cmake"]
