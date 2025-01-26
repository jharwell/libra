.. _usage/testing:

=======
Testing
=======

LIBRA attempts to make building and running unit/integration/etc tests as
painless as possible through automatic test discovery if ``LIBRA_TESTS=YES``
(see :ref:`usage/project-local`). Some important points:

- Tests are not included in the default build. This can greatly reduce build
  times when you *aren't* updating the tests/aren't interested in running them
  yet, for whatever reason (e.g., you are debugging something which can't be
  tested in isolation with a unit test).

- ``make test`` *runs* all built tests, but does not build any tests; adding
  tests as dependencies to this built-in target doesn't seem to work. If you
  want to build *AND* run tests in one shot, do ``make build-and-test`` instead.

Using CDash
===========

CTest also has the ability to build and run tests, gather coverage info, and
report results to a centralized server; LIBRA does not currently use this
functionality, though it might in the future.
