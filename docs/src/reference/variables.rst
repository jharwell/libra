.. SPDX-License-Identifier: MIT

.. _reference/variables:

.. _usage/configure-time:

==================
Variable reference
==================

All ``LIBRA_*`` CMake cache variables. These are set at configure time
via ``-D`` on the cmake command line, or in a preset's
``cacheVariables``. Most can also be set in ``project-local.cmake`` —
see :ref:`reference/project-local` for restrictions.

For a conceptual overview of how feature flags work and interact with
presets, see :ref:`concepts/feature-flags`. For file discovery and
layout conventions, see :ref:`concepts/project-setup/layout`.

.. IMPORTANT:: Unless specified otherwise, all variables apply only to
               the current project and its registered targets. No
               ``CMAKE_XXX`` global variables are set, which prevents
               unintended cascades into dependency builds.

General
=======

.. cmake:variable:: LIBRA_DRIVER

   :default: SELF
   :type: CACHE STRING

   The *primary* user-visible driver to LIBRA, if any. Possible values are:

   - ``SELF`` - LIBRA itself is the driver/main way users interact with the
     build system; for all intents and purposes, LIBRA *IS* the build system. It
     also handles packaging duties, to the extent that cmake supports packaging.

   - ``CONAN`` - CONAN is the primary driver of the build system. It sets up the
     environment and handles all packaging tasks. LIBRA only has to run the
     actual builds.

.. cmake:variable:: LIBRA_SUMMARY

   :default: YES
   :type: CACHE BOOL

   Show a configuration summary after the configuration step finishes.

.. _reference/variables/sw-eng:

Quality Gates
=============

.. cmake:variable:: LIBRA_TESTS

   :default: NO
   :type: CACHE BOOL

   Enable building of tests via:

   - ``make unit-tests`` (unit tests only)
   - ``make integration-tests`` (integration tests only)
   - ``make regression-tests`` (regression tests only)
   - ``make all-tests`` (all tests)

.. cmake:variable:: LIBRA_CODE_COV

   :default: NO
   :type: CACHE BOOL

   Build in runtime code-coverage instrumentation for report generation and
   coverage checking. See :ref:`reference/targets` for the targets enabled.

.. cmake:variable:: LIBRA_CODE_COV_NATIVE

   :default: YES
   :type: CACHE BOOL

   Direct compilers to build in coverage instrumentation in their "native"
   format. E.g., clang will use LLVM format, and GCC will use GNU format. If
   false, all compilers will use GNU format. The created targets will reflect
   which format is selected.

.. cmake:variable:: LIBRA_ANALYSIS

   :default: NO
   :type: CACHE BOOL

   Enable static analysis targets for checkers, formatters, etc. See
   :ref:`reference/targets` for the targets enabled (assuming the necessary
   executables are found). See :ref:`concepts/analysis` for tool-specific
   configuration guidance.

.. cmake:variable:: LIBRA_DOCS

   :default: NO
   :type: CACHE BOOL

   Enable documentation build via ``make apidoc`` and/or ``make sphinxdoc``.

Runtime Checking
================

.. cmake:variable:: LIBRA_SAN

   :default: NONE
   :type: CACHE STRING

   Build in runtime checking of code using any compiler. When passed, the
   value should be a semicolon-separated list of sanitizer groups to enable:

   - ``MSAN`` - Memory checking/sanitization. Requires ``liblsan`` compatible
     with your compiler.
   - ``ASAN`` - Address sanitization. Requires ``libasan`` compatible with your
     compiler.
   - ``SSAN`` - Aggressive stack checking.
   - ``UBSAN`` - Undefined behavior checks.
   - ``TSAN`` - Multithreading checks. Requires ``libtsan`` compatible with your
     compiler.
   - ``NONE`` - None of the above.

   .. NOTE:: ASAN, UBSAN, and SSAN can generally be stacked together without
             issue. TSAN is incompatible with some other sanitizer groups
             depending on compiler.

