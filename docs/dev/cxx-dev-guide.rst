.. SPDX-License-Identifier:  MIT

.. _dev/cxx-dev-guide:

=====================
C++ Development Guide
=====================

In terms of coding style, many aspects are pulled from the
:ref:`CppCoreGuidelines <dev/links/cxx/core-guidelines>`, though there are many
parts which are ignored.

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

   - Restrict the use of thy templated classes to types for which the operations
     of the class are well defined, by doing one or more of:

     - Using :ref:`SFINAE <dev/links/cxx/SFINAE>` on functions/classes.

     - Separating thy templated classes into header and source files so that the
       instantiations of thy classes are restricted to those thou defines in thy
       source files.

     - Use of ``static_assert()`` to check template requirements at compile
       time.

   - Putting ``assert()`` statements throughout thy code (probably in a macro
     with a logging statement which is triggered on failure). These statements
     can be easily compiled away in release builds, AND give thou confidence
     that when thy code is running without crashing, it is running correctly.

   - Using interfaces to FORCE your code to logically and semantically fit
     together. See `Interlocking Interfaces`_ below for more details.

   - Not using ``friend``, or ``mutable``.

   - Concepts (if using C++20 or later).

   - Using function pre/post condition checking to avoid the "garbage in garbage
     out" issue.

   - Writing small functions which do ONE THING, to reduce the probability of
     logic errors.

   - Force link-time errors of undefined variables/functions in dynamic
     libraries, rather than waiting until run-time. E.g., passing
     ``-Wl,--no-undefined`` consistently to the linker.

#. Thou shalt write thy code using only pure conditions--those without side
   effects such as assigning values, throwing exceptions, interacting with I/O,
   etc., so that thy program's logic is clear and its behavior unobscured by
   secondary actions.

Principles For Clean Code
=========================

These are *principles*, not commandments, because you probably won't be able to
follow them everywhere, but you should try to follow them in as many places as
you can.

#. **Embrace The Power Of Brevity**

   Limit your functions to no more than 10 lines of code. This encourages you to
   extract methods, promoting more readable and maintainable code.

#. **Mutually Exclusive Call Or Pass**

   Your functions should either call methods on an object or pass it on as an
   argument, but not both. This encourages you to write methods which maintain a
   single level of abstraction within each method, promoting more readable and
   maintainable code. That is:

   .. tabs::

      .. tab:: Not Using The Principle

         ::

            bool check_for_bar(MyObject& obj1) {
               if (obj1.bar()) {
                obj1.reset();
                return true;
                }
               return false;
              }

            void bad_func1(MyObject& obj1) {
              obj1.foo();
              if (check_for_bar(obj1) ) {
                return;
              }

              for (auto& s: obj1.subobjects()) {
                if (s.fizz()) {
                  obj1.remove(s);
                }
              }
            }

         Notice:

            - Visually there are two functions to parse, and you have look at
              multiple abstraction contexts to figure out the execution flow.

            - This example relies on member functions with side effects which
              are hidden at the level of ``bad_func1()``. You could argue that
              that could be fixed with a better name for ``check_for_bar()``
              such as ``reset_on_bar()``, and that helps, but the side-effect
              problem is still present. Generally speaking, the more "pure"
              functions you write, the better off you are.

      .. tab:: Using The Principle

         ::

            void good_func(MyObject& obj1) {
              obj1.foo();
              if (obj1.bar()) {
                obj1.reset();
                return;
              }

              for (auto& s: obj1.subobjects()) {
                if (s.fizz()) {
                  obj1.remove(s);
                }
              }
            }

         Notice:

         - There is only a single function to parse.

         - There are no functions with side effects (well, assuming none of the
           member functions have side effects).

         - The single function is more complex than the two simpler functions,
           BUT is easier to grasp at a glance. This is a great example for why
           breaking everything out into lots of little functions can be
           counterproductive, unless the functions at all scales adhere to this
           principle.


#. **If Only At The Start of Functions**

   Position all ``if`` statements at the start of functions to determine state,
   check data integrity, etc. This minimizes nested logic and clarifies the
   decision making process within functions, making code more intuitive and
   straightforward by streamlining the logic within functions: once all
   decisions have been made about what to do, the actual code to *do* the thing
   is just a series of procedural statements.

#. **Never Use if With else**

   Don't use ``if`` with ``else`` in order to avoid the complexity of
   ``if-else`` labyrinths which we have all seen. ``clang-tidy`` can check for
   this. To illustrate this, look at the "Not Using The Principle" tab of the
   previous item, which contains a LOT of if/else blocks and complex logic. The
   ``Evaluate()`` function in the "Using The Principle" rewrite is much simpler,
   because it returns after each if() condition.

