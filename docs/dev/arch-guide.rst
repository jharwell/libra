.. _dev/arch-guide:

==============================
High-Level Architectural Guide
==============================

This guide covers higher-level considerations that every developer should be
aware of when coding in C++. They are complementary to the other development
guides; if you find a conflict between another guide and this one, that's a
bug--please report it.

Software Architecture...The Important Stuff
===========================================

#. Software architecture always traces back to the business model
   for the company, and considers the implications of that for software
   development.


#. The success of a given software architecture is measured by how well said
   software aligns with the business model.

#. Characteristics of a successful software architecture:


#. Adoption of engineering practices that provide repeatable benefits,
   including:

   - `Architectural Constraints`_: rules for the system, what is and is not
     allowed.

   - Principles and models: guidelines for how developers should go about
     implementing features. Basically, the combination of :ref:`dev/design`. and
     the guide for your programming language (e.g., :ref:`dev/cxx-dev-guide` for
     C++).

   - Structure: the building blocks of the system and how they should fit
     together.

   - :ref:`dev/design/patterns` and understandability: same problem, same
     solution; document, document, document (not for the developer that wrote
     it!).

   - Detailed designs: How does the SW implement architectural elements in ways
     that align with the overall goals of the system ?

   - Testing environments: how can we test what we produce and ensure everything
     we produce works, continues to work, and aligns with the overall goals of
     the system.

   - Release environments: how can we make releases of our system in a way that
     works, continues to work, and aligns with the overall goals of the system.

.. IMPORTANT:: Architecture, software design and implementation, testing and
               release need to work and play well together, otherwise you don't
               have an architecture--just a collection of stuff that doesn't
               "hang together" in any meaningful way.

Craig's Laws of Software Architecture
=====================================

#. **Everything Is A Trade-Off**

   If you think you’ve found something that does not involve a trade-off, you
   just haven’t identified the trade-off yet

#. **Why Is More Important Than How**

   Always capture why an architectural decision was made: in a design document,
   class comment header, etc.  If you only consider how things are done *now*,
   and you invent a new “better” way to do it, you may miss very important
   reasons why it was originally done differently.

#. **There Is Always A Bigger Picture**

   Remember that there are “important things to consider” that may not be
   immediately clear when looking at design/implementation details at *any*
   level of abstraction

   The biggest picture (TM) involves business goals (of our company and
   partners); moving down to architecture, designs, implementations testing,
   release and maintenance.

#. **Embrace change**

   Continuous improvement is not just a Japanese auto manufacturer thing; being
   static or unchanging is typically not a natural or desirable state. The needs
   of the business *will* change over time, and the architecture (whatever that
   is) will need to adapt to change with it.
