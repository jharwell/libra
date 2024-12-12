.. _usage/capabilities/configure-time:


Configure-Time Knobs
====================

The following variables are available for fine-tuning the cmake configuration
process. All of these variables can be specified on the command line via ``-D``,
or put in your ``project-local.cmake``--see :ref:`usage/project-local` for
details.

.. _usage/capabilities/configure-time/libra:

Knobs For Configuring LIBRA/Cmake
---------------------------------

.. tabs::

   .. tab:: LIBRA_DEPS_PREFIX

      The location where cmake should search for other locally installed
      libraries (e.g., ``$HOME/.local``). VERY useful to separate out 3rd party
      headers which you want to suppress all warnings for by treating them as
      system headers when you can't/don't want to install things as root.

      Only available if ``LIBRA_DRIVER=SELF``.

      Default: ``$HOME/.local/system``

   .. tab:: LIBRA_DRIVER

      The *primary* user-visible driver to LIBRA, if any. Possible values are:

      - ``SELF`` - LIBRA itself is the driver/main way users interact with the
        build system; for all intents and purposes, LIBRA *IS* the build
        system. It also handles packaging duties, to the extent that cmake
        supports packaging.

      - ``CONAN`` - CONAN is the primary driver of the build system. It sets up
        the environment and handles all packaging tasks. LIBRA only has to run
        the actual builds.

      Default: SELF.

   .. tab:: LIBRA_SUMMARY

      Show a configuration summary after the configuration step finishes.

      Default: NO.

.. _usage/capabilities/configure-time/sw-eng:

Knobs For Supporting SW Engineering
-----------------------------------

.. tabs::

   .. tab:: LIBRA_DOCS

      Enable documentation build via ``make apidoc``.

      Default: NO.

   .. tab:: LIBRA_CODE_COV

      Build in runtime code-coverage instrumentation for use with ``make
      precoverage-report`` and ``make coverage-report``.

      Default: NO.

   .. tab:: LIBRA_SAN

      Build in runtime checking of code using any compiler. When passed, the
      value should be a comma-separated list of sanitizer groups to enable:

      - ``MSAN`` - Memory checking/sanitization.

      - ``ASAN`` - Address sanitization.

      - ``SSAN`` - Aggressive stack checking.

      - ``UBSAN`` - Undefined behavior checks.

      - ``TSAN`` - Multithreading checks.

      - ``None`` - None of the above.

      The first 4 can generally be stacked together without issue. Depending on
      compiler; the thread sanitizer is incompatible with some other sanitizer
      groups.

      Default: "None".

   .. tab:: LIBRA_ANALYSIS

      Enable static analysis targets for checkers, formatters, etc. See below
      for the ``make`` targets enabled (assuming the necessary executables are
      found).

      Default: NO.

   .. tab:: LIBRA_OPT_REPORT

     Enable compiler-generated reports for optimizations performed, as well as
     suggestions for further optimizations.

     Default: NO.

   .. tab:: LIBRA_FORTIFY


      Build in compiler support/runtime checking of code for heightened
      security. Which options get passed to compiler/linker AND which groups are
      supported is obviously compiler dependent.

      .. IMPORTANT:: When enabling things using this variable, you probably will
                     have to compile *everything* with the same settings to
                     avoid getting linker errors.

      When passed, the value should be a comma-separated list of groups to
      enable:

      - ``STACK`` - Fortify the stack: add stack protector, etc.

      - ``SOURCE`` - Fortify source code via ``_FORTIFY_SOURCE=2``.

      - ``LIBCXX_FAST`` - Fortify libc++ with the set of "fast" checks. clang
        only. See `here <https://libcxx.llvm.org/Hardening.html>`_ for more
        details. LIBRA does not currently set clang to use libc++ for you.

      - ``LIBCXX_EXTENSIVE`` - Fortify libc++ with the set of "extensive"
        checks. clang only. See `here <https://libcxx.llvm.org/Hardening.html>`_
        for more details. LIBRA does not currently set clang to use libc++ for
        you.

      - ``LIBCXX_DEBUG`` - Fortify libc++ with a comprehensive set of debug
        checks that might slow things down a lot. clang only. See `here
        <https://libcxx.llvm.org/Hardening.html>`_ for more details. LIBRA does
        not currently set clang to use libc++ for you.

      - ``CFI`` - Fortify against Control Flow Integrity (CFI) attacks. clang
        only.

      - ``GOT`` - Fortify against Global Offset Table (GOT) attacks with
        read-only relocations and immediate symbol binding on load.

      - ``FORMAT`` - Fortify against formatting attacks.

      - ``ALL`` - All of the above.

      - ``NONE`` - None of the above.

      Default: NONE. Any non-None value also sets ``LIBRA_LTO=YES``.

      .. versionadded:: 0.8.3

   .. tab::  LIBRA_TESTS

      Enable building of tests via:

      - ``make unit-tests`` (unit tests only)

      - ``make integration-tests`` (integration tests only)

      - ``make tests`` (all tests)

      Default: NO.

.. _usage/capabilities/configure-time/builds:

Knobs For Configuring Builds
----------------------------

.. tabs::


   .. tab:: LIBRA_MT

      Enable multithreaded code/OpenMP code via compiler flags (e.g.,
      ``-fopenmp``), and/or selecting additional code for compilation.

      Default: NO.

   .. tab:: LIBRA_MP

      Enable multiprocess code/MPI code for the selected compiler, if
      supported.

      Default: NO.

   .. tab:: LIBRA_FPC

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

      - ``INHERIT`` - FPC configuration should be inherited from a parent
        project which exposes it.

       Default: RETURN.

   .. tab:: LIBRA_ERL

      Specify Event Reporting Level (ERL). LIBRA does not prescribe a given
      event reporting framework (e.g., log4ccx, log4c) which must be
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
        parent project which exposes it.

     Default: "".

   .. tab:: LIBRA_PGO

      Generate a PGO build for the selected compiler, if supported. Possible
      values for this option are:

      - ``NONE``

      - ``GEN`` - Input stage

      - ``USE`` - Final stage (after executed the ``GEN`` build to get
        profiling info).

      Default: NONE.

   .. tab:: LIBRA_VALGRIND_COMPAT

      Disable compiler instructions in 64-bit code so that programs will run
      under valgrind reliably.

      Default: NO.

   .. tab:: LIBRA_LTO

      Enable Link-Time Optimization.

      Default: NO.

      .. versionchanged:: 0.8.3
         This is automatically enabled by ``LIBRA_FORTIFY != NONE``.


   .. tab:: LIBRA_STDLIB

      Enable using the standard library. You would only turn this off for
      bare-metal builds (e.g., bootstraps).

      Default: YES.

   .. tab:: LIBRA_NO_DEBUG_INFO

      Disable generation of debug symbols *independent* of whatever the default
      is with a given cmake build type.

      Default: NO.

      .. versionadded:: 0.8.4