#. **Minimize Use of switch()**

   All ``switch()`` statements:

   - Should contain no default case.

   - Should contain no fall-through cases

   - The contain a return/function call in every case.

   This helps to avoid subtle bugs and maintenance headaches.

#. **Only Inherit From Interfaces**

   Inheriting from classes containing only pure virtual functions (not base
   classes!) strongly encourages composition over inheritance, which is a major
   factor in code scalability and coupling, or lack thereof.

#. **No Interfaces With A Single Implementation**

   That is, if you are creating a new abstraction in the codebase, and it will
   only have a single implementation, does the abstraction provide more clarity
   or mental clutter?  This principle helps to ensure appropriate design
   choices, and to seek simplicity and necessity in your architectural
   decisions.

#. **Embrace the Law of Demeter**

   The :ref:`The Law Of Demeter <dev/links/arch-and-design/demeter>` states
   that:

   - You should not use getters or setters

   - Objects should avoid accessing internal data of other objects, and only
     communicate with similar objects. As an example, consider
     ``std::vector``. Instead of directly exposing the raw storage it manages,
     ``std::vector`` generally only exposes *behavioral* functions, rather than
     accesors/mutators.

   This emphasizes a *behavioral* approach to class design, reducing
   dependencies and increasing encapsulation. Supports the :ref:`Transparency
   Principle <dev/design/transparency>`.


Basic Coding Style
==================

Files
-----

- All source files should have either:

  - An abbreviated version of the license text and a pointer to full license
    text (e.g., ``Copyright Foo Corp blah blah blah. See LICENSE.md for
    details``).

  - An :ref:`SDPX <dev/links/misc/SDPX>` identifier; e.g.,
    ``SPDX-License-Identifier: MIT``.

- All C source files have the ``.c`` extension, and all header files have the
  ``.h``, to clearly distinguish them from C++ code, and not to confuse the
  tools used to parse them, such as clang tooling.

  Rationale: Principle of Least Surprise.

- All C++ source files have the ``.cpp`` extension, and all header files have
  the ``.hpp``, to clearly distinguish them from C code, and not to confuse the
  tools used to parse them, such as clang tooling.

  Rationale: Principle of Least Surprise.

- All header files must be checkable standalone; that is, ``foo.hpp`` can't
  depend on ``bar.hpp`` being included before it in a compilation unit for the
  code it contains to be syntactically correct. This supports the
  :ref:`Transparency Principle <dev/design/transparency>`.

  Rationale: If this isn't the case, you have coupling, circular dependencies,
  etc., that shouldn't be there.

- Don't use ``#ifndef FOO_H`` followed by ``#define FOO_H``\--use ``#pragma
  once`` instead. It is supported by all major compilers.

  Rationale: Makes header files way easier to move around without mind-numbing
  refactoring.  Headers often need to be moved around as a library/application
  evolves and functionality is expanded, etc. It is also more readable::

    #pragma once

    // header file contents

  vs::

    #ifndef DIR1_DIR2_DIR3_FOO_BAR_H_
    #define DIR1_DIR2_DIR3_FOO_BAR_H_

    // header file contents

    #endif

  The second variant has much more visual clutter, and must be updated *anytime*
  the file is moved, even if nothing else in the header file changes.

- Exactly one class/struct definition per ``.cpp``\/``.hpp`` file, unless there
  is a very good reason to do otherwise. class/struct definitions nested within
  other classes/structs are exempt from this rule, but their use should still be
  minimized and well documented if they reside in the ``public`` part of the
  enclosing class.

  Rationale: Can massively reduce compilation time by eliminating redundant
  compilation, and makes dependencies between files/classes/etc MUCH clearer: if
  a file includes the header for another class, that class is a
  dependency. Supports the :ref:`Transparency Principle
  <dev/design/transparency>`.

- If a C++ file lives under ``src/my_module/my_file.cpp`` then its corresponding
  include file is found under ``include/<repo_name>/my_module/my_file.hpp``
  (same idea for C, but with the corresponding extensions).

  Rationale: Principle of Least Surprise, and makes it as easy as possible for
  people unfamiliar with the code to find stuff in it.

