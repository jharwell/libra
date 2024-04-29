.. _dev/design/transparency:

==========================================================================
The Transparency Principle: Minimizing Hidden Dependencies Between Classes
==========================================================================

Backgound And Formal Definition
===============================

Assume A and B are classes, interfaces, or packages. A depends on B if changes
to B could cause changes to A. Formally ``A << B``. In UML::

  -----
  | B |
  -----
    ^
    |
    |
  -----
  | A |
  -----


Dependency is reflexive, so ``A << A``. Dependencies are also transitive, so
``A << B`` and ``B << C`` implies ``A << C``. When you think about this in terms
of base/derived classes, it should make sense.

So what does it mean for A to depend on B, in terms of things in the code?
Basically, does A *reference* B? Possible ways in the class interface include:

- A extends or implements B
- A has a field of type B
- A has a method that references B
- B appears as a template parameter in A (C++ only)
- B is a friend of A (C++ only)
- A references a B pointer, reference, or array

Even if there are no dependencies in the class declaration between A and B, in
the implementation, you can still have a dependency. Consider a method ``A.m``
which references B if:

- B appears in the signature of ``A.m``
- A.m has a local variable of type B
- A.m uses a global variable of type B (C++ only)

If A references B, in any way, then ``A << B`` formally speaking. So, with that
background in place, we now can consider the crucial question of "How can A come
to depend on B even if all the things above are avoided?". These "hidden"
dependencies would definitely make A harder to understand, modify, and reuse.

We can now state the Transparency Principle in OOP::

  Avoid hidden dependencies between classes. Formally: the dependency
  relationship is no more than the transitive closure of the references
  relationship between two classes A, B.

If we have ``A << B``, this implies A references some C if ``C << B``. The
transitive closure of A::

  TC(A) = { B | A << B }

gives us an idea of how much support A requires. In terms of graphs, the
transitive closure is the graph which contains all edges ``{u, v}`` for which
there are paths from u to v. In the above example, there is direct dependence
via A -> B, and an *indirect* dependency via transitivity via A -> B -> C.

If A is a stand-alone class, then trivially::

  TC(A) = { A }

Clearly, the larger TC(A) is, the harder it is to reuse, understand, or
replace A.

We can extend the concept of dependence and transitive closure to objects in the
obvious way::

  TC(obj) = { x | obj << x }

For example, saving an object to a file or database, or sending this object to a
remote object over a network will require saving or sending the entire
transitive closure of that object. The size of the transitive closure--its
*encumbrance* -- is a crude measure of the required set of support::

  encumbrance(A) = |TC(A)|

Aside: Bi-directional dependencies are possible; i.e. ``A << B AND B << A``, to
TC(A) might not be a tree. Strictly speaking, it's a directed graph.


Coupling: Encumbrance In OOP
============================

The concept of encumbrance can be rather abstract, so we explicitly connect it
to OOP with the notion of *coupling*.  coupling refines the notion of dependence
by attempting to qualify and quantify the strength of the dependency of one
class on another in an OOP context.

Assume A depends on B. If A and B are loosely coupled, only major changes to
certain methods of B should impact A. If A and B are tightly coupled, then small
changes to B can have a dramatic impact on A.

Although there is no precise way to measure how tightly an association couples
one class to another, we can identify several common coupling "degrees". For
example, assume an E-commerce server keeps track of customers and the
transactions they commit.

.. tabs::

   .. tab:: Content Coupling (THE WORST)

       If a C++ ``Transaction`` class is a friend of the ``Customer`` class, we
       have::

         class Customer {
            friend class Transaction;
         };

       Then Transaction is content coupled to Customer. Changes to the private
       members of Customer could impact Transaction. Declaring one class to be
       the friend of another tightens the coupling between the two classes.

   .. tab:: Client Coupling (BAD)

      The ``Transaction`` class has a member variable that points to a
      Customer::

        class Transaction {
           Customer customer;
        }

      Some changes to the Customer class will impact the Transaction class, but
      some will not. For example, changing the private members of the
      ``Customer`` class should have no impact. This is the most common form of
      coupling.

   .. tab:: Interface Coupling (good)


      If ``Customer`` is an interface for ``Corporate`` and ``Individual``
      customers, then then the ``Transaction`` class can't even be sure what
      type of object its customer pointer points at. There is no mention in the
      ``Transaction`` class of corporate or individual customers, only
      customers. Transactions can call public ``Corporate`` and ``Individual``
      methods that are explicitly declared in the Customer interface. Other
      public methods such as ``Corporate::getCEO()`` or
      ``Individual::getSpouse()`` are not visible to transaction
      objects. Transaction exhibits interface coupling with the ``Corporate``
      and ``Individual`` classes. Obviously interface coupling is looser than
      client coupling, and preferable.

   .. tab:: Message Coupling (best)

      Message passing also helps to loosen the coupling between objects. For
      example, suppose an object representing an ATM machine mediates (possibly
      via the Mediator design pattern) between transactions and customers. In
      this case transactions and customers communicate by passing messages
      through the ATM machine, which means that the transaction doesn't even
      need to know the location of the customer. This is message coupling.

Designing Minimally Coupled Classes
===================================

By necessity the classes you create in any non-trivial program will *have* to
interact and depend on each other in *some* way if they are all working towards
a common goal. If they don't interact, perhaps what you have created is a set of
reusable/generic functionalities instead. We are concerned with creating
programs to accomplish a single task, so we consider that case. Short of totally
uncoupled, we can achieve the loosest form of coupling by combining interface
and message coupling, and so you should strive to write code with only those
forms of coupling.

To help make your code adhere to the Transparency Principle and be loosely
coupled, here are some simple guidelines to follow.

- Minimize the number of arguments that class constructors or functions
  take. The more arguments, the greater encumbrance of the enclosing
  class/function.

- Avoid direct references to classes via members, references, or pointers (C++
  only) whenever possible. Prefer to rely on intermediate classes which handle
  communication between objects. For example, instead of requiring an object
  reference to attach/observe it, use a publish/subscribe framework where you
  instead attach/observer to objects by name or ID.

- Minimize the size of classes and functions. The larger the size, the greater
  the chances that the enclosing class/function/namespace/package will have a
  large encumbrance.

- Rely on the build/packaging system where possible to enforce module
  independence; C++'s Bazel is a good example of a build system which can do
  this.

- Separate out functionalities into the smallest possible units; e.g., don't
  put multiple classes in a single file. This helps to avoid inadvertent
  couplings.

- Use design patterns (see :ref:`dev/design/patterns`) to break dependencies
  between classes. Mediator, strategy, and factory are highly relevant here.
