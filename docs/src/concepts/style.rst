.. SPDX-License-Identifier: MIT

.. _concepts/style:

==========
Code Style
==========

LIBRA's format checking and autoformatting use a baked-in ``.clang-format`` file
based on a hybrid of:

- `Google C++ Style <https://google.github.io/styleguide/cppguide.html>`_
- "Do as the standard library does"

This page documents the specific choices and where they diverge from the
baseline. To substitute your own config, see
:cmake:variable:`LIBRA_CLANG_FORMAT_FILEPATH`.

Indentation and line length
===========================

- **Indent width**: 2 spaces. No tabs.
- **Continuation indent**: 2 spaces for wrapped lines — same as the base
  indent, keeping wrapped expressions visually flush with the opening token
  rather than double-indented.
- **Column limit**: 82 characters. Slightly wider than the Google baseline
  (80) to reduce unnecessary line breaks in modern code with longer
  identifiers and namespace-qualified names, while still fitting
  side-by-side diffs on a standard terminal.

Alignment
=========

Consecutive declarations and assignments are column-aligned when they appear
in a block:

.. code-block:: cpp

   // declarations
   int         x     = 0;
   double      ratio = 1.5;
   std::string name  = "foo";

   // assignments
   x     = 10;
   ratio = 2.0;
   name  = "bar";

Trailing comments are also aligned within a block:

.. code-block:: cpp

   int x = 0;    // horizontal position
   int y = 0;    // vertical position
   int z = 0;    // depth

These rules apply to contiguous blocks only — a blank line resets alignment.

Pointers and references
=======================

The ``*`` and ``&`` bind to the **type**, not the variable name:

.. code-block:: cpp

   int* ptr;         // not int *ptr
   const std::string& ref;

This is a deliberate divergence from the Google baseline (which uses
right-alignment) in favour of the type-system reading: ``int*`` is a
distinct type from ``int``.

Function arguments and parameters
=================================

Bin-packing is disabled for both arguments and parameters. Every call or
declaration either fits on one line or puts each argument on its own line —
there is no middle ground where some arguments wrap and others do not:

.. code-block:: cpp

   // all on one line if it fits
   foo(alpha, beta, gamma);

   // all on separate lines if it doesn't
   foo(alpha,
       beta,
       gamma);

``AllowAllArgumentsOnNextLine`` is also disabled, so the "all arguments on
the next line as a block" form is not used. This keeps call sites visually
consistent.

Templates
=========

Template declarations always break before the ``<``:

.. code-block:: cpp

   template <typename T>
   void foo(T val);

   template <
     typename T,
     typename U>
   void bar(T t, U u);

Short functions
===============

Functions short enough to fit on one line are permitted to stay on one line,
including empty bodies and simple accessors:

.. code-block:: cpp

   int x() const { return x_; }
   void reset() {}

Constructor initialisers
========================

Constructor initialisers break before the colon, with each initialiser on
its own line if they do not fit on the constructor declaration line. If they
fit on the current line they stay there:

.. code-block:: cpp

   // fits on one line
   Foo::Foo() : x_(0), y_(0) {}

   // does not fit — break before colon, each initialiser on its own line
   Foo::Foo(int x, int y, int z)
       : x_(x),
         y_(y),
         z_(z) {}

Include ordering
================

Includes are automatically regrouped and sorted case-sensitively into the
following priority order on every format run. The groups are separated by
blank lines:

.. list-table::
   :header-rows: 1
   :widths: 10 30 60

   * - Priority
     - Pattern
     - Examples

   * - 1
     - STL extension-free headers (``<name>``)
     - ``<vector>``, ``<string>``, ``<algorithm>``

   * - 2
     - C standard library headers (``<name.h>``)
     - ``<stdio.h>``, ``<stdint.h>``, ``<string.h>``

   * - 3
     - Third-party ``.h`` headers with ``<>``
     - ``<yaml-cpp/yaml.h>``, ``<zmq.h>``

   * - 4
     - Third-party ``.hpp`` headers with ``<>``
     - ``<nlohmann/json.hpp>``, ``<spdlog/spdlog.hpp>``

   * - 5
     - Project-local headers with ``""``
     - ``"cogew/config/base_config.hpp"``

   * - 6
     - Everything else
     - Generated headers, conditionally included platform headers

Within each group, headers are sorted case-sensitively (uppercase before
lowercase). The format target rewrites include blocks to match this order
on every run — manual ordering within a group will not be preserved.

Comments
========

Comments are reflowed to fit within the column limit. This applies to both
line comments and block comments. Trailing comments within a block are
aligned as described above.
