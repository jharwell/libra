.. SPDX-License-Identifier:  MIT

=======================================
Luigi Build Reusable Automation (LIBRA)
=======================================

.. |docs| image:: https://jharwell.github.com/libra/actions/workflows/pages.yml/badge.svg?branch=master
                  :target: https://jharwell.github.io/libra

|docs|

This is a repository containing 100% reusable CMake build
boilerplate/scaffolding that can be used for nested/flat C/C++ projects (mix and
match), and provides reusable build "plumbing" that can be transferred without
modification between projects.

Why use it?

- You have a lot of C/C++ projects which are more or less all built the same,
  with a few tweaks.

- You work with multiple compilers and don't want to have to learn how to do the
  same thing via different options on the different compilers.

- You use CMake as your main build system.

Why *not* use it?

- All/most of your C/C++ projects require vastly different build configurations.


Project documentation is here: `<https://jharwell.github.io/libra/>`_.
