.. SPDX-License-Identifier:  MIT

.. _dev/cxx-guide:

=====================
C++ Development Guide
=====================

In terms of coding style, many aspects are pulled from the `CppCoreGuidelines
<https://github.com/isocpp/CppCoreGuidelines/blob/master/CppCoreGuidelines>`_,
though there are many parts which are ignored.

In general, follow the Google C++ style guide (unless something below
contradicts it, then go with what is below).


Commandments
============

These are higher-level stylistic advice which has been hard-fought and
hard-won. Ignore them at your peril; read: FOLLOW THEM.

#. Thou shalt include configurable debugging/logging statements in thy
   code. Thy statements shall be subject to conditional compilation to turn
   off/on in release/debug builds, as well as configurable the verbosity of the
   logger for each class/module/whatever can be turned changed independently.

   Rationale: Having good logging statements which can be compiled in/out and
   turned on/off in a fine-grained way will make your life MUCH easier in the
   future when you need to debug difficult problems.

#. Thy debugging/logging statements shall be of sufficient quality that **NO
   ADDITIONAL** ``printf()`` statements are required to debug ANY problem in the
   code.

   Rationale: When other people use your code and find bugs in it, having a
   strong set of logging messages available to enable/disable makes it MUCH
   easier to triage and fix problems, because users won't have to wait for you
   to push code with more debugging statements added to try and replicate the
   issue--they will just have to edit a config file and re-run.


#. Thou shalt strive to make thy code "correct by construction". This includes:

   - Use of ``static_assert()`` to check template requirements at compile time.

   - Putting ``assert()`` statements throughout thy code (probably in a macro
     with a logging statement which is triggered on failure). These statements
     can be easily compiled away in release builds, AND give thou confidence
     that when thy code is running without crashing, it is running correctly.

   - Using interfaces to FORCE your code to logically and semantically fit
     together.

   - Not using ``friend``, or ``mutable``.

   - Concepts (if using C++20 or later).

   - Using function pre/post condition checking to avoid the "garbage in garbage
     out" issue.

   - Writing small functions which do ONE THING, to reduce the probability of
     logic errors.

   - Force link-time errors of undefined variables/functions in dynamic
     libraries, rather than waiting until run-time.

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

  Rationale: Principle of Least Surprise.

- Don't use ``#ifndef FOO_H`` followed by ``#define FOO_H``\--use ``#pragma
  once`` instead. It is supported by all major compilers.

  Rationale: Makes header files way easier to move around without mind-numbing
  refactoring. Headers often need to be moved around as a library/application
  evolves and functionality is expanded, etc.,

- Exactly one class/struct definition per ``.cpp``\/``.hpp`` file, unless there
  is a very good reason to do otherwise. class/struct definitions nested within
  other classes/structs are exempt from this rule, but their use should still be
  minimized and well documented if they reside in the ``public`` part of the
  enclosing class.

  Rationale: Can massively reduce compilation time by eliminating redundant
  compilation, and makes dependencies between files/classes/etc MUCH clearer: if
  a file includes the header for another class, that class is a dependency.

- If a C++ file lives under ``src/my_module/my_file.cpp`` then its corresponding
  include file is found under ``include/<repo_name>/my_module/my_file.hpp``
  (same idea for C, but with the corresponding extensions).

  Rationale: Principle of Least Surprise, and makes it as easy as possible for
  people unfamiliar with the code to find stuff in it.

- Files in ``#include`` should use ``""`` by default, and **ONLY** use ``<>``
  when you are referencing a *system* project. At a minimum, a *system* project
  should be outside the current module project, if not a system header per-se
  (i.e., something under ``/usr/include``). This has two benefits:

  Rationale:

  - Avoids subtle/hard to find bugs if you happen to name a file the same as a
    system header.

  - Makes the intent of the code clearer.

Naming
------

- All file, class, variable, enum, namespace, etc. names are snake case
  ``specified_like_this``, NOT ``specifiedLikeThis`` or ``SpecifiedLikeThis``.

  Rationale: Most of the time you should not really need to know whether the
  thing in between ``::`` is a class, namespace, enum, etc. You really only need
  to know what operations it has. This also makes the code play nicely with the
  STL/boost from a readability point of view. Plus, snake case is easier to
  parse visually because of the underscores.

- All member variables are prefixed with ``m_``.

  Rationale: Easier to parse visually than say ``m``.

