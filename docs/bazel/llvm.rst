.. _dev/bazel/platforms:

==============================
Integrating The LLVM Toolchain
==============================

Platforms Background
====================

In Bazel, targets can specify which *platforms* they are compatible with via
``target_compatible_with``; that is, the sets of configuration for which it
makes sense to build a given target. This means:

- If you explicitly specific which platform(s) you want to build for on the
  cmdline, AND explicitly request to build a target which is not compatible with
  the platform(s) you specified, Bazel will throw an error.

- If you explicitly specific which platform(s) you want to build for on the
  cmdline, AND request that all targets in a package are built with
  e.g. ``//mypackage:all``, then Bazel will implicitly filter out targets
  incompatible with the platforms you selected. This behavior is not documented,
  afaict.

In Bazel, toolchains can also specify which platforms they are compatible with
via:

- ``target_compatible_with`` - The platforms that the toolchain can be
  used to build stuff for

- ``exec_compatible_with`` - The build-time execution environment. Usually, this
  says what OS a toolchain will work for, and a toolchain repo will provide a
  "suite" of toolchains which work for Linux, OSX, and Windows.


This all works out-of-the-box if you only build stuff for common desktop
environments, OSes, CPUs, etc.

Motivation
==========

Suppose:

- You need a set of custom "boards" for embedded development.

- Some of those custom boards also require one or more custom CPUs not
  intrinsically supported by Bazel.

- Some of those custom boards DO use CPUs already supported intrinsically
  by Bazel, such as ``armv7e-m``.

Further suppose that although use usually use gcc build things for your custom
platforms, you want to use a clang/LLVM toolchain to improve code robustness
through better warnings. The official, hermetic LLVM toolchain is here:
`<https://github.com/bazel-contrib/toolchains_llvm>`_. In it, that toolchain
declares that it is ``exec_compatible_with`` Linux via ``@platforms//os:linux``,
and ``target_compatible_with`` x86 via ``@platforms//cpu:x86_64`` and
``@platforms//cpu:x86_32``.

After cloning and following the setup instructions (mostly) I registered a
native x86_64 toolchain via::

  load("@toolchains_llvm//toolchain:deps.bzl", "bazel_toolchain_dependencies")
  load("@toolchains_llvm//toolchain:rules.bzl", "llvm_toolchain")

  bazel_toolchain_dependencies()

  llvm_toolchain(
      name = "llvm16_toolchain",

  )

This is different than what is recommended by the docs for non-bzlmod setups,
because I didn't want to "pollute" the ``WORKSPACE`` file with low-level
toolchain stuff--much better and more scalable to call a hook which recursively
handles all dependencies. Crucially, I don't register any toolchains via
``native.register_toolchain()``. Why?

After an insane amount of digging, I uncovered the following general tidbits
about toolchain resolution when multiple toolchains match all specified
constraints (which is my situation given I've been using gcc to natively compile
on Linux, and now want to use clang):

#. ``--extra_toolchains`` specified on cmdline is given highest priority.

#. Registration order of toolchains via ``native.register_toolchain()``.

Thus, to maintain a 1 -> 1 mapping for all platforms to exactly one toolchain
(which is generally what you want -> Principle of Least Surprise), don't
register the LLVM toolchain, in a ``.bzl`` or ``WORKSPACE`` file, and instead
register it via ``--extra_toolchains`` on the cmdline or in a ``.bazelrc``, so
that it is only selected when you actually want to use it.

So, I tried to tell Bazel I wanted to use my new toolchain via::

  bazel build --extra_toolchains=@llvm16_toolchain//:cc-toolchain-x86_64-linux //my:target

Which didn't work, because the platforms didn't match according to Bazel. There
are two goals here, in order of difficulty:

#. Get the LLVM/clang toolchain to build for a custom "board" which targets a
   desktop environment, such as
   ``@common-bazel//platforms:desktop-x86_64-linux``, defined as::

     platform(
         name = "desktop-x86_64-linux",
         constraint_values = [
             "@platforms//cpu:x86_64",
             "@platforms//os:linux",
             "@platforms//board:desktop",
         ],
     )

#. Get the LLVM/clang toolchain to cross-compile for a custom board which
   targets an embedded environment, such as
   ``@common-bazel//platforms/board:zynqmp``.


Challenge #1: Custom Platforms
==============================

In this scenario, you CANNOT simply add the necessary declarations under
``@common-bazel//platforms/cpu`` or ``@common-bazel//platforms/os``, because
e.g., ``@common-bazel//platforms/os:linux`` is treated as a *completely*
different constraint value than ``@platforms//os:linux``. So even if you
define::

  constraint_value(
      name = "linux",
      constraint_setting = ":os",
  )

under ``@common-bazel//platforms/os/BUILD``, since the LLVM toolchain defines
that it is compatible with ``@platforms//os:linux`` on the host, that toolchain
will always be skipped during toolchain resolution for any targets you try to
build which should be compatible with
``@common-bazel//platforms:desktop-x86_64-linux``.

To solve this, you have to clone the official Bazel platforms repo from
`<https://github.com/bazelbuild/platforms>`_ as a submodule somewhere within
your project workspace, registering it as::

  native.local_repository(
      name = "platforms",
      path = "/path/to/platforms"
  )

.. IMPORTANT:: Bazel will use this repository as ``@platforms`` instead of its
               built-in one, so doing this results in higher maintenance costs
               and possibly strange build errors if you get things wrong. But
               afaik, this is the only way to do this.

Then, make your custom modifications for CPU, OS, board, etc., to your local
``@platforms//``, and everything will work, in terms of resolving toolchains via
platform constraints. With this in place, I was able to specify the LLVM
toolchain via ``--extra_toolchains`` and successfully complete a native build!