- Files in ``#include`` should use ``""`` when referencing includes within the
  same project/module/etc,, and **ONLY** use ``<>`` when you are referencing a
  *system* project; that is, a project outside of a given
  project/module/etc.

  Rationale:

  - Avoids subtle/hard to find bugs if you happen to name a file the same as a
    "system" header, and have both parent directories on the include path.

  - Makes the intent of the code clearer.

  Consider the following example:

  .. tabs::

     .. tab:: Ignoring This Rule

        ::

           #include <module_config.hpp>

           #include <common/include/lockless_ring.hpp>
           #include <common/include/observer.hpp>
           #include <common/include/pnt_burst_data.hpp>
           #include <common/include/first_class.hpp>
           #include <common/include/tlv_shared.hpp>

           #include <hal/include/tlv_hal.hpp>

           #include <pal/include/os/abstract/log.hpp>

           #include <spri/include/spri_observer.hpp>
           #include <hal/include/pnt_window_data.hpp>
           #include <spri/include/burst_detection_fifo.hpp>
           #include <spri/include/tlv_spri.hpp>

           #include <sdpm3/include/api/common/sdpm.hpp>


        Without any additional context (e.g., the moment you first open a header
        file), you have no idea what is local to the module the file you are
        looking at belongs to, and what is "external".

     .. tab:: Following This Rule

        ::

           #include <module_config.hpp>

           #include <common/include/lockless_ring.hpp>
           #include <common/include/observer.hpp>
           #include <common/include/pnt_burst_data.hpp>
           #include <common/include/first_class.hpp>
           #include <common/include/tlv_shared.hpp>

           #include <hal/include/tlv_hal.hpp>

           #include <pal/include/os/abstract/log.hpp>
           #include <hal/include/pnt_window_data.hpp>

           #include <sdpm3/include/api/common/sdpm.hpp>

           #include "spri/include/spri_observer.hpp"
           #include "spri/include/burst_detection_fifo.hpp"
           #include "spri/include/tlv_spri.hpp"

        Here, it is clear--*without any additional context*--that the code
        snippet you are looking at is part of the SPRI module.



Class Layout
------------

- Follow the Google C++ style ordering: ``public`` -> ``protected`` ->
  ``private`` layout, generally speaking. However, there are some cases when
  putting public accessors/mutators AFTER the declaration of private variables
  which they access/modify is required.

- Within each access modifier section, the layout should be (in order):

    - ``using`` declarations (types or functions from base classes).

    - Type definitions.

    - Class constants (should hopefully be ``static constexpr const``).

    - Functions.

  The choice of this ordering is somewhat arbitrary, but it is necessary to have
  SOME sort of ordering, and this is already how I was generally doing most
  classes.

- Within the ``public`` section, the constructor, destructor, and any copy/move
  operators should be listed first among all the functions if they are
  included.

- If a class does not need the copy/move operations, you must explicitly
  ``delete`` the not needed operators. Note that even though ``delete``-ing the
  copy constructor+copy assignment operator will implicitly delete the move
  equivalents, you can get better error messages in complex template
  instantiation contexts if you actually ``delete`` all the not need operators,
  rather than rely on implicit deletion.

Data Visibility
---------------

- Per Google C++ guidelines, all data members should be ``private`` unless there
  is a VERY good reason to do otherwise; for non-``private`` data, inline
  documentation must be provided. Supports the :ref:`Transparency Principle
  <dev/design/transparency>`.

- Don't use ``this->`` to access members of the current object within its own
  class functions, except in ``operatorXX()``.

  Rationale: Per the convention above, seeing ``m_mymember`` in a function
  should always refer to a member variable in the current class, not one in a
  parent class. So ``this->`` only adds to the cognitive load for readers,
  without providing any readability benefit. In operators, because there is
  *another* object/RHS present in the scope of the function, doing e.g.::

    this->m_mymember = rhs->m_mymember;

  makes the programmer's intent explicit, and forces you to chain
  ``operatorXX()`` calls through parent classes if for some reason you have a
  non-``private`` member in a parent class which you want to use in an operator
  function.


Functions
---------

- Functions should be short, ideally no more than 50 lines; the maximum
  allowable length is inversely proportional to its complexity. E.g., a function
  which contains a long 500 line ``switch()`` statement is fine, while one which
  contains 500 lines of general logic is not.

- If a function overrides a function in a parent class via polymorphism, mark it
  as such using ``override``. Don't use ``virtual``, even though the compiler
  will accept it. If a function is intended to be the final override, use
  ``override final`` even though it is a little redundant.

  Rationale: Using ``override`` vs. ``virtual`` as part of the function
  signature makes it clear that you are overriding a virtual function in a
  parent class, instead of declaring a new virtual function with a default
  implementation.

