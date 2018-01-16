include(${CMAKE_CURRENT_LIST_DIR}/cppcheck.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/clang_tidy.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/clang_format.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/clang_check.cmake)

# Registers all sources with the cppcheck checker
function(register_cppcheck_checker target)
  if (CPPCHECK_ENABLED)
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
      register_cppcheck(cppcheck-${target} ${current_proj_name}-${target} ${ARGN})
    endif()

    add_dependencies(check-${target} cppcheck-${target})
    add_dependencies(cppcheck-all cppcheck-${target})
  endif()
endfunction()

# Registers all sources with the clang_tidy checker
function(register_clang_tidy_checker target)
if (CLANG_TIDY_CHECK_ENABLED)
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
      register_clang_tidy_check(tidy-check-${target} ${current_proj_name}-${target} ${ARGN})
    endif()
    add_dependencies(check-${target} tidy-check-${target})
    add_dependencies(tidy-check-all tidy-check-${target})
  endif()
endfunction()

# Registers all sources with the clang_check checker
function(register_clang_check_checker target)
  if (CLANG_STATIC_CHECK_ENABLED)
    if(NOT TARGET clang-check-all)
    add_custom_target(clang-check-all)

    set_target_properties(clang-check-all
      PROPERTIES
      EXCLUDE_FROM_DEFAULT_BUILD 1
      )
  endif()
  if (IS_ROOT_TARGET)
      register_clang_static_check(clang-check-${target} ${target} ${ARGN})
    else()
      register_clang_static_check(clang-check-${target} ${current_proj_name}-${target} ${ARGN})
    endif()

    add_dependencies(check-${target} clang-check-${target})
    add_dependencies(clang-check-all clang-check-${target})
  endif()
endfunction()

# Function to register a target for enabled code checkers
function(register_checkers target)
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

  if (CLANG_FORMAT_ENABLED)
    if (IS_ROOT_TARGET)
      register_clang_format(clang-format-${target} ${target} ${ARGN})
    else()
      register_clang_format(clang-format-${target} ${current_proj_name}-${target} ${ARGN})
    endif()
    add_dependencies(format-${target} clang-format-${target})
  endif()

  add_dependencies(format-all format-${target})
endfunction()

# Function to register a target for enabled automated fixers
function(register_auto_fixers target)
  if(NOT TARGET fix-all)
    add_custom_target(fix-all)

    set_target_properties(fix-all
      PROPERTIES
      EXCLUDE_FROM_DEFAULT_BUILD 1
      )
  endif()

  add_custom_target(fix-${target})

  set_target_properties(fix-${target}
    PROPERTIES
    EXCLUDE_FROM_DEFAULT_BUILD 1
    )

  if (CLANG_TIDY_FIX_ENABLED)
    if (IS_ROOT_TARGET)
      register_clang_tidy_fix(clang-tidy-fix-${target} ${target} ${ARGN})
    else()
      register_clang_tidy_fix(clang-tidy-fix-${target} ${current_proj_name}-${target} ${ARGN})
    endif()

    add_dependencies(fix-${target} clang-tidy-fix-${target})
  endif()

  add_dependencies(fix-all fix-${target})
endfunction()
