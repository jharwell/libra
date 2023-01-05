#
# Copyright 2022 SIFT LLC, All rights reserved.
#
# RESTRICTED RIGHTS
#
# Contract No. 9700-1100-001-009
#
# Smart Information Flow Technologies
#
# 319 1st Ave N, Suite 400
# Minneapolis, MN 55401-1689
#
# The Government's rights to use, modify, reproduce, release, perform, display,
# or disclose this software are restricted by paragraph (b)(3) of the Rights in
# Noncommercial Computer Software and Noncommercial Computer Software
# Documentation clause contained in the above identified contract. Any
# reproduction of computer software or portions thereof marked with this legend
# must also reproduce the markings. Any person, other than the Government, who
# has been provided access to such software must promptly notify the above
# named Contractor.
#

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
