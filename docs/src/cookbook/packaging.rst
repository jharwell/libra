.. SPDX-License-Identifier: MIT

.. _cookbook/packaging:

========================
Packaging and Installing
========================

This guide covers how to configure a LIBRA project for installation and
packaging — making your library consumable by other CMake projects via
``find_package()``, generating distributable packages (``.deb``, ``.rpm``,
archives), and optionally exposing components so downstream projects can
request only what they need.

All functions described here are only available when
:cmake:variable:`LIBRA_DRIVER` is ``SELF``. For the full function reference
see :ref:`reference/project-local/packaging`.

.. _cookbook/packaging/install:

Basic installation
==================

The minimum setup to make your library installable and usable with
``find_package()`` is two calls in ``cmake/project-local.cmake``:

.. code-block:: cmake

   libra_configure_exports(mylib)
   libra_install_target(mylib INCLUDE_DIR include/)

After ``cmake --build . --target install``, downstream projects can use:

.. code-block:: cmake

   find_package(mylib REQUIRED)
   target_link_libraries(their_target PRIVATE mylib::mylib)

**Required: config.cmake.in template**

:cmake:command:`libra_configure_exports` requires a template at
``cmake/config.cmake.in``. A minimal template for a library with no
dependencies:

.. code-block::

   @PACKAGE_INIT@

   include("${CMAKE_CURRENT_LIST_DIR}/mylib-exports.cmake")
   check_required_components(mylib)

If your library depends on other packages, add ``find_dependency()`` calls
before the ``include()``:

.. code-block::

   @PACKAGE_INIT@

   include(CMakeFindDependencyMacro)
   find_dependency(fmt REQUIRED)
   find_dependency(spdlog REQUIRED)

   include("${CMAKE_CURRENT_LIST_DIR}/mylib-exports.cmake")
   check_required_components(mylib)

.. NOTE::

   Do **not** add ``find_dependency()`` for header-only dependencies passed
   directly to :cmake:command:`libra_configure_exports` — this causes an
   infinite loop when ``find_package()`` is called.

.. _cookbook/packaging/headers:

Header-only libraries
=====================

For a header-only library there is no compiled target to install:

.. code-block:: cmake

   libra_configure_exports(mylib)
   libra_install_headers(${PROJECT_SOURCE_DIR}/include)

The ``cmake/config.cmake.in`` for a header-only library sets up the include
path rather than importing exported targets:

.. code-block::

   @PACKAGE_INIT@

   set_and_check(mylib_INCLUDE_DIR "${PACKAGE_PREFIX_DIR}/include")
   check_required_components(mylib)

.. _cookbook/packaging/cmake-modules:

Installing CMake modules
========================

If your project ships reusable ``.cmake`` modules for downstream projects,
install them alongside the config file:

.. code-block:: cmake

   libra_install_cmake_modules(mylib cmake/modules)         # whole directory
   libra_install_cmake_modules(mylib cmake/MyHelpers.cmake) # individual file

Installed modules land in ``${CMAKE_INSTALL_LIBDIR}/cmake/mylib/`` and are
accessible to downstream projects after ``find_package(mylib)``.

.. _cookbook/packaging/components:

Components
==========

Components let downstream projects request only a subset of your library:

.. code-block:: cmake

   find_package(mylib REQUIRED COMPONENTS networking serialization)

**Choosing a strategy**

LIBRA offers :cmake:command:`libra_add_component_library`, which builds a
separate ``mylib_<component>`` library target for each component. Useful when
setting components are large, optional, or have distinct link dependencies;
downstream projects link ``mylib_networking`` explicitly.

.. code-block:: cmake

   libra_add_component_library(
     TARGET    mylib  COMPONENT networking
     SOURCES   ${ALL_SRC}  REGEX "src/net/.*\\.cpp")

   libra_add_component_library(
     TARGET    mylib  COMPONENT serialization
     SOURCES   ${ALL_SRC}  REGEX "src/serial/.*\\.cpp")

   # Downstream:
   # find_package(mylib REQUIRED COMPONENTS networking)
   # target_link_libraries(their_target PRIVATE mylib_networking)

**Wiring up config.cmake.in**

Whichever strategy you use, call :cmake:command:`libra_check_components` at
the end of ``cmake/config.cmake.in`` so missing required components produce a
clear error at ``find_package()`` time:

.. code-block::

   @PACKAGE_INIT@

   include("${CMAKE_CURRENT_LIST_DIR}/mylib-exports.cmake")

   libra_add_component_library(TARGET mylib COMPONENT networking ...)
   libra_add_component_library(TARGET mylib COMPONENT serialization ...)

   libra_check_components(mylib)