.. cmake:variable:: LIBRA_FORTIFY

   :default: NONE. Any non-None value also sets ``LIBRA_LTO=YES``.
   :type: CACHE STRING

   Build in compiler support/runtime checking of code for heightened
   security. Which options get passed to compiler/linker AND which groups are
   supported is compiler dependent.

   .. IMPORTANT:: When enabling fortification, you will likely need to compile
                  *everything* with the same settings to avoid linker errors.

   When passed, the value should be a comma-separated list of groups to enable:

   - ``STACK`` - Fortify the stack: add stack protector, etc.
   - ``SOURCE`` - Fortify source code via ``_FORTIFY_SOURCE=2``.
   - ``FORMAT`` - Fortify against formatting attacks.
   - ``ALL`` - All of the above.
   - ``NONE`` - None of the above.

   .. versionadded:: 0.8.3

.. cmake:variable:: LIBRA_VALGRIND_COMPAT

   :default: NO
   :type: CACHE BOOL

   Disable compiler instructions in 64-bit code so that programs will run
   under valgrind reliably.

.. _reference/variables/builds:

Build configuration
===================

.. cmake:variable:: LIBRA_FPC

   :default: INHERIT
   :type: CACHE STRING

   Enable Function Precondition Checking (FPC): checking function
   parameters/global state before executing a function. LIBRA defines a
   declarative interface for specifying *what* type of checking is desired;
   a library or application chooses how to interpret it.

   Possible values:

   - ``NONE`` - Checking compiled out.
   - ``RETURN`` - If a precondition is not met, return without executing the
     function.
   - ``ABORT`` - If a precondition is not met, abort() the program.
   - ``INHERIT`` - Inherit from a parent project that exposes it. Default,
     to avoid cluttering compiler commands for projects that do not use FPC.

.. cmake:variable:: LIBRA_FPC_EXPORT

   :default: NO
   :type: CACHE BOOL

   Make :cmake:variable:`LIBRA_FPC` visible to downstream projects. Private
   by default.

.. cmake:variable:: LIBRA_ERL

   :default: INHERIT
   :type: CACHE STRING

   Specify Event Reporting Level (ERL). LIBRA provides a declarative
   interface for specifying the desired result of event reporting framework
   configuration. Possible values:

   - ``ALL`` - All event reporting compiled in.
   - ``FATAL`` - Compile out all except FATAL events.
   - ``ERROR`` - Compile out all except [FATAL, ERROR].
   - ``WARN`` - Compile out all except [FATAL, ERROR, WARN].
   - ``INFO`` - Compile out all except [FATAL, ERROR, WARN, INFO].
   - ``DEBUG`` - Compile out all except [FATAL, ERROR, WARN, INFO, DEBUG].
   - ``TRACE`` - Same as ``ALL``.
   - ``NONE`` - All event reporting compiled out.
   - ``INHERIT`` - Inherit from a parent project. Default.

.. cmake:variable:: LIBRA_ERL_EXPORT

   :default: NO
   :type: CACHE BOOL

   Make :cmake:variable:`LIBRA_ERL` visible to downstream projects. Private
   by default.


Build optimization
==================

.. cmake:variable:: LIBRA_NATIVE_OPT

   :default: NO
   :type: CACHE BOOL

   Enable compiler optimizations native to the current machine. Binaries
   compiled this way are not portable across CPU microarchitectures. Not
   recommended for CI pipelines or Docker builds.

   .. versionadded:: 0.9.15

.. cmake:variable:: LIBRA_PGO

   :default: NONE
   :type: CACHE STRING

   Generate a Profile-Guided Optimisation build. Possible values:

   - ``NONE``
   - ``GEN`` - Instrumentation phase. Build, run with a representative
     workload, then merge profile data (Clang only):

     .. code-block:: bash

        cmake -DLIBRA_PGO=GEN ..
        make
        ./bin/my_application
        llvm-profdata merge -o default.profdata default*.profraw  # Clang only

   - ``USE`` - Optimisation phase, after collecting profile data:

     .. code-block:: bash

        cmake -DLIBRA_PGO=USE ..
        make

