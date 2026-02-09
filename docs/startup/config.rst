.. SPDX-License-Identifier:  MIT

.. _startup/config:

=========================
Environment Configuration
=========================

Platform Requirements
=====================

**Supported Platforms:**

- **Linux** - Primary target (Ubuntu 20.04+, RHEL 8+, Arch, Fedora, Debian)
- **macOS** - Supported with Homebrew compilers (Clang or GCC via Homebrew)
- **WSL** - Works via Windows Subsystem for Linux
- **Windows** - **NOT SUPPORTED** (MSVC, MinGW not tested)

.. warning::

   LIBRA is designed for Unix-like systems and does not support native Windows
   builds. Windows developers should use WSL (Windows Subsystem for Linux) or
   Docker containers with Linux base images.

**Required Tools:**

- **CMake** >= 3.31

- **Python** - Required for some analysis tools (any recent version)

**Optional Tools:**

The following tools enable specific LIBRA features but are not required for
basic builds:

- **doxygen** + **graphviz** - API documentation generation (any recent version)
- **lcov** >= 1.14, **gcovr** >= 5.0 - GNU code coverage reporting
- **llvm-cov** - LLVM/Clang native coverage (bundled with Clang, version matches
  compiler)
- **cppcheck** >= 2.0 - Static analysis
- **clang-tidy** - Static analysis and auto-fixing (bundled with Clang)
- **clang-format** - Code formatting (bundled with Clang)
- **cmake-format** - Code formatting (any recent version)

Compiler Support
----------------

LIBRA provides a unified interface across three compiler families:

.. list-table::
   :header-rows: 1
   :widths: 30 30 40

   * - Compiler
     - Minimum Version
     - Notes

   * - **GCC** (gcc/g++)
     - 9.0
     - Versions 7-8 may work but are untested and unsupported

   * - **Clang** (clang/clang++)
     - 17.0
     - Older versions may work; LLVM coverage requires matching llvm-cov

   * - **Intel LLVM** (icx/icpx)
     - 2024.1
     - Legacy ``icc``/``icpc`` compilers are NOT supported (also deprecated by
       Intel).  The Intel compiler suite must be downloaded separately from
       Intel's website.  It installs to a non-standard location (typically
       ``/opt/intel``). Before using Intel compilers, source the environment
       setup script with something like::

         source /opt/intel/oneapi/setvars.sh


LIBRA's internal diagnostics are optimized for GCC 12+, Clang 21+, and Intel
2025+, but older versions within the supported range will work with reduced
diagnostic coverage.

.. WARNING::

   Always use matching C and C++ compilers from the same vendor:

   - Correct: ``gcc`` + ``g++``, ``clang`` + ``clang++``, ``icx`` + ``icpx``
   - Incorrect: ``gcc`` + ``clang++``, ``icx`` + ``g++``

   Mixing compiler vendors can cause subtle ABI incompatibilities and linking
   errors.  LIBRA will warn if it detects a mismatch during configuration.

Why Not Windows?
----------------

LIBRA currently targets Unix-like systems for several reasons:

**Technical Limitations:**

- Build patterns assume Unix filesystem conventions (``/``, symlinks, ``*.sh``)
- Shell scripts in the test suite use bash syntax
- Many coverage/analysis tools (lcov, gcovr) have limited or no Windows support
- Intel compilers on Windows use different flag syntax than on Linux

**Architectural Differences:**

- Path handling differs (``\`` vs ``/``, drive letters)
- Shared library model differs (``.dll`` vs ``.so``, export/import declarations)

**Workarounds for Windows Users:**

- **WSL (Recommended)**: Full Linux compatibility on Windows 10/11
- **Docker**: Use Linux base images for builds and development
- **Contribute**: Windows support contributions are welcome!

.. _startup/config/structure:

Repository/Code Structure Requirements
======================================

**Mandatory Requirements:**

- All C++ source files must end in ``.cpp``, and all C++ header files in ``.hpp``
- All C source files must end in ``.c``, and all C header files in ``.h``
- All projects must include ``cmake/project-local.cmake`` containing
  project-specific configuration (targets, libraries, options, etc.)

See :ref:`usage/project-local` for how to structure this file.

Repository/Code Structure Recommendations
==========================================

These are *recommended* elements of repository/code structure, which can safely
be ignored if you don't want to use them. However, following these conventions
enables LIBRA's automation features, as show in the figure below.

.. uml:: /figures/layout.uml


**Source File Organization:**

All source files for a project should live under ``src/`` in the repository
root.  This is only required if you want automated source file globbing
(recommended). See :ref:`design/philosophy` for the rationale behind globbing.

**Test File Organization:**

All tests should live under ``tests/`` in the repository root with specific
suffixes:

- Unit tests: ``*-utest.{cpp,c}``
- Integration tests: ``*-itest.{cpp,c}``
- Regression tests: ``*-rtest.{cpp,c}``
- Test harness/common files: ``*_test.{cpp,c,hpp,h}``

This is only required if you want automated test discovery.  See
:ref:`usage/build-time` for how to customize these patterns.

.. NOTE::

   Test harness files (``*_test.{cpp,c,hpp,h}``) are compiled and linked with
   test executables but are not themselves executable tests. Use these for
   shared test utilities, fixtures, and helper functions.

**Documentation Organization:**

If :cmake:variable:`LIBRA_DOCS` is enabled, project documentation should live
under ``docs/`` with a ``docs/Doxyfile.in`` configured for Doxygen generation.

**Using LIBRA Helper Functions:**

Use :cmake:command:`libra_add_library()` and
:cmake:command:`libra_add_executable()` instead of standard ``add_library()``
and ``add_executable()``. This ensures all LIBRA compiler flags, analysis
targets, and quality gates are applied automatically.

You can still use standard CMake commands, but they won't receive LIBRA features
unless you manually apply them.
