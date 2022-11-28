.. SPDX-License-Identifier:  MIT

.. _ln-libra-cxx-dev-guide:

=====================
C++ Development Guide
=====================

In terms of coding style, many aspects are pulled from the `CppCoreGuidelines
<https://github.com/isocpp/CppCoreGuidelines/blob/master/CppCoreGuidelines>`_,
though there are many parts which are ignored.

In general, follow the Google C++ style guide (unless something below
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
   ADDITIONAL** ``printf()/std::cout/std::cerr`` statements are required to
   debug ANY problem in the code. This makes in MUCH easier to triage and fix
   errors that other people find with your code.

#. Thou shalt strive to make thy code "correct by construction". This includes:

   - Use of ``static_assert()`` to check template requirements at compile time.

   - Putting ``assert()`` statements throughout thy code (probably in a macro
     with a logging statement which is triggered on failure). These statements
     can be easily compiled away in release builds, AND give thou confidence
     that when thy code is running without crashing, it is running correctly.

Coding Style
============

Files
-----

- All source files have the ``.cpp`` extension, and all header files have the
  ``.hpp`` extension (not a ``.h`` extension), to clearly distinguish them from
  C code, and not to confuse the tools used.

- Don't use ``#ifndef FOO_HPP`` followed by ``#define FOO_HPP``--use ``#pragma
  once`` instead. It is supported by all major compilers, and makes header files
  way easier to move around without mind-numbing refactoring.

- Exactly one class/struct definition per ``.cpp``\/``.hpp`` file, unless there
  is a very good reason to do otherwise. class/struct definitions nested within
  other classes/structs are exempt from this rule, but their use should still be
  minimized and well documented if they reside in the ``public`` part of the
  enclosing class.

- If a C++ file lives under ``src/my_module/my_file.cpp`` then its corresponding
  include file is found under ``include/<repo_name>/my_module/my_file.hpp``
  (same idea for C, but with the corresponding extensions). This is the
  Principle of Least Surprise, and makes it as easy as possible for people
  unfamiliar with the code to find stuff in it.

Naming
------

- All file, class, variable, enum, namespace, etc. names are
  ``specified_like_this``, NOT ``specifiedLikeThis`` or
  ``SpecifiedLikeThis``. Rationale: Most of the time you should not really need
  to know whether the thing in between ``::`` is a class, namespace, enum,
  etc. You really only need to know what operations it has. This also makes the
  code play nicely with the STL/boost from a readability point of view.

- Namespace names should NEVER contain underscores. This is because a name like
  "nest_acq" (short for "nest_acquisition") is actually two concepts: things
  related to nests, and things related to acquiring nests. Inevitably what will
  happen is you will need to create another namespace for leaving nests (say
  "nest_exit"), and put the two namespaces side by side. Clearly it should be
  "acq" and "exit" inside of a parent "nest" namespace. So if you can't use a
  single word/acronym for a given namespace, 99% of the time you should split it
  up. This also makes your code more open to extension but closed to
  modification.

- All structs that are "types" (e.g. convenient wrappers around a boolean
  status + possibly valid result of an operation) should have a ``_t`` postfix
  so that it is clear when constructing them that they are types and it is not a
  function being called (calls with ``()`` can seem ambiguous if you don't know
  the code). Types are collections of data members that generally should be
  treatable as POD, even if they are not (e.g. contain a std::vector).

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

- All template parameters should be in ``CamelCase`` and preceded with a
  ``T``. This is to make it very easy to tell at a glance that something is a
  template parameter, rather than an object type, in a templated class/function.

- All enum names should be postfixed with ``_type``, in order to enforce
  semantic similarity between members when possible (i.e. if it does not make
  sense to do this, should you really be using an enum vs. a collection of
  ``constexpr`` values?).

- ``#define`` for literal constants should be avoided, as it pollutes the global
  namespace. ``constexpr`` values in an appropriate namespace should be used
  instead.

Class Layout
------------

- Follow the Google C++ style ordering: ``public`` -> ``protected`` ->
  ``private`` layout, generally speaking. However, there are some cases when
  putting public accessors/mutators AFTER the declaration of private variables
  which they access/modify is required (e.g. ``RCPPSW_WRAP_FUNC()``).

- Within each access modifier section, the layout should be (in order):

    - ``using`` declarations (types or functions from base classes).
    - Type definitions.
    - Class constants (should hopefully be ``static constexpr const``).
    - Functions.

  The choice of this ordering is somewhat arbitrary, but it is necessary to have
  SOME sort of ordering, and this is already how I was generally doing most
  classes.

- Within the ``public`` section, the constructor, destructor, and any copy/move
  operators should be listed first among all the functions.

Miscellaneous
-------------

- Use spaces NOT tabs.

- Always use strongly typed enums (class enums) whenever possible to avoid name
  collisions. Sometimes this is not possible without extensive code contortions.

- When testing ``==/!=`` with a CONSTANT, the constant goes on the lhs, because
  that way if you mistype and only put a single ``=`` you'll get a compiler
  error rather than it (maybe) silently compiling into a bug.

- Non-const static variables should be avoided.

- Do not use Hungarian notation. Linus was right--it _is_ brain damaged.

- Class nesting should be avoided, unless it is an internal convenience
  ``struct`` to hold related data.

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

Code should pass the google C++ linter, ignoring the following items. For
everything else, the linter warnings should be addressed.

- Use of non-const references--I do this regularly. When possible, const
  references should be used, but sometimes it is more expressive and
  self-documenting to use a non-const reference in many cases.

- Header ordering (this is done by ``clang-format``, as configured.

- Line length >= 80 ONLY if it is only 1-2 chars too long, and breaking the
  line would decrease readability. The formatter generally takes care of this.

Code should pass the clang-tidy linter, which checks for style elements like:

- All members prefixed with ``m_``

- All constant members prefixed with ``mc_``.

- All global variables prefixed with ``g_``.

- All functions less than 100 lines, with no more than 5 parameters/10
  branches. If you have something longer than this, 9/10 times it can and
  should be split up.

Function Parameters
===================

Most of these are from Herb Sutter's excellent C++ guidelines on smart pointers
[here](https://herbsutter.com/2013/05/29/gotw-89-solution-smart-pointers/)).

- If a constructor has more than 3-5 parameters, *especially* if many/all of the
  parameters are primitive types the compiler will silently convert (a
  ``double`` is passed where an ``int`` is expected, for example), then the
  constructor should be made to take a pointer/lvalue reference/rvalue reference
  to a parameter struct containing the primitive members, in order to reduce
  the chance of subtle bugs due to silent primitive conversions if the order of
  two of the parameters is swapped at the call site.

- Function inputs should use ``const`` to indicate that the parameter is
  input-only (``&`` or ``*``), and cannot be modified in the function body.

- Function inputs should use ``&&`` to indicate the parameter will be consumed
  by the function and further use after the function is called is invalid.

- Function inputs should pass by reference (not by constant reference), to
  indicate that the parameter is an input-output parameter. The number of
  parameters of this type should be minimized.

- Only primitive types should be passed by value; all other more complex types
  should be passed by reference, constant reference, or by pointer. If for some
  reason you *DO* pass a non-primitive type by value, the doxygen function
  header should clearly explain why.

- ``std::shared_ptr`` should be passed by VALUE to a function when the function
  is going to take a copy and share ownership, and ONLY then.

- Pass ``std::shared_ptr`` by ``&`` if the function is itself not going to take
  ownership, but a function/object that it calls will. This will avoid the copy
  on calls that don't need it.

- ``const std::shared_ptr<T>&`` should be not be used--use ``const T*`` to indicate
  non-owning access to the managed object.

- ``std::unique_ptr`` should be passed by VALUE to a "consuming" function
  (i.e. whatever function is ultimately going to claim ownership of the object).

- ``std::unique_ptr`` should NOT be passed by reference, unless the function
  needs to replace/update/etc the object contained in the unique_ptr. It should
  never be passed by constant reference.

- Raw pointers should be used to express the idea that the pointed to object is
  going to outlive the function call and the function is just going to
  observe/modify it (i.e. non-owning access).

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
  least a ``\brief``, UNLESS those functions are overrides/inherited from a
  parent class, in which case they should be left blank (usually) and their
  documentation be in the class in which they are initially declared. All
  non-obvious parameters should be documented, including if they are ``[in]`` or
  ``[out]``.

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
