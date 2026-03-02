..
   Copyright 2026 John Harwell, All rights reserved.

   SPDX-License-Identifier:  MIT

.. _usage/presets:

=========================
CMake Presets Integration
=========================

Testing
=======

- ``--output-on-failure`` is unconditionally passed to CTest via
  ``build-and-test``, as that is what you want 99% of the time. So no need to
  configure test preset output/environment variables to make this happen, *if*
  you are using this target. If you use CTest directly, then you will have to
  presets to achieve this behavior in the usual way.

- ``--test-dir`` is set to the ``build/`` directory, so that ctest doesn't
  pollute the repo if you invoke it via ``build-and-test``.  If you use CTest
  directly, then you will have to use presets to achieve this behavior in the
  usual way.