Function Parameters
-------------------

Most of these are from Herb Sutter's excellent C++ guidelines on smart pointers
:ref:`here <dev/links/cxx/smart-pointers>`.

- If a constructor has more than 3-5 parameters, *especially* if many/all of the
  parameters are primitive types the compiler will silently convert (e.g.,
  ``double`` is passed where an ``int`` is expected), then the constructor
  should be made to take a pointer/lvalue reference/rvalue reference to a
  parameter struct containing the primitive members, in order to reduce the
  chance of subtle bugs due to silent primitive conversions if the order of two
  of the parameters is swapped at the call site. Supports the :ref:`Transparency
  Principle <dev/design/transparency>`.

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
  observe/modify it (i.e. non-owning access). Note that (possibly const)
  non-owning access can also be expressed via a reference; however, this can
  lead to null pointer dereferences in the conversion to reference. It is better
  if something is a pointer in parent function that non-owning access is
  conveyed to the child function also with a pointer. The "is this null or not"
  check needs to be done regardless.

- ``const`` parameters should be declared before non-``const`` parameters when
  possible, unless doing so would make the semantics of the function not make
  sense.

Namespaces
----------

- Aliases and ``using``: using namespace aliases can make references to stuff
  in a nested namespace from *another* nested namespace much easier to write
  and clearer to grok. However, the following restrictions apply:

  - Do not use ``using namespace foo`` in a header file.

    Rationale: You are polluting the global namespace with whatever is in
    namespace ``foo``, which can lead to headaches for you and other developers
    in the future.

  - Do not use ``using namespace std`` ever.

    Rationale: Requiring ``std::`` for all things referenced in a given file
    makes it clear when you see a symbol without a preceding ``::`` that said
    symbol is visible in the current namespace/scope, rather than being
    something from the standard library.

- All classes/definitions/whatever which are *internal* to a module should go in
  a ``detail`` namespace.

  Rationale:

  - Makes the intent of the code clearer to readers and future developers
    touching a module by indicating "anything under here shouldn't be needed
    outside the module--if you use it you are asking for trouble".

  - This is the convention used by many open-source libraries: clang, boost,
    etc.

Miscellaneous
-------------

- Prefer ``alignas`` over ``__attribute__((aligned(...)))`` when using C++11 or
  later in nearly all cases.

  Rationale: One is a compiler extension (granted, one supported by most major
  compilers), and one is standard. There are some subtle differences between
  them, and cases where you can use one and not the other, but they are
  rare.

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

Identifier Naming
=================

General Guidance
----------------

- **Never** include the datatype or units in the name of *anything*.

  Rationale:

  - Linus was right--it *is* brain damaged.

  - It makes refactoring more work.

  - You don't actually prevent yourself from passing e.g., a ``float``
    containing a value in cm to a function which contains a value in
    meters--just make it less likely. If you find yourself wanting to use
    Hungarian-esque notation use `Strongly Named Types`_ instead--the compiler
    will enforce type/unit correctness for you.


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

- Namespace names should NEVER contain multiple concepts; therefore, namespace
  names should never contain underscores, under the naming convention below.

- Don't use smurf naming: When almost every class has the same prefix. i.e.,
  when a user clicks on the button, a ``SmurfAccountView`` passes a
  ``SmurfAccountDTO`` to the ``SmurfAccountController``. The ``SmurfID`` is used
  to fetch a ``SmurfOrderHistory`` which is passed to the ``SmurfHistoryMatch``
  before forwarding to either ``SmurfHistoryReviewView`` or
  ``SmurfHistoryReportingView``. If a ``SmurfErrorEvent`` occurs it is logged by
  ``SmurfErrorLogger to`` ``${app}/smurf/log/smurf/smurflog.log``. From
  :ref:`here <dev/links/cxx/smurf-naming>`. Note that this does `not` apply to
  classes with common postfixes; e.g., ``battery_sensor``, ``light_sensor``,
  etc.

  Rationale: Hampers visibility.

Coding Construct Naming
-----------------------

A simple taxonomy for naming conventions applied to code in any language has two
axes: categorical and functional.

A *categorical* naming convention is intended to help code readers disambiguate
between the various coding constructs present in a language; in C++, that is
between things like classes, local variables, namespaces, etc.

A *functional* naming convention is intended to help readers disambiguate
between different aspects of code from a functional point of view, independent
of what coding construct is used. For example, one grouping in a functional
naming convention might be mathematical constants; in C++, a functionally
targeted naming convention would use the same naming scheme for macros, class
constants, etc. which all represent numbers.

