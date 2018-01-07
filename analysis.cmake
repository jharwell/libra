include(${CMAKE_CURRENT_LIST_DIR}/cppcheck.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/clang_tidy.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/clang_format.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/clang_check.cmake)

# Function to register a target for enabled code checkers
function(register_checkers target)
  if (NOT "${root_target}" STREQUAL "${current_proj_name}")
    return()
  endif()

  if(NOT TARGET check-all)
    add_custom_target(check-all)

    set_target_properties(check-all
      PROPERTIES
      EXCLUDE_FROM_DEFAULT_BUILD 1
      )
  endif()

  add_custom_target(check-${target})

  set_target_properties(check-${target}
    PROPERTIES
    EXCLUDE_FROM_DEFAULT_BUILD 1
    )
  register_cppcheck_checker(${target} ${ARGN})
  register_clang_tidy_checker(${target} ${ARGN})
  register_clang_check_checker(${target} ${ARGN})

  add_dependencies(check-all check-${target})
endfunction()

# Function to register a target for enabled automated formatters
function(register_auto_formatters target)
  if (NOT IS_ROOT_PROJECT)
    return()
  endif()


  if (NOT CLANG_FORMAT_ENABLED)
    return()
  endif()

  if(NOT TARGET format-all)
    add_custom_target(format-all)

    set_target_properties(format-all
      PROPERTIES
      EXCLUDE_FROM_DEFAULT_BUILD 1
      )
  endif()

  register_clang_format(${target} ${ARGN})
endfunction()

# Function to register a target for enabled automated fixers
function(register_auto_fixers target)
  if (NOT IS_ROOT_PROJECT)
    return()
  endif()

  if (NOT CLANG_TIDY_FIX_ENABLED)
    return()
  endif()

  register_clang_tidy_fix(${target} ${ARGN})
endfunction()