Challenge #2: Native Compilation
================================

This requires modifying the LLVM toolchain repo to support new platforms by
using the following the ``llvm_toolchain`` rule instantiation::

  llvm_toolchain(
      name = "llvm16_toolchain",
      llvm_versions = {
          "linux-x86_64": "16.0.0",
      },
      cxx_standard = {"": "c++11"}, # C++11 for all platforms
      stdlib = {
          "linux-x86_64": "stdc++",
      },
      link_flags = {
          "linux-x86_64": [
              "-stdlib=libstdc++",
              "-lstdc++",
              "-lm",
          ],
  )


Some important notes:

- The LLVM toolchain provides attributes such as ``link_flags`` to customize the
  built-in flags for any defined toolchain, so you don't need to do it in a
  ``.bazelrc``.


- Specifying the standard library version as stdc++ is required, or at least I
  couldn't get it to work any other way. If you don't specify it, you get the
  builtin clang version, which does not appear work even for native compilation,
  or at least not without a lot of include path hackery.

With all of that in place, specifying a native 64-bit compilation x86 build on
linux using clang worked!

Challenge #3: Cross-Compilation
===============================

This requires modifying the LLVM toolchain repo to support new platforms by
performing the following steps (following their docs, which are *mostly*)
correct. I first tried adding cross-compilation support for 32-bit binaries on
x64, which is what the steps below are concretely for. For all steps, I added a
header to make it easier to add support for MORE platforms in the future.

#. Modify ``toolchain/cc_toolchain_config.bzl:89`` (rough line number), and
   add::

     ########################################
     # Extensions
     ########################################
     "linux-x86_32": (
         "clang-x86_64-x86_32-linux",
         "x86_32",
         "glibc_unknown",
         "clang",
         "clang",
         "glibc_unknown",
     ),

   Afaict, the contents of the dict item don't really matter to get stuff to
   build, but still need to be filled out to be reasonable. However, the
   ``linux-x86_32`` key DOES matter--see below.

#. Modify ``toolchain/internal/common.bzl:12`` (rough line number), and add::

     SUPPORTED_TARGETS = [
     ("linux", "x86_64"),
     ("linux", "aarch64"),
     ("darwin", "x86_64"),
     ("darwin", "aarch64"),
     ########################################
     # Extensions
     ########################################
     ("linux", "x86_32")
     ]

   The OS+arch tuple here is for supported target platforms, not host/exec
   platforms. The tuple also must EXACTLY match what you specified as the key in
   the previous step via ``<OS>-<ARCH>``, or you will get a VERY cryptic error.

#. Modify ``toolchain/internal/configure.bzl:304`` (rough line number), and
   add::

     ########################################
     # Extensions
     ########################################
     "linux-x86_32": "i686-linux-gnu",

   This is a map of your OS+arch key to a valid target system name clang will
   accept via ``--target``. ``x86_32-unknown-linux-gnu`` isn't valid, so I did a
   ``clang -print-targets`` to show the supported architectures and find what
   32-bit x86 needed to be. YMMV; I THINK that whatever you put here needs to
   match the name of the sysroot directory, but I'm not 100% sure.

#. Install the sysroot on the filesystem. On ubuntu 20.04, that meant installing
   the ``libstdc++-10-dev-i686-cross``, which puts the sysroot under
   ``/usr/i686-linux-gnu``.

   .. IMPORTANT:: You MUST also symlink ``/usr/i686-linux-gnu``->
                  ``/i686-linux-gnu`` to get things to work with these
                  instructions. Whatever its promises, the LLVM bazel toolchain
                  really only seems to work with sysroot=\ ``/``.

   If you are on a different OS, you'll need to do something different.


#. Finally, modify the ``toolchain_llvm`` rule instantiation::


     llvm_toolchain(
         name = "llvm16_toolchain",
         llvm_versions = {
             "linux-x86_64": "16.0.0",
             "linux-x86_32": "16.0.0",
             },
         sysroot = {
             "linux-x86_32": "/i686-linux-gnu",
         },
         cxx_standard = {"": "c++11"}, # C++11 for all platforms
         stdlib = {
            "linux-x86_32": "stdc++",
            "linux-x86_64": "stdc++",
         },
         link_flags = {
             "linux-x86_64": [
                "-lstdc++",
                "-lm",
             ],
             "linux-x86_32": [
                 "-m32",
                 "-lstdc++",
                 "-lm",
             ]
         },
         compile_flags = {
             "linux-x86_32": [
                 "-m32"
             ]
         },
         cxx_builtin_include_directories = {
            "linux-x86_32": [
                "/i686-linux-gnu"
            ]
         }
      )


Some important notes:

- Unless the host OS+architecture matches the target OS+architecture, that is
  treated as cross compilation (even for e.g. building 32 bit binaries on 64 bit
  linux). For all cross compilation, you have to provide a sysroot.

- The above configuration is NOT hermetic. It SHOULD work to glob all the needed
  headers+libraries into a filegroup(), and pass that as the sysroot, but that
  isn't the case, for unknown reasons.Well, there probably is a reason, I just
  can't figure it out yet.

- The LLVM toolchain provides attributes such as ``link_flags`` to customize the
  built-in flags for any defined toolchain, so you don't need to do it in a
  ``.bazelrc``.

- Specifying the standard library version as stdc++ is required, or at least I
  couldn't get it to work any other way. If you don't specify it, you get the
  builtin clang version, which does not appear to support cross compilation.

With all of that in place, specifying a 32-bit cross-compilation x86 build on
64-bit linux using clang worked!