.. _cookbook/packaging/cpack:

Generating packages
===================

LIBRA wraps CPack to generate distributable packages via
``cmake --build . --target package``. Add this to ``cmake/project-local.cmake``
after your target definitions:

.. code-block:: cmake

   libra_configure_cpack(
     "DEB;RPM;TGZ"
     "A short one-line summary of mylib"
     "Longer description of what mylib does."
     "Your Name or Organisation"
     "https://example.com/mylib"
     "Your Name <you@example.com>")

Then build packages:

.. code-block:: bash

   cmake --preset release
   cmake --build --preset release --target package

Packages land in the build directory. Filename format per generator:

- **DEB**: ``<n>_<version>_<arch>.deb``
- **RPM**: ``<n>-<version>-<release>.<arch>.rpm``
- **TGZ/ZIP/etc.**: ``<n>-<version>-<arch>.<ext>``

**Overriding CPack variables**

Set any ``CPACK_*`` variable *before* calling ``libra_configure_cpack()``
to override its defaults. The full set of overridable variables:

.. list-table::
   :widths: 40 30 30
   :header-rows: 1

   * - Variable
     - Default
     - Notes

   * - ``CPACK_PACKAGE_INSTALL_DIRECTORY``
     - ``${CMAKE_INSTALL_PREFIX}``
     - Install prefix inside the package

   * - ``CPACK_PACKAGE_FILE_NAME``
     - ``${PROJECT_NAME}-${VERSION}-${ARCH}``
     - Override to set a fixed filename

   * - ``CPACK_DEBIAN_PACKAGE_SECTION``
     - ``devel``
     -

   * - ``CPACK_DEBIAN_PACKAGE_PRIORITY``
     - ``optional``
     -

   * - ``CPACK_RPM_PACKAGE_GROUP``
     - ``Development/Libraries``
     -

   * - ``CPACK_RPM_PACKAGE_LICENSE``
     - Auto-detected from ``LICENSE*``
     - Set manually if auto-detection fails

   * - ``CPACK_RPM_PACKAGE_RELEASE``
     - ``1``
     -

.. code-block:: cmake

   set(CPACK_PACKAGE_INSTALL_DIRECTORY /opt/mylib)
   set(CPACK_DEBIAN_PACKAGE_SECTION "libs")
   set(CPACK_RPM_PACKAGE_LICENSE "MIT")

   libra_configure_cpack(...)

License auto-detection reads the first 200 bytes of your ``LICENSE`` file
and recognises MIT, Apache, GPL, and BSD. For anything else set
``CPACK_RPM_PACKAGE_LICENSE`` manually or a warning is emitted and
``"Unknown"`` is used.

.. NOTE::

   ``libra_configure_cpack()`` is a CMake ``macro``, not a function, so
   ``CPACK_*`` variables propagate to the calling scope as required by CPack.
   Call it from the top level of ``project-local.cmake``, not from inside a
   function.

.. _cookbook/packaging/full-example:

Full example
============

A complete ``cmake/project-local.cmake`` for a library with components,
installation, and packaging:

.. code-block:: cmake

   # ── Components ─────────────────────────────────────────────────────────────
   libra_add_component_library(
     TARGET    ${PROJECT_NAME}  COMPONENT networking
     SOURCES   ${${PROJECT_NAME}_CXX_SRC}
     REGEX     "src/net/.*\\.cpp")

   libra_add_component_library(
     TARGET    ${PROJECT_NAME}  COMPONENT serialization
     SOURCES   ${${PROJECT_NAME}_CXX_SRC}
     REGEX     "src/serial/.*\\.cpp")

   # ── Main target ────────────────────────────────────────────────────────────
   libra_add_library(${PROJECT_NAME} ${${PROJECT_NAME}_CXX_SRC})

   # ── Installation ───────────────────────────────────────────────────────────
   libra_configure_exports(${PROJECT_NAME})

   libra_install_target(${PROJECT_NAME}
     INCLUDE_DIR ${PROJECT_SOURCE_DIR}/include)

   libra_install_cmake_modules(${PROJECT_NAME} cmake/modules)

   libra_install_copyright(${PROJECT_NAME} ${PROJECT_SOURCE_DIR}/LICENSE)

   # ── Packaging ──────────────────────────────────────────────────────────────
   libra_configure_cpack(
     "DEB;TGZ"
     "One-line summary"
     "Full description."
     "Your Organisation"
     "https://example.com/${PROJECT_NAME}"
     "maintainer@example.com")
