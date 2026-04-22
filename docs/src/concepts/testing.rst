.. SPDX-License-Identifier: MIT

.. _concepts/testing:

=======
Testing
=======

How to work with LIBRA's test infrastructure day-to-day. For the
reference material on test discovery, naming conventions, and the test
harness, see :ref:`reference/testing`.

Why tests are not in the default build
=======================================

LIBRA does not include test targets in the default build. The reasoning
follows the natural rhythm of development:

.. list-table::
   :header-rows: 1
   :widths: 40 15 45

   * - Phase
     - Include tests?
     - Why

   * - Initial code development
     - No
     - You are trying to get something implemented. Waiting for tests
       to build when your library hasn't compiled yet yet adds friction
       without value.

   * - Writing tests to validate what you just wrote
     - Yes
     - You want one command to build and run. ``make build-and-test``
       provides this; all test targets depend on the main target.

   * - Validating in a broader context (integration, real hardware)
     - No
     - The code already passed unit and integration tests. Rebuilding
       a large test suite on every iteration is wasted time.

Use ``make all-tests`` or ``clibra test`` explicitly when you want
tests built. Use ``make build-and-test`` or ``clibra test`` when you
want them built and run.
