set(CLANG_TIDY_CHECK_ENABLED OFF)
set(CLANG_TIDY_FIX_ENABLED OFF)

# Function to register a target for clang-tidy checking
function(register_clang_tidy_check check_target target)
  set(includes "$<TARGET_PROPERTY:${target},INCLUDE_DIRECTORIES>")

  add_custom_target(${check_target})

  foreach(file ${ARGN})
    add_custom_command(TARGET ${check_target}
      COMMAND
      ${clang_tidy_EXECUTABLE}
      --header-filter=${CMAKE_SOURCE_DIR}/include/*
      -p\t${PROJECT_BINARY_DIR}
      ${file}
      "$<$<NOT:$<BOOL:${CMAKE_EXPORT_COMPILE_COMMANDS}>>:--\t$<$<BOOL:${includes}>:-I$<JOIN:${includes},\t-I>>>"
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
      )
endforeach()
  set_target_properties(${check_target}
    PROPERTIES
    EXCLUDE_FROM_DEFAULT_BUILD 1
    )

  add_dependencies(${check_target} ${target})
endfunction()

# Function to register a target for clang-tidy fixing
function(register_clang_tidy_fix check_target target)
  set(includes "$<TARGET_PROPERTY:${target},INCLUDE_DIRECTORIES>")

  add_custom_target(
    ${check_target}
    COMMAND
    ${clang_tidy_EXECUTABLE}
    -p\t${PROJECT_BINARY_DIR}
    ${ARGN}
    -fix
    -fix-errors
    -checks=cert*,clang-analyzer*,cppcoreguidelnes*,google*,llvm*,modernize*,readability*,-readability-else-after-return,modernize*
    "$<$<NOT:$<BOOL:${CMAKE_EXPORT_COMPILE_COMMANDS}>>:--\t$<$<BOOL:${includes}>:-I$<JOIN:${includes},\t-I>>>"
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    )

  set_target_properties(${check_target}
    PROPERTIES
    EXCLUDE_FROM_DEFAULT_BUILD 1
    )

  add_dependencies(${check_target} ${target})
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
      message(STATUS "  Checker clang-tidy [enabled]")
      endif()

    set(CMAKE_EXPORT_COMPILE_COMMANDS On PARENT_SCOPE)
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
        message(WARNING "  Auto-fixer clang-tidy skipped: [clang-tidy not found]")
      endif()
        return()
    endif()

    set(CLANG_TIDY_FIX_ENABLED ${status} PARENT_SCOPE)
    if (IS_ROOT_PROJECT)
    message(STATUS "  Auto-fixer clang-tidy [enabled]")
  endif()
    set(CMAKE_EXPORT_COMPILE_COMMANDS On PARENT_SCOPE)
endfunction()
