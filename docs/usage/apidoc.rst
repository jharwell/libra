.. _usage/apidoc:

=======================
API Documentation Tools
=======================

Generating API Documentation
============================

LIBRA provides targets for generating the documentation with:

- doxgyen

.. _usage/apidoc/check:

Checking API Documentation
==========================

LIBRA provides tools for checking API documentation with:

- doxygen (``make apidoc-check-doxygen``)

- clang (``make apidoc-check-clang``)

None of these targets depend on the main project, and so can be run in CI prior
to the build stage, if desired.

.. tabs::

   .. tab:: doxygen

      Several tags are modified in the generated Doxyfile:

      - ``WARN_AS_ERROR=FAIL_ON_WARNINGS``

      - ``QUIET=YES``

      This checker can warn on missing/malformed documentation, but cannot check
      documentation for consistency with the code itself.

   .. tab:: clang

      This checker only checkers *existing* documentation for consistency; if
      you forget to document something, no error will be emitted. It will also
      check for consistency between documentation and code (e.g., the documented
      parameter has the same name as the parameter in the code), since it is AST
      aware.

      If your project depends on/links with 3rd party libraries which are not
      "system" libraries, then clang will warn about documentation issues in the
      3rd party headers as well, and error out, even if your documentation is
      clean. This can happen with :cmake:variable:`LIBRA_DRIVER`\= ``CONAN``, or
      (more rarely) stand-alone 3rd party libraries don't specify their includes
      properly.

      There are two solutions to this:

      - Modify one or more of the ``{INCLUDE_DIRECTORIES,
        INTERFACE_INCLUDE_DIRECTORIES}`` properties to mark the include
        directories from the 3rd party libraries as ``SYSTEM`` so that they get
        specified on the compiler command line as ``isystem``.

      - Wrap the problematic 3rd party headers in::

          #pragma clang diagnostic push
          #pragma clang diagnostic ignored "-Wdocumentation"
          #include <3rdparty/problem.hpp>
          #pragma clang diagnostic pop

      The first way is less invasive, and so should be preferred.
