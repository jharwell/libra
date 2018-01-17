include(${CMAKE_CURRENT_LIST_DIR}/cppcheck.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/clang_tidy.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/clang_format.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/clang_check.cmake)

# Registers all sources with the cppcheck checker
function(register_cppcheck_checker target)
  if (NOT CPPCHECK_ENABLED)
    return()
  endif()

  if(NOT TARGET cppcheck-all)
    add_custom_target(cppcheck-all)

    set_target_properties(cppcheck-all
      PROPERTIES
      EXCLUDE_FROM_DEFAULT_BUILD 1
      )
  endif()

  if (IS_ROOT_TARGET)
    register_cppcheck(cppcheck-${target} ${target} ${ARGN})
  else()
    register_cppcheck(cppcheck-${target} ${root_target}-${target} ${ARGN})
  endif()
  add_dependencies(cppcheck-all cppcheck-${target})
  add_dependencies(check-${target} cppcheck-all)

endfunction()

# Registers all sources with the clang_tidy checker
function(register_clang_tidy_checker target)
  if (NOT CLANG_TIDY_CHECK_ENABLED)
    return()
  endif()

  if(NOT TARGET tidy-check-all)
    add_custom_target(tidy-check-all)

    set_target_properties(tidy-check-all
      PROPERTIES
      EXCLUDE_FROM_DEFAULT_BUILD 1
      )
  endif()

  if (IS_ROOT_TARGET)
    register_clang_tidy_check(tidy-check-${target} ${target} ${ARGN})
  else()
    register_clang_tidy_check(tidy-check-${target} ${root_target}-${target} ${ARGN})
  endif()

  add_dependencies(tidy-check-all tidy-check-${target})
  add_dependencies(check-${target} tidy-check-all)

endfunction()

# Registers all sources with the clang_check checker
function(register_clang_check_checker target)
  if (NOT CLANG_STATIC_CHECK_ENABLED)
    return()
  endif()

  if(NOT TARGET static-check-all)
    add_custom_target(static-check-all)

    set_target_properties(static-check-all
      PROPERTIES
      EXCLUDE_FROM_DEFAULT_BUILD 1
      )
  endif()

  if (IS_ROOT_TARGET)
    register_clang_static_check(static-check-${target} ${target} ${ARGN})
  else()
    register_clang_static_check(static-check-${target} ${root_target}-${target} ${ARGN})
  endif()

  add_dependencies(static-check-all static-check-${target})
  add_dependencies(check-${target} static-check-all)
endfunction()

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

  add_custom_target(format-${target})
  set_target_properties(format-${target}
    PROPERTIES
    EXCLUDE_FROM_DEFAULT_BUILD 1
    )

  if (IS_ROOT_TARGET)
    register_clang_format(__format-${target} ${target} ${ARGN})
  else()
    register_clang_format(__format-${target} ${target} ${ARGN})
  endif()

  add_dependencies(format-${target} __format-${target})
  add_dependencies(format-all format-${target})
endfunction()

# Function to register a target for enabled automated fixers
function(register_auto_fixers target)
  if (NOT IS_ROOT_PROJECT)
    return()
  endif()

  if (NOT CLANG_TIDY_FIX_ENABLED)
    return()
  endif()

  if(NOT TARGET tidy-fix-all)
    add_custom_target(tidy-fix-all)

    set_target_properties(tidy-fix-all
      PROPERTIES
      EXCLUDE_FROM_DEFAULT_BUILD 1
      )
  endif()

  add_custom_target(tidy-fix-${target})

  set_target_properties(tidy-fix-${target}
    PROPERTIES
    EXCLUDE_FROM_DEFAULT_BUILD 1
    )

  register_clang_tidy_fix(__tidy-fix-${target} ${target} ${ARGN})

  add_dependencies(tidy-fix-${target} __tidy-fix-${target})
  add_dependencies(tidy-fix-all tidy-fix-${target})
endfunction()
