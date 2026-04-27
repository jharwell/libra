#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#
# ##############################################################################
# Custom messaging
# ##############################################################################
include(libra/messaging)

include(libra/utils)

#[[.rst:
.. cmake:command:: libra_add_component_library

  Define a component of TARGET by building a separate library from matching
  sources, for use with ``find_package()`` COMPONENTS.

  Creates a library target named ``<TARGET>_<COMPONENT>`` (included in the
  default build) and sets ``<TARGET>_<COMPONENT>_FOUND=1`` in both the current
  and parent scope.

  :param TARGET: The main target this component belongs to.

  :param COMPONENT: Component name. Used to name the created library target
   (``<TARGET>_<COMPONENT>``), set ``<TARGET>_<COMPONENT>_FOUND``, and
   identify the component in :cmake:command:`libra_check_components`.

  :param SOURCES: Full list of candidate source files to filter.

  :param REGEX: Regular expression selecting sources for this component.

  **Example:**

  .. code-block:: cmake

    libra_add_component_library(
      TARGET    mylib
      COMPONENT networking
      SOURCES   ${ALL_SOURCES}
      REGEX     "src/net/.*\\.cpp")
]]
function(libra_add_component_library)
  cmake_parse_arguments(
    ARG
    ""
    "TARGET;COMPONENT;REGEX;TYPE"
    "SOURCES"
    ${ARGN})

  if(NOT ARG_TARGET)
    libra_error("libra_add_component_library: TARGET is required")
  endif()
  if(NOT ARG_COMPONENT)
    libra_error("libra_add_component_library: COMPONENT is required")
  endif()
  if(NOT ARG_SOURCES)
    libra_error("libra_add_component_library: SOURCES is required")
  endif()
  if(NOT ARG_REGEX)
    libra_error("libra_add_component_library: REGEX is required")
  endif()

  _libra_list_extract(_component_src "${ARG_REGEX}" "${ARG_SOURCES}")

  if(NOT _component_src)
    libra_message(
      WARNING
      "libra_add_component_library: No sources matched REGEX '${ARG_REGEX}' for component '${ARG_COMPONENT}'"
    )
  endif()

  set(_lib_name ${ARG_TARGET}_${ARG_COMPONENT})

  libra_add_library(${_lib_name} SHARED ${_component_src})
  dual_scope_set(${ARG_TARGET}_${ARG_COMPONENT}_FOUND 1)

  libra_message(
    STATUS
    "Defined component '${ARG_COMPONENT}' for ${ARG_TARGET} (SHARED library target: ${_lib_name})"
  )
endfunction()

#[[.rst:
.. cmake:command:: libra_check_components

  Verify that all components requested via ``find_package()`` COMPONENTS have
  been found for TARGET.

  Reads ``<TARGET>_FIND_COMPONENTS`` and ``<TARGET>_FIND_REQUIRED_<component>``
  as set by CMake's ``find_package()`` machinery. Reports missing optional
  components as a configure-time check failure; raises a fatal error for any
  missing required component.

  :param TARGET: The target whose requested components should be verified.

  **Example:**

  .. code-block:: cmake

    # At the end of mylib-config.cmake:
    libra_check_components(mylib)
]]
function(libra_check_components)
  cmake_parse_arguments(
    ARG
    ""
    "TARGET"
    ""
    ${ARGN})

  if(NOT ARG_TARGET AND ARG_UNPARSED_ARGUMENTS)
    list(GET ARG_UNPARSED_ARGUMENTS 0 ARG_TARGET)
  endif()

  if(NOT ARG_TARGET)
    libra_error("libra_check_components: TARGET is required")
  endif()

  message(CHECK_START "Finding ${ARG_TARGET} components")

  set(_missing "")
  set(_missing_required "")

  foreach(_component ${${ARG_TARGET}_FIND_COMPONENTS})
    if(NOT ${ARG_TARGET}_${_component}_FOUND)
      list(APPEND _missing ${_component})
      if(${ARG_TARGET}_FIND_REQUIRED_${_component})
        list(APPEND _missing_required ${_component})
      endif()
    endif()
  endforeach()

  if(_missing)
    message(CHECK_FAIL "Missing: ${_missing}")
    if(_missing_required)
      libra_error(
        "libra_check_components: Required components not found for ${ARG_TARGET}: ${_missing_required}"
      )
    endif()
  else()
    message(CHECK_PASS "All components found: ${${ARG_TARGET}_FIND_COMPONENTS}")
  endif()
endfunction()

# ##############################################################################
# Deprecated function wrappers
#
# These are the old function names, kept for backwards compatibility. They will
# be removed in a future version of libra. Use the new names instead.
# ##############################################################################

macro(libra_component_register_as_lib)
  libra_message(
    DEPRECATION
    "libra_component_register_as_lib() is deprecated. Use libra_add_component_library() instead."
  )
  libra_add_component_library(${ARGN})
endmacro()

macro(libra_requested_components_check)
  libra_message(
    DEPRECATION
    "libra_requested_components_check() is deprecated. Use libra_check_components() instead."
  )
  libra_check_components(${ARGN})
endmacro()
