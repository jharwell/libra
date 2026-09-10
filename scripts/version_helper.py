#
# Copyright 2026 John Harwell, All rights reserved.
#
# SPDX-License-Identifier: MIT
#

# Core packages
import pathlib
import tempfile
import subprocess

# 3rd party packages

# Project packages


def get_version(repo_dir: pathlib.Path, numeric: bool):
    """Return the numeric X.Y.Z version by driving version.cmake.

    repo_dir: directory to resolve git state from (cwd for the cmake call).
    cmake_module_dir: the cmake/ dir containing libra/version.cmake, added
                      to CMAKE_MODULE_PATH so include(libra/version) resolves.
    """
    cmake_module_dir = repo_dir / "cmake"
    driver = (
        f'list(APPEND CMAKE_MODULE_PATH "{cmake_module_dir}")\n'
        "include(libra/version)\n"
        "libra_extract_version()\n"
        # A distinctive prefix so we can pick our line out of any STATUS/WARNING noise.
        'message("VERSION_NUMERIC=${LIBRA_PROJECT_VERSION_NUMERIC}")\n'
        'message("VERSION=${LIBRA_PROJECT_VERSION}")\n'
    )
    with tempfile.NamedTemporaryFile("w", suffix=".cmake", delete=False) as f:
        f.write(driver)
        driver_path = f.name

    try:
        # message() writes to stderr in script mode, so capture both.
        result = subprocess.run(
            ["cmake", "-P", driver_path],
            cwd=repo_dir,
            capture_output=True,
            text=True,
            check=True,
        )
    finally:
        pathlib.Path(driver_path).unlink(missing_ok=True)

    for line in (result.stdout + result.stderr).splitlines():
        prefix = "VERSION_NUMERIC=" if numeric else "VERSION="
        if line.startswith(prefix):
            return line.split("=", 1)[1].strip()

    raise RuntimeError(f"could not parse version from cmake output:\n{result.stderr}")


if __name__ == "__main__":
    print(get_version(pathlib.Path(__file__).parent.parent, numeric=True))
