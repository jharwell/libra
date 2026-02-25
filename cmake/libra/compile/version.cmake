#
# Copyright 2026 John Harwell, All rights reserved.
#
# SPDX-License-Identifier: MIT
#
# Copyright 2026 John Harwell, All rights reserved.
#
# SPDX-License-Identifier: MIT
#

#[[.rst:
.. cmake:command:: libra_require_compiler

   Enforce a minimum major version for a given compiler and language.  Can be
   called multiple times to enforce requirements for different compilers or
   languages independently.

   **Signature:**

   .. code-block:: cmake

      libra_require_compiler(
          [LANG  <C|CXX> ...]   # Languages to check. Defaults to both C and CXX.
          ID      <compiler-id> # Compiler ID: GNU, Clang, AppleClang, IntelLLVM
          VERSION <major>       # Minimum required major version (integer)
      )

   :param LANG: Accepts one or more languages. If omitted, both ``C`` and
    ``CXX`` are checked. Languages not enabled in the project are silently
    skipped.

   :param ID: The ID of the compiler to check.  If the active compiler ID does
    not match ``ID``, the check is silently skipped. This allows calling
    ``libra_require_compiler`` once per supported compiler without needing
    ``if()`` guards around each call. Basically, if and only if the active
    compiler ID matches the argument is the version checked.

   :param VERSION: Compiler major version to check against. If the active
    compiler ID matches and its major version is less than this, a fatal error
    is issued immediately.

   **Examples:**

   .. code-block:: cmake

      # Require GCC >= 13 for both C and C++
      libra_require_compiler(ID GNU VERSION 13)

      # Require Clang >= 17 for C++ only
      libra_require_compiler(LANG CXX ID Clang VERSION 17)

      # Require GCC >= 13 for C, IntelLLVM >= 2024 for C++
      libra_require_compiler(LANG C   ID GNU       VERSION 13)
      libra_require_compiler(LANG CXX ID IntelLLVM VERSION 2024)

   **Fatal error format:**

   .. code-block:: none

      [LIBRA] C compiler version requirement not met:
        Required: GNU >= 13
        Found:    GNU 12.3.1

]]
include(libra/messaging)

function(libra_require_compiler)
  cmake_parse_arguments(
    ARG
    "" # options
    "ID;VERSION" # one-value
    "LANG" # multi-value
    ${ARGN})

  if(NOT ARG_ID)
    libra_error("libra_require_compiler: ID is required (e.g. GNU, Clang)")
  endif()

  if(NOT ARG_VERSION)
    libra_error(
      "libra_require_compiler: VERSION is required (major version number)")
  endif()

  # Default to both languages if LANG not specified
  if(NOT ARG_LANG)
    set(ARG_LANG C CXX)
  endif()

  get_property(_enabled_languages GLOBAL PROPERTY ENABLED_LANGUAGES)

  foreach(lang ${ARG_LANG})
    # Skip languages not enabled in this project
    if(NOT lang IN_LIST _enabled_languages)
      continue()
    endif()

    set(_compiler_id "${CMAKE_${lang}_COMPILER_ID}")
    set(_compiler_ver "${CMAKE_${lang}_COMPILER_VERSION}")

    # Not the requested compiler ID -- skip (not an error, project may support
    # multiple compilers and call libra_require_compiler once per supported ID)
    if(NOT _compiler_id MATCHES "${ARG_ID}")
      continue()
    endif()

    # Extract major version
    string(REGEX MATCH "^([0-9]+)" _major "${_compiler_ver}")

    if(NOT _major)
      libra_error(
        "libra_require_compiler: could not determine major version for \
${lang} compiler ${_compiler_id} (full version: '${_compiler_ver}')")
    endif()

    if(_major LESS ARG_VERSION)
      string(CONCAT _msg "${lang} compiler version requirement not met:\n"
                    "  Required: ${ARG_ID} >= ${ARG_VERSION}\n"
                    "  Found:    ${_compiler_id} ${_compiler_ver}")
      libra_error("${_msg}")
    endif()

    libra_message(STATUS "${lang} compiler version requirement satisfied: \
${_compiler_id} ${_compiler_ver} >= ${ARG_VERSION}")
  endforeach()
endfunction()
