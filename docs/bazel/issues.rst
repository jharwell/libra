.. _bazel/issues:

====================
Current Bazel Issues
====================

This page captures most of the issues we are having with our usage of Bazel.

- Defining toolchains "properly", so our builds are truly hermetic.

- Defining a build process which does not require internet access/the ability to
  point Bazel to a local directory with all the installed toolchains. Would
  still want the ability to download everything from Satelles Gitlab for us, so
  maybe condition this on an envvar?

- Creating variables which can be set on the cmdline AND in a BUILD file for
  targets which:

  - Doesn't break usage of ``:all``.

  - Setting on cmdline overrides whatever setting is in a BUILD file.

- Migrating to bazelmod/bazel 7.0 from 6.4.

- No support/infrastructure set up for using bazel to run unit tests/smoke
  tests/etc on a dedicated device farm.

- Not sure if it would be effective in terms of saved build time, to set up a
  build pool of nodes which Bazel could connect to that all developers would use
  (as opposed to their local machines).

- Incorporating support for signed builds

- Can't set features via compiler toolchains in platform() call, or at the
  package level--only per-target or in bazelrc.
