.. SPDX-License-Identifier:  MIT

.. _dev/python-guide:

========================
Python Development Guide
========================

Coding Style
============

Strive to follow existing style guides. Linters such as :ref:`Ruff <dev/links/python/ruff>`
will ensure these guidelines are followed, so take advantage of them!

- :ref:`PEP8 <dev/links/python/PEP8>` is the universally recognized Python style
  guide.  Follow PEP8 first -- if this document conflicts with PEP8, follow PEP8
  and notify the team of the conflict.

- :ref:`PEP484 <dev/links/python/PEP484>` describes guidelines for using type
  hints.  All Python code should have type hints; using strict typing makes
  Python code easier to use and reduces assumptions.  Our projects should
  validate the type hints with ``pytype``.

- :ref:`Google Python Style Guide <dev/links/python/google-style>` includes
  information not covered in PEP8, such as docstring and import guidelines.
  Follow this when something isn't covered by PEP8 or this guide.

Files
-----

- All source files should have the exact license text (e.g., GNU GPLv3), or an
  abbreviated version and a pointer to full license text (e.g., ``Copyright Foo
  Corp blah blah blah. See LICENSE.md for details``).

Project Structure
-----------------

- When starting a python project, consider using the :ref:`Python Project
  Template <dev/links/python/project-template>`.  This contains all of the
  boilerplate structure to generate an installable python package that can be
  installed and referenced by other projects.

- Python projects should be structured in a way that it can be collected and
  installed as a Python Package.  We should strive to reuse as much Python code
  as possible -- copy-pasted code causes issues with maintainability.
  Structuring Python projects this way allows them to be installed and used by
  other repositories.

- Projects should include one top-level package (but can contain sub-packages
  within that package).  Following a principle of one repository, one package
  makes it easier to track what package ties to what code base.

