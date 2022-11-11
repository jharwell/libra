.. _ln-libra-c-dev-guide:

===================
C Development Guide
===================

Unsurprisingly, some of the items in this development guide are dictated by
LIBRA, and are intended for use with it; these are clearly stated below. If you
are not using LIBRA, then you can ignore them if you want to--but you shouldn't!

In general, follow the Linux kernel C style guide (unless something below
contradicts it, then go with what is below).

Coding Style
============

Files
-----

- All source files should have the exact license text (e.g., GNU GPLv3), or an
  abbreviated version and a pointer to full license text (e.g., ``Copyright Foo
  Corp blah blah blah. See LICENSE.md for details``).


- All source files have the ``.c`` extension, and all header files have the
  ``.h``, to clearly distinguish them from C++ code, and not to confuse the
  tools used.

- Exactly one class/struct definition per ``.c``\/``.h`` file, unless there is a
  very good reason to do otherwise. struct definitions nested within other
  structs are exempt from this rule, but their use should still be minimized and
  well documented.

- The "namespace" hierarchy exactly corresponds to the directory hierarchy that
  the source/header files for classes can be found in. Since C doesn't really
  have namespaces, something that is logically named as
  ``module_component_XX`` should be found in ``src/module/component``. Principle
  of least surprise.

- The curly brace must always be the last code thing on the line; don't put it
  on its own line.

Naming
------

- All file, class, variable, enum, namespace, etc. names are
  ``specified_like_this``, NOT ``specifiedLikeThis`` or
  ``SpecifiedLikeThis``. Rationale: Most of the time you should not really need
  to know whether the thing in between ``::`` is a class, namespace, enum,
  etc. You really only need to know what operations it has. This also makes the
  code play nicely with the STL/boost from a readability point of view.

- Never typedef structs. You can typedef types though (i.e., ``int64_t``).

- All mathematical constants (e.g. ints, doubles, etc) should be
  ``kSPECIFIED_LIKE_THIS``: MACRO CASE + a preceding ``k``.

- All static class constants (you should not have non-static class constants)
  that are any kind of object should be ``kSpecifiedLikeThis``: Upper
  CamelCase + a preceding ``k``.

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

Class Layout
------------

Miscellaneous
-------------

- Tabs are 4 characters.

- ALWAYS use ``{}``, even for one line bodies, because it makes things WAY LESS
  error prone.

- Non-const static variables should be avoided.

- Do not use Hungarian notation. Linus was right--it _is_ brain damaged.

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
