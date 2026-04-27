.. SPDX-License-Identifier: MIT

.. _getting-started/installation:

============
Installation
============

Supported platforms
===================

- **Linux** — primary target (Ubuntu 20.04+, RHEL 8+, Arch, Fedora, Debian)
- **macOS** — supported with Homebrew compilers (Clang or GCC via Homebrew)
- **WSL** — works via Windows Subsystem for Linux

.. warning::

   Native Windows builds (MSVC, MinGW) are not supported. Windows developers
   should use WSL or a Linux Docker container.

   Reasons include: build patterns assume Unix filesystem conventions,
   test scripts use bash syntax, many coverage and analysis tools (lcov,
   gcovr) have limited or no Windows support, and Intel compilers on Windows
   use different flag syntax than on Linux. Windows support contributions
   are welcome.

Required tools
==============

.. list-table::
   :header-rows: 1
   :widths: 25 20 55

   * - Tool
     - Minimum version
     - Notes

   * - **CMake**
     - 3.31
     - Required for all builds.

   * - **Python**
     - any recent
     - Required by some analysis tools (cppcheck, cmake-format).

   * - A C/C++ compiler
     - see below
     - GCC, Clang, or Intel LLVM.

.. _getting-started/installation/compilers:

Compiler support
----------------

LIBRA provides a unified interface across three compiler families:

.. list-table::
   :header-rows: 1
   :widths: 30 25 45

   * - Compiler
     - Minimum version
     - Notes

   * - **GCC** (``gcc`` / ``g++``)
     - 9.0
     - Versions 7–8 may work but are untested and unsupported. Diagnostics
       are optimized for GCC 12+.

   * - **Clang** (``clang`` / ``clang++``)
     - 17.0
     - LLVM coverage tools (``llvm-cov``, ``llvm-profdata``) must match
       the compiler version. Diagnostics are optimized for Clang 21+.

   * - **Intel LLVM** (``icx`` / ``icpx``)
     - 2025.0
     - Legacy ``icc``/``icpc`` are not supported (deprecated by Intel).
       The Intel suite installs to a non-standard location (typically
       ``/opt/intel``). Source the environment before use::

         source /opt/intel/oneapi/setvars.sh

       Diagnostics are optimized for Intel 2025+.

.. warning::

   Always use matching C and C++ compilers from the same vendor:

   - **Correct**: ``gcc`` + ``g++``, ``clang`` + ``clang++``, ``icx`` + ``icpx``
   - **Incorrect**: ``gcc`` + ``clang++``, ``icx`` + ``g++``

   Mixing compiler vendors causes ABI incompatibilities and linking errors.

Optional tools
==============

The following tools are not required for basic builds but each enables specific
LIBRA features: **Ninja** (faster builds), **ccache** (build caching),
**doxygen** (API docs) **sphinx** (hosted documentation), **lcov** / **gcovr**
(GNU coverage reports), **llvm-cov** (Clang coverage), **cppcheck**,
**clang-tidy**, **clang-format** (static analysis and formatting),
**cmake-format** (CMake formatting).

Installing ``clibra``
=====================

``clibra`` requires the Rust toolchain. If you do not have Cargo installed,
the quickest path is `rustup <https://rustup.rs>`_:

.. code-block:: bash

   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

Then install ``clibra``:

.. code-block:: bash

   cargo install clibra

Cargo places the binary in ``~/.cargo/bin/``. The Rust installer adds this
to your ``PATH`` automatically. If ``clibra`` is not found after installation:

.. code-block:: bash

   # bash / zsh — add to ~/.bashrc or ~/.zshrc
   export PATH="$HOME/.cargo/bin:$PATH"

Verify the installation:

.. code-block:: bash

   clibra --version

.. note::

   The ``clibra`` CLI is optional. You can use LIBRA as a pure CMake
   framework without it. See :ref:`getting-started/quickstart-cmake`.

Shell completions
=================

``clibra`` can generate shell completion scripts:

.. code-block:: bash

   # bash
   clibra generate --shell=bash >> ~/.bash_completion

   # zsh — ensure ~/.zfunc is in your fpath
   clibra generate --shell=zsh > ~/.zfunc/_clibra

   # fish
   clibra generate --shell=fish > ~/.config/fish/completions/clibra.fish

   # elvish
   clibra generate --shell=elvish >> ~/.config/elvish/rc.elv
