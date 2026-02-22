.. _usage/analysis:

===============
Static Analysis
===============

LIBRA attempts to make static analysis as easy and automated as possible; in
most cases, you should not have to do *anything* to get analysis working other
than to enable it via :cmake:variable:`LIBRA_ANALYSIS`.  LIBRA attempts to
detect the languages enabled for your cmake project, and sets the source files
to pass to the analysis targets appropriately. This allows for inclusion of
analysis tools which could be C/C++ only, and have them not cause errors when
used of a project of an incompatible type. You should never have to set
:cmake:variable:`LIBRA_ANALYSIS_LANGUAGE` directly to avoid warnings/errors.  An
individual target is created for each auto-registered source file, giving you
per-file warnings/errors, just like during compilation.

LIBRA supports the following analysis tools; more may be added in the future:

- `cppcheck`_
- `clang-check`_
- `clang-format`_
- `clang-tidy`_

Some of these tools have additional configuration variables--see
:ref:`usage/project-local/variables` for options.

Use of Compilation Database
===========================

All of these tools *can* run with compilation database, but can also work
without *IF* you give them the correct #defines, includes, and language
standard. LIBRA does *not* use a compilation database with any of the above
tools that support it, for the following reasons:

- clang-xx and cppcheck don't work well with using a compilation database with
  header only libraries without anything to compile (e.g., those without
  tests). We could assume that all header-only libs have tests, so it's safe to
  unconditionally use a compdb by default, but that's not guaranteed.

- If the compiler is something other than clang, there may be flags in the
  compdb that clang doesn't understand and will error out on if clang-based
  analysis is run.

This can be overriden with :cmake:variable:`LIBRA_USE_COMPDB` if desired. You
may need to do this if there are ``-f`` compiler options that your code needs to
compile correctly, since only #defines, includes, and language standard are
extracted from each target.

A Note on Best Practices
========================

Static analysis is generally a rather contested topic, in terms of *what* should
be analyzed/checked for a given project. LIBRA tries to be as general as
possible, and enables maximum warnings per-tool which are not noisy. E.g., it
disables warnings specific to the Fuschia project, because most of those are,
well, Fuschia-specific. You can of course override this, either by supply your
own tool configuration files, or using one of the LIBRA configuration variables.

Things get even more contested when it comes to coding style (e.g., clang-format
usage). LIBRA does not pretend that the config files it ships with are the
pinnacle of C/C++ style and best practices for all use cases and all projects;
but they are a reasonable set, and it has to ship with something. Pull
requests/suggestions are always welcome.

Tool Specifics
==============

cppcheck
--------

``--inline-suppr`` is unconditionally passed.

clang-check
-----------

No unusual baked-in cmdline args.

clang-format
------------

No unusual baked-in cmdline args. The baked-in config file generally follows
Google style.

clang-tidy
----------

``--header-filter`` is set to ``<repo>/include/*``, so errors from headers
outside of there will not be shown. Targets are created for each category of
checks:

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
following in the effective ``.clang-tidy`` has no effect:

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
:cmake:variable:`LIBRA_CLANG_TIDY_EXTRA_ARGS`.
