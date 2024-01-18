.. SPDX-License-Identifier:  MIT

.. _dev/c-guide:

===================
C Development Guide
===================

Unsurprisingly, some of the items in this development guide are dictated by
LIBRA, and are intended for use with it; these are clearly stated below. If you
are not using LIBRA, then you can ignore them if you want to--but you shouldn't!

In general, follow the `Linux kernel C style guide
<https://www.kernel.org/doc/html/latest/process/coding-style.html>`_ (unless
something below contradicts it, then go with what is below).


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

   - Putting ``assert()`` statements throughout thy code (probably in a macro
     with a logging statement which is triggered on failure). These statements
     can be easily compiled away in thy release builds, AND give thou confidence
     that when thy code is running without crashing, it is running correctly.

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

- The "namespace" hierarchy exactly corresponds to the directory hierarchy that
  the source/header files for classes can be found in. Since C doesn't really
  have namespaces, something that is logically named as
  ``module_component_XX`` should be found in ``src/module/component``.

  Rationale: Principle Of Least Surprise.

- The curly brace must always be the last code thing on the line; don't put it
  on its own line.

  Rationale: It makes reading code much easier, in terms of lessening cognitive
  load, because your mind doesn't have to switch between parsing different
  styles every second as you scan a file.

- Don't use ``#ifndef FOO_H`` followed by ``#define FOO_H``\--use ``#pragma
  once`` instead. It is supported by all major compilers.

  Rationale: Makes header files way easier to move around without mind-numbing
  refactoring. Headers often need to be moved around as a library/application
  evolves and functionality is expanded, etc.,

- Don't forward declare static functions in the ``.c`` file, only to define
  them later. Attach docs (if any) to the definition the function,
  which should probably be before all the non-static functions so they are
  available.

  Rationale: Reduces noise and cognitive processing for readers.

- Files in ``#include`` should use ``""`` by default, and **ONLY** use ``<>``
  when you are referencing a *system* project. At a minimum, a *system* project
  should be outside the current module project, if not a system header per-se
  (i.e., something under ``/usr/include``).

  Rationale:

  - Avoids subtle/hard to find bugs if you happen to name a file the same as a
    system header.

  - Makes the intent of the code clearer.

General Naming
--------------

- All file, variable, enum, etc. names are snake case ``specified_like_this``, NOT
  ``specifiedLikeThis`` or ``SpecifiedLikeThis``.

  Rationale: this is how it was originally done in C, and the way it should
  remain. This also makes the code play nicely with the standard library from a
  readability point of view. Plus, snake case is easier to parse visually
  because of the underscores.

- Do not use Hungarian notation.

  Rationale: Linus was right--it *is* brain damaged.

- Never typedef structs. You can typedef types though (i.e., ``int64_t``).

  Rationale:

  - If you see something with a ``_t`` it is a type, NOT a ``struct``.

  - You WANT to know if something is a ``struct`` or ``union``, not hide it.

- All types should end in ``_t``; e.g., ``int64_t``.

  Rationale: Only types end it ``_t``, which makes the code easier to scan.

- All mathematical constants (``#define`` or otherwise) (e.g. ints, doubles,
  etc) should be ``kSPECIFIED_LIKE_THIS``: MACRO CASE + a preceding ``k``.

  Rationale: This makes them easier to identify at a glance from global
  variables and macros, improving readability.

- All constants which are not mathematical constants ``kSpecifiedLikeThis``:
  Upper CamelCase + a preceding ``k``.

  Rationale: Improves code comprehension when read, because it makes it clear
  that a given constant is NOT a number, but something else.

- All enum values should be ``ekSPECIFIED_LIKE_THIS``: MACRO_CASE + a preceding
  ``ek``.

  Rationale: Improves code comprehension because you can tell at a glance if a
  constant is a mathematical one or only serves as a logical placeholder to make
  the code more understandable. The preceding ``ek`` does hinder at-a-glance
  readability somewhat, but that is outweighed by the increased at-a-glance code
  comprehension.


