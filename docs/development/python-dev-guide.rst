========================
Python Development Guide
========================

Coding Style
============

Follows the Google python style guide, except in the ways noted in the following
subsections.


Classes
-------

- Don't nest classes, unless there is a really good reason to. Generally nesting
  is a way to avoid doing a bunch of extra coding to create a set of
  classes/functions with proper encapsulation which is going to be easier to
  maintain anyway.

Testing
-------

All NEW classes should have some basic unit tests associated with them, when
possible (one for each major public function that the class provides). For any
*existing* classes that have *new* public functions added, a new unit test
should also be added. It is not possible to create unit tests for all classes,
as some can only be tested in an integrated manner, but there many that can and
should be tested in a stand alone fashion.