In this style guide, we use a blend of these two axes/paradigms, and choose
whichever improves readability the most, tending towards functional.

Categorically Differentiated Coding Constructs
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Classes
"""""""

.. tabs::

   .. group-tab:: Key Points

      Classes are arguably the most important coding construct in C++, so we
      define their naming scheme *first*, and use a categorical naming scheme.

   .. group-tab:: Naming convention Decision

      Snake case, ``specified_like_this``.

   .. group-tab:: Rationale

      - Taking a functional view, it is more important to view a "thing" in the
        codebase from a "what operations does it have" rather than "what is it".
        It is reasonable to argue that when you see ``foo::bar`` in code, you
        shouldn't actually *need* to know if the scoping operator is being
        applied to a class, struct, or namespace, and that what is important is
        the operations that the scoped thing (``foo`` in the above example)
        has--it doesn't matter what it's type is; this is a functional view.


      - The STL uses snake case for everything, so this convention helps reduce
        cognitive load otherwise required when switching between snake case for
        STL things and something else for other constructs.

      - Abbreviations can still be easily kept without hampering
        readability. E.g., ``TCP_IP_connection`` vs. ``tcpIpConnection``--the
        former is much more readable.

      - We want code to resemble natural writing as much as possible. That is,
        ``int my_special_int = 4`` is preferred and more readable than ``int
        mySpecialInt = 4``.

Namespaces
""""""""""

.. tabs::


   .. group-tab:: Key Points

      - Namespaces are often used far from the site of their declaration via
        ``namespace foo {...}``; their usage is disambiguated from variables,
        enums, macros, etc. by the scoping operator ``::``.

      - Classes and structs can also use the scoping operator, so if namespaces
        have a different naming convention they will be at-a-glance
        differentiable from classes and structs.

      - It is reasonable to argue that when you see ``Foo::Bar`` in code, you
        shouldn't actually *need* to know if the scoping operator is being
        applied to a class, struct, or namespace, and that what is important is
        the operations that the scoped thing (``Foo`` in the above example)
        has--it doesn't matter what it's type is; this is a functional
        view. This is the style preferred/used by major open source libraries
        such as Boost.

      - Namespace names should NEVER contain multiple concepts; therefore, namespace
        names should never contain underscores, under the naming convention above.


   .. group-tab:: Naming Convention Decision

      Lower case, NOT snake case ``specified_like_this``; that is, a namespace
      should only ever consist of a single lower case word.

   .. group-tab:: Rationale

      - The STL uses snake case for everything, so this convention helps reduce
        cognitive load otherwise required when switching between snake case for
        STL things and something else for other constructs.

      - At-a-glance disambiguation from classes, structs, variables, etc. is
        accomplished by the combination of snake case and the scoping operator,
        and outweighs the benefit of the functional view. The functional view
        can be useful when writing code to someone already familiar with the
        codebase, but code is read much more often than it is written, so
        readability wins here.

      - If you allow names like "nest_acq" (short for "nest_acquisition") as a
        namespace name, your namespace actually encapsulates two concepts:
        things related to nests, and things related to acquiring
        nests. Inevitably what will happen is you will need to create another
        namespace for leaving nests (say "nest_exit"), and put the two
        namespaces side by side. Clearly it should be "acq" and "exit" inside of
        a parent "nest" namespace. So if you can't use a single word/acronym for
        a given namespace, 99% of the time you should split it up. This also
        makes your code more open to extension but closed to modification.


Template Types
""""""""""""""

.. tabs::

   .. group-tab:: Key Points

      Are only ever encountered in header files, and therefore near the point of
      their declaration.

   .. group-tab:: Naming Convention Decision

      ``CamelCase`` and preceded with a ``T``.

   .. group-tab:: Rationale

      Makes it easy to tell at a glance that something is a template parameter,
      rather than an object type, in a templated class/function.


Local variables
"""""""""""""""

