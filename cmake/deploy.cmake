#
# Copyright 2023 John Harwell, All rights reserved.
#
# SPDX-License-Identifier:  MIT

################################################################################
# CPack Options
################################################################################
function (libra_configure_cpack
    GENERATORS  # One or more CPack generators, separated by ';'
    DESCRIPTION # Description of the package (DEB only)
    VENDOR      # Package vendor (DEB only)
    HOMEPAGE    # Project home page (DEB only)
    CONTACT     # Project contact (DEB only)
    )

  file(GLOB LICENSE "${CMAKE_SOURCE_DIR}/LICENSE*")
  file(GLOB README "${CMAKE_SOURCE_DIR}/README*")

  if(NOT LICENSE)
    message(WARNING "No LICENSE file found: tried LICENSE*")
  endif()
  if(NOT README)
    message(WARNING "No README file found: tried README*")
  endif()

  if(NOT CPACK_PACKAGE_INSTALL_DIRECTORY)
    set(CPACK_PACKAGE_INSTALL_DIRECTORY "/usr/local")
  endif()

  set(CPACK_RESOURCE_FILE_LICENSE "${LICENSE}")
  set(CPACK_RESOURCE_FILE_README "${README}")
  set(CPACK_PACKAGE_VENDOR "${VENDOR}")
  set(CPACK_PACKAGE_HOMEPAGE_URL "${HOMEPAGE}")
  set(CPACK_PACKAGE_DESCRIPTION "${DESCRIPTION}")
  set(CPACK_PACKAGE_CONTACT "${CONTACT}")

  set(CPACK_GENERATOR "${GENERATORS}")

  set(CPACK_PACKAGE_VERSION_MAJOR ${PROJECT_VERSION_MAJOR})
  set(CPACK_PACKAGE_VERSION_MINOR ${PROJECT_VERSION_MINOR})
  set(CPACK_PACKAGE_VERSION_PATCH ${PROJECT_VERSION_PATCH})
  set(CPACK_PACKAGE_VERSION "${CPACK_PACKAGE_VERSION_MAJOR}.${CPACK_PACKAGE_VERSION_MINOR}.${CPACK_PACKAGE_VERSION_PATCH}")

  # Because the built things are architecture dependent, and that
  # should be reflected in the file name (unless overridden by the user).
  if(NOT CPACK_PACKAGE_FILE_NAME)
    set(CPACK_PACKAGE_FILE_NAME
      ${PROJECT_NAME}-${CPACK_PACKAGE_VERSION}-${CMAKE_SYSTEM_PROCESSOR})

    # Add architecture to generated .deb name.
    set(CPACK_DEBIAN_FILE_NAME DEB-DEFAULT)
  endif()


  if("${GENERATORS}" MATCHES "DEB")
    # Compute the .deb packages that this target needs
    set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS ON)


    # More helpful logging
    set(CPACK_DEBIAN_PACKAGE_DEBUG ON)
  elseif ("${GENERATORS}" MATCHES "TGZ")
    # Nothing to do for now
  else()
    message(FATAL_ERROR "Bad GENERATOR ${GENERATORS}. Must be [DEB, TGZ]")
  endif()

  include(CPack)

  message(STATUS "Configured CPack for ${PROJECT_NAME} ${CPACK_PACKAGE_VERSION}, CPACK_GENERATOR=${GENERATORS}")
endfunction()
