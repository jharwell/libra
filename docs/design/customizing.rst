..
   Copyright 2025 John Harwell, All rights reserved.

   SPDX-License-Identifier:  MIT

=================
Customizing LIBRA
=================

If you want to customize LIBRA so that you don't have to define the same things
in ``project-local.cmake`` for a large set of repos, LIBRA makes it easy to do
so. Most of the defaults you would want to tweak are in
``defaults.cmake``. Simply fork this repo, modify ``defaults.cmake``, and then
BOOM--done.

.. IMPORTANT:: Only non-empty defaults are contained in ``defaults.cmake``. For
               things which default to empty, such as
               ``LIBRA_CPPCHECK_EXTRA_ARGS``, you can just define them directly
               in that file. See :ref:`usage/project-local` for which
               variables fall into this category.

The main exception to this single point of customization is the C/C++ diagnostic
candidates; since those are uniquely defined for each compiler, you can't put
multiple definitions in a single file. Thus, if you override the defaults in
``defaults.cmake`` (or ``project-local.cmake`` on a per-repo basis), you are
necessarily limited to using LIBRA with that compiler, which may or may not be
an issue for you.