- Dependencies needed for development should be included in the
  ``requirements.txt`` file.  This makes it easy for developers to set up a
  virtual environment (``python3 -m venv .venv && source .venv/bin/activate``
  and install the packages needed to develop the software (``pip install -r
  requirements.txt``)

- Runtime dependences should be included in the ``pyproject.toml`` :ref:`file
  <dev/links/python/tools/pyproject.toml>` This will ensure runtime dependencies
  are installed when the package is installed with ``pip``.

- Use the :ref:`hatch <dev/links/python/tools/hatch>` framework to manage
  project versioning and release builds.  Hatch seems to have fewer issues
  interacting with pyproject.toml files compared to setuptools.

- Public classes and functions should be included in ``__init__.py``'s
  ``__all__`` list.  This provides an easy way to see a module's public
  interfaces.  For example:

  .. code-block:: python

    # __init__.py

    from receiver_automated_test import tlv, message, configuration, receiver, template

    # Define the public API of this module here
    __all__ = ["receiver", "template", "configuration", "message", "tlv"]


- Files that are intended to be executed from the command line should put all
  executable code behind a ``if __name__ == "__main__":`` statement.

Pythonic Style
--------------

"Ask for forgiveness, not permission"
"""""""""""""""""""""""""""""""""""""

Python has a robust exception/handler framework; instead of testing if an
operation can be performed, simply perform the operation and catch an exception
if necessary.  Not only does this make the code usable in typical Python style,
but it allows unhandled errors to be easily identifiable.

.. tabs::

  .. tab:: Using the Principle

    .. code-block:: python

      try:
          with open(nonexistant_file, 'r') as fpt:
              data = fpt.read()
      except FileNotFoundError:
          print("File does not exist.")
          data = ""

  .. tab:: Not Using the Principle

    .. code-block:: python

      if nonexistant_file.is_file():
          print("File does not exist.")
          data = ""
      else:
          with open(nonexistant_file, 'r') as fpt:
              data = fpt.read()

Use exceptions, do not return pass/fail status
""""""""""""""""""""""""""""""""""""""""""""""

Extending on the above, don't use error codes to return the status of a function
call. Use an exception, and let the caller either catch the error or let the
exception bubble up. Assume function calls are successful if they do not raise
an exception.

.. tabs::

  .. tab:: Using the Principle

    .. code-block:: python

      if key in my_dict:
          raise ValueError(f"{key} already exists in 'my_dict'")

  .. tab:: Not Using the Principle

    .. code-block:: python

      if key in my_dict:
          return -1

  .. tab:: Unmaintainable

    .. code-block:: python

      if key in my_dict:
          sys.exit(-1)

Unpack Command Line Arguments When They are Received
""""""""""""""""""""""""""""""""""""""""""""""""""""

Command line arguments should be immediately unpacked and passed to relevant
functions.  Passing an ``args`` object into functions results in code that can't
be reused and violates type hint rules.

  .. tabs::

    .. tab:: Using the Principle

      .. code-block:: python

        def foo(bar: bar_package.Bar):
            # Interact with Bar directly; easily reusable function
            bar.baz()

        if __name__ == "__main__":
            parser = argparse.ArgumentParser()
            parser.add_argument('bar_name', type=bar_package.Bar)
            args = parser.parse_args()
            foo(args.bar_name)


    .. tab:: Not Using the Principle

      .. code-block:: python

        def foo(args):
            # Tightly coupled to command line args, not reusable
            args.bar_name.baz()

        if __name__ == "__main__":
            parser = argparse.ArgumentParser()
            parser.add_argument('bar_name', type=bar_package.Bar)
            args = parser.parse_args()
            foo(args)


Iterating through Lists
"""""""""""""""""""""""

.. code-block:: python

  # Don't do this
  for i in range(len(my_list)):
      print(my_list[i])

  # Do this instead
  for item in my_list:
      print(item)

  # Or this, if you need the index
  for index, item in enumerate(my_list):
      print(f"Item #{index} is {item}")

  # To see if an item exists in a list...
  if item in my_list:
      print(f"item {item} exists in my_list")

Iterating through Dictionaries
""""""""""""""""""""""""""""""

.. code-block:: python

  # Do this if you only need to use the keys
  for key in my_dict:
      print(f"my_dict contains key {key}")

  # Do this if you only need to use the values
  for value in my_dict.values():
      print(f"my_dict contains value {value}")

  # Do this if you need to use keys and values
  for key, value in my_dict.items():
      print(f"Key {key} contains value {value}")

Imports
-------

When importing stuff, don't import classes directly, because:

#. Class names can get pretty long, while module/package names are generally
   short

#. It is EXTREMELY helpful to people unfamiliar with a code base looking at a
   file to be able to attach a semantically meaningful namespace to the class
   name via ``mymodule.MyClass``.

#. You can have the same class name in multiple modules imported and used in a
   single ``.py`` file without conflict. This is particularly helpful with
   "trampoline" classes which dispatch things from a common entry point to a
   selected implementation of something.


.. tabs::

  .. tab:: Following the Principle:

    .. code-block:: python

      import pathlib
      import typing
      from unittest import mock

  .. tab:: Not following the Principle:

    .. code-block:: python

      from pathlib import Path
      from typing import Dict
      from unittest.mock import Mock

Naming Conventions
------------------

- Use the `recommended naming conventions
  <https://google.github.io/styleguide/pyguide.html#3164-guidelines-derived-from-guidos-recommendations>`_
  for classes, variables, files, etc.

- Don't use smurf naming: When almost every class has the same prefix. IE, when
  a user clicks on the button, a ``SmurfAccountView`` passes a
  ``SmurfAccountDTO`` to the ``SmurfAccountController``. The ``SmurfID`` is used
  to fetch a ``SmurfOrderHistory`` which is passed to the ``SmurfHistoryMatch``
  before forwarding to either ``SmurfHistoryReviewView`` or
  ``SmurfHistoryReportingView``. If a ``SmurfErrorEvent`` occurs it is logged by
  ``SmurfErrorLogger to`` ``${app}/smurf/log/smurf/smurflog.log``. From
  :ref:`here <dev/links/cxx/smurf-naming>`. Note that this does `not` apply to
  classes with common postfixes; e.g., ``battery_sensor``, ``light_sensor``,
  etc.  ``SmurfLog``, etc.

- Don't put the type of the variable in the variable name (e.g., ``sender_list``
  for a list). Linus was right--it _is_ brain damaged.

- All private methods for a class start with ``_``.

Classes
-------

- Don't nest classes, unless there is a really good reason to. Generally nesting
  is a way to avoid doing a bunch of extra coding to create a set of
  classes/functions with proper encapsulation which is going to be easier to
  maintain anyway.

- When laying out classes, put special methods first (e.g., ``__repr__``), then
  public methods, and then private methods.

IDE Plugins
-----------

VSCode
""""""

- VSCode has official plugins for writing Python code:
   - Python
   - Python Debugger

- VSCode has third-party plugins to help writing Python code:
   - Ruff -- a plugin for the Ruff linter

- VSCode has plugins for remote development:
   - Remote - SSH
   - WSL

Install links are available on the :ref:`links page
<dev/links/python/vscode-extensions>`.

Documentation
=============


- `__init__.py` files' docstrings should contain a description of the module.

- All classes should have:

    - A brief
    - A detailed description for non-casual users of the class

- All non-getter/non-setter member functions should be documentated with at
  least a brief, UNLESS those functions are overrides/inherited from a parent
  class, in which case they should be left blank (usually) and their
  documentation be in the class in which they are initially declared. All
  non-obvious parameters should be documented.

Tricky/nuanced issues with member variables should be documented, though in
general the module name + class name + member variable name + member variable
type should be enough documentation. If its not, chances are you are naming
things somewhat obfuscatingly and need to refactor.

Function arguments should be documented using the `Napoleon/Google style
<https://google.github.io/styleguide/pyguide.html#doc-function-args>`_

Here's a simple example of a class with docstrings:

.. code-block:: python

  class Environment:
    """Provides a collection of interfaces for executing receiver application tests.

       The Environment class should serve as a one-stop-shop for collections
       related to the test environment.  Receiver and TestCase objects should be
       tracked as members of this class.  Ideally, the test runner
       object/class/function will need to interact *only* with the Environment
       object, and the Environment object will set up the test and execute
       Environment by interacting with those member objects.

    """
    def __init__(self, platform_name: str):
        self._platform_name = platform_name

    def execute_receiver_operations(self, operations: typing.List[op.Operation]):
        """Execute a set of receiver operations on the provided environment.

        Args:
            operations: A list of operations to run on the receiver.
        """
        rec = receiver.receiver_factory.from_platform_name(self._platform_name)
        rec.initialize()
        for operation in operations:
            operation.execute(rec)
        rec.execute()


Testing
=======

All NEW classes should have some basic unit tests associated with them, when
possible (one for each major public function that the class provides). For any
*existing* classes that have *new* public functions added, a new unit test
should also be added. Unit-tested code is significantly less likely to contain
bugs, makes refactoring significantly easier, and draws attention to when code
changes break assumptions about the internal operations of the software.

Use the built in :ref:`unittest <dev/links/python/tools/unittest>` package to
perform unit tests.  Tests should be placed in a top-level directory named
``tests``.

Use the :ref:`coverage <dev/links/python/tools/coverage>` plugin to generate
test coverage reports.  This demonstrates how much of your code is exercised by
the unit tests.  Developers should strive for 100% coverage whenever possible.

Linting and Type Checking
=========================

All projects should use the following linters/analysis tools:

- :ref:`Ruff <dev/links/python/analysis/analysis>`: A fast, feature-rich linter
  for Python.  The project should contain a ``ruff.toml`` file at root level
  with the linter settings.  Running ``ruff`` should be part of the CI pipeline.
  As a developer, you should use a Ruff plugin for your IDE to visually
  demonstrate when code isn't following guidelines.  Ruff configurations and
  VSCode settings are included in the Python Project Template.

- :ref:`Pytype <dev/links/python/analysis/pytype>`: The project should contain a
  ``pytype.toml`` file at root level with the pytype settings.  Pytype
  configurations are included wiht the Python Project Template.
