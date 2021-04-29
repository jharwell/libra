Welcome to LIBRA's documentation!
===================================

Motivation
----------

I've found myself frequently copying and pasting CmakeLists.txt between
projects, and when I find a new flag I want to add, or a new static analysis
checker, etc., I would have to go and add it to EVERY project individually. By
using this repository as a submodule, that can be avoided.

This documentation has two parts: How to use LIBRA/what it can do and various
other development guides that needed a central place to live that was outside of
a specific project.

.. toctree::
   :maxdepth: 2
   :caption: Contents:

   usage/requirements.rst
   usage/capabilities.rst

   development/cxx-dev-guide.rst
   development/git-commit-guide.rst
   development/git-issue-guide.rst
   development/workflow.rst

Projects using LIBRA (in descending probability of interest)
------------------------------------------------------------

- :xref:`PRISM`
- :xref:`FORDYCA`
- :xref:`COSM`
- :xref:`RCPPSW`
- :xref:`RCSW`
