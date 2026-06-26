# ##############################################################################
# Packaging bootstrap
#
# We do NOT need to configure/install LIBRA, since CPM makes it available via
# libra_SOURCE_DIR.
# ##############################################################################
if(NOT EXISTS ${CMAKE_CURRENT_BINARY_DIR}/cmake/CPM.cmake)
  file(
    DOWNLOAD
    https://github.com/cpm-cmake/CPM.cmake/releases/download/v0.40.2/CPM.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/cmake/CPM.cmake)
endif()
set(CPM_SOURCE_CACHE
    $ENV{HOME}/.cache/CPM
    CACHE PATH "CPM source cache")
# We want CPM to prefer local packages if they exist. This allows seamless
# mixing of local and remote repos when doing local development.
set(CPM_USE_LOCAL_PACKAGES YES)
include(${CMAKE_CURRENT_BINARY_DIR}/cmake/CPM.cmake)

# TODO: update VERSION and GIT_TAG when upgrading libra.
cpmaddpackage(
  NAME
  libra
  GIT_REPOSITORY
  https://github.com/jharwell/libra.git
  VERSION
  0.12.8
  GIT_TAG
  v0.12.8)

if(libra_ADDED)
  list(APPEND CMAKE_MODULE_PATH ${libra_SOURCE_DIR}/cmake)
endif()

include(libra/version)
# Optional/only needed if you want to use LIBRA's  versioning capabilities
libra_extract_version()

project(
  {{PROJECT_NAME}}
  LANGUAGES CXX C
  VERSION ${LIBRA_PROJECT_VERSION_NUMERIC})
message(
  STATUS
    "Configuring {{PROJECT_NAME}} v${PROJECT_VERSION} (${LIBRA_PROJECT_VERSION})"
)

# The magic
include(libra/project)