.. tabs::

   .. group-tab:: Key Points

      Local variables are the most common coding construct encountered when
      reading C++ code, so readability is paramount.

   .. group-tab:: Naming Convention Decision

      Snake case, ``specified_like_this`` for non-const variables.

   .. group-tab:: Rationale

      We chose snake case, rather than upper camel case (i.e.,
      ``specified_like_this`` rather than ``specifiedLikeThis``) because:

      - The STL uses snake case for everything, so this convention helps reduce
        cognitive load otherwise required when switching between snake case for
        STL things and something else for other constructs.

      - The latter is very close to the naming convention for classes, and after
        a long day of programming things can blur together more easier with
        upper camel case.

      - Abbreviations can still be easily kept without hampering
        readability. E.g., ``TCP_IP_connection`` vs. ``tcpIpConnection``--the
        former is much more readable.

      - Local variables are much more common than classes in code, so their
        usage should resemble natural writing as much as possible. That is,
        ``int my_special_int = 4`` is preferred and more readable than
        ``int mySpecialInt = 4``.

      Both namespaces and local variables have the same identifier naming
      convention, and are differentiated by the use of ``::``.

Member Variables
^^^^^^^^^^^^^^^^

.. tabs::

   .. group-tab:: Key Points

      - Member variables are often encountered far from their original
        declaration, unlike local variables.

      - Member variables should be made ``const`` whenever possible to improve
        correctness by construction, and expressing programmer intent to this
        effect via naming convention is therefore important.

   .. group-tab:: Naming Convention Decision

      Snake case, ``specified_like_this``, with a preceding ``m_`` for
      non-``const`` member variables.

      Snake case, ``specified_like_this``, with a preceding ``mc_`` for
      ``const`` member variables.

   .. group-tab:: Rationale

      We chose snake case, rather than upper camel case (i.e.,
      ``m_specified_like_this`` rather than ``mSpecifiedLikeThis`` because

      - The ``m`` differentiates these constructs at a glance from local
        variables.

      - The latter is very close to the naming convention for classes, and after
        a long day of programming things can blur together more easier with
        upper camel case.

      - Abbreviations can still be easily kept without hampering
        readability. E.g., ``m_TCP_IP_connection`` vs. ``m_tcpIpConnection``.

      - Member variables are much more common than classes in code, so their
        usage should resemble natural writing as much as possible. That is,
        ``GhostRider.is_riding_motorcycle`` is preferred and more readable than
        ``GhostRider.isRidingMotorCycle()``.

      - The STL uses snake case for everything, so this convention helps reduce
        cognitive load otherwise required when switching between snake case for
        STL things and something else for other constructs.


Global Variables
""""""""""""""""

.. tabs::

   .. group-tab:: Key Points

      Should not be encountered often in the code, as their usage is minimized.

   .. group-tab:: Naming Convention Decision

      Snake case, ``specified_like_this``, with a preceding ``g_`` for
      non-``const`` global variables.

      Snake case, ``specified_like_this``, with a preceding ``gc_`` for ``const``
      global variables.


   .. group-tab:: Rationale

      - Clearly distinguishes global variables from member and local variables
        within any scope.

      - Most global variables should be const, so it is important to provide
        at-a-glance disambiguation between const and non-const global variables
        to improve readability and code comprehension.

Enum Names
""""""""""

.. tabs::

   .. group-tab:: Key Points

      Enum values are usually encountered singly in the code, so the naming
      convention must support at-a-glance uniqueness in reference to other
      similar types of constants such as macros and ``#define``\s. In addition,
      enum values are commonly encountered in tandem with class, macro, enum,
      and namespace identifiers, and so must be at-a-glance distinct in their
      naming convention from those other identifier types.

   .. group-tab:: Naming Convention Decision

      Values are ``SPECIFIED_LIKE_THIS`` (macro case), with a preceding ``ek``.

   .. group-tab:: Rationale

      Improves code comprehension by indicating at a glance if a constant is
      a (a) mathematical one or (b) only serves as a logical placeholder to make
      the code more understandable *and* that the constant is part of a larger
      semantically defined set.

      Consider the following example illustrating the usefulness of this
      concept. If we do not prefix all enum values with ``ek``, and use
      MACRO_CASE for both enums and macros, we would define a enum like this::

        enum class Identifier {
        ONE,
        TWO,
        THREE
        };

      If it is used in a different module::

        Identifier::TWO

      At a glance, a casual read or new developer would have no idea whether
      the referred to thing was (a) the mathematical constant 2, or (b) an
      enum value. If instead the values in the ``Identifier`` enum were
      prefixed with ``ek``::

        enum class Identifier {
        ekONE,
        ekTWO,
        ekTHREE
        };

      Then if it is used in a different module::

        Identifier::ekTWO

      Then the *intent* of the programmer is clear at the site of the
      usage. Since code is read much more often than it is written, this
      provides a clear benefit.


Macros
""""""

.. tabs::

   .. group-tab:: Key Points

      - Macros are substituted by the preprocessor before the compiler runs, so
        avoiding unintended substitutions is paramount.

      - Macros are distinct from ``#define``\s because they take arguments.


   .. group-tab:: Naming Convention Decision

      Macro case, ``SPECIFIED_LIKE_THIS``.

   .. group-tab:: Rationale

      - This is the general convention for macros in both C and C++, and will be
        familiar to most programmers.

      - The usage of macro case without preceding ``ek`` or ``k`` provides
        at-a-glance comprehension that a given identifier refers to a macro,
        instead of a constant or enum.

#defines
""""""""

.. tabs::

   .. group-tab:: Key Points

      - Usage of ``#define``\s should be minimized, as noted elsewhere in this
        guide.

      - Most ``#define``\s refer to mathematical constants, but not all.


   .. group-tab:: Naming Convention Decision

      ``SPECIFIED_LIKE_THIS`` for non-mathematical constant instances, and
      prefixed with ``k`` for mathematical constants.

   .. group-tab:: Rationale

      - Improves at-a-glance comprehension by indicating if something is a
        non-mathematical constant or not.

      - When reading code, mathematical constants which are ``#define``\s and
        those which are non-static member variables are equivalent, and it is
        rarely necessary to need to distinguish between them. There should not
        *be* many ``#define`` mathematical constants anyway.


Additional Functional Naming Considerations
-------------------------------------------

All guidance in this section is complementary to that in the previous section,
and should not conflict with it. If you find a situation that does, then this
style development guide has "bug".

- All mathematical constants (``#define`` or otherwise) (e.g. ints, doubles,
  etc) should be ``kSPECIFIED_LIKE_THIS``: MACRO CASE + a preceding ``k``.

  Rationale: This makes them easier to identify at a glance from global
  variables, macros, and enums, improving readability.

- All static class constants (you should not have non-static class constants)
  that are anything other than a mathematical constant should be
  ``kSpecifiedLikeThis``: Upper CamelCase + a preceding ``k``.

  Rationale: Improves code comprehension when read, because it makes it clear
  that a given constant is NOT a number, but something else.

  .. NOTE:: We exclude static members from consideration here because how they
            are used is generally more useful for improving code comprehension
            than knowing that a given member is static.

Composite Coding Constructs
===========================

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
- Prototype
- Singleton
- Visitor
- Observer
- PIMPL - This one is dispreferred, because it is easy to abuse as a "cure" for
  many dependency problems which are better solve by a clean interface +
  implementation + factory). It is still allowable, and can be useful in some
  situations with careful design.

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

