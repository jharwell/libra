.. SPDX-License-Identifier:  MIT

.. _dev/core-guide:

======================
Core Development Guide
======================

Language agnostic bits collected here in the interest of Don't Repeat Yourself
(DRY).

Commandments
============

These are higher-level stylistic advice which has been hard-fought and
hard-won. Ignore them at your peril; read: FOLLOW THEM.

#. Thou shalt imitate the surrounding code when writing new code.

   From the GNOME developer site::

    The single most important rule when writing code is this: check the
    surrounding code and try to imitate it.

    As a maintainer it is dismaying to receive a patch that is obviously in a
    different coding style to the surrounding code. This is disrespectful, like
    someone tromping into a spotlessly-clean house with muddy shoes.

    So, whatever this document recommends, if there is already written code and
    you are patching it, keep its current style consistent even if it is not
    your favorite style.

#. Thou shalt be compassionate towards code written against an older version of
   the style guide.

   All style guides are always a work in progress, so you may encounter code
   written against older versions of it: update it incrementally/locally if
   possible to the latest version. If you can't do so easily (i.e., it would be
   a extra refactoring task), then stick with the original style unless you
   *know* are going to be changing more than 50% of a file, then go ahead and
   update.

#. Thou shalt not bring thy favorite language's style into another language.

   E.g., don't write C++ code in the same style you would write python
   code. Also called "Man With His Favorite Hammer" mentality.

#. Thou shalt not reinvent the wheel.

   Before implementing something from scratch, check if it (or something close
   to it) is in the standard library. If it is--USE IT. If it's not, check if
   there is a *prominent* open-source library which has what you need. Prominent
   is key--don't immediately jump onboard to a github project that someone did
   for a class that *looks* like it might work, because chances are it actually
   won't.

#. Thou shalt not write code that is more complex than the problem being solved.

   If you find yourself doing this, chances are you are doing something wrong.

#. Thou shalt not commit code that is commented out.

   If you need it, include it uncommented. If you don't need it, why include it
   at all?  If it was previously there, it can be recovered in version
   control. If it wasn't previously there, you have just added cruft that
   someone else will have to parse and deal with.

#. Thou shalt not create "yo-yo" code that converts a value into a different
   representation, does something, and then converts it back.

#. Thou shalt not call idempotent functions multiple times.

   E.g., "just to be sure". If it says idempotent, treat it as such.

#. Thou shalt not create multiple versions of an algorithm to handle different
   types or operators, rather than using generics or passing callbacks to a
   generic implementation.

#. Thou shalt understand pointers and thy language's memory model.

#. Thou shalt write thy classes, and functions with high cohesion, low coupling.
