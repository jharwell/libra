.. _usage/configure-time:

======================
Configure-Time Actions
======================

This page details LIBRA usage and actions when you invoke CMake on the
cmdline. It is coupled to, but distinct from, :ref:`usage/project-local`.


Target Configuration
====================

LIBRA will apply all of its magic (compile options, analysis config, etc.) to
all targets registered with:

- :cmake:command:`libra_add_library()`
- :cmake:command:`libra_add_executable()`

You can also use :cmake:variable:`LIBRA_GLOBAL_C_FLAGS`,
:cmake:variable:`LIBRA_GLOBAL_CXX_FLAGS` to apply compiler configuration to all
targets, though this will affect ALL Cmake targets, which is generally a bad
idea.

File Discovery
==============

.. uml:: /figures/layout.uml


- All files under ``src/`` ending in:

  - ``.c``
  - ``.cpp``

  are globbed as source files (see :ref:`startup/config/structure` for
  repository layout requirements) so that if you add a new source file, rename a
  source file, etc., you just need to re-run cmake. This means you don't have to
  MANUALLY specify all the files in the cmake project. Woo-hoo!

  .. NOTE:: See :ref:`design/philosophy/globbing` for rationale on why globs are
     used, contrary to common cmake guidance.

- All files under ``tests/`` ending in a specified pattern are recursively
  globbed as unit test files which will be compiled into executable unit tests
  at build time if :cmake:variable:`LIBRA_TESTS` is enabled. See
  :ref:`usage/project-local/variables` more details on this configuration
  item. Same for integration tests.

- All files under ``tests/`` ending in a specified pattern are recursively
  globbed as the test harness for unit/integration tests. All test harness files
  will be compiled into static libraries at build time and all test targets link
  against them if :cmake:variable:`LIBRA_TESTS` is enabled.

.. NOTE:: The difference between unit tests and integration tests is purely
          semantic, and exists solely to help organize your tests. LIBRA treats
          both types of tests equivalently.

The rest of the page details variables available for fine-tuning the cmake
configuration process; thus, these variables are indended to be set on the
command line via ``-D``, as they enable/disable LIBRA features, instead of
configuring a feature. However, *most* can be put in your
``project-local.cmake`` if you want to--see :ref:`usage/project-local` for
details about restrictions.

.. IMPORTANT:: Unless specified otherwise, all knobs only apply to the current
               project and/or target; i.e., no ``CMAKE_XXX`` global variables
               are set. This helps to prevent untended cascades of build options
               which might cause issues.


Knobs For Configuring LIBRA/CMake
=================================

.. cmake:variable:: LIBRA_DEPS_PREFIX

   :default: $HOME/.local/system
   :type: CACHE STRING

   The location where cmake should search for other locally installed libraries
   (e.g., ``$HOME/.local``). VERY useful to separate out 3rd party headers which
   you want to suppress all warnings for by treating them as system headers when
   you can't/don't want to install things as root, or wrap in ``#pragma GCC
   system_header`` headers.

   Only available if :cmake:variable:`LIBRA_DRIVER` is ``SELF``. Cannot be set
   in ``project-local.cmake``.

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

.. _usage/configure-time/sw-eng:

Knobs For Supporting SW Engineering
===================================

See also the :ref:`individual docs pages for each compiler <usage/compilers>`,
which describe how these knobs are realized for each supported compiler.

.. cmake:variable:: LIBRA_DOCS

   :default: NO
   :type: CACHE BOOL

   Enable documentation build via ``make apidoc``.

.. cmake:variable:: LIBRA_CODE_COV

   :default: NO
   :type: CACHE BOOL

   Build in runtime code-coverage instrumentation for report generation and
   coverage checking. See :ref:`usage/build-time/sw-eng` for specifics.

.. cmake:variable:: LIBRA_CODE_COV_NATIVE

   :default: YES
   :type: CACHE BOOL

   Direct compilers to build in coverage instrumentation in their "native"
   format. E.g., clang will using LLVM format, and GCC will use GNU
   format. If false, all compilers will use GNU format. The created targets will
   reflect which format is selected.

.. cmake:variable:: LIBRA_SAN

   :default: NONE
   :type: CACHE STRING

   Build in runtime checking of code using any compiler. When passed, the
   value should be a comma-separated list of sanitizer groups to enable:

   - ``MSAN`` - Memory checking/sanitization. To use this, you may need
     ``liblsan`` installed, compatible with your compiler.

   - ``ASAN`` - Address sanitization. To use this, you will need ``libasan``
     installed, compatible with your compiler.

   - ``SSAN`` - Aggressive stack checking.

   - ``UBSAN`` - Undefined behavior checks.

   - ``TSAN`` - Multithreading checks. To use this, you will need ``libtsan``
     installed, compatible with your compiler.

   - ``NONE`` - None of the above.

   .. NOTE:: The first 4 can generally be stacked together without
              issue. Depending on compiler; the thread sanitizer is incompatible
              with some other sanitizer groups.