Naming In Embedded Code
-----------------------

"Embedded code" in this case refers to things like:

- Code which runs on an embedded chip

- Bare-metal device drivers

- BSP code

- Other "low-level" code

Normally, when you name functions, macros, etc., you want to do::

  <project>_<module>_<thing>_

However, for embedded code don't do this. Rationale: embedded code is often
consumed in situ, meaning that it is written for a specific project/application,
and not reused beyond that context. As such the usual practice of naming to
prevent name collisions/linking errors/etc is not necessary. So why add
additional burden to future readers of your code? For example, consider writing
a BSP:

- ``#define``\s don't need to be universally unique (only reasonably
  unique), because you never need to combine two BSPs together where you might
  have duplicate definitions of e.g., ``UART0_BASE``.


Thus, in the context of embedded code:

- All macro names are ``MODULEY_SOME_MACRO`` not ``PROJECTX_MODULEY_SOME_MACRO``.

- Global variables do not need to be prefixed with ``g_``.

Naming In Non-Embedded Code
---------------------------

Unless your application meets the criteria specified in `Naming In Embedded
Code`_, you are in a general context. So:


- All macro names are ``PROJECTX_MODULEY_SOME_MACRO`` not
  ``MODULEY_SOME_MACRO``.

- All global variables prefixed with ``g_``.

Miscellaneous
-------------

- Prefer forward declarations to ``#include`` class definitions in ``.h``
  files.

  Rationale: Improves compilation times, sometimes by a LOT.

  Important caveats:

  - Never forward declare symbols in a source file--just ``#include`` the needed
    header.

- Use spaces NOT tabs.

  Rationale: Only heathens use tabs.

- ALWAYS use ``{}``, even for one line bodies.

  Rationale: It makes things WAY LESS error prone, because if you've been coding
  for several hours and have to add another statement after the single statement
  inside an ``if``, there is no risk of a logic error because your brain is
  tired.

- Non-const static variables should be avoided.

  Rationale: These are global variables with file scope, and global variables
  generally=bad. They increase binary size, and lead libraries/applications to
  hold state in surprising ways. Better not to, unless it can't be avoided
  (e.g., to provide a UART driver in a bare-metal application).

- When testing ``==/!=`` with a CONSTANT, the constant goes on the LHS.

  Rationale: If you mistype and only put a single ``=`` you'll get a compiler
  error rather than it (maybe) silently compiling into a bug. Most compilers
  will warn about this, but what if you have that warning disabled, or are using
  an older compiler which doesn't emit it?

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

  Rationale: Improve readability.

Linting
=======

- Header ordering (this is done by ``clang-format``, as configured).

- Line length >= 80 ONLY if it is only 1-2 chars too long, and breaking the
  line would decrease readability. The formatter generally takes care of this.

Code should pass the clang-tidy linter, which checks for style elements like:

- All functions less than 100 lines, with no more than 5 parameters/10
  branches. If you have something longer than this, 9/10 times it can and
  should be split up.

Function Parameters
===================

- Only primitive types should be passed by value; all other more complex types
  should be passed by reference. If for some reason you *DO* pass a
  non-primitive type by value, the doxygen function header should clearly
  explain why.

- ``const`` parameters should be declared before non-``const`` parameters when
  possible, unless doing so would make the semantics of the function not make
  sense.

Documentation
=============

- All structs should have:

    - A doxygen brief
    - A group tag
    - A detailed description for non-casual users of the class

- All functions should be documented with at least a brief. All non-obvious
  parameters should be documented, including whether they are ``[in]`` or
  ``[out]``.

Testing
=======

All NEW functionality should have some basic unit tests associated with them,
when possible (one for each major function that the module provides). It often
is not possible to create unit tests for all new functionality, as some can only
be tested in an integrated manner, but everything else can and should be tested
in a stand alone fashion.