- All constant members prefixed with ``mc_``.

  Rationale: Makes the programmer's intent clear in the code.

- All global variables prefixed with ``g_``.

  Rationale: Makes the programmer's intent clear in the code.

- All mathematical constants (``#define`` or otherwise) (e.g. ints, doubles,
  etc) should be ``kSPECIFIED_LIKE_THIS``: MACRO CASE + a preceding ``k``.

  Rationale: This makes them easier to identify at a glance from global
  variables and macros, improving readability.

- All static class constants (you should not have non-static class constants)
  that are anything other than a mathematical constant should be
  ``kSpecifiedLikeThis``: Upper CamelCase + a preceding ``k``.

  Rationale: Improves code comprehension when read, because it makes it clear
  that a given constant is NOT a number, but something else.

- All enum values should be ``ekSPECIFIED_LIKE_THIS``: MACRO_CASE + a preceding
  ``ek``.

  Rationale: Improves code comprehension because you can tell at a glance if a
  constant is a mathematical one or only serves as a logical placeholder to make
  the code more understandable. The preceding ``ek`` does hinder at-a-glance
  readability somewhat, but that is outweighed by the increased at-a-glance code
  comprehension.

- All template parameters should be in ``CamelCase`` and preceded with a
  ``T``.

  Rationale: Makes it easy to tell at a glance that something is a template
  parameter, rather than an object type, in a templated class/function.

- All enum names should be postfixed with ``_type``.

  Rationale: Enforces semantic similarity between members when possible (i.e. if
  it does not make sense to do this, should you really be using an enum vs. a
  collection of ``constexpr`` values?).

- **Never** include the datatype or units in the name of *anything*.

  Rationale:

  - Linus was right--it *is* brain damaged.

  - It makes refactoring more work.

  - You don't actually prevent yourself from passing e.g., a ``float``
    containing a value in cm to a function which contains a value in
    meters--just make it less likely. If you find yourself wanting to use
    Hungarian-esque notation use `Strongly Named Types`_ instead--the compiler will
    enforce type/unit correctness for you.

- Namespace names should NEVER contain underscores.

  Rationale: A name like "nest_acq" (short for "nest_acquisition") is actually
  two concepts: things related to nests, and things related to acquiring
  nests. Inevitably what will happen is you will need to create another
  namespace for leaving nests (say "nest_exit"), and put the two namespaces side
  by side. Clearly it should be "acq" and "exit" inside of a parent "nest"
  namespace. So if you can't use a single word/acronym for a given namespace,
  99% of the time you should split it up. This also makes your code more open to
  extension but closed to modification.

- The namespace name for a class is the same as where it can be found in the
  directory hierarchy under ``include/`` or ``src/``. For example, if ``class
  foobar{}`` is in ``ns1::ns2``, then ``foobar.hpp`` will be in
  ``include/<project_name>/ns1/ns2`` and ``foobar.cpp`` will be in
  ``src/ns1/ns2``.

  Rationale: Makes it MUCH easier for people to find where stuff is in the code.

  The one exception to this rule is if something is in ``include/x/y/common/z``
  or ``src/x/y/common/z``; ``common`` may be omitted from the namespace. This is
  a necessary concession to make building mutually exclusive components in a
  library which share some common code easier.

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

  Rationale: Hampers visibility.

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

Data Visibility
---------------

- Per Google C++ guidelines, all data members should be ``private`` unless there
  is a VERY good reason to do otherwise; for non-``private`` data, inline
  documentation must be provided.

- Don't use ``this->`` to access members of the current object within its own
  class functions, except in ``operatorXX()``. Rationale: Per the convention
  above, seeing ``m_mymember`` in a function should always refer to a member
  variable in the current class, not one in a parent class. So ``this->``
  only adds to the cognitive load for readers, without providing any readability
  benefit. In operators, because there is *another* object/RHS present in the
  scope of the function, doing e.g.::

    this->m_mymember = rhs->m_mymember;

  makes the programmer's intent explicit, and forces you to chain
  ``operatorXX()`` calls through parent classes if for some reason you have a
  non-``private`` member in a parent class which you want to use in an operator
  function.

Function Parameters
-------------------

