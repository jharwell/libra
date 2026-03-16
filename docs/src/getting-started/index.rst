.. SPDX-License-Identifier: MIT

.. _getting-started:

===============
Getting started
===============

LIBRA has two interfaces: a :ref:`Rust CLI <getting-started/quickstart-cli>`
(``clibra``) and a :ref:`CMake framework <getting-started/quickstart-cmake>`
that the CLI wraps. Most developers will want both — the CLI for day-to-day
work, the CMake framework for project configuration.

Not sure where to start? See :ref:`getting-started/choose-your-path`.
Once you have a working install, the :ref:`cookbook` has end-to-end
guides for every common task.

.. grid:: 1 2 2 2
   :gutter: 3

   .. grid-item-card:: Choose your path
      :link: getting-started/choose-your-path
      :link-type: ref

      CLI or CMake-only? Start here if you are new to LIBRA.

   .. grid-item-card:: Installation
      :link: getting-started/installation
      :link-type: ref

      Install ``clibra`` and verify your environment.

   .. grid-item-card:: Quickstart — CLI
      :link: getting-started/quickstart-cli
      :link-type: ref

      Build, test, and generate coverage for a new project in minutes
      using the ``clibra`` CLI.

   .. grid-item-card:: Quickstart — CMake only
      :link: getting-started/quickstart-cmake
      :link-type: ref

      Use LIBRA as a pure CMake framework without the CLI.

   .. grid-item-card:: Troubleshooting
      :link: getting-started/troubleshooting
      :link-type: ref

      Common errors and how to fix them.

.. toctree::
   :hidden:

   choose-your-path
   installation
   quickstart-cli
   quickstart-cmake
   troubleshooting