.. cmake:variable:: LIBRA_ANALYSIS

   :default: NO
   :type: CACHE BOOL

   Enable static analysis targets for checkers, formatters, etc. See
   :ref:`usage/build-time` for the targets enabled (assuming the necessary
   executables are found).

.. cmake:variable:: LIBRA_OPT_REPORT

   :default: NO
   :type: CACHE BOOL

   Enable compiler-generated reports for optimizations performed, as well as
   suggestions for further optimizations.

.. cmake:variable:: LIBRA_FORTIFY

   :default: NONE. Any non-None value also sets ``LIBRA_LTO=YES``.
   :type: CACHE STRING

   Build in compiler support/runtime checking of code for heightened
   security. Which options get passed to compiler/linker AND which groups are
   supported is obviously compiler dependent.

   .. IMPORTANT:: When enabling things using this variable, you probably will
                  have to compile *everything* with the same settings to avoid
                  getting linker errors.

   When passed, the value should be a comma-separated list of groups to enable:

   - ``STACK`` - Fortify the stack: add stack protector, etc.

   - ``SOURCE`` - Fortify source code via ``_FORTIFY_SOURCE=2``.

   - ``FORMAT`` - Fortify against formatting attacks.

   - ``ALL`` - All of the above.

   - ``NONE`` - None of the above.

   .. versionadded:: 0.8.3

.. cmake:variable:: LIBRA_TESTS

   :default: NO
   :type: CACHE BOOL

   Enable building of tests via:

   - ``make unit-tests`` (unit tests only)

   - ``make integration-tests`` (integration tests only)

   - ``make regression-tests`` (regression tests only)

   - ``make all-tests`` (all tests)

.. _usage/configure-time/builds:

Knobs For Configuring Builds
============================

.. cmake:variable:: LIBRA_FPC

   :default: INHERIT
   :type: CACHE STRING

   Enable Function Precondition Checking (FPC): checking function
   parameters/global state before executing a function, for functions which
   a library/application has defined conditions for. LIBRA does not define
   *how* precondition checking is implemented for a given
   library/application using it, only a simple declarative interface for
   specifying *what* type of checking is desired at build time; a library
   application can choose how to interpret the specification. This
   flexibility and simplicity is part of what makes LIBRA a very useful
   build process front-end across different projects.

   FPC is, generally speaking, mostly used in C, and is very helpful for
   debugging, but can slow things down in production builds. Possible values
   for this option are:

   - ``NONE`` - Checking compiled out.

   - ``RETURN`` - If at least one precondition is not met, return without
     executing the function. Do not abort() the program.

   - ``ABORT`` - If at least one precondition is not met, abort() the
     program.

   - ``INHERIT`` - FPC configuration should be inherited from a parent project
     which exposes it. This is the default because it prevents cluttering
     compiler commands with #defines for projects which don't use it.

.. cmake:variable:: LIBRA_FPC_EXPORT

   :default: NO
   :type: CACHE BOOL

   Make :cmake:variable:`LIBRA_FPC` visible to downstream projects; it is
   private by default. This allows you to create an arbitrary dependency graph
   w.r.t which projects define their own FPC vs. which inherit it from
   elsewhere.

.. cmake:variable:: LIBRA_C_STANDARD

   :default: Autodetected to the latest C standard supported by
             :cmake:variable:`CMAKE_C_COMPILER`.

   :type: CACHE STRING

   Respects :cmake:variable:`CMAKE_C_STANDARD`, if set/overridden. Note that
   ``C_EXTENSIONS ON`` is set for the configured version as well.

   .. versionadded:: 0.8.4

.. cmake:variable:: LIBRA_CXX_STANDARD

   :default: Autodetected to the latest C++ standard supported by
             :cmake:variable:`CMAKE_CXX_COMPILER`.

   :type: CACHE STRING

   Respects :cmake:variable:`CMAKE_CXX_STANDARD`, if set/overridden.  Note that
   ``CXX_EXTENSIONS ON`` is set for the configured version as well.

   .. versionadded:: 0.8.4

.. cmake:variable:: LIBRA_GLOBAL_C_FLAGS

   :default: NO
   :type: CACHE BOOL

   Specify that the total set of C flags (diagnostic, sanitizer, optimization,
   defines, etc.) which are automatically set for registered targets should be
   applied globally via ``CMAKE_C_FLAGS_<build type>`` to all C files.

   Use with care, as applying said flags to external dependencies built
   alongside your code can cause a cascade of unintended errors. That said, for
   well-behaved dependencies, this can be a nice way of ensuring uniformity of
   build options when building from source.

.. cmake:variable:: LIBRA_GLOBAL_CXX_FLAGS

   :default: NO
   :type: CACHE BOOL

   Specify that the total set of C++ flags (diagnostic, sanitizer, optimization,
   defines, etc.) which are automatically set for registered targets should be
   applied globally via ``CMAKE_CXX_FLAGS_<build type>`` to all C++ files.

   Use with care, as applying said flags to external dependencies built
   alongside your code can cause a cascade of unintended errors. That said, for
   well-behaved dependencies, this can be a nice way of ensuring uniformity of
   build options when building from source.

   .. versionchanged:: 0.9.14

