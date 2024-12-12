#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#
include(libra/analyze/cppcheck)
include(libra/analyze/clang_tidy)
include(libra/analyze/clang_format)
include(libra/analyze/clang_check)

# Function to register a target for enabled code checkers
function(libra_register_checkers TARGET)
  add_custom_target(check)

  set_target_properties(check PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1)
  libra_register_checker_cppcheck(${TARGET} ${ARGN})
  libra_register_checker_clang_tidy(${TARGET} ${ARGN})
  libra_register_checker_clang_check(${TARGET} ${ARGN})
endfunction()

# Function to register a target for enabled automated formatters
function(libra_register_formatters TARGET)
  add_custom_target(format)

  set_target_properties(format PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1)

  libra_register_formatter_clang_format(${TARGET} ${ARGN})
endfunction()

# Function to register a target for enabled automated fixers
function(libra_register_fixers TARGET)
  add_custom_target(fix)

  set_target_properties(fix PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1)

  libra_register_fixer_clang_tidy(${TARGET} ${ARGN})
endfunction()