.. _dev/design/modularity:

===============================================================
The Modularity Principle: Designing Internally Cohesive Classes
===============================================================

The methods of a cohesive class work together to achieve a common goal. Classes
that try to do too many marginally related tasks are difficult to understand,
reuse, and maintain.

Cohesion is the formal way of saying "Each <THING> should do one thing and one
thing only" where <THING> can be a function, a class, a module, etc.

While there is no precise way to measure the cohesiveness of a class, we can a
rough spectrum (from low to high, left to right) (inspired from `here
<http://www.cs.sjsu.edu/faculty/pearce/ooa/chp5.htm>`_):

.. tabs::

   .. tab:: Coincidental Cohesion (low)

      A class exhibits coincidental cohesion if the tasks its methods perform
      are totally unrelated. If most of your classes look like this, they are
      not cohesive::

        class Foo {
          void initPrinter() { ... }
          double calcInterest() { ... }
          Date getDate() { ... }
        }

   .. tab:: Logical cohesion (low)

      A class exhibits logical cohesion if the tasks its methods perform are
      conceptually related. For example, the methods of the following class are
      related by the mathematical concept of area::

        class AreaFuns {
          double circleArea() { ... }
          double rectangleArea() { ... }
          double triangleArea() { ... }
        }

   .. tab:: Temporal cohesion (low)

      A logically cohesive class also exhibits temporal cohesion if the tasks
      its methods perform are invoked at or near the same time. For example, the
      methods of the following class are related by the device initialization
      concept, and they are all invoked at system boot time::

        class Initializer {
          void initDisk() { ... }
          void initPrinter() { ... }
          void initMonitor() { ... }
      }

   .. tab:: Procedural Cohesion (medium)

      A class exhibits procedural cohesion, the next step up in our cohesion
      scale, if the tasks its methods perform are steps in the same application
      domain process. For example, if the application domain is a kitchen, then
      cake making is an important application domain process. Each cake we bake
      is the product of an instance of a ``MakeCake`` class::

        class MakeCake {
          void addIngredients() { ... }
          void mix() { ... }
          void bake() { ... }
        }

   .. tab:: Informational Cohesion (high)

      A class exhibits informational cohesion if the tasks its methods perform
      are services performed by application domain objects. For example, an
      ``Airplane`` class exhibits informational cohesion because different
      instances represent different airplanes::

        class Airplane {
          void takeoff() { ... }
          void fly() { ... }
          void land() { ... }
        }


One reason why coincidental, logical, and temporal cohesion are at the low end
of our cohesion scale is because instances of such classes are unrelated to
objects in the application domain. For example, suppose x and y are instances of
the ``Initializer`` class::

  Initializer x = Initializer(), y = new Initializer();

How can we interpret x, and y? What do they represent? How are they different?

Generally speaking, you won't be able to create classes which are
informationally cohesive ALL the time, but you should always write your classes
to be as cohesive in ways on the higher end of the spectrum.