From :ref:`here <dev/links/cxx/named-types>`.

Rationale:

- It makes it *much* harder to pass a semantically mismatched value to a
  function (e.g., the function takes a ``double`` which represents m/s, but you
  pass a ``double`` in cm/s).

- It forces you to design semantically consistent interfaces.

The compiler should be able to optimize away the wrapper you provide in many
cases anyway, so it costs very little to no performance to use strongly named
types (see `<https://www.fluentcpp.com/2017/05/05/news-strong-types-are-free/>`_
for details).

Interlocking Interfaces
-----------------------

One of the most powerful ways to ensure that a code implementation of a design
is logically and semantically consistent is to liberally use pure
interfaces. Everything in this section supports the :ref:`Abstraction Principle
<dev/design/abstraction>`.That is:

- Writing pure abstract classes (i.e. those which only contain pure virtual
  functions) which embody concepts which you want your classes to adhere to. For
  example, you could create a ``Stringizable`` class with a single ``to_str()``
  function returning a ``std::string`` which all classes you want to have a
  string representation for inherit from.

  You don't *have* to create such a structure in order to string-ize classes,
  but doing so makes programmer intent much clearer, and reduces the chances of
  obviously "bad" things/code smells making their way into the code in more
  complex situations, because the compiler will not be able to correctly deduce
  something in a given context.

- Your classes should mostly consist of ``override`` calls to pure virtual
  functions for interfaces you have inherited from.

Structuring your code using interlocking interfaces has some important benefits:

- Use of interlocking interfaces encourages use of the strategy design pattern,
  because classes can manipulate pointers/references to abstract interface
  classes, which will naturally call the implementations in whatever pointed
  to/referenced object the interface handle refers to.

- Coupling between classes is reduced, because they interact/interface (ha!) via
  indirect handles (i.e., references/pointers to the abstract interface
  classes). That is, if a downstream client class ``Bar`` has a pointer to an
  ``FooObserver`` abstract interface class, then ``Bar`` can *only* access
  ``FooObserver`` through the virtual methods--no other member variables,
  functions, etc. are defined. This is one of the key aspects of this approach
  to class design which makes things interlocking.

