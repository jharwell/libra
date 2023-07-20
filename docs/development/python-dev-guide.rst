.. SPDX-License-Identifier:  MIT

.. _dev-python-guide:

========================
Python Development Guide
========================

Coding Style
============

Follows the Google python style guide, except in the ways noted in the following
subsections.

Files
-----

- All source files should have the exact license text (e.g., GNU GPLv3), or an
  abbreviated version and a pointer to full license text (e.g., ``Copyright Foo
  Corp blah blah blah. See LICENSE.md for details``).

Imports
-------

When importing stuff, don't import classes directly, because:

#. Class names can get pretty long, while module/package names are generally
   short

#. It is EXTREMELY helpful to people unfamiliar with a code base looking at a
   file to be able to attach a semantically meaningful namespace to the class
   name via ``mymodule.MyClass``.

#. You can have the same class name in multiple modules imported and used in a
   single ``.py`` file without conflict. This is particularly helpful with
   "trampoline" classes which dispatch things from a common entry point to a
   selected implementation of something.

Naming
------

- All mathematical constants (e.g. ints, doubles, etc) should be
  ``kSPECIFIED_LIKE_THIS``: MACRO CASE + a preceding ``k``.

- All static class constants (you should not have non-static class constants)
  that are any kind of object should be ``kSpecifiedLikeThis``: Upper
  CamelCase + a preceding ``k``.

- Don't use smurf naming: When almost every class has the same prefix. IE, when
  a user clicks on the button, a ``SmurfAccountView`` passes a
  ``SmurfAccountDTO`` to the ``SmurfAccountController``. The ``SmurfID`` is used
  to fetch a ``SmurfOrderHistory`` which is passed to the ``SmurfHistoryMatch``
  before forwarding to either ``SmurfHistoryReviewView`` or
  ``SmurfHistoryReportingView``. If a ``SmurfErrorEvent`` occurs it is logged by
  ``SmurfErrorLogger to`` ``${app}/smurf/log/smurf/smurflog.log``. From
  `<https://blog.codinghorror.com/new-programming-jargon/>`_. Note that this
  does `not` apply to classes with common postfixes; e.g., ``battery_sensor``,
  ``light_sensor``, etc.
  ``SmurfLog``, etc.

- Don't put the type of the variable in the variable name (e.g., ``sender_list``
  for a list). Linus was right--it _is_ brain damaged.

- All private methods for a class start with ``_``.

Classes
-------

- Don't nest classes, unless there is a really good reason to. Generally nesting
  is a way to avoid doing a bunch of extra coding to create a set of
  classes/functions with proper encapsulation which is going to be easier to
  maintain anyway.

- When laying out classes, put special methods first (e.g., ``__repr__``), then
  public methods, and then private methods.

Miscellaneous
-------------

- FOR CRYING OUT LOUD, USE TYPE HINTS

Linting
=======

All projects should use the following linters/analysis tools:

- ``pylint``: However it is configured, code should pass with a grade of A.

- ``mypy``: Code probably won't pass in larger projects, but it's good to try.

- ``pytype``

Documentation
=============

- All classes should have:

    - A brief
    - A detailed description for non-casual users of the class

- All non-getter/non-setter member functions should be documentated with at
  least a brief, UNLESS those functions are overrides/inherited from a parent
  class, in which case they should be left blank (usually) and their
  documentation be in the class in which they are initially declared. All
  non-obvious parameters should be documented.

Tricky/nuanced issues with member variables should be documented, though in
general the module name + class name + member variable name + member variable
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
