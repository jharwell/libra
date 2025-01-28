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

clang-tidy
==========

Targets are created for each category of checks:

- abseil

- cppcoreguidelines

- readability

- hicpp

- bugprone

- cert

- performance

- portability

- concurrency

- modernize

- misc

- google

Because some warnings are enabled by default in each category, in order to ONLY
get warnings from a given category when building the target for that category
(e.g., only get modernize checks for ``make analyze-clang-tidy-modernize``),
LIBRA disables all checks via ``-*`` and then enables all checks for the
category. This whitelisting approach works well, EXCEPT that something like the
following in the effective ``.clang-tidy`` has no effect::

.. code-block:: YAML

   ---
   Checks:
   '-*,
   -cppcoreguidelines-pro-bounds-constant-array-index,
   -clang-diagnostic-*,
   -fuchsia-default-argument-calls,
   -fuchsia-overloaded-operator,
   -modernize-pass-by-values,
   -modernize-use-trailing-return-type
   '

This is expected because the docs for ``--checks`` says::

  Comma-separated list of globs with optional '-' prefix. Globs are processed in
  order of appearance in the list. Globs without '-' prefix add checks with
  matching names to the set, globs with the '-' prefix remove checks with
  matching names from the set of enabled checks. This option's value is appended
  to the value of the 'Checks' option in .clang-tidy file, if any.

So, when using LIBRA's automation, if you want to selectively disable checks
within a category *other* than the ones which LIBRA disables, you can use
``LIBRA_CLANG_TIDY_EXTRA_ARGS`` as described in :ref:`usage/project-local`.
