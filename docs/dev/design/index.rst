.. _dev/design:

===========================================
OOP Software Design Principles And Patterns
===========================================

This guide covers higher-level considerations that every developer should be
aware of when coding in C++. They are complementary to the other development
guides; if you find a conflict between another guide and this one, that's a
bug--please report it.

The goal of every program is to be *useful* (solve the right problems), *usable*
(easy to use), and *modifiable* (easy to maintain). To that end, there are
important high level design principles that help developers achieve these goals,
discussed below in order. Crucially, all of these principles are valid across
different levels of software, and for many different definitions of "module":
function, object, class, architecture, etc.

The principles discussed are all from the perspective of other developers and
future you--not the end/customer client!

Generally speaking, Systems should designed such that they can be decomposed
into *cohesive*, *loosely coupled* modules. A cohesive module has a unified
purpose, while loose coupling implies dependencies on other modules are
minimized. Taken together, this makes a module easier to reuse, replace, and
understand.

.. IMPORTANT:: Naming is of paramount importance at ALL levels of abstraction
               and modularity, because how those identifiers hang together (or
               don't) at the level of classes, functions, etc., plays a large
               role in how people understand your code and how easy or difficult
               it will be for someone to say "Oh I can just add this one other
               thing even though..."; the more cohesive the code, the
               greater the cognitive dissonance developers will experience if
               they try to shoehorn in something unrelated.


Design Principles for Useful Software
=====================================

TBD.

Design Principles For Usable Software
=====================================

.. _dev/design/patterns:

OOP Design Patterns
-------------------

Incorporate design patterns into your code *explicitly* whenever possible. That
is, if you're going to use the decorator pattern, instead of just having a
member variable and wrapping/extending functionality as needed, inherit from a
``decorator<T>`` class in C++ for example. See :ref:`here <dev/design/patterns>`
for a comprehensive list of patterns to be aware of. Not all patterns are
relevant in all cases/languages.

.. tabs::

   .. tab:: Creational

      Patterns in this category create objects for you by some mechanism, rather
      than you having to instantiate objects directly.

      - Factory

      - Prototype

      - Singleton

   .. tab:: Structural

      Patterns in this category concern class and object composition (duh).

      - Decorator

      - Composite

      - PIMPL - This one is dispreferred, because it is easy to abuse as a
        "cure" for many dependency problems which are better solve by a clean
        interface + implementation + factory). It is still allowable, and can be
        useful in some situations with careful design.

   .. tab:: Behavioral

      Patterns in this category are primarily concerned with communication
      between objects.

      - FSM

      - Visitor

      - :ref:`Observer <dev/links/arch-and-design/observer-pattern>`

      - Memento

      - Strategy

      - Mediator


Rationale: Improves readability and makes the intent of the code/programmer
much clearer, and having reuseable template classes for common design patterns
greatly reduces the risk of bugs in your usage of them.

Design Principles For Modifiable Software
=========================================

.. toctree::
   :maxdepth: 1

   modularity.rst
   abstraction.rst
   transparency.rst

SOLID Design Principles
=======================

Another overlapping school of thought worth mentioning with respect to design
principles discussed above is:

- Single responsibility - This mostly maps to :ref:`dev/design/modularity`.

- Open/Closed - Software entities (classes, modules, functions, etc.) should be
  open for extension, but closed for modification. Basically, you should be able
  to add new features while leaving existing code intact.

- Liskov substitution - Objects of a superclass shall be replaceable with
  objects of its subclasses without breaking the application. That is,
  subclasses cannot exhibit different behavior at the level of interfaces than
  their parent classes. Such behaviors might include taking additional
  parameters in overriden functions, return any data types that parent class
  methods don't.

- Interface Segregation - Clients should not be forced to rely on interfaces
  they don't use. Basically, if you have to stub out a bunch of methods from an
  interface when inherit from it in a class, your interface is too broad, and
  needs to be separated.

- Dependency Inversion - High-level modules should not depend on low-level
  modules. Both should depend on abstractions. Abstractions should not depend on
  details. Details should depend on abstractions. This mostly maps to the
  :ref:`Abstraction Principle <dev/design/abstraction>`.