- Compile times are improved, because references/pointers to simpler, abstract
  interface classes are passed around instead of pointers to implementation/base
  classes, resulting in fewer, less complex ``#include`` statements.

- It encourages developers to think in terms of *interfaces*--how a class
  interacts with the outside world--rather than implementation--*how* it
  accomplishes whatever its task is.

- It encourages developers to think about code from a reusable building block
  perspective: defining common concepts/interfaces reusable across modules.

- It helps to develop large designs that "hang together", through definition and
  use of some number of key concepts uniformly (expressed via abstract interface
  classes) throughout.

A few additional notes:

- There are performance implications for excessive use of virtual functions, but
  compiler optimizers are *very* good, so it is best to default to always using
  them, and only choose not to use them for "hot" classes after measuring and
  profiling.


Linting
=======

Code should pass the google C++ linter, ignoring the following items. For
everything else, the linter warnings should be addressed.

- Use of non-const references--I do this regularly. When possible, const
  references should be used, but sometimes it is more expressive and
  self-documenting to use a non-const reference in many cases.

- Header ordering (this is done by ``clang-format``, as configured).

- Line length >= 80 ONLY if it is only 1-2 chars too long, and breaking the
  line would decrease readability. The formatter generally takes care of this.

Code should pass the clang-tidy linter, when configured to check for
readability as described in `Identifier Naming`_.

- All functions less than 100 lines, with no more than 5 parameters/10
  branches. If you have something longer than this, 9/10 times it can and
  should be split up.

Documentation
=============

Namespaces
----------

- All namespaces should be documented with at least a ``\brief`` in one, and
  EXACTLY one place; rely on developer IDEs to show the relevant documentation
  when visiting "undocumented" declarations of a namespace.

  Rationale: Duplicating the same namespace documentation everywhere is ripe for
  copy-paste/refactoring errors, and adds to developer cognitive load without
  buying you much.

Classes
-------

All classes should have:

- A doxygen brief

- A group tag

- A detailed description for non-casual users of the class

Functions
---------

- For important/tricky/nuanced logic, document the *why* of it, not the
  *how*--developers can figure out the how if they really want/need to. The
  *why* is much more important so (a) they can understand your code and (b) they
  are not tempted to change it to something else because they like it
  better--there was a good reason you did the tricky bit in this way, after all.

- All non-getter/non-setter member functions should be documentated with at
  least a ``\brief``, UNLESS those functions are overrides/inherited from a
  parent class, in which case they should be left blank (usually) and their
  documentation be in the class in which they are initially declared (doxygen
  can pull this in for you).

- All non-obvious parameters should be documented, including if they are
  ``[in]`` or ``[out]``. Obvious parameters don't need to be documented, and
  *shouldn't* be documented if doing so doesn't add value. E.g., documenting a
  parameter named ``params`` by saying "The function parameters".

  .. TIP:: If you choose good function + parameter names, AND your functions are
           small and do exactly one thing, you won't need to document the
           parameters in many cases.

  Rationale: Helps with ordering function parameters with outputs being before
  inputs.

- All documentation should be in the function header--don't document individual
  parameters inline with ``///>`` or ``///``.

  Rationale: Clean visual separation between code and comments/documentation
  makes it easier for developers to read/parse, and much easier to refactor if
  needed.

- Tricky/nuanced issues with member variables should be documented, though in
  general the namespace name + class name + member variable name + member
  variable type should be enough documentation. If its not, chances are you need
  to refactor.

- When documenting member variables, prefer the block style documentation
  comments to ``///>`` or ``///``.

  Rationale:

  - If you are documenting a member variable, it must be because it is "tricky"
    in some way, so a single line of inline documentation is probably not going
    to cut it.

  - Consistency in documentation style: reduces cognitive load by using the same
    block comment style for everything.

Testing
=======

We break testing down into the following categories, each detailed in
subsections below.

- Unit testing

- Integration testing

- System testing

- Acceptance testing

Unit Tests
----------

- All NEW classes should have unit tests associated with them, when possible.

  Rationale: Legacy code you touch for a given task might be
  difficult/intractable to write unit tests for in its current state. But NEW
  classes should always adhere to good practices.

- One test case for each major public function that  class provides; may be
  more/less depending on the class.

  Rationale: Having one test case/public function makes it easy to write modular
  unit tests which can easily be extended as needed in the future.
