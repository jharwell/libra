#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#
# ##############################################################################
# Testing Options
# ##############################################################################
include(libra/messaging)
include(libra/defaults)
include(libra/test/negative)
include(libra/utils)

_libra_register_custom_target(unit-tests LIBRA_TESTS NONE)
_libra_register_custom_target(integration-tests LIBRA_TESTS NONE)
_libra_register_custom_target(regression-tests LIBRA_TESTS NONE)
_libra_register_custom_target(all-tests LIBRA_TESTS NONE)

# ##############################################################################
# Test sources
# ##############################################################################
set(${PROJECT_NAME}_TEST_PATH ${CMAKE_CURRENT_SOURCE_DIR}/tests)

# Matcher variables: set in project-local.cmake to encode the project's
# file-naming convention.  Non-cache: they are a structural property of the
# project, not a per-build knob.  All guards use if(NOT DEFINED ...) so that any
# project-local value, including an unusual one, is always respected.
if(NOT DEFINED LIBRA_UNIT_TEST_MATCHER)
  set(LIBRA_UNIT_TEST_MATCHER ${LIBRA_UNIT_TEST_MATCHER_DEFAULT})
endif()

if(NOT DEFINED LIBRA_INTEGRATION_TEST_MATCHER)
  set(LIBRA_INTEGRATION_TEST_MATCHER ${LIBRA_INTEGRATION_TEST_MATCHER_DEFAULT})
endif()

if(NOT DEFINED LIBRA_REGRESSION_TEST_MATCHER)
  set(LIBRA_REGRESSION_TEST_MATCHER ${LIBRA_REGRESSION_TEST_MATCHER_DEFAULT})
endif()

if(NOT DEFINED LIBRA_TEST_HARNESS_MATCHER)
  set(LIBRA_TEST_HARNESS_MATCHER ${LIBRA_TEST_HARNESS_MATCHER_DEFAULT})
endif()

# ##############################################################################
# Extension classification
# ##############################################################################

# Extensions compiled into test executables via add_executable/linking.
set(_LIBRA_COMPILED_EXTENSIONS c cpp)

# Extensions run via an interpreter.
set(_LIBRA_INTERPRETED_EXTENSIONS bats py sh)

# Map interpreted extensions to their interpreter executable.
set(_LIBRA_INTERPRETER_bats "bats")
set(_LIBRA_INTERPRETER_py "python3")
set(_LIBRA_INTERPRETER_sh "bash")

# ##############################################################################
# Glob for all test sources
#
# Four categories, each with three types (unit / integration / regression):
#
# LIBRA_<ext>_utests / itests / rtests   compiled and interpreted tests
# LIBRA_neg_utests / neg_itests / neg_rtests  negative compile tests
#
# Negative tests are globbed separately (*.neg.cpp, *.neg.c) to populate their
# own lists. They are naturally excluded from the compiled extension lists
# because *-utest.cpp does not match *-utest.neg.cpp.
# ##############################################################################

