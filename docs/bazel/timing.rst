=============
Timing Builds
=============

Bazel provides intrinsic support for timing how long it takes to analyze stuff,
but not for seeing why certain files/targets take longer to compile. To analyze
that, we need additional tooling. The are two ways to do this: the quick and
dirty/one-off way, and the proper way with aspects.

Quick And Dirty
===============

#. Add ``--sandbox_debug`` and ``spawn_strategy=standalone`` to your bazel build
   cmd to make bazel behave just like a cmake/make build.

   .. IMPORTANT:: Make sure NONE of the packages you are building define any
                  header files with the same name as the standard library--you
                  aren't protected by bazel's sandboxing anymore, and weird
                  errors can result. clapack is an example of a library which
                  can cause problems when sandboxing is in play, but DOES when
                  it isn't, because some versions define a ``ctype.h`` on its
                  exported include paths.

#. If there is a default toolchain set in your ``.bazelrc``, remove it. If you
   have a default set.

#. Add ``--copt=-ftime-trace`` to your bazel build cmd to enable clang's time
   tracking functionality.

#. If you already have a clang toolchain installed/selectable, select it via
   ``--config=...``. Otherwise,invoke bazel as ``CC=clang bazel <...>`` to force
   bazel to using the locally installed clang. This is obviously non-hermetic
   and something you should never commit...

#. After the build, the .json files can be analyzed with a number of tools; I
   would recommend the `Clang Build Analyzer
   <https://github.com/aras-p/ClangBuildAnalyzer>`_ even though it isn't
   graphical because it can look at the whole build at once::

     ClangBuildAnalyzer --all $(bazel info execution_root) out.bin
     ClangBuildAnalyzer --analyze out.bin

   You'll get a nice text summary which you can use to inform your optimization
   efforts.

The Proper Way: Bazel Aspects
=============================
