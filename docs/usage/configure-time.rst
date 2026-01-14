.. _usage/configure-time:

==============
Configure-Time
==============

File Discovery
==============

- All files under ``src/`` ending in:

  - ``.c``
  - ``.cpp``

  are globbed as source files (see :ref:`startup/req` for repository layout
  requirements) so that if you add a new source file, rename a source file,
  etc., you just need to re-run cmake. This means you don't have to MANUALLY
  specify all the files in the cmake project. Woo-hoo!

  .. NOTE:: See :ref:`philosophy/globbing` for rationale on why globs are used,
     contrary to common cmake guidance.

- All files under ``tests/`` ending in a specified pattern are recursively
  globbed as unit test files which will be compiled into executable unit tests
  at build time if ``LIBRA_TESTS=YES``. See :ref:`usage/project-local/variables`
  more details on this configuration item. Same for integration tests.
  ``${LIBRA_INTEGRATION_TEST_MATCHER.{c,cpp}}``.

- All files under ``tests/`` ending in a specified pattern are recursively
  globbed as the test harness for unit/integration tests. All test harness files
  will be compiled into static libraries at build time and all test targets link
  against them if ``LIBRA_TESTS=YES``.

.. NOTE:: The difference between unit tests and integration tests is purely
          semantic, and exists solely to help organize your tests. LIBRA treats
          both types of tests equivalently.


The following variables are available for fine-tuning the cmake configuration
process; thus, these variables are indended to be set on the command line via
``-D``, as they enable/disable LIBRA features, instead of configuring a
feature. However, *most* can be put in your ``project-local.cmake`` if you want
to--see :ref:`usage/project-local` for details about restrictions.

.. IMPORTANT:: Unless specified otherwise, all knobs only apply to the current
               project and/or target; i.e., no ``CMAKE_XXX`` global variables
               are set. This helps to prevent untended cascades of build options
               which might cause issues.

.. _usage/configure-time/libra:

Knobs For Configuring LIBRA/CMake
=================================


.. cmake:variable:: LIBRA_DEPS_PREFIX

   :default: $HOME/.local/system
   :type: STRING

   The location where cmake should search for other locally installed libraries
   (e.g., ``$HOME/.local``). VERY useful to separate out 3rd party headers which
   you want to suppress all warnings for by treating them as system headers when
   you can't/don't want to install things as root.

   Only available if ``LIBRA_DRIVER=SELF``. Cannot be set in
   ``project-local.cmake``.

.. cmake:variable:: LIBRA_DRIVER

   :default: SELF
   :type: STRING

   The *primary* user-visible driver to LIBRA, if any. Possible values are:

   - ``SELF`` - LIBRA itself is the driver/main way users interact with the
     build system; for all intents and purposes, LIBRA *IS* the build system. It
     also handles packaging duties, to the extent that cmake supports packaging.

   - ``CONAN`` - CONAN is the primary driver of the build system. It sets up the
     environment and handles all packaging tasks. LIBRA only has to run the
     actual builds.

.. cmake:variable:: LIBRA_SUMMARY

   :default: YES
   :type: BOOL

   Show a configuration summary after the configuration step finishes.

.. _usage/configure-time/sw-eng:

Knobs For Supporting SW Engineering
===================================


.. cmake:variable:: LIBRA_DOCS

   :default: NO
   :type: BOOL

   Enable documentation build via ``make apidoc``.

.. cmake:variable:: LIBRA_CODE_COV

   :default: NO
   :type: BOOL

   Build in runtime code-coverage instrumentation for use with ``make
   precoverage-report`` and ``make coverage-report``.


.. cmake:variable:: LIBRA_SAN

   :default: NONE
   :type: STRING

   Build in runtime checking of code using any compiler. When passed, the
   value should be a comma-separated list of sanitizer groups to enable:

   - ``MSAN`` - Memory checking/sanitization.

   - ``ASAN`` - Address sanitization.

   - ``SSAN`` - Aggressive stack checking.

   - ``UBSAN`` - Undefined behavior checks.

   - ``TSAN`` - Multithreading checks.

   - ``NONE`` - None of the above.

   The first 4 can generally be stacked together without issue. Depending on
   compiler; the thread sanitizer is incompatible with some other sanitizer
   groups.

