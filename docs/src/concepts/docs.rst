.. SPDX-License-Identifier: MIT

.. _concepts/docs:

=============
Documentation
=============

LIBRA provides targets for generating and checking API documentation
(Doxygen) and project documentation (Sphinx). This page covers
tool-specific behaviour and known issues. For the target reference,
see :ref:`reference/targets`.

General behaviour
=================

Documentation targets do not depend on the main project build, so they
can run in CI before or independently of the build step. Enable them
with :cmake:variable:`LIBRA_DOCS`.

Both ``apidoc`` and ``sphinxdoc`` targets are attempted independently
when running ``clibra docs``. If a target is unavailable (e.g. doxygen
is not installed), it is skipped with a warning rather than an error.

API documentation (Doxygen)
============================

The ``apidoc`` target generates API docs from your source using Doxygen.
Requires a ``docs/Doxyfile.in`` in the project root.

For checker configuration, third-party header gotchas, and the
step-by-step workflow, see :ref:`cookbook/documentation`.

Project documentation (Sphinx)
================================

The ``sphinxdoc`` target generates HTML project documentation using
Sphinx. If the ``apidoc`` target exists, ``sphinxdoc`` depends on it
so that API documentation is always current before Sphinx runs.

The Sphinx command used can be customized via
:cmake:variable:`LIBRA_SPHINXDOC_COMMAND` if you need to pass
additional arguments or use a wrapper script.

Currently, LIBRA only supports generating HTML output from Sphinx.
Other builders (PDF, man pages, etc.) are not supported via the
``sphinxdoc`` target.
