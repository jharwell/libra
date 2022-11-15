.. SPDX-License-Identifier:  MIT

.. _ln-libra-cuda-dev-guide:

======================
CUDA Development Guide
======================

Generally, since CUDA can be C or C++ flavored, follow either
:ref:`ln-libra-c-dev-guide` or :ref:`ln-libra-cxx-dev-guide`, as appropriate,
with the additions below. If something below contradicts the C/C++ style guides,
go with the below for a CUDA project.

Coding Style
============

Files
-----

- All source files should have the exact license text (e.g., GNU GPLv3), or an
  abbreviated version and a pointer to full license text (e.g., ``Copyright Foo
  Corp blah blah blah. See LICENSE.md for details``).

- For C/C++ headers, use a ``.h/.hpp`` extension, respectively.

- For C/C++ sources, use a ``.c/.cpp`` extension, respectively for improved
  compilation speed.

- Use CUDA source files (``.cu``) *only* for code blocks containing device code
  (i.e., at least 1 ``__device__`` or ``__global__`` definition)

- Use empty ``__host__`` and ``__device__`` definition guards in function
  headers to make them portable for builds without CUDA support.

- Do not declare ``__global__`` functions in C/C++ header or source files.

- Declare kernel calling functions in C/C++ headers, and encapsulate pointers to
  device and host memory locations.

Naming
------

- All global variables should be prefixed with ``g_``.

- All device-local variables should be prefixed with ``d_``.
