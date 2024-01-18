.. SPDX-License-Identifier:  MIT

.. _dev/git-usage-guide:

===============
Git Usage Guide
===============

First, read and understand Git Flow:
`<https://nvie.com/posts/a-successful-git-branching-model/>`_.  This model was
chosen because:

- We need to support multiple semantically versioned releases.

- We need to make sure all code which is released is high quality, which is
  difficult to do when you only have branches to/from ``master``.

- We need to support CI/CD.

Feature/Topic branches
======================

- All feature/topic branches branch off of ``devel`` and eventually merge back
  into ``devel`` once approved for merging. No exceptions!!!

- All feature/topic branches must be approved via a MR/PR before merging into
  ``devel``.

- In general, squash all of your commits down to one when merging into
  ``devel``. There are exceptions to this, such as for very large changesets
  which make more sense to break up logically. Use your best judgement.


Rebasing, Merging, And Squashing
================================

- Do not rebase and force push changes on ``devel`` or ``master``. Those are
  publicly visible changes which other developers have based their work on, so
  your rebasing may cause headaches for them when they go to try to merge.
