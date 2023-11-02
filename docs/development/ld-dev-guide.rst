.. SPDX-License-Identifier:  MIT

.. _dev/ld-guide:

==================================
ld/Linker Script Development Guide
==================================

- All variables which are intended to be accessible to C/C++/etc code should be
  ``__SPECIFIED_LIKE_THIS``. The two leading underscores should make sane
  programmers think verrryyyy carefully about how they use such variables.

- All variables which are *not* intended to be accessible to C/C++/etc code
  should be ``__specified_like_this``.

- For embedded targets, put the heap/stack into a dedicated section and use OS
  build-time capabilities to place memory for stacks/threads/tasks/etc into said
  section to provide a hard cap on memory usage via compile-time error if code
  needs grow. Rationale: correctness by construction.