.. cmake:variable:: LIBRA_ERL

   :default: INHERIT
   :type: CACHE STRING

   Specify Event Reporting Level (ERL). LIBRA does not prescribe a given
   event reporting framework (e.g., log4ccx, log4c, spdlog) which must be
   used. Instead, it provides a simple declarative interface for specifying
   the desired *result* of framework configuration at the highest
   level. Possible values of this option are:

   - ``ALL`` - Event reporting is compiled in fully and linked with; that
     is, all possible events of all levels are present in the compiled
     binary, and whether an encountered event is emitted is dependent on the
     level and scope of the event (which may be configured at runtime).

   - ``FATAL`` - Compile out event reporting EXCEPT FATAL events.

   - ``ERROR`` - Compile out event reporting EXCEPT [FATAL, ERROR] events.

   - ``WARN`` - Compile out event reporting EXCEPT [FATAL, ERROR, WARN]
     events.

   - ``INFO`` - Compile out event reporting EXCEPT [FATAL, ERROR, WARN,
     INFO] events.

   - ``DEBUG`` - Compile out event reporting EXCEPT [FATAL, ERROR, WARN,
     INFO, DEBUG] events.

   - ``TRACE`` - Same as ``ALL``.

   - ``NONE`` - All event reporting compiled out.

   - ``INHERIT`` - Event reporting configuration should be inherited from a
     parent project which exposes it. This is the default because it prevents
     cluttering compiler commands with #defines for projects which don't use it.

.. cmake:variable:: LIBRA_ERL_EXPORT

   :default: NO
   :type: CACHE BOOL

   Make :cmake:variable:`LIBRA_ERL` visible to downstream projects; it is
   private by default. This allows you to create an arbitrary dependency graph
   w.r.t which projects define their own ERL vs. which inherit it from
   elsewhere.

.. cmake:variable:: LIBRA_PGO

   :default: NONE
   :type: CACHE STRING

   Generate a PGO build for the selected compiler, if supported. Possible values
   for this option are:

   - ``NONE``

   - ``GEN`` - Input stage. Generally, you would do something like::

       cmake -DLIBRA_PGO=GEN ..
       make
       ./bin/my_application  # Run with representative workload


     If you're using clang, you would then have to do something like::

       llvm-profdata merge -o default.profdata default*.profraw

   - ``USE`` - Final stage (after executing the ``GEN`` build to get
     profiling info and running)::

       cmake -DLIBRA_PGO=USE ..
       make

     The optimized binary in will be tuned based on the runtime behavior
     observed in when running with PGO instrumentation compiled in.

Requires :cmake:variable:`LIBRA_PGO` to be set to ``GEN`` or ``USE``.


.. cmake:variable:: LIBRA_VALGRIND_COMPAT

   :default: NO
   :type: CACHE BOOL

   Disable compiler instructions in 64-bit code so that programs will run under
   valgrind reliably.

.. cmake:variable:: LIBRA_LTO

   :default: NO
   :type: BOOL

   Enable Link-Time Optimization (LTO), also known as Interprocedural
   optimization (IPO). Compiler-independent.

   .. versionchanged:: 0.8.3
      This is automatically enabled by ``LIBRA_FORTIFY != NONE``.


.. cmake:variable:: LIBRA_STDLIB

   :default: UNDEFINED; use compiler built-in default.
   :type: CACHE STRING

   Enable using the standard library and/or select *which* standard library to
   use. You would only turn this off for bare-metal builds (e.g.,
   bootstraps). Valid values are:

   - ``NONE`` - Don't use the stdlib at all. Defines ``__nostdlib__`` macro for
     all source files.

   - ``CXX`` - Use libc++, if the compiler supports it.

   - ``STDCXX`` - Use libstdc++, if the compiler supports it.

.. cmake:variable:: LIBRA_DEBUG_INFO

   :default: YES
   :type: CACHE BOOL

   Enable generation of debug symbols *independent* of whatever the default is
   with a given cmake build type.

   .. versionadded:: 0.8.4

   .. versionchanged:: 0.9.36 Renamed to ``LIBRA_DEBUG_INFO``, and default to
                       on.

.. cmake:variable:: LIBRA_NATIVE_OPT

   :default: NO
   :type: CACHE BOOL

   Enable compiler optimizations native to the current machine. This will likely
   make code compiled in this way *only* runnable on the current machine. Not
   recommended for use with docker/CI pipelines.

   .. versionadded:: 0.9.15

.. cmake:variable:: LIBRA_USE_COMPDB

   :default: NO
   :type: CACHE BOOL

  Tell LIBRA that all analysis tools should use a compilation database, rather
  than the default of extracting the necessary includes, #defines, etc. from the
  target itself. See :ref:`usage/analysis` for more details about this decision.

  For best results, if you are using any of the clang-based analysis targets,
  set the compiler to clang and then set :cmake:variable:`LIBRA_USE_COMPDB`. If
  you are using e.g., gcc as the compiler, clang-based analysis may still work,
  but generate some spurious warnings about a compilation database not being
  found/used.

   .. versionadded:: 0.9.36