.. cmake:variable:: LIBRA_ANALYSIS

   :default: NO
   :type: BOOL

   Enable static analysis targets for checkers, formatters, etc. See below for
   the targets enabled (assuming the necessary executables are found).

.. cmake:variable:: LIBRA_OPT_REPORT

   :default: NO
   :type: BOOL

   Enable compiler-generated reports for optimizations performed, as well as
   suggestions for further optimizations.

.. cmake:variable:: LIBRA_FORTIFY

   :default: NONE. Any non-None value also sets ``LIBRA_LTO=YES``.
   :type: STRING

   Build in compiler support/runtime checking of code for heightened
   security. Which options get passed to compiler/linker AND which groups are
   supported is obviously compiler dependent.

   .. IMPORTANT:: When enabling things using this variable, you probably will
                  have to compile *everything* with the same settings to avoid
                  getting linker errors.

   When passed, the value should be a comma-separated list of groups to enable:

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

   .. versionadded:: 0.8.3

.. cmake:variable:: LIBRA_TESTS

   :default: NO
   :type: BOOL

   Enable building of tests via:

   - ``make unit-tests`` (unit tests only)

   - ``make integration-tests`` (integration tests only)

   - ``make regression-tests`` (regression tests only)

   - ``make tests`` (all tests)


.. _usage/configure-time/builds:

Knobs For Configuring Builds
============================


.. cmake:variable:: LIBRA_MT

   :default: NO
   :type: BOOL

   Enable multithreaded code/OpenMP code via compiler flags (e.g.,
   ``-fopenmp``), and/or selecting additional code for compilation.

.. cmake:variable:: LIBRA_MP

   :default: NO
   :type: BOOL

   Enable multiprocess code/MPI code for the selected compiler, if
   supported.

.. cmake:variable:: LIBRA_FPC

   :default: RETURN
   :type: STRING

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

.. cmake:variable:: LIBRA_FPC_EXPORT

   :default: NO
   :type: BOOL

   Make :cmake:variable:`LIBRA_FPC` visible to downstream projects; it is
   private by default. This allows you to create an arbitrary dependency graph
   w.r.t which projects define their own FPC vs. which inherit it from
   elsewhere.

.. cmake:variable:: LIBRA_C_STANDARD

   :default: Autodetected to the Latest C standard supported by
             ``CMAKE_C_COMPILER``.

   :type: STRING

   Respects ``CMAKE_C_STANDARD`` if set.

   .. versionadded:: 0.8.4

.. cmake:variable:: LIBRA_CXX_STANDARD

   :default: Autodetected to the latest C++ standard supported by
             ``CMAKE_CXX_COMPILER``.
   :type: STRING

   Respects ``CMAKE_CXX_STANDARD`` if set.

   .. versionadded:: 0.8.4

.. cmake:variable:: LIBRA_GLOBAL_C_STANDARD

   :default: NO
   :type: BOOL

   Specify that the what C standard is detected for the selected compiler is set
   globally via ``CMAKE_C_STANDARD``. This results in all targets, not just the
   automatically defined ``${PROJECT_NAME}`` target getting this property
   set. For this to work, this variable must be set *before* you define the
   ``project()`` *and* before you ``include(libra/project)``.

   .. versionadded:: 0.9.5

.. cmake:variable:: LIBRA_GLOBAL_CXX_STANDARD

    :default: NO
    :type: BOOL

    Specify that the what C++ standard is detected for the selected compiler is
    set globally via ``CMAKE_CXX_STANDARD``. This results in all targets, not
    just the automatically defined ``${PROJECT_NAME}`` target getting this
    property set. For this to work, this variable must be set *before* you
    define the ``project()`` *and* before you ``include(libra/project)``.

    .. versionadded:: 0.9.5