.. cmake:variable:: LIBRA_LTO

   :default: NO
   :type: BOOL

   Enable Link-Time Optimisation (LTO), also known as Interprocedural
   Optimisation (IPO). Compiler-independent.

   .. versionchanged:: 0.8.3
      Automatically enabled when ``LIBRA_FORTIFY != NONE``.

.. cmake:variable:: LIBRA_STDLIB

   :default: UNDEFINED; use compiler built-in default.
   :type: CACHE STRING

   Select which standard library to use. Valid values:

   - ``NONE`` - No stdlib. Defines ``__nostdlib__`` for all source files.
     For bare-metal builds.
   - ``CXX`` - Use libc++, if the compiler supports it.
   - ``STDCXX`` - Use libstdc++, if the compiler supports it.


.. cmake:variable:: LIBRA_OPT_REPORT

   :default: NO
   :type: CACHE BOOL

   Enable compiler-generated reports for optimizations performed, as well as
   suggestions for further optimizations.


Toolchain/compiler
==================

.. cmake:variable:: LIBRA_C_STANDARD

   :default: Autodetected to the latest C standard supported by
             :cmake:variable:`CMAKE_C_COMPILER`.
   :type: CACHE STRING

   Respects :cmake:variable:`CMAKE_C_STANDARD` if set. ``C_EXTENSIONS ON``
   is set for the configured version.

   .. versionadded:: 0.8.4

.. cmake:variable:: LIBRA_CXX_STANDARD

   :default: Autodetected to the latest C++ standard supported by
             :cmake:variable:`CMAKE_CXX_COMPILER`.
   :type: CACHE STRING

   Respects :cmake:variable:`CMAKE_CXX_STANDARD` if set. ``CXX_EXTENSIONS ON``
   is set for the configured version.

   .. versionadded:: 0.8.4

.. cmake:variable:: LIBRA_GLOBAL_C_FLAGS

   :default: NO
   :type: CACHE BOOL

   Apply all C flags set for registered targets globally via
   ``CMAKE_C_FLAGS_<build type>`` to all C files. Use with care — this
   affects external dependencies built alongside your code.

.. cmake:variable:: LIBRA_GLOBAL_CXX_FLAGS

   :default: NO
   :type: CACHE BOOL

   Apply all C++ flags set for registered targets globally via
   ``CMAKE_CXX_FLAGS_<build type>`` to all C++ files. Use with care.

   .. versionchanged:: 0.9.14

Build tooling
=============

.. cmake:variable:: LIBRA_NO_CCACHE

   :default: NO
   :type: CACHE BOOL

   Disable usage of ``ccache`` even if it is found. Useful when doing build
   profiling where ``ccache`` would skew timing results.

.. cmake:variable:: LIBRA_BUILD_PROF

   :default: NO
   :type: CACHE BOOL

   To the extent supported by the selected compiler, enable build
   profiling. This can be helpful in determining why you're build is taking so
   long (e.g., lots of header file parsing).


.. cmake:variable:: LIBRA_USE_COMPDB

   :default: YES
   :type: CACHE BOOL

   Use ``compile_commands.json`` for all analysis tools. See
   :ref:`concepts/analysis` for when to disable this.

   .. versionadded:: 0.9.36

.. cmake:variable:: LIBRA_CLANG_TOOLS_USE_FIXED_DB

   :default: TRUE
   :type: CACHE BOOL

   When :cmake:variable:`LIBRA_USE_COMPDB` is ``NO``, this controls how include
   paths and defines are passed to clang-based tools. When ``YES`` (default),
   flags are passed after ``--`` (fixed compilation database convention). When
   ``NO``, ``--extra-arg=`` is used for each flag.

   The fixed-DB path (``YES``) is more reliable for projects with complex
   include paths or those using CPM, where include directories may contain
   special characters or spaces. Use the extra-arg path only if a specific tool
   version requires it.

   .. versionadded:: 0.10.0

See also the :ref:`individual docs pages for each compiler <design/compilers>`,
which describe how these variables are realized for each supported compiler.
