.. _usage/testing:

=======
Testing
=======

LIBRA attempts to make building and running unit/integration/etc tests as
painless as possible through automatic test discovery if ``LIBRA_TESTS=YES``
(see :ref:`usage/project-local`).

.. _usage/testing/builtin:

Leveraging CMake/CTest ``test`` Target
======================================

You would think that you could add dependencies to the ``test`` target to build
the tests and then run them in a single command, but it doesn't, and I'm not
sure why. Thus, in LIBRA ``make test`` *runs* all built tests, but does not
build any tests; adding tests as dependencies to this built-in target doesn't
seem to work. If you want to build *AND* run tests in one shot, do ``make
build-and-test`` instead.

.. _usage/testing/default-build:

Tests Are Not Included In Default Build
=======================================

When writing code with LIBRA, your coding can be broken down in the following
functional ways:

.. list-table::
   :header-rows: 1

   * - Category

     - Include unit/integration tests?

     - Why?


   * - Initial code development

     - No

     - You are just trying to get something implemented, and aren't worried
       *yet* about getting test coverage, just that your code builds. Thus,
       having to wait for tests to build is a minor inconvenience (only would
       happen after the library/executable you are modifying finally compiles).

   * - Writing tests to validate the code you just wrote

     - Yes

     - Since you are actively writing unit/integration/etc tests, logically you
       want to build the tests with a single command to minimize cognitive
       load. LIBRA provides this; all ``XX-test`` targets depend on the main
       executable/library.


   * - Validating the code you just wrote in a broader sense (e.g., in
       integration, on real hw, etc.).

     - No

     - The code you wrote has already passed its unit/integration tests; if it
       didn't you wouldn't be testing it at a higher level. Thus, having to wait
       for potentially a large number of unit tests to build and link repeatedly
       is a waste of time.

       This use case is the primary reason why LIBRA does not include any
       defined tests in the default build.


Using CDash
===========

CTest also has the ability to build and run tests, gather coverage info, and
report results to a centralized server; LIBRA does not currently use this
functionality, though it might in the future.
