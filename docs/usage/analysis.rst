.. _usage/analysis:

===============
Static Analysis
===============

LIBRA attempts to make static analysis as easy and automated as possible; in
most cases, you should not have to do *anything* to get analysis working other
than to enable it via ``LIBRA_ANALYSIS=YES``.

LIBRA attempts to detect the languages enabled for your cmake project, and sets
the source files to pass to the analysis targets appropriately. This allows for
inclusion of analysis tools which could be C/C++ only, and have them not cause
errors when used of a project of an incompatible type. You should never have to
set ``LIBRA_ANALYSIS_LANGUAGE`` directly to avoid warnings/errors.

LIBRA supports the following analysis tools; more may be added in the future:

- cppcheck - ``--inline-suppr`` is unconditionally passed.

- clang-check - No unusual baked-in cmdline args.

- clang-format - No unusual baked-in cmdline args.

- clang-tidy - ``--header-filter`` is set to ``<repo>/include/*``, so errors
  from headers outside of there will not be shown.

Some of these tools have additional configuration variables--see
:ref:`usage/project-local` for options.

All of these tools *can* run with compilation database (and generally work
better with them), but can also work without *IF* you give it the correct
#defines, includes, etc. LIBRA works as follows when autogenerating static
analysis targets:

.. list-table::
   :header-rows: 1

   * - Target type

     - LIBRA action

   * - Shared library

     - Used compdb if it exists, otherwise obtain {defs, includes, etc.} from
       target directly.

   * - Static library

     - Used compdb if it exists, otherwise obtain {defs, includes, etc.} from
       target directly.

   * - Interface library

     - Obtain {defs, includes, etc.} from target directly.
