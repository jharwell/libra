.. SPDX-License-Identifier:  MIT

.. _dev-c-guide:

===================
C Development Guide
===================

Unsurprisingly, some of the items in this development guide are dictated by
LIBRA, and are intended for use with it; these are clearly stated below. If you
are not using LIBRA, then you can ignore them if you want to--but you shouldn't!

In general, follow the Linux kernel C style guide (unless something below
contradicts it, then go with what is below).

THE GOLDEN RULE
===============

From the GNOME developer site::

  The single most important rule when writing code is this: check the
  surrounding code and try to imitate it.

  As a maintainer it is dismaying to receive a patch that is obviously in a
  different coding style to the surrounding code. This is disrespectful, like
  someone tromping into a spotlessly-clean house with muddy shoes.

  So, whatever this document recommends, if there is already written code and
  you are patching it, keep its current style consistent even if it is not your
  favorite style.

This style guide is always a work in progress, so you may encounter code written
against older versions of it: update it incrementally/locally if possible to the
latest version. If you can't do so easily (i.e., it would be a extra refactoring
task), then stick with the original style unless you _know_ are going to be
changing more than 50% of a file, then go ahead and update.

Commandments
============

These are higher-level stylistic advice which has been hard-fought and
hard-won. Ignore them at your peril; read: FOLLOW THEM.

#. Thou shalt include configurable debugging/logging statements in thy
   code. Thy statements shall be subject to conditional compilation to turn
   off/on in release/debug builds, as well as configurable the verbosity of the
   logger for each class/module/whatever can be turned changed independently.

#. Thy debugging/logging statements shall be of sufficient quality that **NO
   ADDITIONAL** ``printf()`` statements are required to debug ANY problem in the
   code. This makes in MUCH easier to triage and fix errors that other people
   find with your code.

#. Thou shalt strive to make thy code "correct by construction". This includes:

   - Putting ``assert()`` statements throughout thy code (probably in a macro
     with a logging statement which is triggered on failure). These statements
     can be easily compiled away in release builds, AND give thou confidence
     that when thy code is running without crashing, it is running correctly.

Coding Style
============

Files
-----

- All source files should have either:

  - An abbreviated version of the license text and a pointer to full license
    text (e.g., ``Copyright Foo Corp blah blah blah. See LICENSE.md for
    details``).

  - An SPDX identifier; e.g., ``SPDX-License-Identifier: MIT``.

- All source files have the ``.c`` extension, and all header files have the
  ``.h``, to clearly distinguish them from C++ code, and not to confuse the
  tools used.

- The "namespace" hierarchy exactly corresponds to the directory hierarchy that
  the source/header files for classes can be found in. Since C doesn't really
  have namespaces, something that is logically named as
  ``module_component_XX`` should be found in ``src/module/component``. Principle
  Of Least Surprise.

- The curly brace must always be the last code thing on the line; don't put it
  on its own line.

- Don't use ``#ifndef FOO_H`` followed by ``#define FOO_H``\--use ``#pragma
  once`` instead. It is supported by all major compilers, and makes header files
  way easier to move around without mind-numbing refactoring.

Naming
------

- All file, class, variable, enum, namespace, etc. names are
  ``specified_like_this``, NOT ``specifiedLikeThis`` or
  ``SpecifiedLikeThis``. Rationale: Most of the time you should not really need
  to know whether the thing in between ``::`` is a class, namespace, enum,
  etc. You really only need to know what operations it has. This also makes the
  code play nicely with the STL/boost from a readability point of view.

- Never typedef structs. You can typedef types though (i.e., ``int64_t``). That
  way, you KNOW if you see something with a ``_t`` it is a type, NOT a
  ``struct``.

- All types should end in ``_t``; e.g., ``int64_t``.

- All mathematical constants (``#define`` or otherwise) (e.g. ints, doubles,
  etc) should be ``kSPECIFIED_LIKE_THIS``: MACRO CASE + a preceding ``k``.

- All constants which are not mathematical constants ``kSpecifiedLikeThis``:
  Upper CamelCase + a preceding ``k``.

- All enum values should be ``ekSPECIFIED_LIKE_THIS``: MACRO_CASE + a preceding
  ``ek``. The rationale for this is that it is useful to be able to tell at a
  glance if a constant is a mathematical one or only serves as a logical
  placeholder to make the code more understandable. The preceding ``ek`` does
  hinder at-a-glance readability somewhat, but that is outweighed by the
  increased at-a-glance code comprehension.

- All enum names should be postfixed with ``_type``, in order to enforce
  semantic similarity between members when possible (i.e. if it does not make
  sense to do this, should you really be using an enum vs. a collection of
  ``constexpr`` values?).

Miscellaneous
-------------

- Use spaces NOT tabs.

- ALWAYS use ``{}``, even for one line bodies, because it makes things WAY LESS
  error prone.

- Non-const static variables should be avoided.

- Do not use Hungarian notation. Linus was right--it _is_ brain damaged.

- When testing ``==/!=`` with a CONSTANT, the constant goes on the lhs, because
  that way if you mistype and only put a single ``=`` you'll get a compiler
  error rather than it (maybe) silently compiling into a bug.

- Don't use ``//`` style comments--use ``/* */`` style comments. This is
  because (1) the generally force you NOT to put stuff at the end of a line
  where it is more likely to hamper readability/be missed by the reader, and (2)
  they are easier to reader because they are symmetric.

- When a ``/* */`` style comment is over one line, format it symmetrically, like
  so, to improve readability::

    /* A one-line comment */
    int a = 4;

    /*
     * A much longer comment that is easier to read because it is symmetrically
     * written.
     */
     int b = 7;

Linting
=======

- Header ordering (this is done by ``clang-format``, as configured).

- Line length >= 80 ONLY if it is only 1-2 chars too long, and breaking the
  line would decrease readability. The formatter generally takes care of this.

Code should pass the clang-tidy linter, which checks for style elements like:

- All global variables prefixed with ``g_``.

- All functions less than 100 lines, with no more than 5 parameters/10
  branches. If you have something longer than this, 9/10 times it can and
  should be split up.

Function Parameters
===================

- Only primitive types should be passed by value; all other more complex types
  should be passed by reference, constant reference, or by pointer. If for some
  reason you *DO* pass a non-primitive type by value, the doxygen function
  header should clearly explain why.

- ``const`` parameters should be declared before non-``const`` parameters when
  possible, unless doing so would make the semantics of the function not make
  sense.

Documentation
=============

- All classes should have:

    - A doxygen brief
    - A group tag
    - A detailed description for non-casual users of the class

- All non-getter/non-setter member functions should be documentated with at
  least a brief, UNLESS those functions are overrides/inherited from a parent
  class, in which case they should be left blank (usually) and their
  documentation be in the class in which they are initially declared. All
  non-obvious parameters should be documented.

Tricky/nuanced issues with member variables should be documented, though in
general the namespace name + class name + member variable name + member variable
type should be enough documentation. If its not, chances are you are naming
things somewhat obfuscatingly and need to refactor.

Testing
=======

All NEW classes should have some basic unit tests associated with them, when
possible (one for each major public function that the class provides). For any
*existing* classes that have *new* public functions added, a new unit test
should also be added. It is not possible to create unit tests for all classes,
as some can only be tested in an integrated manner, but there many that can and
should be tested in a stand alone fashion.