.. cmake:variable:: LIBRA_GLOBAL_C_FLAGS

   :default: NO
   :type: BOOL

   Specify that the total set of C flags (diagnostic, sanitizer, optimization,
   defines, etc.) which are automatically set for ``${PROJECT_NAME}`` should be
   applied globally via ``CMAKE_C_FLAGS_<built type>``.

   Use with care, as applying said flags to external dependencies built
   alongside your code can cause a cascade of unintended errors. That said, for
   well-behaved dependencies, this can be a nice way of ensuring uniformity of
   build options when building from source.

   .. versionchanged:: 0.9.14

      When disabled, the ``target_compile_options()`` and
      ``target_compile_definitions()`` set by LIBRA are PRIVATE not PUBLIC.

.. cmake:variable:: LIBRA_GLOBAL_CXX_FLAGS

   :default: NO
   :type: BOOL

   Specify that the total set of C++ flags (diagnostic, sanitizer,
   optimization, defines, etc.) which are automatically set for
   ``${PROJECT_NAME}`` should be applied globally via
   ``CMAKE_CXX_FLAGS_<built type>``.

   Use with care, as applying said flags to external dependencies built
   alongside your code can cause a cascade of unintended errors. That
   said, for well-behaved dependencies, this can be a nice way of
   ensuring uniformity of build options when building from source.

   .. versionchanged:: 0.9.14

      When disabled, the ``target_compile_options()`` and
      ``target_compile_definitions()`` set by LIBRA are PRIVATE, not PUBLIC.

.. cmake:variable:: LIBRA_ERL

   :default: ALL
   :type: STRING

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
     parent project which exposes it.

.. cmake:variable:: LIBRA_ERL_EXPORT

   :default: NO
   :type: BOOL

   Make :cmake:variable:`LIBRA_ERL` visible to downstream projects; it is
   private by default. This allows you to create an arbitrary dependency graph
   w.r.t which projects define their own ERL vs. which inherit it from
   elsewhere.

.. cmake:variable:: LIBRA_PGO

   :default: NONE
   :type: STRING

   Generate a PGO build for the selected compiler, if supported. Possible values
   for this option are:

   - ``NONE``

   - ``GEN`` - Input stage

   - ``USE`` - Final stage (after executing the ``GEN`` build to get
     profiling info).


.. cmake:variable:: LIBRA_VALGRIND_COMPAT

   :default: NO
   :type: BOOL

   Disable compiler instructions in 64-bit code so that programs will run under
   valgrind reliably.

.. cmake:variable:: LIBRA_LTO

   :default: NO
   :type: BOOL

   Enable Link-Time Optimization.

   .. versionchanged:: 0.8.3
      This is automatically enabled by ``LIBRA_FORTIFY != NONE``.


.. cmake:variable:: LIBRA_STDLIB

   :default: UNDEFINED; use compiler built-in default.
   :type: STRING

   Enable using the standard library and/or select *which* standard library to
   use. You would only turn this off for bare-metal builds (e.g.,
   bootstraps). Valid values are:

   - ``NONE`` - Don't use the stdlib at all. Defines ``__nostdlib__``.

   - ``CXX`` - Use libc++, if the compiler supports it.

   - ``STDCXX`` - Use libstdc++, if the compiler supports itn.

.. cmake:variable:: LIBRA_NO_DEBUG_INFO

   :default: NO
   :type: BOOL

   Disable generation of debug symbols *independent* of whatever the default is
   with a given cmake build type.

   .. versionadded:: 0.8.4

.. cmake:variable:: LIBRA_NATIVE_OPT

   :default: NO
   :type: BOOL

   Enable compiler optimizations native to the current machine. This will likely
   make code compiled in this way *only* runnable on the current machine. Not
   recommended for use with docker/CI pipelines.

   .. versionadded:: 0.9.15

.. cmake:variable:: LIBRA_UNSAFE_OPT

   :default: NO
   :type: BOOL

   Enable compiler optimizations which are considered "unsafe"; that is, can
   change numerical results. Most of these pertain to relaxing floating point
   rigor. Tread carefully!!!

   .. versionadded:: 0.9.15
