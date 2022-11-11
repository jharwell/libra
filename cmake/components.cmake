#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  LGPL-2.0-or-later
#
include(custom-cmds)

################################################################################
# Register a COMPONENT as part of a project for use with find_package()
#
# Adds sources matching the regex to the output variable (presumably a list of
# sources to include for a particular project/library).
#
################################################################################
function(component_register_as_src
    enabled_component_SRC
    TARGET
    TARGET_SRC
    component_name
    REGEX)
  list_extract(enabled_component_SRC "${REGEX}" "${TARGET_SRC}")
  set(${TARGET}_${component_name}_FOUND 1 PARENT_SCOPE)
  set(${enabled_component_SRC} ${${enabled_component_SRC}} PARENT_SCOPE)
endfunction()

################################################################################
# Register a COMPONENT as part of a project for use with find_package()
#
# Adds sources matching the regex into a library representing the component.
################################################################################
function(component_register_as_lib
    TARGET
    TARGET_SRC
    component_name
    REGEX)
  list_extract(component_SRC "${REGEX}" "${TARGET_SRC}")
  add_library(
    ${TARGET}_${component_name}
    SHARED
    EXCLUDE_FROM_ALL
    ${component_SRC}
    )

  TARGET_include_directories(
    ${TARGET}_${component_name}
    PUBLIC
    $<BUILD_INTERFACE:${${TARGET}_DIR}/include>
    $<INSTALL_INTERFACE:include>  # <prefix>/<TARGET>
    )
  dual_scope_set(${TARGET}_${component_name}_FOUND 1) #
endfunction()

################################################################################
# Check all requested components from the TARGET
################################################################################
function(requested_components_check
    TARGET)
  message(CHECK_START "Finding ${TARGET} components")
  unset(${TARGET}_MISSING_COMPONENTS)
  foreach(component ${${TARGET}_FIND_COMPONENTS})
    if(NOT "${${TARGET}_${component}_FOUND}")
      list(APPEND ${TARGET}_MISSING_COMPONENTS ${component})
    endif()
  endforeach()
  if (${TARGET}_MISSING_COMPONENTS)
    message(CHECK_FAIL "Missing: ${${TARGET}_MISSING_COMPONENTS}")
  else()
    message(CHECK_PASS "All components found: ${${TARGET}_FIND_COMPONENTS}")
  endif()
endfunction()
