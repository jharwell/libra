.. _dev/design/abstraction:

===================================================================
The Abstraction Principle: Separating Interfaces And Implementation
===================================================================


The abstraction principle implies that the external function or purpose of a
module (the module's interface) should be separated from its internal structure
(the module's implementation). A dependency on such a module is only a
dependency on its public interface, not its private implementation. This frees
clients from the need to understand implementation details, while implementers
are free to modify the implementation without the fear of breaking client code.

Designing Independent Interfaces And Implementation
===================================================

To help make your code adhere to the Abstraction Principle, here are some simple
guidelines to follow.

- If a class needs to reference a function of another class it has a reference
  to, that function should be specified in an interface whenever possible, and
  the reference be to the *interface*, not to the derived class implementing the
  interface.
