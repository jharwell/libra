#
# Copyright 2024 John Harwell, All rights reserved.
#
# SPDX-License Identifier: MIT
#

# Core packages
import os
import pathlib
import re
import subprocess

# 3rd party packages
from conan import ConanFile
from conan.tools.files import copy, save, load
from conan.errors import ConanException

# Project packages

# SemVer 2.0: X.Y.Z, optional -prerelease, optional +build metadata. clibra
# prints versions without a leading 'v'.
_SEMVER = re.compile(
    r"^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)"
    r"(-[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?"
    r"(\+[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?$"
)


def _resolve_live(full):
    """Resolve LIBRA's own version from git via clibra.

    Only works in the source tree (git + cmake + a built clibra). Returns the
    numeric X.Y.Z, or with full=True the complete version including any
    prerelease and build metadata (e.g. 0.13.13-dev.2, 0.13.12+3.g5f7115c).

    The clibra binary defaults to the debug build in this tree; set CLIBRA_BIN
    to use another one.
    """
    repo_root = pathlib.Path(__file__).parent
    clibra = os.environ.get("CLIBRA_BIN", str(repo_root / "target" / "debug" / "clibra"))

    cmd = [clibra, "version", "--self"]
    if full:
        cmd.append("--full")

    try:
        result = subprocess.run(
            cmd, capture_output=True, text=True, cwd=repo_root, check=False
        )
    except FileNotFoundError:
        raise ConanException(
            f"clibra not found at {clibra}: run 'cargo build' first, or set CLIBRA_BIN"
        )

    if result.returncode != 0:
        raise ConanException(
            f"Failed to get LIBRA version ({' '.join(cmd)}):\n{result.stderr.strip()}"
        )

    # The version is the last stdout line; anything before it is noise.
    lines = [ln.strip() for ln in result.stdout.splitlines() if ln.strip()]
    version = lines[-1] if lines else ""
    if not _SEMVER.match(version):
        raise ConanException(
            f"clibra returned something that isn't a version: {result.stdout!r}"
        )
    return version


class LibraConan(ConanFile):
    name = "libra"
    exports_sources = ["cmake/libra/*.cmake", "dots/*.*"]

    def set_version(self):
        # Exported recipe: export() froze the version beside it; just read it.
        # Source tree (e.g. `conan create .`): resolve from git.
        here = pathlib.Path(os.path.abspath(__file__)).parent
        version_txt = here / "version.txt"
        if version_txt.exists():
            self.version = load(self, str(version_txt)).strip()
        else:
            self.version = _resolve_live(full=False)

        if self.version.startswith("0.0.0"):
            raise ConanException(
                "Refusing to set libra version to 0.0.0: git version "
                "resolution failed. Ensure the recipe is loaded from a tree "
                "with reachable git tags, or that a valid version.txt exists."
            )

    def export(self):
        # export() runs in the source tree, where git + cmake + clibra are all
        # present -- the one environment that can resolve the version. Do ALL
        # resolution here, once, and freeze both forms into the exported recipe
        # so set_version() and package() downstream just read files and never
        # need git/cmake/clibra.
        numeric = _resolve_live(full=False)
        full = _resolve_live(full=True)

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
        copy(
            self,
            pattern="*.cmake",
            src=self.source_folder,
            dst=self.package_folder,
            excludes=["*/package/*.cmake"],
        )

        for pattern in ("*.clang-format", "*.clang-tidy", "*.cmake-format"):
            copy(
                self,
                pattern=pattern,
                src=self.source_folder,
                dst=self.package_folder,
            )

        # Bake LIBRA_VERSION into the package's self.cmake.
        #
        # A Conan-consumed package has no .git, so version.cmake cannot resolve
        # the framework version from git at consume time and falls through to
        # self.cmake. We bake the FULL version frozen by export() (not
        # self.version, which is numeric only), so dev and untagged builds
        # stay triageable, e.g. 0.13.13-dev.2 rather than 0.13.13.
        #
        # From the cache (conan create), recipe_folder is the exported recipe
        # and version_full.txt is there. From the source tree (conan
        # export-pkg), recipe_folder is the checkout: no frozen file, but git is
        # present, so resolve live.
        frozen = os.path.join(self.recipe_folder, "version_full.txt")
        if os.path.exists(frozen):
            full_version = load(self, frozen).strip()
        else:
            full_version = _resolve_live(full=True)

        if full_version.startswith("0.0.0") or not _SEMVER.match(full_version):
            # export() already guards this, but re-check defensively: a bad
            # value baked into every consumer would defeat the fallback.
            raise ConanException(
                f"Refusing to bake LIBRA_VERSION={full_version!r} into the package"
            )

        print("save to: ", os.path.join(self.package_folder, "cmake", "libra", "self.cmake"))
        save(
            self,
            os.path.join(self.package_folder, "cmake", "libra", "self.cmake"),
            "# GENERATED at Conan package time -- do not edit.\n"
            "# Full (triageable) version captured while git was present.\n"
            f'set(LIBRA_VERSION "{full_version}")\n',
        )

    def package_info(self):
        # This means that all include() statements will be of the form
        # include(libra/foo/bar.cmake), which is nicely self-documenting.
        self.cpp_info.builddirs = ["cmake"]
