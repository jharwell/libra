#
# Copyright 2023 John Harwell, All rights reserved.
#
# SPDX-License-Identifier:  MIT

# ##############################################################################
# Custom messaging
# ##############################################################################
include(libra/messaging)

#[[.rst:
.. cmake:command:: libra_configure_cpack

  Configure CPack to generate packages via ``make package``.

  Supports multiple package formats including Debian archives (.deb), RPM packages
  (.rpm), and various compressed archives (tar.gz, zip, etc.). Automatically
  detects license type, configures package metadata, and sets up format-specific
  options.

  This is a MACRO (not function) intentionally so that all CPACK_* variables
  propagate to parent scope as required by CPack.

  To use, ``include(libra/package/deploy.cmake)``.


  .. code-block:: cmake

    libra_configure_cpack(<GENERATORS>
                         <SUMMARY>
                         <DESCRIPTION>
                         <VENDOR>
                         <HOMEPAGE>
                         <CONTACT>)

  :param GENERATORS: One or more CPack generators, separated by semicolons.
    Valid options are:

    - ``DEB`` - Debian archive. Packages are set to always install into ``/usr``
      unless ``CPACK_PACKAGE_INSTALL_DIRECTORY`` is set prior to calling this
      function.
    - ``RPM`` - RPM archive. Packages are set to always install into ``/usr``
      unless ``CPACK_PACKAGE_INSTALL_DIRECTORY`` is set prior to calling this
      function.
    - ``TGZ`` - Compressed tar archive (.tar.gz)
    - ``ZIP`` - ZIP archive
    - ``STGZ`` - Self-extracting tar.gz archive
    - ``TBZ2`` - Compressed tar archive (.tar.bz2)
    - ``TXZ`` - Compressed tar archive (.tar.xz)

    Multiple generators can be specified, e.g., ``"DEB;RPM;TGZ"``.

  :param SUMMARY: One line package summary.

  :param DESCRIPTION: Detailed package description.

  :param VENDOR: Package vendor/maintainer organization.

  :param HOMEPAGE: Project home page URL.

  :param CONTACT: Project contact. Email address for DEB packages, name for RPM
    packages.

  **Automatic Features:**

  - License type detection from LICENSE file (supports MIT, Apache, GPL, BSD)
  - Version information from ``PROJECT_VERSION_*`` variables
  - Automatic dependency detection (``SHLIBDEPS`` for DEB, ``AUTOREQ``/``AUTOPROV`` for RPM)
  - Standard directory permissions to satisfy lintian/rpmlint
  - Architecture detection

  **Respects Pre-set Variables:**

  - ``CPACK_PACKAGE_FILE_NAME`` - If set, used as-is. Otherwise defaults to
    ``${PROJECT_NAME}-${CPACK_PACKAGE_VERSION}-${CMAKE_SYSTEM_PROCESSOR}``
  - ``CPACK_PACKAGE_INSTALL_DIRECTORY`` - If set, used as-is. Otherwise defaults
    to ``${CMAKE_INSTALL_PREFIX}``
  - ``CPACK_DEBIAN_PACKAGE_SECTION`` - Package section (defaults to "devel")
  - ``CPACK_DEBIAN_PACKAGE_PRIORITY`` - Package priority (defaults to "optional")
  - ``CPACK_RPM_PACKAGE_GROUP`` - RPM group (defaults to "Development/Libraries")
  - ``CPACK_RPM_PACKAGE_LICENSE`` - RPM license (auto-detected if not set)
  - ``CPACK_RPM_PACKAGE_RELEASE`` - RPM release number (defaults to "1")

  **Expected Files:**

  The function automatically searches for these files in ``CMAKE_SOURCE_DIR``:

  - ``LICENSE*`` - License file (used for package and license detection)
  - ``README*`` - README file

  Warnings are emitted if these files are not found, but package generation
  continues.

  **Example:**

  .. code-block:: cmake

    project(mylib VERSION 1.0.0)

    libra_configure_cpack(
      "DEB;RPM"
      "A short project description"
      "Long description of the project features and capabilities."
      "John Doe"
      "https://example.com/mylib"
      "John Doe <john@example.com>")

    # Generate packages with: make package

  **DEB-Specific Configuration:**

  - File naming: ``DEB-DEFAULT`` (includes architecture)
  - Automatic shared library dependency detection
  - Strict control file permissions
  - Debug output enabled for troubleshooting

  **RPM-Specific Configuration:**

  - File naming: ``RPM-DEFAULT`` (includes version, release, architecture)
  - Relocatable packages (allows installation to different prefixes)
  - Standard system directories excluded from package

]]
macro(
  libra_configure_cpack
  GENERATORS # One or more CPack generators, separated by ';' (e.g.,
             # "DEB;RPM;TGZ")
  SUMMARY # Summary of the package
  DESCRIPTION # Description of the package
  VENDOR # Package vendor/maintainer organization
  HOMEPAGE # Project home page URL
  CONTACT # Project contact (email for DEB, name for RPM)
)
  # Validate required arguments
  if(ARGC LESS 6)
    libra_error(
      "libra_configure_cpack: Requires 6 arguments: GENERATORS SUMMARY DESCRIPTION VENDOR HOMEPAGE CONTACT\n"
      "  Usage: libra_configure_cpack(<generators> <summary> <description> <vendor> <homepage> <contact>)"
    )
  endif()

  # Validate that PROJECT_VERSION is set
  if(NOT DEFINED PROJECT_VERSION_MAJOR
     OR NOT DEFINED PROJECT_VERSION_MINOR
     OR NOT DEFINED PROJECT_VERSION_PATCH)
    libra_error(
      "libra_configure_cpack: PROJECT_VERSION variables not set\n"
      "  Set version in project() command: project(${PROJECT_NAME} VERSION x.y.z)"
    )
  endif()

  # Validate generators
  string(REPLACE ";" "|" VALID_GENERATORS_REGEX "DEB|RPM|TGZ|ZIP|STGZ|TBZ2|TXZ")
  foreach(GENERATOR ${GENERATORS})
    if(NOT "${GENERATOR}" MATCHES "^(${VALID_GENERATORS_REGEX})$")
      libra_error("libra_configure_cpack: Invalid GENERATOR '${GENERATOR}'\n"
                  "  Valid options: DEB, RPM, TGZ, ZIP, STGZ, TBZ2, TXZ")
    endif()
  endforeach()

  # Find common package files
  file(GLOB LICENSE "${CMAKE_SOURCE_DIR}/LICENSE*")
  file(GLOB README "${CMAKE_SOURCE_DIR}/README*")

  if(NOT LICENSE)
    libra_message(
      WARNING "libra_configure_cpack: No LICENSE file found (tried LICENSE*)\n"
      "  A LICENSE file is recommended for package generation")
  endif()
  if(NOT README)
    libra_message(
      WARNING "libra_configure_cpack: No README file found (tried README*)\n"
      "  A README file is recommended for package generation")
  endif()

  # ============================================================================
  # Common CPack settings (all generators)
  # ============================================================================
  set(CPACK_PACKAGE_NAME "${PROJECT_NAME}")
  set(CPACK_PACKAGE_VENDOR "${VENDOR}")
  set(CPACK_PACKAGE_CONTACT "${CONTACT}")
  set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "${SUMMARY}")
  set(CPACK_PACKAGE_DESCRIPTION "${DESCRIPTION}")
  set(CPACK_PACKAGE_HOMEPAGE_URL "${HOMEPAGE}")

  # Version information
  set(CPACK_PACKAGE_VERSION_MAJOR ${PROJECT_VERSION_MAJOR})
  set(CPACK_PACKAGE_VERSION_MINOR ${PROJECT_VERSION_MINOR})
  set(CPACK_PACKAGE_VERSION_PATCH ${PROJECT_VERSION_PATCH})
  set(CPACK_PACKAGE_VERSION
      "${CPACK_PACKAGE_VERSION_MAJOR}.${CPACK_PACKAGE_VERSION_MINOR}.${CPACK_PACKAGE_VERSION_PATCH}"
  )

  # Resource files
  if(LICENSE)
    set(CPACK_RESOURCE_FILE_LICENSE "${LICENSE}")
  endif()
  if(README)
    set(CPACK_RESOURCE_FILE_README "${README}")
  endif()

  # Install directory
  if(NOT CPACK_PACKAGE_INSTALL_DIRECTORY)
    set(CPACK_PACKAGE_INSTALL_DIRECTORY ${CMAKE_INSTALL_PREFIX})
    libra_message(
      STATUS
      "CPACK_PACKAGE_INSTALL_DIRECTORY not set - using CMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}"
    )
  endif()

  # Set generators
  set(CPACK_GENERATOR "${GENERATORS}")

  # Default directory permissions (quiets lintian/rpmlint warnings)
  set(CPACK_INSTALL_DEFAULT_DIRECTORY_PERMISSIONS
      OWNER_READ
      OWNER_WRITE
      OWNER_EXECUTE
      GROUP_READ
      GROUP_EXECUTE
      WORLD_READ
      WORLD_EXECUTE)

  # ============================================================================
  # DEB-specific settings
  # ============================================================================
  if("${GENERATORS}" MATCHES "DEB")
    libra_message(STATUS "Configuring DEB package generator")

    # Use default naming (includes architecture)
    set(CPACK_DEBIAN_FILE_NAME DEB-DEFAULT)

    # Automatic dependency detection
    set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS ON)
    set(CPACK_DEBIAN_PACKAGE_GENERATE_SHLIBS ON)

    # Enable debug output for troubleshooting
    set(CPACK_DEBIAN_PACKAGE_DEBUG ON)

    # Strict permission checking for control files
    set(CPACK_DEBIAN_PACKAGE_CONTROL_STRICT_PERMISSION TRUE)

    # Package section (optional, but recommended)
    if(NOT CPACK_DEBIAN_PACKAGE_SECTION)
      set(CPACK_DEBIAN_PACKAGE_SECTION "devel")
    endif()

    # Priority (optional)
    if(NOT CPACK_DEBIAN_PACKAGE_PRIORITY)
      set(CPACK_DEBIAN_PACKAGE_PRIORITY "optional")
    endif()

    # Architecture (auto-detected if not specified)
    # set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE "amd64")

    # Ensure description propagates correctly
    set(CPACK_DEBIAN_PACKAGE_DESCRIPTION "${CPACK_PACKAGE_DESCRIPTION}")
    set(CPACK_DEBIAN_PACKAGE_SUMMARY "${CPACK_PACKAGE_DESCRIPTION_SUMMARY}")

    libra_message(
      STATUS
      "  DEB: Section=${CPACK_DEBIAN_PACKAGE_SECTION}, Priority=${CPACK_DEBIAN_PACKAGE_PRIORITY}"
    )
  endif()

  # ============================================================================
  # RPM-specific settings
  # ============================================================================
  if("${GENERATORS}" MATCHES "RPM")
    libra_message(STATUS "Configuring RPM package generator")

    # Use default naming (includes version, release, architecture)
    set(CPACK_RPM_FILE_NAME RPM-DEFAULT)

    # Package group (required for older RPM versions)
    if(NOT CPACK_RPM_PACKAGE_GROUP)
      set(CPACK_RPM_PACKAGE_GROUP "Development/Libraries")
    endif()

    # License (required for RPM)
    if(NOT CPACK_RPM_PACKAGE_LICENSE)
      # Try to detect license type from LICENSE file
      if(LICENSE)
        file(READ "${LICENSE}" LICENSE_CONTENT LIMIT 200)
        if(LICENSE_CONTENT MATCHES "MIT")
          set(CPACK_RPM_PACKAGE_LICENSE "MIT")
        elseif(LICENSE_CONTENT MATCHES "Apache")
          set(CPACK_RPM_PACKAGE_LICENSE "ASL 2.0")
        elseif(LICENSE_CONTENT MATCHES "GPL")
          set(CPACK_RPM_PACKAGE_LICENSE "GPLv3+")
        elseif(LICENSE_CONTENT MATCHES "BSD")
          set(CPACK_RPM_PACKAGE_LICENSE "BSD")
        else()
          set(CPACK_RPM_PACKAGE_LICENSE "Unknown")
          libra_message(
            WARNING
            "libra_configure_cpack: Could not detect license type from LICENSE file\n"
            "  Set CPACK_RPM_PACKAGE_LICENSE manually before calling this function"
          )
        endif()
      else()
        set(CPACK_RPM_PACKAGE_LICENSE "Unknown")
        libra_message(
          WARNING
          "libra_configure_cpack: No LICENSE file found\n"
          "  Set CPACK_RPM_PACKAGE_LICENSE manually before calling this function"
        )
      endif()
    endif()

    # Release number (defaults to 1)
    if(NOT CPACK_RPM_PACKAGE_RELEASE)
      set(CPACK_RPM_PACKAGE_RELEASE "1")
    endif()

    # Make package relocatable (allows installation to different prefixes)
    set(CPACK_RPM_PACKAGE_RELOCATABLE ON)

    # Automatic dependency detection
    set(CPACK_RPM_PACKAGE_AUTOREQ ON)
    set(CPACK_RPM_PACKAGE_AUTOPROV ON)

    # Exclude standard system directories from package (prevents conflicts)
    set(CPACK_RPM_EXCLUDE_FROM_AUTO_FILELIST_ADDITION
        /usr
        /usr/bin
        /usr/lib
        /usr/lib64
        /usr/include
        /usr/local
        /usr/local/bin
        /usr/local/lib
        /usr/local/lib64
        /usr/local/include
        /usr/share)

    # Architecture (auto-detected if not specified)
    # set(CPACK_RPM_PACKAGE_ARCHITECTURE "x86_64")

    # URL
    set(CPACK_RPM_PACKAGE_URL "${HOMEPAGE}")

    # Vendor
    set(CPACK_RPM_PACKAGE_VENDOR "${VENDOR}")

    # Ensure description propagates correctly (CPACK_PACKAGE_DESCRIPTION is not
    # always respected by RPM generator)
    set(CPACK_RPM_PACKAGE_DESCRIPTION "${CPACK_PACKAGE_DESCRIPTION}")
    set(CPACK_RPM_PACKAGE_SUMMARY "${CPACK_PACKAGE_DESCRIPTION_SUMMARY}")

    # Debug package (optional - creates separate debug symbols package)
    # set(CPACK_RPM_DEBUGINFO_PACKAGE ON)

    libra_message(
      STATUS
      "  RPM: Group=${CPACK_RPM_PACKAGE_GROUP}, License=${CPACK_RPM_PACKAGE_LICENSE}, Release=${CPACK_RPM_PACKAGE_RELEASE}"
    )
  endif()

  include(CPack)

  # Status message
  libra_message(STATUS
                "Configured CPack for ${PROJECT_NAME} ${CPACK_PACKAGE_VERSION}")
  libra_message(STATUS "  Generators: ${GENERATORS}")
  libra_message(STATUS
                "  Install directory: ${CPACK_PACKAGE_INSTALL_DIRECTORY}")

endmacro()
