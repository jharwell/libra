################################################################################
# Cmake Environment                                                            #
################################################################################
set(CLANG_TIDY_CHECK_ENABLED OFF)

# Function to register a target for clang-tidy checking
function(do_register_clang_tidy_check check_target target)
  set(includes "$<TARGET_PROPERTY:${target},INCLUDE_DIRECTORIES>")
  set(defs "$<TARGET_PROPERTY:${target},COMPILE_DEFINITIONS>")

  add_custom_target(${check_target})

  foreach(file ${ARGN})
    add_custom_command(TARGET ${check_target}
      COMMAND
      ${clang_tidy_EXECUTABLE}
      --header-filter=${CMAKE_SOURCE_DIR}/include/*
      -p\t${PROJECT_BINARY_DIR}
      ${file}
      "$<$<NOT:$<BOOL:${CMAKE_EXPORT_COMPILE_COMMANDS}>>:--\t$<$<BOOL:${includes}>:-I$<JOIN:${includes},\t-I>>>"
      "$<$<NOT:$<BOOL:${CMAKE_EXPORT_COMPILE_COMMANDS}>>:--\t$<$<BOOL:${defs}>:-D$<JOIN:${defs},\t-D>>>"
      -extra-arg=-Wno-unknown-warning-option
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
      )
endforeach()
  set_target_properties(${check_target}
    PROPERTIES
    EXCLUDE_FROM_DEFAULT_BUILD 1
    )

  add_dependencies(${check_target} ${target})
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
    do_register_clang_tidy_check(tidy-check-${target} ${target} ${ARGN})
  else()
    do_register_clang_tidy_check(tidy-check-${target} ${root_target}-${target} ${ARGN})
  endif()

  add_dependencies(tidy-check-all tidy-check-${target})
  add_dependencies(check-${target} tidy-check-all)

endfunction()

# Enable or disable clang-tidy checking
function(toggle_clang_tidy_check status)
    if(NOT ${status})
      set(CLANG_TIDY_CHECK_ENABLED ${status} PARENT_SCOPE)
      if (IS_ROOT_PROJECT)
        message(STATUS "  Checker clang-tidy skipped: [disabled]")
      endif()
        return()
    endif()

    find_package(clang_tidy)

    if(NOT clang_tidy_FOUND)
      set(CLANG_TIDY_CHECK_ENABLED OFF PARENT_SCOPE)
      if (IS_ROOT_PROJECT)
        message(WARNING "  Checker clang-tidy skipped: [clang-tidy not found]")
        endif()
        return()
    endif()

    set(CLANG_TIDY_CHECK_ENABLED ${status} PARENT_SCOPE)
    if (IS_ROOT_PROJECT)
      message(STATUS "  Checker clang-tidy [enabled=${clang_tidy_EXECUTABLE}]")
      endif()

    set(CMAKE_EXPORT_COMPILE_COMMANDS On PARENT_SCOPE)
endfunction()

################################################################################
# Clang Tidy Fixer                                                             #
################################################################################
set(CLANG_TIDY_FIX_ENABLED OFF)

# Function to register a target for clang-tidy fixing
function(do_register_clang_tidy_fix check_target target)
  set(includes "$<TARGET_PROPERTY:${target},INCLUDE_DIRECTORIES>")
  set(defs "$<TARGET_PROPERTY:${target},COMPILE_DEFINITIONS>")

  add_custom_target(${check_target})

  foreach(file ${ARGN})
    add_custom_command(TARGET ${check_target}
      COMMAND
      ${clang_tidy_EXECUTABLE}
      --header-filter=${CMAKE_SOURCE_DIR}/include/*
      -p\t${PROJECT_BINARY_DIR}
      -fix
      -fix-errors
      ${file}
      "$<$<NOT:$<BOOL:${CMAKE_EXPORT_COMPILE_COMMANDS}>>:--\t$<$<BOOL:${includes}>:-I$<JOIN:${includes},\t-I>>>"
      "$<$<NOT:$<BOOL:${CMAKE_EXPORT_COMPILE_COMMANDS}>>:--\t$<$<BOOL:${defs}>:-D$<JOIN:${defs},\t-D>>>"
      -extra-arg=-Wno-unknown-warning-option
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
      )
  endforeach()
  set_target_properties(${check_target}
    PROPERTIES
    EXCLUDE_FROM_DEFAULT_BUILD 1
    )
    add_dependencies(${check_target} ${target})
endfunction()

function(register_clang_tidy_fix target)
  if (NOT CLANG_TIDY_FIX_ENABLED)
    return()
  endif()

  if (NOT TARGET tidy-fix-all)
    add_custom_target(tidy-fix-all)

    set_target_properties(tidy-fix-all
      PROPERTIES
      EXCLUDE_FROM_DEFAULT_BUILD 1
      )
  endif()

  if (IS_ROOT_TARGET)
    do_register_clang_tidy_fix(__tidy-fix-${target} ${target} ${ARGN})
  else()
    do_register_clang_tidy_fix(__tidy-fix-${target} ${root_target}-${target} ${ARGN})
  endif()

  add_dependencies(tidy-fix-all __tidy-fix-${target})
endfunction()

# Enable or disable clang-tidy fixing
function(toggle_clang_tidy_fix status)
    if(NOT ${status})
      set(CLANG_TIDY_FIX_ENABLED ${status} PARENT_SCOPE)
      if (IS_ROOT_PROJECT)
        message(STATUS "  Auto-fixer clang-tidy skipped: [disabled]")
        return()
        endif()
    endif()

    find_package(clang_tidy)

    if(NOT clang_tidy_FOUND)
      set(CLANG_TIDY_FIX_ENABLED OFF PARENT_SCOPE)
      if (IS_ROOT_PROJECT)
        message(WARNING "  Auto-fixer clang-tidy skipped: [clang-tidy not found (>= 8.0 required)]")
      endif()
        return()
    endif()

    set(CLANG_TIDY_FIX_ENABLED ${status} PARENT_SCOPE)
    if (IS_ROOT_PROJECT)
    message(STATUS "  Auto-fixer clang-tidy [enabled=${clang_tidy_EXECUTABLE}]")
  endif()
    set(CMAKE_EXPORT_COMPILE_COMMANDS On PARENT_SCOPE)
endfunction()