Most of these are from Herb Sutter's excellent C++ guidelines on smart pointers
[here](https://herbsutter.com/2013/05/29/gotw-89-solution-smart-pointers/)).

- If a constructor has more than 3-5 parameters, *especially* if many/all of the
  parameters are primitive types the compiler will silently convert (e.g.,
  ``double`` is passed where an ``int`` is expected), then the constructor
  should be made to take a pointer/lvalue reference/rvalue reference to a
  parameter struct containing the primitive members, in order to reduce the
  chance of subtle bugs due to silent primitive conversions if the order of two
  of the parameters is swapped at the call site.

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


Miscellaneous
-------------

- ``#define`` for literal constants should be avoided. ``constexpr`` values in
  an appropriate namespace should be used instead.

  Rationale: Pollutes the global namespace.

- Prefer forward declarations to ``#include`` class definitions in ``.hpp``
  files.

  Rationale: Improves compilation times, sometimes by a LOT.

  Important caveats:

  - Never forward declare symbols from ``std::``--it is undefined.
  - Never forward declare symbols in a source file--just ``#include`` the needed
    header.

- Use spaces NOT tabs.

- Always use strongly typed enums (class enums) whenever possible; sometimes
  this is not possible without extensive code contortions.

  Rationale:

  - Helps to avoid name collisions.

  - Helps to avoid accidentally passing e.g., an ``int`` where a ``float`` is
    expected.

- When testing ``==/!=`` with a CONSTANT, the constant goes on the LHS.

  Rationale: If you mistype and only put a single ``=`` you'll get a compiler
  error rather than it (maybe) silently compiling into a bug. Most compilers
  will warn about this, but what if you have that warning disabled, or are using
  an older compiler which doesn't emit it?

- Non-const static variables should be avoided.

  Rationale: These are global variables with file scope, and global variables
  generally=bad. They increase binary size, and lead libraries/applications to
  hold state in surprising ways. Better not to, unless it can't be avoided
  (e.g., to provide a UART driver in a bare-metal application).

- Class nesting should be avoided, unless it is an internal convenience
  ``struct`` to hold related data.

- Don't use ``//`` style comments--use ``/* */`` style comments.

  Rationale:

  - Forces you NOT to put stuff at the end of a line where it is more likely to
    hamper readability/be missed by the reader.

  - Improves readability because they are symmetric.

- When a ``/* */`` style comment is over one line, format it symmetrically, like
  so::

    /* A one-line comment */
    int a = 4;

    /*
     * A much longer comment that is easier to read because it is symmetrically
     * written.
     */
    int b = 7;

  Rationale: Improves readability.

Coding Constructs
=================

Design Patterns
---------------

Incorporate design patterns into your code *explicitly* whenever possible. That
is, if you're going to use the decorator pattern, instead of just having a
member variable and wrapping/extending functionality as needed, inherit from a
``decorator<T>`` class. Important design patterns you should be aware of (google
for examples/explanations):

- Decorator
- FSM
- Factory
- PIMPL
- Prototype
- Singleton
- Visitor
- Observer

Rationale: Improves readability and makes the intent of the code/programmer
much clearer, and having reuseable template classes for common design patterns
greatly reduces the risk of bugs in your usage of them.

Strongly Named Types
--------------------

Basically, instead of passing literals around, you create a super simple class
wrapper around say an ``int32_t`` which:

- Must be explicitly constructed--the implicit single-parameter constructor is
  disabled.

- Only supports the operators that you define (i.e., no +,-,/,copy, etc).

From
`<https://www.fluentcpp.com/2016/12/08/strong-types-for-strong-interfaces/>`_.

Rationale:

- It makes it *much* harder to pass a semantically mismatched value to a
  function (e.g., the function takes a ``double`` which represents m/s, but you
  pass a ``double`` in cm/s).

- It forces you to design semantically consistent interfaces.

The compiler should be able to optimize away the wrapper you provide in many
cases anyway, so it costs very little to no performance to use strongly named
types (see `<https://www.fluentcpp.com/2017/05/05/news-strong-types-are-free/>`_
for details).

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

Code should pass the clang-tidy linter, when configured to check for
readability as described in `Naming`_.

- All functions less than 100 lines, with no more than 5 parameters/10
  branches. If you have something longer than this, 9/10 times it can and
  should be split up.

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
type should be enough documentation. If its not, chances are you need to
refactor.

Testing
=======

All NEW classes should have some basic unit tests associated with them, when
possible (one for each major public function that the class provides). For any
*existing* classes that have *new* public functions added, a new unit test
should also be added. It is not possible to create unit tests for all classes,
as some can only be tested in an integrated manner, but there many that can and
should be tested in a stand alone fashion.
