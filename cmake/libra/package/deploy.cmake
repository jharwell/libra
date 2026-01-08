#
# Copyright 2023 John Harwell, All rights reserved.
#
# SPDX-License-Identifier:  MIT

# ##############################################################################
# Custom messaging
# ##############################################################################
include(libra/messaging)

# ##############################################################################
# CPack Options
# ##############################################################################
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
    libra_message(
      FATAL_ERROR
      "libra_configure_cpack requires 5 arguments: GENERATORS SUMMARY DESCRIPTION VENDOR HOMEPAGE CONTACT"
    )
  endif()

  # Validate generators
  string(REPLACE ";" "|" VALID_GENERATORS_REGEX "DEB|RPM|TGZ|ZIP|STGZ|TBZ2|TXZ")
  foreach(GENERATOR ${GENERATORS})
    if(NOT "${GENERATOR}" MATCHES "^(${VALID_GENERATORS_REGEX})$")
      libra_message(
        FATAL_ERROR
        "Invalid GENERATOR '${GENERATOR}'. Valid options: DEB, RPM, TGZ, ZIP, STGZ, TBZ2, TXZ"
      )
    endif()
  endforeach()

  # Find common package files
  file(GLOB LICENSE "${CMAKE_SOURCE_DIR}/LICENSE*")
  file(GLOB README "${CMAKE_SOURCE_DIR}/README*")
  file(GLOB CHANGELOG "${CMAKE_SOURCE_DIR}/changelog.gz")

  if(NOT LICENSE)
    libra_message(WARNING "No LICENSE file found: tried LICENSE*")
  endif()
  if(NOT README)
    libra_message(WARNING "No README file found: tried README*")
  endif()
  if(NOT CHANGELOG)
    libra_message(WARNING "No changelog file found: tried changelog.gz")
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
      "CPACK_PACKAGE_INSTALL_DIRECTORY not set--using CMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}"
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
            "Could not detect license type. Set CPACK_RPM_PACKAGE_LICENSE manually."
          )
        endif()
      else()
        set(CPACK_RPM_PACKAGE_LICENSE "Unknown")
        libra_message(
          WARNING
          "No LICENSE file found. Set CPACK_RPM_PACKAGE_LICENSE manually.")
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

    # Changelog file (if exists)
    if(CHANGELOG)
      set(CPACK_RPM_CHANGELOG_FILE "${CHANGELOG}")
    endif()

    # Architecture (auto-detected if not specified)
    # set(CPACK_RPM_PACKAGE_ARCHITECTURE "x86_64")

    # URL
    set(CPACK_RPM_PACKAGE_URL "${HOMEPAGE}")

    # Vendor
    set(CPACK_RPM_PACKAGE_VENDOR "${VENDOR}")

    # Description
    set(CPACK_RPM_PACKAGE_DESCRIPTION "${DESCRIPTION}")
    set(CPACK_RPM_PACKAGE_SUMMARY "${SUMMARY}")

    # Debug package (optional - creates separate debug symbols package)
    # set(CPACK_RPM_DEBUGINFO_PACKAGE ON)
  endif()

  include(CPack)

  # Status message
  libra_message(STATUS
                "Configured CPack for ${PROJECT_NAME} ${CPACK_PACKAGE_VERSION}")

endmacro()