# --- Compiled and interpreted extensions -------------------------------------
foreach(ext ${_LIBRA_COMPILED_EXTENSIONS} ${_LIBRA_INTERPRETED_EXTENSIONS})
  string(REPLACE "." "_" ext_var ${ext})
  file(GLOB_RECURSE LIBRA_${ext_var}_utests
       ${${PROJECT_NAME}_TEST_PATH}/*${LIBRA_UNIT_TEST_MATCHER}.${ext})
  file(GLOB_RECURSE LIBRA_${ext_var}_itests
       ${${PROJECT_NAME}_TEST_PATH}/*${LIBRA_INTEGRATION_TEST_MATCHER}.${ext})
  file(GLOB_RECURSE LIBRA_${ext_var}_rtests
       ${${PROJECT_NAME}_TEST_PATH}/*${LIBRA_REGRESSION_TEST_MATCHER}.${ext})
endforeach()

# --- Negative compile tests --------------------------------------------------

set(LIBRA_neg_utests "")
set(LIBRA_neg_itests "")
set(LIBRA_neg_rtests "")

foreach(neg_ext ${_LIBRA_NEGATIVE_EXTENSIONS})
  file(GLOB_RECURSE _neg_candidates ${${PROJECT_NAME}_TEST_PATH}/*.${neg_ext})

  foreach(f ${_neg_candidates})
    get_filename_component(_fname ${f} NAME)
    if(_fname MATCHES "${LIBRA_UNIT_TEST_MATCHER}\\.${neg_ext}$")
      list(APPEND LIBRA_neg_utests ${f})
    elseif(_fname MATCHES "${LIBRA_INTEGRATION_TEST_MATCHER}\\.${neg_ext}$")
      list(APPEND LIBRA_neg_itests ${f})
    elseif(_fname MATCHES "${LIBRA_REGRESSION_TEST_MATCHER}\\.${neg_ext}$")
      list(APPEND LIBRA_neg_rtests ${f})
    endif()
  endforeach()
endforeach()

# --- Test harness sources -----------------------------------------------------
file(GLOB_RECURSE LIBRA_c_test_harness
     ${${PROJECT_NAME}_TEST_PATH}/*${LIBRA_TEST_HARNESS_MATCHER}.c
     ${${PROJECT_NAME}_TEST_PATH}/*${LIBRA_TEST_HARNESS_MATCHER}.h)

file(GLOB_RECURSE LIBRA_cxx_test_harness
     ${${PROJECT_NAME}_TEST_PATH}/*${LIBRA_TEST_HARNESS_MATCHER}.cpp
     ${${PROJECT_NAME}_TEST_PATH}/*${LIBRA_TEST_HARNESS_MATCHER}.hpp)

set(LIBRA_test_harness)

if(LIBRA_cxx_test_harness)
  set(LIBRA_HAVE_cxx_test_harness YES)
  set(LIBRA_test_harness "${LIBRA_test_harness};${PROJECT_NAME}-cxx-harness")
endif()

if(LIBRA_c_test_harness)
  set(LIBRA_HAVE_c_test_harness YES)
  set(LIBRA_test_harness "${LIBRA_test_harness};${PROJECT_NAME}-c-harness")
endif()

# ##############################################################################
# Enable a single compiled test (C/C++)
# ##############################################################################
function(enable_single_compiled_test t UMBRELLA_TARGET INCLUDE_IN_CTEST)
  # Tests are named the same thing as their source file, sans extension, in the
  # spirit of the Principle of Least Surprise.
  get_filename_component(test_name ${t} NAME_WE)
  get_filename_component(test_file ${t} NAME)

  # Define the test executable
  add_executable(${PROJECT_NAME}-${test_name} EXCLUDE_FROM_ALL ${t})
  _libra_configure_standard(${PROJECT_NAME}-${test_name})
  set_target_properties(${PROJECT_NAME}-${test_name} PROPERTIES LINKER_LANGUAGE
                                                                CXX)

  # Tests depend on the test harness
  add_dependencies(${PROJECT_NAME}-${test_name} ${PROJECT_NAME}
                   ${LIBRA_test_harness})

  # Tests depend on the project library (DUH)
  target_link_libraries(${PROJECT_NAME}-${test_name} ${PROJECT_NAME}
                        ${LIBRA_test_harness} ${LIBRA_TEST_HARNESS_LIBS})

  # If the project is a C project, then we will probably be casting in the C
  # way, so turn off the usual compile warnings about this.
  #
  # This will only work with GCC/clang compilers, but that's OK for now, as I'm
  # not doing anything that requires running unit tests on strange platforms
  # requiring more exotic compilers.
  get_property(LANGUAGES_LIST GLOBAL PROPERTY ENABLED_LANGUAGES)
  if("C" IN_LIST LANGUAGES_LIST)
    target_compile_options(${PROJECT_NAME}-${test_name}
                           PUBLIC -Wno-old-style-cast -Wno-useless-cast)
  endif()

  # Add the test executable to CTest
  if(INCLUDE_IN_CTEST)
    add_test(${test_name}
             ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${PROJECT_NAME}-${test_name})
    # Set target properties:
    #
    # * Propagate BLESS through to the interpreter if set on the ctest
    #   invocation
    #
    # * Add the {unit,regression,integration} label for more convenient ctest
    #   usage.
    #
    # Derive label from umbrella target name: "unit-tests" -> "unit"
    string(REPLACE "-tests" "" test_label ${UMBRELLA_TARGET})
    set_tests_properties(
      ${test_name}
      PROPERTIES LABELS
                 ${test_label}
                 ENVIRONMENT
                 "BLESS=${BLESS}"
                 WORKING_DIRECTORY
                 ${CMAKE_SOURCE_DIR})

  endif()

  # Add to global umbrella target
  add_dependencies(${UMBRELLA_TARGET} ${PROJECT_NAME}-${test_name})

  # Add to global "build-and-test" target to build library+test harness+unit
  # tests and then run the unit tests
  add_dependencies(build-and-test ${PROJECT_NAME}-${test_name})
endfunction()

# ##############################################################################
# Enable a single interpreted test (BATS, Python, shell, etc.)
# ##############################################################################
function(enable_single_interpreted_test t UMBRELLA_TARGET INCLUDE_IN_CTEST)
  get_filename_component(test_name ${t} NAME_WE)
  get_filename_component(test_ext ${t} EXT)

  # Strip the leading dot from the extension to get the key
  string(SUBSTRING ${test_ext} 1 -1 ext_key)

  # Look up the interpreter for this extension
  if(NOT DEFINED _LIBRA_INTERPRETER_${ext_key})
    libra_message(
      WARNING
      "No interpreter registered for extension '${ext_key}' (file: ${t}) -- skipping"
    )
    return()
  endif()

  find_program(_LIBRA_INTERP_${ext_key}_EXE ${_LIBRA_INTERPRETER_${ext_key}})
  if(NOT _LIBRA_INTERP_${ext_key}_EXE)
    string(CONCAT _msg "Interpreter '${_LIBRA_INTERPRETER_${ext_key}}' for "
                  "extension '${ext_key}' not found -- skipping ${test_name}")
    libra_message(WARNING "${_msg}")
    return()
  endif()

  # Interpreted tests have nothing to compile, so register with ctest directly.
  if(INCLUDE_IN_CTEST)
    add_test(
      NAME ${test_name}
      COMMAND ${_LIBRA_INTERP_${ext_key}_EXE} ${t}
      WORKING_DIRECTORY ${${PROJECT_NAME}_TEST_PATH})

    # Set target properties:
    #
    # * Propagate BLESS through to the interpreter if set on the ctest
    #   invocation
    #
    # * Add the {unit,regression,integration} label for more convenient ctest
    #   usage.
    #
    # Derive label from umbrella target name: "unit-tests" -> "unit"
    string(REPLACE "-tests" "" test_label ${UMBRELLA_TARGET})
    set_tests_properties(
      ${test_name}
      PROPERTIES LABELS
                 ${test_label}
                 ENVIRONMENT
                 "BLESS=${BLESS}"
                 WORKING_DIRECTORY
                 ${CMAKE_SOURCE_DIR})

  endif()

  # No-op target — named handle for build-and-test only
  add_custom_target(${PROJECT_NAME}-${test_name})

  # NOT added to umbrella (unit-tests/integration-tests/regression-tests) since
  # there's nothing to build -- only build-and-test runs them via ctest
  add_dependencies(build-and-test ${PROJECT_NAME}-${test_name})
endfunction()

# ##############################################################################
# Enable a single negative compilation test (.neg.c / .neg.cpp)
#
# The source file is expected to FAIL compilation. The custom target invokes the
# compiler directly and inverts the exit code so that:
#
# * compiler rejects the file  → target succeeds → ctest passes
# * compiler accepts the file → target fails → ctest fails
#
# If a companion <name>.expected file exists alongside the source, its contents
# are treated as a string that must appear somewhere in the compiler's stderr
# output. This lets tests assert not just that compilation failed, but that it
# failed with the right message.
# ##############################################################################
function(enable_single_negative_compile_test t UMBRELLA_TARGET INCLUDE_IN_CTEST)
  get_filename_component(test_name ${t} NAME_WE)
  get_filename_component(test_dir ${t} DIRECTORY)
  get_filename_component(test_file ${t} NAME)

  # ------------------------------------------------------------------
  # Select compiler and language standard based on file extension.
  # ------------------------------------------------------------------
  if(test_file MATCHES "\\.neg\\.cpp$")
    set(_compiler ${CMAKE_CXX_COMPILER})
    set(_std_flag "-std=c++${LIBRA_CXX_STANDARD}")
  else()
    set(_compiler ${CMAKE_C_COMPILER})
    set(_std_flag "-std=c${LIBRA_C_STANDARD}")
  endif()

  # ------------------------------------------------------------------
  # Collect compiler flags from target properties at configure time.
  #
  # Generator expressions cannot be used in file(WRITE) content, so they are
  # handled explicitly per property type:
  #
  # INCLUDE_DIRECTORIES: $<BUILD_INTERFACE:path> -> unwrap to plain path
  # $<INSTALL_INTERFACE:..> -> drop (not meaningful at build time) any other
  # $<...>        -> drop
  #
  # COMPILE_DEFINITIONS / COMPILE_OPTIONS: any $<...>              -> drop
  # (warning flags; safe to omit for static_assert / concept tests)
  #
  # The source file is NOT added here — passed directly on the command line
  # (some compilers reject source paths inside @response files).
  # ------------------------------------------------------------------
  set(_compile_args)

  get_target_property(_incdirs ${PROJECT_NAME} INCLUDE_DIRECTORIES)
  if(_incdirs)
    foreach(d ${_incdirs})
      if(d MATCHES "^\\$<BUILD_INTERFACE:(.+)>$")
        string(REGEX REPLACE "^\\$<BUILD_INTERFACE:(.+)>$" "\\1" d "${d}")
        list(APPEND _compile_args "-I${d}")
      elseif(NOT d MATCHES "^\\$<")
        list(APPEND _compile_args "-I${d}")
      endif()
      # $<INSTALL_INTERFACE:...> and unknown genexes silently dropped
    endforeach()
  endif()

  get_target_property(_opts ${PROJECT_NAME} COMPILE_OPTIONS)
  if(_opts)
    foreach(opt ${_opts})
      if(opt MATCHES "^\\$<" OR opt MATCHES "-W")
        continue()
      endif()
      # Strip trailing > left over from split generator expressions e.g.
      # "-Wnull-dereference>" -> "-Wnull-dereference"
      string(REGEX REPLACE ">$" "" opt "${opt}")
      list(APPEND _compile_args ${opt})
    endforeach()
  endif()

  get_target_property(_opts ${PROJECT_NAME} COMPILE_DEFINITIONS)
  if(_opts)
    foreach(opt ${_opts})
      if(opt MATCHES "^\\$<" OR opt STREQUAL ">")
        continue()
      endif()
      # Strip trailing > left over from split generator expressions
      string(REGEX REPLACE ">$" "" opt "${opt}")
      list(APPEND _compile_args -D${opt})
    endforeach()
  endif()

  # Escape-hatch: transitive deps or supplemental flags not on the target.
  foreach(d ${LIBRA_NEGATIVE_TEST_INCLUDE_DIRS})
    list(APPEND _compile_args "-I${d}")
  endforeach()

  foreach(f ${LIBRA_NEGATIVE_TEST_COMPILE_FLAGS})
    list(APPEND _compile_args "${f}")
  endforeach()

  # ------------------------------------------------------------------
  # Write the response file at configure time via file(WRITE).
  #
  # No generator expressions remain in _compile_args at this point so
  # file(WRITE) is safe. One flag per line; GCC, Clang, and MSVC all support
  # this @file format natively.
  #
  # The std flag and -fsyntax-only are passed directly on the command line to
  # keep build output readable.
  # ------------------------------------------------------------------
  set(_rsp_file "${CMAKE_CURRENT_BINARY_DIR}/${test_name}.rsp")
  list(JOIN _compile_args "\n" _rsp_content)
  file(WRITE "${_rsp_file}" "${_rsp_content}\n")

  # ------------------------------------------------------------------
  # Locate companion .expected file. NAME_WE strips only the final extension
  # (.cpp / .c), leaving .neg in the stem. Strip it to get the true stem for the
  # companion lookup.
  # ------------------------------------------------------------------
  string(REGEX REPLACE "\\.neg$" "" _stem "${test_name}")
  set(_expected_file "${test_dir}/${_stem}.expected")
  set(_expected_fragment "")

  if(EXISTS ${_expected_file})
    file(READ ${_expected_file} _expected_fragment)
    string(STRIP "${_expected_fragment}" _expected_fragment)
  endif()

  # ------------------------------------------------------------------
  # Shell command that asserts compilation failure.
  #
  # Flags come from the response file (@_rsp_file); the std flag, -fsyntax-only,
  # and source path are passed directly.
  #
  # With .expected: assert failure AND that the fragment appears in stderr (tee
  # keeps the output visible in build logs). Without .expected: assert failure
  # only, suppress output.
  # ------------------------------------------------------------------
  set(_base_cmd "${_compiler} ${_std_flag} -fsyntax-only @${_rsp_file} ${t}")

  if(_expected_fragment)
    set(_shell_cmd
        "! ${_base_cmd} 2>&1 | tee /dev/stderr | grep -qF '${_expected_fragment}'"
    )
  else()
    set(_shell_cmd "! ${_base_cmd} 2>/dev/null")
  endif()

  add_custom_target(
    ${PROJECT_NAME}-${test_name}
    COMMAND sh -c "${_shell_cmd}"
    COMMENT "Negative compile test: ${test_name}"
    VERBATIM)

  if(INCLUDE_IN_CTEST)
    add_test(NAME ${test_name}
             COMMAND ${CMAKE_COMMAND} --build ${CMAKE_BINARY_DIR} --target
                     ${PROJECT_NAME}-${test_name})

    string(REPLACE "-tests" "" test_label ${UMBRELLA_TARGET})

    set_tests_properties(
      ${test_name}
      PROPERTIES LABELS
                 "${test_label}"
                 ENVIRONMENT
                 "BLESS=${BLESS}"
                 WORKING_DIRECTORY
                 ${CMAKE_SOURCE_DIR})
  endif()

  # Negative tests participate in the umbrella target so "make unit-tests"
  # builds and validates them alongside positive tests.
  add_dependencies(${UMBRELLA_TARGET} ${PROJECT_NAME}-${test_name})
  add_dependencies(build-and-test ${PROJECT_NAME}-${test_name})
endfunction()

# ##############################################################################
# Dispatch: compiled vs interpreted (Negative compile tests are registered
# directly, never reach this function)
# ##############################################################################
function(dispatch_enable_single_test t UMBRELLA_TARGET INCLUDE_IN_CTEST)
  get_filename_component(test_ext ${t} EXT)
  string(SUBSTRING ${test_ext} 1 -1 ext_key)

  if(ext_key IN_LIST _LIBRA_COMPILED_EXTENSIONS)
    enable_single_compiled_test(${t} ${UMBRELLA_TARGET} ${INCLUDE_IN_CTEST})
  else()
    enable_single_interpreted_test(${t} ${UMBRELLA_TARGET} ${INCLUDE_IN_CTEST})
  endif()
endfunction()

# ##############################################################################
# Configure test harness (C/C++ only)
# ##############################################################################
function(configure_test_harness)
  foreach(pkg ${LIBRA_TEST_HARNESS_PACKAGES})
    find_package(${pkg} CONFIG REQUIRED)
  endforeach()

  if(NOT TARGET ${PROJECT_NAME}-c-harness AND "${LIBRA_HAVE_c_test_harness}"
                                              MATCHES "YES")
    add_library(${PROJECT_NAME}-c-harness STATIC EXCLUDE_FROM_ALL
                ${LIBRA_c_test_harness})
    _libra_configure_standard(${PROJECT_NAME}-c-harness)

    set_target_properties(${PROJECT_NAME}-c-harness PROPERTIES LINKER_LANGUAGE
                                                               C)
    # Harness might depend on headers under <repo root>/tests
    target_include_directories(${PROJECT_NAME}-c-harness
                               PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

    # Have to link with the main project to propagate includes, defines, etc.
    target_link_libraries(${PROJECT_NAME}-c-harness ${PROJECT_NAME}
                          ${LIBRA_TEST_HARNESS_LIBS})
  endif()

  # Create C++ test harness
  if(NOT TARGET ${PROJECT_NAME}-cxx-harness AND "${LIBRA_HAVE_cxx_test_harness}"
                                                MATCHES "YES")
    add_library(${PROJECT_NAME}-cxx-harness STATIC EXCLUDE_FROM_ALL
                ${LIBRA_cxx_test_harness})
    _libra_configure_standard(${PROJECT_NAME}-cxx-harness)

    set_target_properties(${PROJECT_NAME}-cxx-harness PROPERTIES LINKER_LANGUAGE
                                                                 CXX)

    # Harness might depend on headers under <repo root>/tests
    target_include_directories(${PROJECT_NAME}-cxx-harness
                               PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

    # Have to link with the main project to propagate includes, defines, etc.
    target_link_libraries(${PROJECT_NAME}-cxx-harness ${PROJECT_NAME}
                          ${LIBRA_TEST_HARNESS_LIBS})

    # If the project is a C project, then we will probably be casting in the C
    # way, so turn off the usual compile warnings about this.
    #
    # This will only work with GCC/clang compilers, but that's OK for now, as
    # I'm not doing anything that requires running unit tests on strange
    # platforms requiring more exotic compilers.
    get_property(LANGUAGES_LIST GLOBAL PROPERTY ENABLED_LANGUAGES)
    if("C" IN_LIST LANGUAGES_LIST)
      target_compile_options(${PROJECT_NAME}-cxx-harness
                             PUBLIC -Wno-old-style-cast -Wno-useless-cast)
    endif()

  endif()
endfunction()

# ##############################################################################
# Helper: register all tests of one category (unit/integration/regression)
#
# Arguments: CATEGORY_LABEL   -- "unit", "integration", or "regression"
# UMBRELLA_TARGET  -- CMake target name, e.g. "unit-tests" CTEST_FLAG       --
# value of LIBRA_CTEST_INCLUDE_<X>_TESTS LIST_SUFFIX      -- suffix used in
# LIBRA_<ext>_<suffix> glob vars ("utests", "itests", "rtests") Sets in parent
# scope: _libra_n_<LIST_SUFFIX>  -- total count registered
# ##############################################################################
function(
  _libra_register_tests
  CATEGORY_LABEL
  UMBRELLA_TARGET
  CTEST_FLAG
  LIST_SUFFIX)
  set(_total 0)
  set(_breakdown "")
  foreach(ext ${_LIBRA_COMPILED_EXTENSIONS} ${_LIBRA_INTERPRETED_EXTENSIONS})
    string(REPLACE "." "_" ext_var ${ext})

    foreach(t ${LIBRA_${ext_var}_${LIST_SUFFIX}})
      string(FIND "${t}" ".#" _pos)
      if(NOT _pos EQUAL -1)
        continue()
      endif()
      dispatch_enable_single_test(${t} ${UMBRELLA_TARGET} ${CTEST_FLAG})
    endforeach()

    list(LENGTH LIBRA_${ext_var}_${LIST_SUFFIX} _n)
    math(EXPR _total "${_total} + ${_n}")
    if(_n GREATER 0)
      if(_breakdown STREQUAL "")
        set(_breakdown "${_n} .${ext}")
      else()
        string(APPEND _breakdown ", ${_n} .${ext}")
      endif()
    endif()
  endforeach()

  set(_libra_n_${LIST_SUFFIX}
      ${_total}
      PARENT_SCOPE)
  set(_libra_breakdown_${LIST_SUFFIX}
      "${_breakdown}"
      PARENT_SCOPE)
endfunction()

# ##############################################################################
# Helper: register negative compile tests for one category
#
# Arguments: NEG_LIST         -- list variable name, e.g. LIBRA_neg_utests
# UMBRELLA_TARGET  -- CMake target name CTEST_FLAG       -- value of
# LIBRA_CTEST_INCLUDE_<X>_TESTS
# ##############################################################################
function(_libra_register_neg_tests NEG_LIST UMBRELLA_TARGET CTEST_FLAG)
  foreach(t ${${NEG_LIST}})
    string(FIND "${t}" ".#" _pos)
    if(NOT _pos EQUAL -1)
      continue()
    endif()
    enable_single_negative_compile_test(${t} ${UMBRELLA_TARGET} ${CTEST_FLAG})
  endforeach()
endfunction()

# ##############################################################################
# Register all tests
# ##############################################################################
if(LIBRA_TESTS AND CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
  libra_message(STATUS "Configuring testing")
  # This also does enable_testing(), but also configures the
  # DartConfiguration.tcl file needed to run tests under valgrind
  include(CTest)

  # Basic test setup
  configure_test_harness()

  # Target for building and running all tests
  add_custom_target(
    build-and-test COMMAND ${CMAKE_CTEST_COMMAND} --test-dir
                           ${CMAKE_CURRENT_BINARY_DIR} --output-on-failure)

  # Target for building all unit tests
  add_custom_target(unit-tests)
  set_target_properties(unit-tests PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1
                                              EXCLUDE_FROM_ALL 1)
  # Target for building all integration tests
  add_custom_target(integration-tests)
  set_target_properties(integration-tests PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD
                                                     1 EXCLUDE_FROM_ALL 1)

  # Target for building all regression tests
  add_custom_target(regression-tests)
  set_target_properties(regression-tests PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1
                                                    EXCLUDE_FROM_ALL 1)
  add_custom_target(all-tests)
  set_target_properties(all-tests PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD 1
                                             EXCLUDE_FROM_ALL 1)

  add_dependencies(all-tests unit-tests integration-tests regression-tests)

  list(APPEND CMAKE_MESSAGE_INDENT " ")

  _libra_register_tests(unit unit-tests ${LIBRA_CTEST_INCLUDE_UNIT_TESTS}
                        utests)
  _libra_register_tests(integration integration-tests
                        ${LIBRA_CTEST_INCLUDE_INTEGRATION_TESTS} itests)
  _libra_register_tests(regression regression-tests
                        ${LIBRA_CTEST_INCLUDE_REGRESSION_TESTS} rtests)

  _libra_register_neg_tests(LIBRA_neg_utests unit-tests
                            ${LIBRA_CTEST_INCLUDE_UNIT_TESTS})
  _libra_register_neg_tests(LIBRA_neg_itests integration-tests
                            ${LIBRA_CTEST_INCLUDE_INTEGRATION_TESTS})
  _libra_register_neg_tests(LIBRA_neg_rtests regression-tests
                            ${LIBRA_CTEST_INCLUDE_REGRESSION_TESTS})

  list(LENGTH LIBRA_neg_utests _n_neg_u)
  list(LENGTH LIBRA_neg_itests _n_neg_i)
  list(LENGTH LIBRA_neg_rtests _n_neg_r)
  math(EXPR _n_neg_total "${_n_neg_u} + ${_n_neg_i} + ${_n_neg_r}")

  # Format each line as "N (breakdown)" or just "0" when empty
  foreach(_suffix utests itests rtests)
    if(_libra_breakdown_${_suffix} STREQUAL "")
      set(_libra_summary_${_suffix} "${_libra_n_${_suffix}}")
    else()
      set(_libra_summary_${_suffix}
          "${_libra_n_${_suffix}} (${_libra_breakdown_${_suffix}})")
    endif()
  endforeach()

  libra_message(STATUS "unit:        ${_libra_summary_utests}")
  libra_message(STATUS "integration: ${_libra_summary_itests}")
  libra_message(STATUS "regression:  ${_libra_summary_rtests}")
  libra_message(STATUS "negative:    ${_n_neg_total}")

  list(POP_BACK CMAKE_MESSAGE_INDENT)
endif()
